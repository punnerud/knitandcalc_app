<?php
session_start();

// Configuration
define('ADMIN_USERNAME', 'morten');
define('ADMIN_PASSWORD', 'TzOFT471Z6Og');
define('DB_PATH', __DIR__ . '/yarn.db');

// Handle login
if (isset($_POST['login'])) {
    if ($_POST['username'] === ADMIN_USERNAME && $_POST['password'] === ADMIN_PASSWORD) {
        $_SESSION['admin_logged_in'] = true;
        header('Location: admin.php');
        exit;
    } else {
        $login_error = 'Feil brukernavn eller passord';
    }
}

// Handle logout
if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: admin.php');
    exit;
}

// Check if logged in
$logged_in = isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;

// Get filter parameters
$user_filter = isset($_GET['user_id']) ? $_GET['user_id'] : null;
$expand_user = isset($_GET['expand']) ? $_GET['expand'] : null;

?>
<!DOCTYPE html>
<html lang="no">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>KnitAndCalc Admin</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f7;
            padding: 20px;
            color: #1d1d1f;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        .header {
            background: white;
            padding: 20px 30px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 28px;
            font-weight: 600;
        }

        .logout-btn {
            background: #ff3b30;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
        }

        .logout-btn:hover {
            background: #e6342a;
        }

        .login-container {
            max-width: 400px;
            margin: 100px auto;
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .login-container h2 {
            margin-bottom: 30px;
            font-size: 24px;
            font-weight: 600;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            font-size: 14px;
        }

        .form-group input {
            width: 100%;
            padding: 12px;
            border: 1px solid #d2d2d7;
            border-radius: 8px;
            font-size: 16px;
        }

        .form-group input:focus {
            outline: none;
            border-color: #007aff;
        }

        .login-btn {
            width: 100%;
            background: #007aff;
            color: white;
            padding: 14px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 500;
        }

        .login-btn:hover {
            background: #0051d5;
        }

        .error {
            background: #ffebee;
            color: #c62828;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .stat-card h3 {
            font-size: 14px;
            color: #86868b;
            margin-bottom: 8px;
            font-weight: 500;
        }

        .stat-card .value {
            font-size: 32px;
            font-weight: 600;
            color: #007aff;
        }

        .stat-card .label {
            font-size: 14px;
            color: #86868b;
            margin-top: 4px;
        }

        .users-table {
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            overflow: hidden;
        }

        .table-wrapper {
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 600px;
        }

        thead {
            background: #f5f5f7;
        }

        th {
            padding: 16px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
            color: #1d1d1f;
        }

        td {
            padding: 16px;
            border-top: 1px solid #f5f5f7;
            font-size: 14px;
        }

        tbody tr:hover {
            background: #fafafa;
        }

        .expand-btn {
            background: #007aff;
            color: white;
            padding: 6px 12px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 12px;
            text-decoration: none;
            display: inline-block;
        }

        .expand-btn:hover {
            background: #0051d5;
        }

        .collapse-btn {
            background: #86868b;
            color: white;
            padding: 6px 12px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 12px;
            text-decoration: none;
            display: inline-block;
        }

        .collapse-btn:hover {
            background: #6e6e73;
        }

        .yarn-details {
            background: #f9f9f9;
            padding: 20px;
            margin: 10px 0;
            border-radius: 8px;
        }

        .yarn-item {
            background: white;
            padding: 15px;
            margin: 10px 0;
            border-radius: 8px;
            border-left: 4px solid #007aff;
        }

        .yarn-item h4 {
            margin-bottom: 10px;
            color: #1d1d1f;
        }

        .yarn-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 10px;
            font-size: 13px;
        }

        .yarn-field {
            padding: 8px 0;
        }

        .yarn-field label {
            font-weight: 600;
            color: #86868b;
            display: block;
            font-size: 11px;
            text-transform: uppercase;
            margin-bottom: 4px;
        }

        .yarn-field span {
            color: #1d1d1f;
        }

        .history-section {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid #e5e5e5;
        }

        .history-section h3 {
            margin-bottom: 15px;
            color: #1d1d1f;
        }

        .history-item {
            background: #fafafa;
            padding: 12px;
            margin: 8px 0;
            border-radius: 6px;
            font-size: 13px;
        }

        /* Mobile Responsive */
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }

            .header {
                padding: 15px;
                flex-direction: column;
                gap: 10px;
                text-align: center;
            }

            .header h1 {
                font-size: 20px;
            }

            .stats-grid {
                grid-template-columns: 1fr;
            }

            .stat-card .value {
                font-size: 24px;
            }

            th, td {
                padding: 10px 8px;
                font-size: 12px;
            }

            th:nth-child(1), td:nth-child(1) {
                min-width: 80px;
            }

            th:nth-child(2), td:nth-child(2) {
                min-width: 110px;
            }

            th:nth-child(3), td:nth-child(3) {
                min-width: 70px;
            }

            th:nth-child(4), td:nth-child(4) {
                min-width: 70px;
            }

            th:nth-child(5), td:nth-child(5) {
                min-width: 70px;
            }

            th:nth-child(6), td:nth-child(6) {
                min-width: 80px;
            }

            th:nth-child(7), td:nth-child(7) {
                min-width: 70px;
            }

            th:nth-child(8), td:nth-child(8) {
                min-width: 90px;
            }

            .expand-btn, .collapse-btn {
                padding: 8px 12px;
                font-size: 11px;
            }

            .yarn-grid {
                grid-template-columns: 1fr;
            }

            .login-container {
                padding: 30px 20px;
                margin: 50px auto;
            }
        }

        @media (max-width: 480px) {
            .header h1 {
                font-size: 18px;
            }

            .stat-card .value {
                font-size: 20px;
            }

            th, td {
                padding: 8px 6px;
                font-size: 11px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <?php if (!$logged_in): ?>
            <!-- Login Form -->
            <div class="login-container">
                <h2>Admin Login</h2>
                <?php if (isset($login_error)): ?>
                    <div class="error"><?php echo htmlspecialchars($login_error); ?></div>
                <?php endif; ?>
                <form method="POST">
                    <div class="form-group">
                        <label>Brukernavn</label>
                        <input type="text" name="username" required autofocus>
                    </div>
                    <div class="form-group">
                        <label>Passord</label>
                        <input type="password" name="password" required>
                    </div>
                    <button type="submit" name="login" class="login-btn">Logg inn</button>
                </form>
            </div>
        <?php else: ?>
            <!-- Admin Dashboard -->
            <div class="header">
                <h1>KnitAndCalc Admin</h1>
                <a href="?logout" class="logout-btn">Logg ut</a>
            </div>

            <?php
            // Connect to database
            try {
                $db = new PDO('sqlite:' . DB_PATH);
                $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

                // Get overall statistics
                $stmt = $db->query("SELECT COUNT(*) as total_submissions FROM yarn_stash_submissions");
                $total_submissions = $stmt->fetch(PDO::FETCH_ASSOC)['total_submissions'];

                $stmt = $db->query("SELECT COUNT(DISTINCT user_id) as unique_users FROM yarn_stash_submissions");
                $unique_users = $stmt->fetch(PDO::FETCH_ASSOC)['unique_users'];

                // Calculate total yarns, meters, and grams (only latest submission per user)
                $total_yarn_count = 0;
                $total_meters = 0;
                $total_grams = 0;

                // Get latest submission for each user
                $stmt = $db->query("
                    SELECT user_id, MAX(timestamp_last_received) as last_received
                    FROM yarn_stash_submissions
                    GROUP BY user_id
                ");
                $latest_submissions = $stmt->fetchAll(PDO::FETCH_ASSOC);

                foreach ($latest_submissions as $sub) {
                    // Get the actual latest payload for this user
                    $payload_stmt = $db->prepare("
                        SELECT payload_json
                        FROM yarn_stash_submissions
                        WHERE user_id = :user_id AND timestamp_last_received = :last_received
                        LIMIT 1
                    ");
                    $payload_stmt->execute([
                        ':user_id' => $sub['user_id'],
                        ':last_received' => $sub['last_received']
                    ]);
                    $row = $payload_stmt->fetch(PDO::FETCH_ASSOC);

                    if ($row) {
                        $payload = json_decode($row['payload_json'], true);
                        if (isset($payload['yarnStash']) && is_array($payload['yarnStash'])) {
                            foreach ($payload['yarnStash'] as $yarn) {
                                $total_yarn_count++;
                                if (isset($yarn['numberOfSkeins']) && isset($yarn['lengthPerSkein'])) {
                                    $total_meters += $yarn['numberOfSkeins'] * $yarn['lengthPerSkein'];
                                }
                                if (isset($yarn['numberOfSkeins']) && isset($yarn['weightPerSkein'])) {
                                    $total_grams += $yarn['numberOfSkeins'] * $yarn['weightPerSkein'];
                                }
                            }
                        }
                    }
                }

                // Get last 5 requests from request_log
                $last_requests_stmt = $db->query("
                    SELECT * FROM request_log
                    ORDER BY id DESC
                    LIMIT 5
                ");
                $last_requests = $last_requests_stmt->fetchAll(PDO::FETCH_ASSOC);

                ?>

                <!-- Last 5 Requests Section -->
                <?php if (count($last_requests) > 0): ?>
                <div class="users-table" style="margin-bottom: 20px;">
                    <div style="padding: 20px; border-bottom: 1px solid #f5f5f7;">
                        <h2 style="font-size: 20px; font-weight: 600; margin: 0;">Siste 5 forespørsler</h2>
                        <p style="font-size: 14px; color: #86868b; margin-top: 8px;">Inkluderer både vellykkede og feilede forespørsler</p>
                    </div>
                    <div class="table-wrapper">
                        <table>
                            <thead>
                                <tr>
                                    <th>Tidspunkt</th>
                                    <th>Status</th>
                                    <th>Bruker ID</th>
                                    <th>Garn</th>
                                    <th>Feilmelding</th>
                                    <th>App versjon</th>
                                    <th>IP</th>
                                </tr>
                            </thead>
                            <tbody>
                            <?php foreach ($last_requests as $req): ?>
                                <tr style="<?php echo $req['status_code'] == 200 ? 'background: #f0f9ff;' : 'background: #fff5f5;'; ?>">
                                    <td style="font-size: 12px;"><?php echo date('Y-m-d H:i:s', strtotime($req['timestamp'])); ?></td>
                                    <td>
                                        <span style="padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 500; <?php echo $req['status_code'] == 200 ? 'background: #d1fae5; color: #065f46;' : 'background: #fee; color: #991b1b;'; ?>">
                                            <?php echo $req['status_code']; ?>
                                        </span>
                                    </td>
                                    <td><code style="font-size: 11px;"><?php echo $req['user_id'] ? substr(htmlspecialchars($req['user_id']), 0, 8) . '...' : '-'; ?></code></td>
                                    <td><?php echo $req['yarn_count'] ?? '-'; ?></td>
                                    <td style="max-width: 250px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 12px;">
                                        <?php echo $req['error_message'] ? htmlspecialchars($req['error_message']) : '<span style="color: #10b981;">✓ Success</span>'; ?>
                                    </td>
                                    <td style="font-size: 12px;"><?php echo htmlspecialchars($req['app_version']); ?></td>
                                    <td style="font-size: 11px;"><?php echo htmlspecialchars($req['ip_address']); ?></td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
                <?php endif; ?>

                <!-- Statistics Cards -->
                <div class="stats-grid">
                    <div class="stat-card">
                        <h3>Unike brukere</h3>
                        <div class="value"><?php echo number_format($unique_users, 0, ',', ' '); ?></div>
                    </div>
                    <div class="stat-card">
                        <h3>Totalt antall innsendinger</h3>
                        <div class="value"><?php echo number_format($total_submissions, 0, ',', ' '); ?></div>
                    </div>
                    <div class="stat-card">
                        <h3>Totalt antall garn</h3>
                        <div class="value"><?php echo number_format($total_yarn_count, 0, ',', ' '); ?></div>
                        <div class="label">nøster</div>
                    </div>
                    <div class="stat-card">
                        <h3>Totalt meter</h3>
                        <div class="value"><?php echo number_format($total_meters, 0, ',', ' '); ?></div>
                        <div class="label">meter</div>
                    </div>
                    <div class="stat-card">
                        <h3>Totalt gram</h3>
                        <div class="value"><?php echo number_format($total_grams, 0, ',', ' '); ?></div>
                        <div class="label">gram</div>
                    </div>
                </div>

                <!-- Users Table -->
                <div class="users-table">
                    <div class="table-wrapper">
                        <table>
                            <thead>
                                <tr>
                                    <th>Bruker ID</th>
                                    <th>Siste mottatt</th>
                                    <th>Antall garn</th>
                                    <th>Meter</th>
                                    <th>Gram</th>
                                    <th>Antall innsendinger</th>
                                    <th>App versjon</th>
                                    <th>Handlinger</th>
                                </tr>
                            </thead>
                            <tbody>
                            <?php
                            // Get users with their latest submission info
                            $users_stmt = $db->query("
                                SELECT
                                    user_id,
                                    MAX(timestamp_last_received) as last_received,
                                    COUNT(*) as submission_count
                                FROM yarn_stash_submissions
                                GROUP BY user_id
                                ORDER BY last_received DESC
                            ");

                            while ($user_row = $users_stmt->fetch(PDO::FETCH_ASSOC)):
                                $is_expanded = ($expand_user === $user_row['user_id']);

                                // Get the actual latest submission for this user
                                $latest_stmt = $db->prepare("
                                    SELECT payload_json, yarn_count, app_version
                                    FROM yarn_stash_submissions
                                    WHERE user_id = :user_id AND timestamp_last_received = :last_received
                                    LIMIT 1
                                ");
                                $latest_stmt->execute([
                                    ':user_id' => $user_row['user_id'],
                                    ':last_received' => $user_row['last_received']
                                ]);
                                $row = $latest_stmt->fetch(PDO::FETCH_ASSOC);

                                if (!$row) continue;

                                // Calculate meters and grams for this user's latest submission
                                $user_meters = 0;
                                $user_grams = 0;
                                $payload = json_decode($row['payload_json'], true);
                                if (isset($payload['yarnStash']) && is_array($payload['yarnStash'])) {
                                    foreach ($payload['yarnStash'] as $yarn) {
                                        if (isset($yarn['numberOfSkeins']) && isset($yarn['lengthPerSkein'])) {
                                            $user_meters += $yarn['numberOfSkeins'] * $yarn['lengthPerSkein'];
                                        }
                                        if (isset($yarn['numberOfSkeins']) && isset($yarn['weightPerSkein'])) {
                                            $user_grams += $yarn['numberOfSkeins'] * $yarn['weightPerSkein'];
                                        }
                                    }
                                }
                            ?>
                                <tr>
                                    <td><code><?php echo substr(htmlspecialchars($user_row['user_id']), 0, 8); ?>...</code></td>
                                    <td><?php echo date('Y-m-d H:i', strtotime($user_row['last_received'])); ?></td>
                                    <td><?php echo $row['yarn_count']; ?></td>
                                    <td><?php echo number_format($user_meters, 0, ',', ' '); ?></td>
                                    <td><?php echo number_format($user_grams, 0, ',', ' '); ?></td>
                                    <td><?php echo $user_row['submission_count']; ?></td>
                                    <td><?php echo htmlspecialchars($row['app_version']); ?></td>
                                    <td>
                                        <?php if ($is_expanded): ?>
                                            <a href="admin.php" class="collapse-btn">Skjul</a>
                                        <?php else: ?>
                                            <a href="?expand=<?php echo urlencode($user_row['user_id']); ?>" class="expand-btn">Vis detaljer</a>
                                        <?php endif; ?>
                                    </td>
                                </tr>

                                <?php if ($is_expanded): ?>
                                <tr>
                                    <td colspan="8">
                                        <div class="yarn-details">
                                            <h3>Garndetaljer for bruker: <?php echo htmlspecialchars($user_row['user_id']); ?></h3>

                                            <?php
                                            // Payload is already loaded above
                                            // $payload = json_decode($row['payload_json'], true);

                                            if (isset($payload['yarnStash']) && is_array($payload['yarnStash'])):
                                                foreach ($payload['yarnStash'] as $yarn):
                                            ?>
                                                <div class="yarn-item">
                                                    <h4><?php echo htmlspecialchars($yarn['brand'] ?? 'Ukjent'); ?> - <?php echo htmlspecialchars($yarn['type'] ?? 'Ukjent'); ?></h4>
                                                    <div class="yarn-grid">
                                                        <div class="yarn-field">
                                                            <label>Farge</label>
                                                            <span><?php echo htmlspecialchars($yarn['color'] ?? '-'); ?></span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Fargenummer</label>
                                                            <span><?php echo htmlspecialchars($yarn['colorNumber'] ?? '-'); ?></span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Partinummer</label>
                                                            <span><?php echo htmlspecialchars($yarn['lotNumber'] ?? '-'); ?></span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Antall nøster</label>
                                                            <span><?php echo number_format($yarn['numberOfSkeins'] ?? 0, 1, ',', ' '); ?></span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Vekt per nøste</label>
                                                            <span><?php echo number_format($yarn['weightPerSkein'] ?? 0, 0, ',', ' '); ?> g</span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Lengde per nøste</label>
                                                            <span><?php echo number_format($yarn['lengthPerSkein'] ?? 0, 0, ',', ' '); ?> m</span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Total vekt</label>
                                                            <span><?php echo number_format(($yarn['numberOfSkeins'] ?? 0) * ($yarn['weightPerSkein'] ?? 0), 0, ',', ' '); ?> g</span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Total lengde</label>
                                                            <span><?php echo number_format(($yarn['numberOfSkeins'] ?? 0) * ($yarn['lengthPerSkein'] ?? 0), 0, ',', ' '); ?> m</span>
                                                        </div>
                                                        <div class="yarn-field">
                                                            <label>Strikkefasthet</label>
                                                            <span><?php echo htmlspecialchars($yarn['gauge'] ?? '-'); ?></span>
                                                        </div>
                                                    </div>
                                                    <?php if (!empty($yarn['notes'])): ?>
                                                    <div class="yarn-field" style="margin-top: 10px;">
                                                        <label>Notater</label>
                                                        <span><?php echo nl2br(htmlspecialchars($yarn['notes'])); ?></span>
                                                    </div>
                                                    <?php endif; ?>
                                                </div>
                                            <?php
                                                endforeach;
                                            endif;
                                            ?>

                                            <!-- History section -->
                                            <?php
                                            // Get all submissions for this user
                                            $history_stmt = $db->prepare("
                                                SELECT
                                                    timestamp_last_received,
                                                    yarn_count,
                                                    app_version,
                                                    receive_count
                                                FROM yarn_stash_submissions
                                                WHERE user_id = :user_id
                                                ORDER BY timestamp_last_received DESC
                                            ");
                                            $history_stmt->execute([':user_id' => $user_row['user_id']]);
                                            $history = $history_stmt->fetchAll(PDO::FETCH_ASSOC);

                                            if (count($history) > 1):
                                            ?>
                                            <div class="history-section">
                                                <h3>Historikk (<?php echo count($history); ?> innsendinger)</h3>
                                                <?php foreach ($history as $hist): ?>
                                                <div class="history-item">
                                                    <strong><?php echo date('Y-m-d H:i:s', strtotime($hist['timestamp_last_received'])); ?></strong>
                                                    - <?php echo $hist['yarn_count']; ?> garn
                                                    - App v<?php echo htmlspecialchars($hist['app_version']); ?>
                                                    - Mottatt <?php echo $hist['receive_count']; ?> gang(er)
                                                </div>
                                                <?php endforeach; ?>
                                            </div>
                                            <?php endif; ?>
                                        </div>
                                    </td>
                                </tr>
                                <?php endif; ?>
                            <?php endwhile; ?>
                            </tbody>
                        </table>
                    </div>
                </div>

            <?php
            } catch (PDOException $e) {
                echo '<div class="error">Database feil: ' . htmlspecialchars($e->getMessage()) . '</div>';
            }
            ?>
        <?php endif; ?>
    </div>
</body>
</html>
