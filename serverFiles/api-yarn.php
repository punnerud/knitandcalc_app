<?php
/**
 * KnitAndCalc Yarn Stash API Endpoint
 * Receives and stores anonymous yarn stash data from iOS app
 */

header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Read raw POST data
$rawInput = file_get_contents('php://input');
if (empty($rawInput)) {
    http_response_code(400);
    echo json_encode(['error' => 'Empty request body']);
    exit;
}

// Parse JSON
$payload = json_decode($rawInput, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON: ' . json_last_error_msg()]);
    exit;
}

// Validate required fields
if (!isset($payload['userId']) || !isset($payload['timestamp']) || !isset($payload['yarnStash'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields (userId, timestamp, yarnStash)']);
    exit;
}

// Get headers
$payloadHash = $_SERVER['HTTP_X_PAYLOAD_HASH'] ?? null;
$payloadHashSalted = $_SERVER['HTTP_X_PAYLOAD_HASH_SALTED'] ?? null;
$idempotencyKey = $_SERVER['HTTP_X_IDEMPOTENCY_KEY'] ?? null;
$deviceInfo = $_SERVER['HTTP_X_DEVICE_INFO'] ?? $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
$appVersion = $_SERVER['HTTP_X_APP_VERSION'] ?? 'Unknown';

// Calculate idempotency key if not provided (hash of yarnStash array)
if (!$idempotencyKey && isset($payload['yarnStash'])) {
    $idempotencyKey = hash('sha256', json_encode($payload['yarnStash']));
}

// Validate hashes
$hashValid = false;
$saltedHashValid = false;

if ($payloadHash && $payloadHashSalted) {
    $calculatedHash = hash('sha256', $rawInput);
    $calculatedHashSalted = hash('sha256', $rawInput . 'essTF4dY6639');

    $hashValid = ($calculatedHash === $payloadHash);
    $saltedHashValid = ($calculatedHashSalted === $payloadHashSalted);

    // Reject if hashes don't match
    if (!$hashValid) {
        http_response_code(400);
        echo json_encode([
            'error' => 'Invalid payload hash',
            'expected' => $calculatedHash,
            'received' => $payloadHash
        ]);
        exit;
    }

    if (!$saltedHashValid) {
        http_response_code(400);
        echo json_encode([
            'error' => 'Invalid salted payload hash',
            'expected' => $calculatedHashSalted,
            'received' => $payloadHashSalted
        ]);
        exit;
    }
}

// Get client IP address
$ipAddress = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
// Clean up IP if it's a comma-separated list (from proxy)
if (strpos($ipAddress, ',') !== false) {
    $ipAddress = trim(explode(',', $ipAddress)[0]);
}

// Open/create SQLite database
$dbPath = __DIR__ . '/yarn.db';
try {
    $db = new PDO('sqlite:' . $dbPath);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Create table if it doesn't exist
    $db->exec('CREATE TABLE IF NOT EXISTS yarn_stash_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        idempotency_key TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        timestamp_first_received TEXT NOT NULL,
        timestamp_last_received TEXT NOT NULL,
        timestamp_file TEXT NOT NULL,
        ip_address TEXT,
        device_info TEXT,
        app_version TEXT,
        payload_hash TEXT,
        payload_hash_salted TEXT,
        hash_valid INTEGER DEFAULT 0,
        salted_hash_valid INTEGER DEFAULT 0,
        yarn_count INTEGER,
        receive_count INTEGER DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )');

    // Create indexes
    $db->exec('CREATE INDEX IF NOT EXISTS idx_user_id ON yarn_stash_submissions(user_id)');
    $db->exec('CREATE INDEX IF NOT EXISTS idx_idempotency ON yarn_stash_submissions(user_id, idempotency_key)');
    $db->exec('CREATE INDEX IF NOT EXISTS idx_timestamp_received ON yarn_stash_submissions(timestamp_last_received)');

    // Check if this exact data has been received before (idempotency check)
    $checkStmt = $db->prepare('SELECT id, receive_count FROM yarn_stash_submissions
        WHERE user_id = :user_id AND idempotency_key = :idempotency_key LIMIT 1');
    $checkStmt->execute([
        ':user_id' => $payload['userId'],
        ':idempotency_key' => $idempotencyKey
    ]);
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

    $receiveCount = 1;
    $isUpdate = false;

    if ($existing) {
        // Data already exists - update timestamp_last_received and increment receive_count
        $updateStmt = $db->prepare('UPDATE yarn_stash_submissions
            SET timestamp_last_received = :timestamp_last_received,
                receive_count = receive_count + 1,
                ip_address = :ip_address,
                device_info = :device_info,
                app_version = :app_version,
                hash_valid = :hash_valid,
                salted_hash_valid = :salted_hash_valid
            WHERE id = :id');
        $updateStmt->execute([
            ':timestamp_last_received' => date('c'),
            ':ip_address' => $ipAddress,
            ':device_info' => $deviceInfo,
            ':app_version' => $appVersion,
            ':hash_valid' => $hashValid ? 1 : 0,
            ':salted_hash_valid' => $saltedHashValid ? 1 : 0,
            ':id' => $existing['id']
        ]);
        $receiveCount = $existing['receive_count'] + 1;
        $isUpdate = true;
    } else {
        // New data - insert
        $insertStmt = $db->prepare('INSERT INTO yarn_stash_submissions
            (user_id, idempotency_key, payload_json, timestamp_first_received, timestamp_last_received, timestamp_file, ip_address, device_info, app_version, payload_hash, payload_hash_salted, hash_valid, salted_hash_valid, yarn_count)
            VALUES
            (:user_id, :idempotency_key, :payload_json, :timestamp_first_received, :timestamp_last_received, :timestamp_file, :ip_address, :device_info, :app_version, :payload_hash, :payload_hash_salted, :hash_valid, :salted_hash_valid, :yarn_count)');

        $now = date('c');
        $insertStmt->execute([
            ':user_id' => $payload['userId'],
            ':idempotency_key' => $idempotencyKey,
            ':payload_json' => $rawInput,
            ':timestamp_first_received' => $now,
            ':timestamp_last_received' => $now,
            ':timestamp_file' => $payload['timestamp'],
            ':ip_address' => $ipAddress,
            ':device_info' => $deviceInfo,
            ':app_version' => $appVersion,
            ':payload_hash' => $payloadHash,
            ':payload_hash_salted' => $payloadHashSalted,
            ':hash_valid' => $hashValid ? 1 : 0,
            ':salted_hash_valid' => $saltedHashValid ? 1 : 0,
            ':yarn_count' => is_array($payload['yarnStash']) ? count($payload['yarnStash']) : 0
        ]);
    }

    // Success response
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => $isUpdate ? 'Yarn stash data updated (no changes)' : 'Yarn stash data received (new)',
        'received_at' => date('c'),
        'yarn_count' => is_array($payload['yarnStash']) ? count($payload['yarnStash']) : 0,
        'idempotency_key' => $idempotencyKey,
        'receive_count' => $receiveCount,
        'is_update' => $isUpdate
    ]);

} catch (PDOException $e) {
    error_log('Database error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Database error']);
    exit;
}
