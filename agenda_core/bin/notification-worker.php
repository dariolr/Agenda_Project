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

use Agenda\Infrastructure\Notifications\EmailService;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Database\Connection;
use Dotenv\Dotenv;

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
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// Check required config
$requiredEnv = ['DB_HOST', 'DB_DATABASE', 'DB_USERNAME', 'DB_PASSWORD'];
foreach ($requiredEnv as $key) {
    if (empty($_ENV[$key])) {
        fwrite(STDERR, "Missing required environment variable: {$key}\n");
        exit(1);
    }
}

// Initialize services
try {
    $db = new Connection();
    $notificationRepo = new NotificationRepository($db);
    $emailService = EmailService::create();
} catch (\Throwable $e) {
    fwrite(STDERR, "Failed to initialize services: {$e->getMessage()}\n");
    exit(1);
}

if ($verbose) {
    echo "Notification Worker started\n";
    echo "Provider: " . $emailService->getName() . "\n";
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
    $channel = $notification['channel'];  // booking_confirmed, booking_reminder, etc.
    $recipient = $notification['recipient_email'];
    
    if ($verbose) {
        echo "[{$id}] {$channel} -> {$recipient}... ";
    }
    
    // Mark as processing
    $notificationRepo->markProcessing($id);
    
    try {
        // Decode payload
        $payload = json_decode($notification['payload'], true);
        if (!$payload) {
            throw new \RuntimeException('Invalid payload JSON');
        }
        
        // Render email template based on channel (not type)
        $templateData = renderTemplate($channel, $payload);
        
        if ($dryRun) {
            if ($verbose) {
                echo "DRY-RUN OK\n";
            }
            $notificationRepo->markSent($id);
            $sent++;
            continue;
        }
        
        // Sender: ALWAYS use the verified sender from .env
        // The business email is used as reply-to only
        $variables = $payload['variables'] ?? $payload;
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $fallbackName = $notification['recipient_name'] ?? 'Cliente';
            $variables['client_name'] = $fallbackName;
        }
        
        // From: use channel-specific verified sender (fallback to default)
        $fromEmail = match ($channel) {
            'booking_reminder' =>
                $_ENV['MAIL_FROM_ADDRESS_BOOKING_REMINDER']
                    ?? $_ENV['MAIL_FROM_ADDRESS']
                    ?? null,
            'booking_cancelled' =>
                $_ENV['MAIL_FROM_ADDRESS_BOOKING_CANCELLED']
                    ?? $_ENV['MAIL_FROM_ADDRESS']
                    ?? null,
            'booking_rescheduled' =>
                $_ENV['MAIL_FROM_ADDRESS_BOOKING_RESCHEDULED']
                    ?? $_ENV['MAIL_FROM_ADDRESS']
                    ?? null,
            default =>
                $_ENV['MAIL_FROM_ADDRESS_BOOKING_CONFIRMED']
                    ?? $_ENV['MAIL_FROM_ADDRESS']
                    ?? null,
        };
        $fromName = $variables['business_name'] ?? null; // Show business name as sender name
        
        // Reply-To: use business/location email so replies go to the business
        $replyTo = $variables['sender_email'] 
            ?? $variables['location_email'] 
            ?? $variables['business_email'] 
            ?? null;
        
        // Render template placeholders in subject and body
        $subject = EmailTemplateRenderer::render($templateData['subject'], $variables);
        $htmlBody = EmailTemplateRenderer::render($templateData['html'], $variables);
        $textBody = isset($templateData['text']) ? EmailTemplateRenderer::render($templateData['text'], $variables) : null;
        
        // Send email
        $success = $emailService->send(
            to: $recipient,
            subject: $subject,
            htmlBody: $htmlBody,
            textBody: $textBody,
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
function renderTemplate(string $channel, array $payload): array
{
    // Extract variables from payload (may be nested under 'variables')
    $variables = $payload['variables'] ?? $payload;
    
    // Add year if not present
    if (!isset($variables['year'])) {
        $variables['year'] = date('Y');
    }
    
    switch ($channel) {
        case 'booking_confirmed':
            return EmailTemplateRenderer::bookingConfirmed($variables);
            
        case 'booking_cancelled':
            return EmailTemplateRenderer::bookingCancelled($variables);
            
        case 'booking_reminder':
            return EmailTemplateRenderer::bookingReminder($variables);
            
        case 'booking_rescheduled':
            return EmailTemplateRenderer::bookingRescheduled($variables);
            
        default:
            // Generic email with custom subject/body from payload
            $businessName = $variables['business_name'] ?? 'Agenda';
            return [
                'subject' => $variables['subject'] ?? 'Notifica da ' . $businessName,
                'html' => $variables['html_body'] ?? $variables['body'] ?? '',
                'text' => $variables['text_body'] ?? strip_tags($variables['body'] ?? ''),
            ];
    }
}
