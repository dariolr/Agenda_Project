#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Notification Queue Worker
 * 
 * Processes pending notifications from the queue.
 * Run via cron: * * * * * php /path/to/agenda_core/bin/notification-worker.php
 * 
 * Options:
 *   --batch=N     Process N notifications per run (default: 50)
 *   --verbose     Show detailed output
 *   --dry-run     Don't actually send emails
 */

// Autoload e bootstrap
require_once __DIR__ . '/../vendor/autoload.php';

use AgendaCore\Infrastructure\Notification\EmailService;
use AgendaCore\Infrastructure\Notification\EmailTemplateRenderer;
use AgendaCore\Infrastructure\Persistence\NotificationRepository;
use AgendaCore\Infrastructure\Persistence\DatabaseConnection;

// Parse CLI options
$options = getopt('', ['batch::', 'verbose', 'dry-run', 'help']);

if (isset($options['help'])) {
    echo <<<HELP
Notification Queue Worker

Usage: php notification-worker.php [options]

Options:
  --batch=N     Process N notifications per run (default: 50)
  --verbose     Show detailed output
  --dry-run     Don't actually send emails
  --help        Show this help message

HELP;
    exit(0);
}

$batchSize = isset($options['batch']) ? (int) $options['batch'] : 50;
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

// Check required config
$requiredEnv = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASS'];
foreach ($requiredEnv as $key) {
    if (empty($_ENV[$key])) {
        fwrite(STDERR, "Missing required environment variable: {$key}\n");
        exit(1);
    }
}

// Initialize services
try {
    $db = DatabaseConnection::getInstance();
    $notificationRepo = new NotificationRepository($db);
    $emailService = EmailService::create();
} catch (\Throwable $e) {
    fwrite(STDERR, "Failed to initialize services: {$e->getMessage()}\n");
    exit(1);
}

if ($verbose) {
    echo "Notification Worker started\n";
    echo "Provider: " . $emailService->getProvider()->getName() . "\n";
    echo "Batch size: {$batchSize}\n";
    echo "Dry run: " . ($dryRun ? 'yes' : 'no') . "\n";
    echo "---\n";
}

// Get pending notifications
$notifications = $notificationRepo->getPending($batchSize);
$count = count($notifications);

if ($count === 0) {
    if ($verbose) {
        echo "No pending notifications\n";
    }
    exit(0);
}

if ($verbose) {
    echo "Processing {$count} notification(s)...\n";
}

$sent = 0;
$failed = 0;

foreach ($notifications as $notification) {
    $id = (int) $notification['id'];
    $type = $notification['type'];
    $recipient = $notification['recipient'];
    
    if ($verbose) {
        echo "[{$id}] {$type} -> {$recipient}... ";
    }
    
    // Mark as processing
    $notificationRepo->markProcessing($id);
    
    try {
        // Decode payload
        $payload = json_decode($notification['payload'], true);
        if (!$payload) {
            throw new \RuntimeException('Invalid payload JSON');
        }
        
        // Render email template
        $templateData = renderTemplate($type, $payload);
        
        if ($dryRun) {
            if ($verbose) {
                echo "DRY-RUN OK\n";
            }
            $notificationRepo->markSent($id);
            $sent++;
            continue;
        }
        
        // Dynamic sender per-business
        $variables = $payload['variables'] ?? $payload;
        
        // Priority: sender_email (pre-computed) > business_email > null (use .env)
        $fromEmail = $variables['sender_email'] 
            ?? $variables['location_email'] 
            ?? $variables['business_email'] 
            ?? null;
        
        // Priority: sender_name (pre-computed) > location_name (if has email) > business_name > null
        $fromName = $variables['sender_name'] 
            ?? (!empty($variables['location_email']) ? $variables['location_name'] : null)
            ?? $variables['business_name'] 
            ?? null;
        
        $replyTo = $fromEmail; // Reply to the same prioritized email
        
        // Send email
        $success = $emailService->send(
            to: $recipient,
            subject: $templateData['subject'],
            htmlBody: $templateData['html'],
            textBody: $templateData['text'],
            fromEmail: $fromEmail,  // Dynamic: location > business > .env
            fromName: $fromName,    // Dynamic: location > business > .env
            replyTo: $replyTo       // Reply to location/business email
        );
        
        if ($success) {
            $notificationRepo->markSent($id);
            $sent++;
            if ($verbose) {
                echo "OK\n";
            }
        } else {
            throw new \RuntimeException('Email service returned false');
        }
        
    } catch (\Throwable $e) {
        $error = $e->getMessage();
        $notificationRepo->markFailed($id, $error);
        $failed++;
        
        if ($verbose) {
            echo "FAILED: {$error}\n";
        } else {
            error_log("Notification {$id} failed: {$error}");
        }
    }
    
    // Small delay to avoid rate limits
    usleep(100000); // 100ms
}

if ($verbose) {
    echo "---\n";
    echo "Completed: {$sent} sent, {$failed} failed\n";
}

// Exit with error code if all failed
exit($sent === 0 && $failed > 0 ? 1 : 0);

/**
 * Render email template based on notification type
 */
function renderTemplate(string $type, array $payload): array
{
    $businessName = $payload['business_name'] ?? 'Agenda';
    $clientName = $payload['client_name'] ?? '';
    $serviceName = $payload['service_name'] ?? '';
    $staffName = $payload['staff_name'] ?? '';
    $dateTime = $payload['date_time'] ?? '';
    $locationName = $payload['location_name'] ?? '';
    $locationAddress = $payload['location_address'] ?? '';
    $bookingId = $payload['booking_id'] ?? '';
    $notes = $payload['notes'] ?? '';
    
    $variables = [
        'business_name' => $businessName,
        'client_name' => $clientName,
        'service_name' => $serviceName,
        'staff_name' => $staffName,
        'date_time' => $dateTime,
        'location_name' => $locationName,
        'location_address' => $locationAddress,
        'booking_id' => $bookingId,
        'notes' => $notes,
        'year' => date('Y'),
    ];
    
    switch ($type) {
        case 'booking_confirmed':
            return EmailTemplateRenderer::bookingConfirmed($variables);
            
        case 'booking_cancelled':
            return EmailTemplateRenderer::bookingCancelled($variables);
            
        case 'booking_reminder':
            return EmailTemplateRenderer::bookingReminder($variables);
            
        case 'booking_rescheduled':
            $variables['old_date_time'] = $payload['old_date_time'] ?? '';
            $variables['new_date_time'] = $payload['new_date_time'] ?? $dateTime;
            return EmailTemplateRenderer::bookingRescheduled($variables);
            
        default:
            // Generic email with custom subject/body from payload
            return [
                'subject' => $payload['subject'] ?? 'Notifica da ' . $businessName,
                'html' => $payload['html_body'] ?? $payload['body'] ?? '',
                'text' => $payload['text_body'] ?? strip_tags($payload['body'] ?? ''),
            ];
    }
}
