#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Queue Class Event Reminders
 *
 * Scans class_bookings whose class_events.starts_at falls within the next 48 hours
 * and queues a class_booking_reminder notification for each confirmed participant.
 *
 * Run via cron: 0 * * * * php /path/to/agenda_core/bin/job-queue-class-reminders.php
 *
 * Options:
 *   --verbose     Show detailed output
 *   --dry-run     Show what would be queued without actually queuing
 *   --help        Show this help message
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\UseCases\Notifications\QueueClassBookingNotification;

$options = getopt('', ['verbose', 'dry-run', 'help']);

if (isset($options['help'])) {
    echo <<<HELP
Queue Class Event Reminders

Usage: php job-queue-class-reminders.php [options]

Options:
  --verbose     Show detailed output
  --dry-run     Show what would be queued without actually queuing
  --help        Show this help message

Notes:
  - Scans class_bookings with status "confirmed" in the next 48 hours
  - Respects business notification settings (email_class_booking_reminder)
  - Uses email_reminder_hours setting to schedule (default 24h before)
  - Deduplication handled by NotificationRepository

HELP;
    exit(0);
}

$verbose = isset($options['verbose']);
$dryRun  = isset($options['dry-run']);

// Load environment
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_starts_with(trim($line), '#') || !str_contains($line, '=')) {
            continue;
        }
        [$key, $value] = explode('=', $line, 2);
        $key   = trim($key);
        $value = trim(trim($value), '"\'');
        $_ENV[$key] = $value;
        putenv("$key=$value");
    }
}

if ($verbose) {
    echo '[' . date('Y-m-d H:i:s') . "] Queue Class Reminders started\n";
    echo 'Dry run: ' . ($dryRun ? 'yes' : 'no') . "\n---\n";
}

try {
    $db               = new Connection();
    $notificationRepo = new NotificationRepository($db);
    $queueNotification = new QueueClassBookingNotification($db, $notificationRepo);
} catch (\Throwable $e) {
    fwrite(STDERR, '[ERROR] Failed to initialize services: ' . $e->getMessage() . "\n");
    exit(1);
}

// Fetch confirmed class bookings without a reminder already queued,
// whose class event starts within the next 48 hours.
$stmt = $db->getPdo()->prepare(
    'SELECT
         cb.id         AS class_booking_id,
         cb.business_id,
         ce.starts_at,
         l.timezone    AS location_timezone
     FROM class_bookings cb
     INNER JOIN class_events ce
         ON ce.id = cb.class_event_id AND ce.business_id = cb.business_id
     INNER JOIN locations l
         ON l.id = ce.location_id
     WHERE cb.status = "confirmed"
       AND ce.starts_at > NOW()
       AND ce.starts_at <= DATE_ADD(NOW(), INTERVAL 48 HOUR)
       AND NOT EXISTS (
           SELECT 1 FROM notification_queue nq
           WHERE nq.class_booking_id = cb.id
             AND nq.channel = "class_booking_reminder"
             AND nq.status IN ("pending", "processing", "sent", "skipped")
       )
     LIMIT 1000'
);
$stmt->execute();
$rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

if ($verbose) {
    echo 'Found ' . count($rows) . " class booking(s) to process\n";
}

if ($dryRun) {
    echo '[DRY-RUN] Would process ' . count($rows) . " class booking(s)\n";
    exit(0);
}

$defaultHoursBefore = 24;
$queued = 0;

foreach ($rows as $row) {
    $classBookingId = (int) $row['class_booking_id'];
    $businessId     = (int) $row['business_id'];

    // Determine hours_before from business settings
    $settings = $notificationRepo->getSettings($businessId);
    $hoursBefore = isset($settings['email_reminder_hours']) && (int) $settings['email_reminder_hours'] > 0
        ? (int) $settings['email_reminder_hours']
        : $defaultHoursBefore;

    // Calculate scheduled_at in UTC
    try {
        $locationTz = new DateTimeZone($row['location_timezone'] ?? 'Europe/Rome');
        $startsAt   = new DateTimeImmutable((string) $row['starts_at'], new DateTimeZone('UTC'));
        $now        = new DateTimeImmutable('now', $locationTz);
        $scheduledAt = $startsAt->modify("-{$hoursBefore} hours");

        // Skip if the scheduled send time is already past
        if ($scheduledAt <= $now) {
            if ($verbose) {
                echo "  Skip class_booking #{$classBookingId}: scheduled time already past\n";
            }
            continue;
        }

        $scheduledAtStr = $scheduledAt->setTimezone(new DateTimeZone('UTC'))->format('Y-m-d H:i:s');
    } catch (\Throwable $e) {
        if ($verbose) {
            fwrite(STDERR, "  Skip class_booking #{$classBookingId}: " . $e->getMessage() . "\n");
        }
        continue;
    }

    $result = $queueNotification->execute($classBookingId, $businessId, 'class_booking_reminder', $scheduledAtStr);

    if ($result > 0) {
        $queued++;
        if ($verbose) {
            echo "  Queued reminder for class_booking #{$classBookingId} at {$scheduledAtStr} UTC\n";
        }
    } elseif ($verbose) {
        echo "  Skipped class_booking #{$classBookingId} (dedup or no client)\n";
    }
}

if ($verbose) {
    echo "---\n[" . date('Y-m-d H:i:s') . "] Completed: {$queued} reminder(s) queued\n";
} elseif ($queued > 0) {
    echo '[' . date('Y-m-d H:i:s') . "] Queued {$queued} class reminder(s)\n";
}

exit(0);
