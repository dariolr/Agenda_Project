#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Queue Upcoming Reminders
 * 
 * Scans bookings scheduled in the next 48 hours and queues reminder notifications.
 * Run via cron: 0 * * * * php /path/to/agenda_core/bin/queue-reminders.php
 * 
 * Options:
 *   --verbose     Show detailed output
 *   --dry-run     Don't actually queue reminders (just show what would be queued)
 *   --help        Show this help message
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\UseCases\Notifications\QueueBookingReminder;

// Parse CLI options
$options = getopt('', ['verbose', 'dry-run', 'help']);

if (isset($options['help'])) {
    echo <<<HELP
Queue Upcoming Reminders

Usage: php queue-reminders.php [options]

Options:
  --verbose     Show detailed output
  --dry-run     Show what would be queued without actually queuing
  --help        Show this help message

Notes:
  - Scans bookings in the next 48 hours
  - Only queues reminders for bookings with client_id (registered customers)
  - Respects business notification settings (email_reminder_enabled)
  - Uses email_reminder_hours setting for scheduling (default 24h before)

HELP;
    exit(0);
}

$verbose = isset($options['verbose']);
$dryRun = isset($options['dry-run']);

// Load environment
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_starts_with(trim($line), '#')) {
            continue;
        }
        if (str_contains($line, '=')) {
            [$key, $value] = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            // Remove quotes if present
            $value = trim($value, '"\'');
            $_ENV[$key] = $value;
            putenv("$key=$value");
        }
    }
}

if ($verbose) {
    echo "[" . date('Y-m-d H:i:s') . "] Queue Reminders started\n";
    echo "Dry run: " . ($dryRun ? 'yes' : 'no') . "\n";
    echo "---\n";
}

// Initialize services
try {
    $db = Connection::getInstance();
    $notificationRepo = new NotificationRepository($db);
    $queueReminder = new QueueBookingReminder($db, $notificationRepo);
} catch (\Throwable $e) {
    fwrite(STDERR, "[ERROR] Failed to initialize services: {$e->getMessage()}\n");
    exit(1);
}

// Dry run mode: just show statistics
if ($dryRun) {
    // Count bookings that would be queued
    $stmt = $db->getPdo()->prepare(
        'SELECT COUNT(DISTINCT b.id) as total
         FROM bookings b
         JOIN booking_items bi ON b.id = bi.booking_id
         WHERE b.status IN ("pending", "confirmed")
           AND (b.client_id IS NOT NULL OR b.user_id IS NOT NULL)
           AND bi.start_time BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 48 HOUR)
           AND NOT EXISTS (
               SELECT 1 FROM notification_queue nq 
               WHERE nq.booking_id = b.id 
                 AND nq.channel = "booking_reminder"
                 AND nq.status IN ("pending", "processing", "sent")
           )'
    );
    $stmt->execute();
    $row = $stmt->fetch(\PDO::FETCH_ASSOC);
    $count = $row['total'] ?? 0;
    
    echo "[DRY-RUN] Found {$count} booking(s) that would have reminders queued\n";
    exit(0);
}

// Queue reminders
try {
    $queued = $queueReminder->queueUpcomingReminders();
    
    if ($verbose) {
        echo "---\n";
        echo "[" . date('Y-m-d H:i:s') . "] Completed: {$queued} reminder(s) queued\n";
    } else {
        // Log only if something was queued
        if ($queued > 0) {
            echo "[" . date('Y-m-d H:i:s') . "] Queued {$queued} reminder(s)\n";
        }
    }
    
} catch (\Throwable $e) {
    fwrite(STDERR, "[ERROR] Failed to queue reminders: {$e->getMessage()}\n");
    if ($verbose) {
        fwrite(STDERR, $e->getTraceAsString() . "\n");
    }
    exit(1);
}

exit(0);
