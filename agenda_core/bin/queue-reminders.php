#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Queue Upcoming Reminders
 * 
 * Scans bookings scheduled in the next 24-48 hours and queues reminder notifications.
 * Run via cron: 0 * * * * php /path/to/agenda_core/bin/queue-reminders.php
 * 
 * Options:
 *   --hours=N     Look ahead N hours (default: 24)
 *   --verbose     Show detailed output
 *   --dry-run     Don't actually queue reminders
 */

require_once __DIR__ . '/../vendor/autoload.php';

use AgendaCore\Infrastructure\Persistence\DatabaseConnection;
use AgendaCore\Infrastructure\Persistence\NotificationRepository;
use AgendaCore\UseCases\Notification\QueueBookingReminder;

// Parse CLI options
$options = getopt('', ['hours::', 'verbose', 'dry-run', 'help']);

if (isset($options['help'])) {
    echo <<<HELP
Queue Upcoming Reminders

Usage: php queue-reminders.php [options]

Options:
  --hours=N     Look ahead N hours for bookings (default: 24)
  --verbose     Show detailed output
  --dry-run     Don't actually queue reminders
  --help        Show this help message

HELP;
    exit(0);
}

$hoursAhead = isset($options['hours']) ? (int) $options['hours'] : 24;
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
            $_ENV[trim($key)] = trim($value);
        }
    }
}

// Initialize services
try {
    $db = DatabaseConnection::getInstance();
    $notificationRepo = new NotificationRepository($db);
} catch (\Throwable $e) {
    fwrite(STDERR, "Failed to initialize services: {$e->getMessage()}\n");
    exit(1);
}

if ($verbose) {
    echo "Queue Reminders started\n";
    echo "Looking ahead: {$hoursAhead} hours\n";
    echo "Dry run: " . ($dryRun ? 'yes' : 'no') . "\n";
    echo "---\n";
}

// Find bookings in the next N hours that don't have a reminder queued yet
$now = new DateTimeImmutable();
$until = $now->modify("+{$hoursAhead} hours");

$sql = "
    SELECT 
        b.id AS booking_id,
        b.start_time,
        b.notes,
        u.id AS user_id,
        u.email AS customer_email,
        u.first_name AS customer_first_name,
        u.last_name AS customer_last_name,
        s.name AS service_name,
        st.first_name AS staff_first_name,
        st.last_name AS staff_last_name,
        l.name AS location_name,
        l.address AS location_address,
        bu.name AS business_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN booking_services bs ON bs.booking_id = b.id
    JOIN services s ON bs.service_id = s.id
    LEFT JOIN staff st ON b.staff_id = st.id
    LEFT JOIN locations l ON b.location_id = l.id
    LEFT JOIN businesses bu ON b.business_id = bu.id
    WHERE b.status = 'confirmed'
    AND b.start_time BETWEEN :now AND :until
    AND NOT EXISTS (
        SELECT 1 FROM notification_queue nq
        WHERE nq.type = 'booking_reminder'
        AND nq.recipient = u.email
        AND JSON_EXTRACT(nq.payload, '$.booking_id') = b.id
        AND nq.status IN ('pending', 'processing', 'sent')
    )
    GROUP BY b.id
    ORDER BY b.start_time ASC
";

try {
    $stmt = $db->prepare($sql);
    $stmt->execute([
        'now' => $now->format('Y-m-d H:i:s'),
        'until' => $until->format('Y-m-d H:i:s'),
    ]);
    $bookings = $stmt->fetchAll();
} catch (\PDOException $e) {
    // Table might not exist yet or different schema
    if ($verbose) {
        echo "Query failed (schema might differ): {$e->getMessage()}\n";
    }
    $bookings = [];
}

$count = count($bookings);

if ($count === 0) {
    if ($verbose) {
        echo "No bookings need reminders\n";
    }
    exit(0);
}

if ($verbose) {
    echo "Found {$count} booking(s) needing reminders\n";
}

$queued = 0;
$skipped = 0;

foreach ($bookings as $booking) {
    $bookingId = $booking['booking_id'];
    $customerEmail = $booking['customer_email'];
    $startTime = new DateTimeImmutable($booking['start_time']);
    
    if ($verbose) {
        echo "[{$bookingId}] {$customerEmail} at {$startTime->format('Y-m-d H:i')}... ";
    }
    
    // Check business notification settings
    $businessId = $booking['business_id'] ?? null;
    if ($businessId) {
        $settings = $notificationRepo->getSettings($businessId);
        if (!($settings['reminder_enabled'] ?? true)) {
            if ($verbose) {
                echo "SKIPPED (disabled)\n";
            }
            $skipped++;
            continue;
        }
    }
    
    if ($dryRun) {
        if ($verbose) {
            echo "DRY-RUN OK\n";
        }
        $queued++;
        continue;
    }
    
    try {
        // Queue reminder to be sent immediately (booking is within 24h)
        $payload = [
            'booking_id' => $bookingId,
            'customer_name' => trim($booking['customer_first_name'] . ' ' . ($booking['customer_last_name'] ?? '')),
            'customer_email' => $customerEmail,
            'service_name' => $booking['service_name'],
            'staff_name' => trim(($booking['staff_first_name'] ?? '') . ' ' . ($booking['staff_last_name'] ?? '')),
            'date_time' => $startTime->format('d/m/Y H:i'),
            'location_name' => $booking['location_name'] ?? '',
            'location_address' => $booking['location_address'] ?? '',
            'business_name' => $booking['business_name'] ?? 'Agenda',
            'notes' => $booking['notes'] ?? '',
        ];
        
        // Check deduplication
        if ($notificationRepo->wasRecentlySent('booking_reminder', $customerEmail, $bookingId, 24)) {
            if ($verbose) {
                echo "SKIPPED (already sent)\n";
            }
            $skipped++;
            continue;
        }
        
        $notificationRepo->queue(
            type: 'booking_reminder',
            channel: 'email',
            recipient: $customerEmail,
            payload: $payload,
            scheduledAt: null, // Send immediately
            priority: 5
        );
        
        $queued++;
        if ($verbose) {
            echo "QUEUED\n";
        }
        
    } catch (\Throwable $e) {
        if ($verbose) {
            echo "FAILED: {$e->getMessage()}\n";
        } else {
            error_log("Failed to queue reminder for booking {$bookingId}: {$e->getMessage()}");
        }
        $skipped++;
    }
}

if ($verbose) {
    echo "---\n";
    echo "Completed: {$queued} queued, {$skipped} skipped\n";
}

exit(0);
