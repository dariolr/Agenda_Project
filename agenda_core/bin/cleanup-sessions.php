#!/usr/bin/env php
<?php
/**
 * Session Cleanup Worker
 * 
 * Removes expired and revoked sessions older than 30 days from:
 * - auth_sessions (operators)
 * - client_sessions (customers)
 * 
 * Run via cron: 0 3 * * 0 /usr/bin/php /path/to/cleanup-sessions.php
 * (Every Sunday at 3 AM)
 */

declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;

// Load environment
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// Database connection
try {
    $pdo = new PDO(
        sprintf(
            'mysql:host=%s;dbname=%s;charset=utf8mb4',
            $_ENV['DB_HOST'],
            $_ENV['DB_DATABASE']
        ),
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (PDOException $e) {
    echo "Database connection failed: " . $e->getMessage() . PHP_EOL;
    exit(1);
}

$retentionDays = 30;
$cutoffDate = date('Y-m-d H:i:s', strtotime("-{$retentionDays} days"));

echo "Session Cleanup - " . date('Y-m-d H:i:s') . PHP_EOL;
echo "Removing sessions older than {$retentionDays} days (before {$cutoffDate})" . PHP_EOL;
echo str_repeat('-', 60) . PHP_EOL;

$totalDeleted = 0;

// Cleanup auth_sessions (operators)
$stmt = $pdo->prepare("
    DELETE FROM auth_sessions 
    WHERE expires_at < :cutoff 
       OR (revoked_at IS NOT NULL AND revoked_at < :cutoff)
");
$stmt->execute(['cutoff' => $cutoffDate]);
$deletedAuth = $stmt->rowCount();
$totalDeleted += $deletedAuth;
echo "auth_sessions:   {$deletedAuth} deleted" . PHP_EOL;

// Cleanup client_sessions (customers)
$stmt = $pdo->prepare("
    DELETE FROM client_sessions 
    WHERE expires_at < :cutoff 
       OR (revoked_at IS NOT NULL AND revoked_at < :cutoff)
");
$stmt->execute(['cutoff' => $cutoffDate]);
$deletedClient = $stmt->rowCount();
$totalDeleted += $deletedClient;
echo "client_sessions: {$deletedClient} deleted" . PHP_EOL;

// Cleanup password_reset_token_clients (expired or used)
$stmt = $pdo->prepare("
    DELETE FROM password_reset_token_clients 
    WHERE expires_at < :cutoff 
       OR used_at IS NOT NULL
");
$stmt->execute(['cutoff' => $cutoffDate]);
$deletedTokens = $stmt->rowCount();
$totalDeleted += $deletedTokens;
echo "password_reset_token_clients: {$deletedTokens} deleted" . PHP_EOL;

// Cleanup password_reset_token_users (operators - expired or used)
$stmt = $pdo->prepare("
    DELETE FROM password_reset_token_users 
    WHERE expires_at < :cutoff 
       OR used_at IS NOT NULL
");
$stmt->execute(['cutoff' => $cutoffDate]);
$deletedOpTokens = $stmt->rowCount();
$totalDeleted += $deletedOpTokens;
echo "password_reset_token_users: {$deletedOpTokens} deleted" . PHP_EOL;

echo str_repeat('-', 60) . PHP_EOL;
echo "Total deleted: {$totalDeleted}" . PHP_EOL;

// ============================================================================
// LOG ROTATION - Keep only last 30 days of logs
// ============================================================================
echo PHP_EOL . "Log rotation..." . PHP_EOL;

$logsDir = __DIR__ . '/../logs';
$maxLogAgeDays = 30;
$maxLogSizeMB = 10;

if (is_dir($logsDir)) {
    $logFiles = glob($logsDir . '/*.log');
    
    foreach ($logFiles as $logFile) {
        $fileName = basename($logFile);
        $fileSize = filesize($logFile);
        $fileSizeMB = round($fileSize / 1024 / 1024, 2);
        
        // Se il file è troppo grande (>10MB), tronca mantenendo ultime 1000 righe
        if ($fileSize > $maxLogSizeMB * 1024 * 1024) {
            $lines = file($logFile);
            $lastLines = array_slice($lines, -1000);
            file_put_contents($logFile, implode('', $lastLines));
            $newSize = round(filesize($logFile) / 1024 / 1024, 2);
            echo "  {$fileName}: truncated {$fileSizeMB}MB -> {$newSize}MB" . PHP_EOL;
        }
    }
    
    // Elimina file .log.old più vecchi di 30 giorni
    $oldLogs = glob($logsDir . '/*.log.*');
    foreach ($oldLogs as $oldLog) {
        if (filemtime($oldLog) < strtotime("-{$maxLogAgeDays} days")) {
            unlink($oldLog);
            echo "  Deleted old log: " . basename($oldLog) . PHP_EOL;
        }
    }
}

echo "Cleanup completed successfully" . PHP_EOL;
