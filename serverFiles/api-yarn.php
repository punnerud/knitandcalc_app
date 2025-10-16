<?php
/**
 * KnitAndCalc Yarn Stash API Endpoint
 * Receives and stores anonymous yarn stash data from iOS app
 */

header('Content-Type: application/json');

// Helper function to log request
function logRequest($db, $ipAddress, $deviceInfo, $appVersion, $httpMethod, $rawBody, $errorMessage, $statusCode, $userId = null, $yarnCount = null, $hasPayloadHash = 0, $hasSaltedHash = 0, $hasIdempotencyKey = 0) {
    try {
        $stmt = $db->prepare('INSERT INTO request_log
            (timestamp, ip_address, device_info, app_version, http_method, raw_body, error_message, status_code, user_id, yarn_count, has_payload_hash, has_salted_hash, has_idempotency_key)
            VALUES (:timestamp, :ip_address, :device_info, :app_version, :http_method, :raw_body, :error_message, :status_code, :user_id, :yarn_count, :has_payload_hash, :has_salted_hash, :has_idempotency_key)');
        $stmt->execute([
            ':timestamp' => date('c'),
            ':ip_address' => $ipAddress,
            ':device_info' => $deviceInfo,
            ':app_version' => $appVersion,
            ':http_method' => $httpMethod,
            ':raw_body' => substr($rawBody, 0, 10000), // Limit to 10KB
            ':error_message' => $errorMessage,
            ':status_code' => $statusCode,
            ':user_id' => $userId,
            ':yarn_count' => $yarnCount,
            ':has_payload_hash' => $hasPayloadHash,
            ':has_salted_hash' => $hasSaltedHash,
            ':has_idempotency_key' => $hasIdempotencyKey
        ]);
    } catch (PDOException $e) {
        error_log('Failed to log request: ' . $e->getMessage());
    }
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Get headers early for logging
$payloadHash = $_SERVER['HTTP_X_PAYLOAD_HASH'] ?? null;
$payloadHashSalted = $_SERVER['HTTP_X_PAYLOAD_HASH_SALTED'] ?? null;
$idempotencyKey = $_SERVER['HTTP_X_IDEMPOTENCY_KEY'] ?? null;
$deviceInfo = $_SERVER['HTTP_X_DEVICE_INFO'] ?? $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
$appVersion = $_SERVER['HTTP_X_APP_VERSION'] ?? 'Unknown';

// Get client IP address early for logging
$ipAddress = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
if (strpos($ipAddress, ',') !== false) {
    $ipAddress = trim(explode(',', $ipAddress)[0]);
}

// Read raw POST data
$rawInput = file_get_contents('php://input');

// Open database early so we can log all requests
$dbPath = __DIR__ . '/yarn.db';
try {
    $db = new PDO('sqlite:' . $dbPath);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Create request log table for ALL requests (including failed ones)
    $db->exec('CREATE TABLE IF NOT EXISTS request_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        ip_address TEXT,
        device_info TEXT,
        app_version TEXT,
        http_method TEXT,
        raw_body TEXT,
        error_message TEXT,
        status_code INTEGER,
        user_id TEXT,
        yarn_count INTEGER,
        has_payload_hash INTEGER DEFAULT 0,
        has_salted_hash INTEGER DEFAULT 0,
        has_idempotency_key INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )');

    // Create index on request_log timestamp
    $db->exec('CREATE INDEX IF NOT EXISTS idx_request_log_timestamp ON request_log(timestamp DESC)');

} catch (PDOException $e) {
    error_log('Database connection error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Database error']);
    exit;
}

// Validate empty request body
if (empty($rawInput)) {
    logRequest($db, $ipAddress, $deviceInfo, $appVersion, $_SERVER['REQUEST_METHOD'], '', 'Empty request body', 400);
    http_response_code(400);
    echo json_encode(['error' => 'Empty request body']);
    exit;
}

// Parse JSON
$payload = json_decode($rawInput, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    logRequest($db, $ipAddress, $deviceInfo, $appVersion, $_SERVER['REQUEST_METHOD'], $rawInput, 'Invalid JSON: ' . json_last_error_msg(), 400);
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON: ' . json_last_error_msg()]);
    exit;
}

// Validate required fields
if (!isset($payload['userId']) || !isset($payload['timestamp']) || !isset($payload['yarnStash'])) {
    $missingFields = [];
    if (!isset($payload['userId'])) $missingFields[] = 'userId';
    if (!isset($payload['timestamp'])) $missingFields[] = 'timestamp';
    if (!isset($payload['yarnStash'])) $missingFields[] = 'yarnStash';

    logRequest(
        $db,
        $ipAddress,
        $deviceInfo,
        $appVersion,
        $_SERVER['REQUEST_METHOD'],
        $rawInput,
        'Missing required fields: ' . implode(', ', $missingFields),
        400,
        $payload['userId'] ?? null,
        isset($payload['yarnStash']) && is_array($payload['yarnStash']) ? count($payload['yarnStash']) : null,
        $payloadHash ? 1 : 0,
        $payloadHashSalted ? 1 : 0,
        $idempotencyKey ? 1 : 0
    );
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields (userId, timestamp, yarnStash)']);
    exit;
}

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
        logRequest(
            $db,
            $ipAddress,
            $deviceInfo,
            $appVersion,
            $_SERVER['REQUEST_METHOD'],
            $rawInput,
            'Invalid payload hash',
            400,
            $payload['userId'],
            is_array($payload['yarnStash']) ? count($payload['yarnStash']) : 0,
            1,
            $payloadHashSalted ? 1 : 0,
            $idempotencyKey ? 1 : 0
        );
        http_response_code(400);
        echo json_encode([
            'error' => 'Invalid payload hash',
            'expected' => $calculatedHash,
            'received' => $payloadHash
        ]);
        exit;
    }

    if (!$saltedHashValid) {
        logRequest(
            $db,
            $ipAddress,
            $deviceInfo,
            $appVersion,
            $_SERVER['REQUEST_METHOD'],
            $rawInput,
            'Invalid salted payload hash',
            400,
            $payload['userId'],
            is_array($payload['yarnStash']) ? count($payload['yarnStash']) : 0,
            1,
            1,
            $idempotencyKey ? 1 : 0
        );
        http_response_code(400);
        echo json_encode([
            'error' => 'Invalid salted payload hash',
            'expected' => $calculatedHashSalted,
            'received' => $payloadHashSalted
        ]);
        exit;
    }
}

// Create main submissions table if it doesn't exist
try {
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

    // Log successful request
    logRequest(
        $db,
        $ipAddress,
        $deviceInfo,
        $appVersion,
        $_SERVER['REQUEST_METHOD'],
        $rawInput,
        null, // No error
        200,
        $payload['userId'],
        is_array($payload['yarnStash']) ? count($payload['yarnStash']) : 0,
        $payloadHash ? 1 : 0,
        $payloadHashSalted ? 1 : 0,
        $idempotencyKey ? 1 : 0
    );

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

    // Try to log the database error (might fail if it's a DB connection issue)
    try {
        logRequest(
            $db,
            $ipAddress,
            $deviceInfo,
            $appVersion,
            $_SERVER['REQUEST_METHOD'],
            $rawInput,
            'Database error: ' . $e->getMessage(),
            500,
            $payload['userId'] ?? null,
            isset($payload['yarnStash']) && is_array($payload['yarnStash']) ? count($payload['yarnStash']) : null,
            $payloadHash ? 1 : 0,
            $payloadHashSalted ? 1 : 0,
            $idempotencyKey ? 1 : 0
        );
    } catch (Exception $logError) {
        // Ignore logging errors
    }

    http_response_code(500);
    echo json_encode(['error' => 'Database error']);
    exit;
}
