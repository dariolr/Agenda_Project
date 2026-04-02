#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Notification Queue Worker
 * 
 * Processes pending notifications from the queue.
 * Run via cron: * * * * * php /path/to/agenda_core/bin/job-notification.php
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
use Agenda\Infrastructure\Notifications\CalendarICSGenerator;
use Agenda\Infrastructure\Database\Connection;
use Dotenv\Dotenv;

// Parse CLI options
$options = getopt('', ['batch::', 'verbose', 'dry-run', 'help']);

if (isset($options['help'])) {
    echo <<<HELP
Notification Queue Worker

Usage: php job-notification.php [options]

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
    $recipient = (string) ($notification['recipient_email'] ?? '');
    $bookingId = $notification['booking_id'] ?? null;
    
    if ($verbose) {
        echo "[{$id}] {$channel} -> {$recipient}... ";
    }
    
    // Per i reminder, invia finche' l'appuntamento e' ancora futuro.
    // Evita invii troppo a ridosso (cutoff configurabile) e mantieni tracciabilita'.
    if ($channel === 'booking_reminder' && $bookingId !== null) {
        $sendDecision = getReminderSendDecision($db->getPdo(), (int) $bookingId);
        if ($sendDecision['skip_send']) {
            $discardReason = 'Promemoria non inviato: notifica generata in ritardo e fuori finestra -24h (' . $sendDecision['reason'] . ').';
            if ($verbose) {
                echo "SKIPPED ({$sendDecision['reason']}) - marking failed\n";
            }
            $discardStmt = $db->getPdo()->prepare(
                'UPDATE notification_queue
                 SET status = "failed",
                     failed_at = NOW(),
                     error_message = :error_message
                 WHERE id = :id'
            );
            $discardStmt->execute([
                'id' => $id,
                'error_message' => $discardReason,
            ]);
            $failed++;
            continue;
        }
    }
    
    // Mark as processing
    $notificationRepo->markProcessing($id);
    
    try {
        // Decode payload
        $payload = json_decode($notification['payload'], true);
        if (!$payload) {
            throw new \RuntimeException('Invalid payload JSON');
        }

        // Safety net: refresh reminder ICS at send-time so already queued payloads
        // are aligned with location timezone and not with stale/ambiguous content.
        if ($channel === 'booking_reminder' && $bookingId !== null) {
            $variables = $payload['variables'] ?? $payload;
            $locale = (string) ($variables['locale'] ?? 'it');
            $attachment = buildReminderIcsAttachment(
                $db->getPdo(),
                (int) $bookingId,
                $locale
            );
            if ($attachment === null) {
                throw new \RuntimeException(
                    "Unable to rebuild reminder ICS for booking {$bookingId}"
                );
            }
            $payload['attachments'] = [$attachment];
        }
        
        // Render email template based on channel (not type)
        $templateData = renderTemplate($channel, $payload);
        
        if ($dryRun) {
            if ($verbose) {
                echo "DRY-RUN OK\n";
            }
            $notificationRepo->markSent($id, false);
            $sent++;
            continue;
        }
        
        // Sender: use verified sender from .env.
        // Business/location email is used as reply-to when valid.
        $variables = $payload['variables'] ?? $payload;
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $fallbackName = $notification['recipient_name'] ?? 'Cliente';
            $variables['client_name'] = $fallbackName;
        }
        
        // From: use channel-specific verified sender (fallback to default)
        $fromEmail = normalizeEmail(match ($channel) {
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
        });
        $defaultFromEmail = normalizeEmail($_ENV['MAIL_FROM_ADDRESS'] ?? null);
        $fromName = $variables['business_name'] ?? null; // Show business name as sender name
        
        // Reply-To: use business/location email so replies go to the business
        $replyTo = normalizeEmail(
            $variables['sender_email'] 
            ?? $variables['location_email'] 
            ?? $variables['business_email'] 
            ?? null
        );
        if ($replyTo !== null && !isValidEmail($replyTo)) {
            if ($verbose) {
                echo "WARN invalid reply-to ({$replyTo}), ignoring... ";
            }
            $replyTo = null;
        }
        if (!isValidEmail($recipient)) {
            throw new \RuntimeException("Invalid recipient email: {$recipient}");
        }
        if ($fromEmail === null || !isValidEmail($fromEmail)) {
            $fromEmail = $defaultFromEmail;
        }
        
        // Render template placeholders in subject and body
        $subject = EmailTemplateRenderer::render($templateData['subject'], $variables);
        $htmlBody = EmailTemplateRenderer::render($templateData['html'], $variables);
        $textBody = isset($templateData['text']) ? EmailTemplateRenderer::render($templateData['text'], $variables) : null;
        $attachments = $payload['attachments'] ?? null;
        
        // Send email
        $success = $emailService->send(
            to: $recipient,
            subject: $subject,
            htmlBody: $htmlBody,
            textBody: $textBody,
            attachments: $attachments,
            fromEmail: $fromEmail,  // Dynamic: location > business > .env
            fromName: $fromName,    // Dynamic: location > business > .env
            replyTo: $replyTo       // Reply to location/business email
        );
        if (
            !$success
            && $defaultFromEmail !== null
            && $fromEmail !== null
            && strcasecmp($fromEmail, $defaultFromEmail) !== 0
        ) {
            if ($verbose) {
                echo "RETRY with default sender... ";
            }
            $success = $emailService->send(
                to: $recipient,
                subject: $subject,
                htmlBody: $htmlBody,
                textBody: $textBody,
                attachments: $attachments,
                fromEmail: $defaultFromEmail,
                fromName: $fromName,
                replyTo: $replyTo
            );
        }
        
        if ($success) {
            $usedProvider = method_exists($emailService, 'getLastUsedProvider')
                ? $emailService->getLastUsedProvider()
                : $emailService->getName();
            $notificationRepo->markSent($id, true, $usedProvider);
            $sent++;
            if ($verbose) {
                echo "OK [provider={$usedProvider}]\n";
            }
        } else {
            $provider = $emailService->getName();
            $providerError = null;
            if (method_exists($emailService, 'getLastError')) {
                $providerError = $emailService->getLastError();
            }
            $errorDetail = $providerError !== null && trim($providerError) !== ''
                ? " | provider_error={$providerError}"
                : '';
            throw new \RuntimeException(
                "Email service returned false (provider={$provider}, channel={$channel}, recipient={$recipient}, from={$fromEmail}){$errorDetail}"
            );
        }
        
    } catch (\Throwable $e) {
        $error = $e->getMessage();
        if (isHardFailure($error)) {
            markHardFailed($db->getPdo(), $id, $error);
            $failed++;
            if ($verbose) {
                echo "FAILED (hard): {$error}\n";
            } else {
                error_log("Notification {$id} hard-failed: {$error}");
            }
            continue;
        }

        $retryScheduledAt = null;
        if ($channel === 'booking_reminder' && $bookingId !== null) {
            $currentAttempt = ((int) ($notification['attempts'] ?? 0)) + 1;
            $retryDecision = getReminderRetryDecision(
                $db->getPdo(),
                (int) $bookingId,
                $currentAttempt
            );

            if ($retryDecision['skip_retry']) {
                $error .= ' | Retry skipped: ' . $retryDecision['reason'];
            } else {
                $retryScheduledAt = $retryDecision['retry_at'];
            }
        }

        $notificationRepo->markFailed($id, $error, $retryScheduledAt);
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
 * Returns true when error is permanent and retries are pointless.
 */
function isHardFailure(string $error): bool
{
    $normalized = strtolower(trim($error));
    if ($normalized === '') {
        return false;
    }

    return str_contains($normalized, 'invalid recipient email');
}

/**
 * Mark notification as failed immediately (no further retries).
 */
function markHardFailed(\PDO $pdo, int $id, string $error): void
{
    $stmt = $pdo->prepare(
        'UPDATE notification_queue
         SET status = "failed",
             failed_at = NOW(),
             error_message = :error
         WHERE id = :id'
    );
    $stmt->execute([
        'id' => $id,
        'error' => $error,
    ]);
}

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
    
    // Get locale from variables, default to 'it'
    $locale = $variables['locale'] ?? 'it';
    
    // Get template based on channel
    switch ($channel) {
        case 'booking_confirmed':
            $template = EmailTemplateRenderer::bookingConfirmed($locale);
            break;
            
        case 'booking_cancelled':
            $template = EmailTemplateRenderer::bookingCancelled($locale);
            break;
            
        case 'booking_reminder':
            $template = EmailTemplateRenderer::bookingReminder($locale);
            break;
            
        case 'booking_rescheduled':
            $template = EmailTemplateRenderer::bookingRescheduled($locale);
            break;
            
        default:
            throw new \RuntimeException("Unsupported notification channel: {$channel}");
    }
    
    // Render template with variables
    return [
        'subject' => EmailTemplateRenderer::render($template['subject'], $variables),
        'html' => EmailTemplateRenderer::render($template['html'], $variables),
        'text' => EmailTemplateRenderer::render($template['text'], $variables),
    ];
}

function normalizeEmail(?string $email): ?string
{
    if ($email === null) {
        return null;
    }
    $trimmed = trim($email);
    return $trimmed === '' ? null : $trimmed;
}

function isValidEmail(string $email): bool
{
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Build a fresh ICS attachment for reminder emails from current booking data.
 *
 * @return array{filename: string, content: string, content_type: string, encoding: string}|null
 */
function buildReminderIcsAttachment(\PDO $pdo, int $bookingId, string $locale = 'it'): ?array
{
    $stmt = $pdo->prepare(
        'SELECT
            b.id AS booking_id,
            b.status,
            l.timezone AS location_timezone,
            bus.name AS business_name,
            l.name AS location_name,
            l.address AS location_address,
            l.city AS location_city,
            MIN(bi.start_time) AS start_time,
            MAX(bi.end_time) AS end_time,
            GROUP_CONCAT(DISTINCT s.name ORDER BY s.name SEPARATOR ", ") AS services
         FROM bookings b
         JOIN locations l ON b.location_id = l.id
         JOIN businesses bus ON l.business_id = bus.id
         LEFT JOIN booking_items bi ON b.id = bi.booking_id
         LEFT JOIN service_variants sv ON bi.service_variant_id = sv.id
         LEFT JOIN services s ON sv.service_id = s.id
         WHERE b.id = :booking_id
           AND b.status IN ("pending", "confirmed")
         GROUP BY b.id'
    );
    $stmt->execute(['booking_id' => $bookingId]);
    $booking = $stmt->fetch(\PDO::FETCH_ASSOC);

    if (!$booking || empty($booking['start_time']) || empty($booking['end_time'])) {
        return null;
    }

    $eventData = CalendarICSGenerator::prepareEventFromBooking(
        $booking,
        (string) ($booking['business_name'] ?? ''),
        $locale
    );
    $icsContent = CalendarICSGenerator::generateIcsContent($eventData);

    return CalendarICSGenerator::createIcsAttachment($icsContent);
}

/**
 * Compute the next retry slot for booking reminders.
 *
 * Reminder retry policy:
 * - 1st failure: retry after 30 minutes
 * - 2nd failure: retry after 2 hours
 * - 3rd failure: retry after 6 hours
 * - no retry if the appointment is no longer active or the next slot would be
 *   too close to the appointment start.
 *
 * @return array{skip_retry: bool, retry_at: ?string, reason: string}
 */
function getReminderRetryDecision(\PDO $pdo, int $bookingId, int $currentAttempt): array
{
    $delayMinutesByAttempt = [
        1 => 30,
        2 => 120,
        3 => 360,
    ];

    if (!isset($delayMinutesByAttempt[$currentAttempt])) {
        return [
            'skip_retry' => true,
            'retry_at' => null,
            'reason' => 'no retry slot available',
        ];
    }

    $stmt = $pdo->prepare(
        'SELECT b.status, l.timezone AS location_timezone, MIN(bi.start_time) AS start_time
         FROM bookings b
         JOIN locations l ON b.location_id = l.id
         LEFT JOIN booking_items bi ON bi.booking_id = b.id
         WHERE b.id = :booking_id
         GROUP BY b.id, b.status, l.timezone'
    );
    $stmt->execute(['booking_id' => $bookingId]);
    $booking = $stmt->fetch(\PDO::FETCH_ASSOC);

    if (!$booking) {
        return [
            'skip_retry' => true,
            'retry_at' => null,
            'reason' => 'booking not found',
        ];
    }

    $status = (string) ($booking['status'] ?? '');
    if (!in_array($status, ['pending', 'confirmed'], true)) {
        return [
            'skip_retry' => true,
            'retry_at' => null,
            'reason' => "booking status is {$status}",
        ];
    }

    $startTimeRaw = $booking['start_time'] ?? null;
    if (!is_string($startTimeRaw) || trim($startTimeRaw) === '') {
        return [
            'skip_retry' => true,
            'retry_at' => null,
            'reason' => 'appointment start time unavailable',
        ];
    }

    $timezone = new \DateTimeZone((string) ($booking['location_timezone'] ?? 'Europe/Rome'));
    $appointmentStart = new \DateTimeImmutable($startTimeRaw, $timezone);
    $retryAt = new \DateTimeImmutable('now', $timezone);
    $retryAt = $retryAt->modify('+' . $delayMinutesByAttempt[$currentAttempt] . ' minutes');

    // Avoid reminders that would arrive too close to or after the appointment.
    $retryDeadline = $appointmentStart->modify('-15 minutes');
    if ($retryAt >= $retryDeadline) {
        return [
            'skip_retry' => true,
            'retry_at' => null,
            'reason' => 'appointment too close for another reminder retry',
        ];
    }

    return [
        'skip_retry' => false,
        'retry_at' => $retryAt->format('Y-m-d H:i:s'),
        'reason' => '',
    ];
}

/**
 * Decide whether a reminder should still be sent.
 *
 * Rules:
 * - booking must be active (pending|confirmed)
 * - appointment start must be available
 * - reminder is sendable while appointment is still in the future
 * - optional cutoff to avoid useless "too-late" reminders
 * - upper bound to avoid sending reminders too early
 *
 * Env:
 * - REMINDER_MIN_HOURS_BEFORE_START (default: 2)
 * - REMINDER_MAX_HOURS_BEFORE_START (default: 25)
 *
 * @return array{skip_send: bool, reason: string}
 */
function getReminderSendDecision(\PDO $pdo, int $bookingId): array
{
    $stmt = $pdo->prepare(
        'SELECT b.status, l.timezone AS location_timezone, MIN(bi.start_time) AS start_time
         FROM bookings b
         JOIN locations l ON b.location_id = l.id
         LEFT JOIN booking_items bi ON bi.booking_id = b.id
         WHERE b.id = :booking_id
         GROUP BY b.id, b.status, l.timezone'
    );
    $stmt->execute(['booking_id' => $bookingId]);
    $booking = $stmt->fetch(\PDO::FETCH_ASSOC);

    if (!$booking) {
        return [
            'skip_send' => true,
            'reason' => 'booking not found',
        ];
    }

    $status = (string) ($booking['status'] ?? '');
    if (!in_array($status, ['pending', 'confirmed'], true)) {
        return [
            'skip_send' => true,
            'reason' => "booking status is {$status}",
        ];
    }

    $startTimeRaw = $booking['start_time'] ?? null;
    if (!is_string($startTimeRaw) || trim($startTimeRaw) === '') {
        return [
            'skip_send' => true,
            'reason' => 'appointment start time unavailable',
        ];
    }

    $timezone = new \DateTimeZone((string) ($booking['location_timezone'] ?? 'Europe/Rome'));
    $appointmentStart = new \DateTimeImmutable($startTimeRaw, $timezone);
    $now = new \DateTimeImmutable('now', $timezone);
    $secondsUntilStart = $appointmentStart->getTimestamp() - $now->getTimestamp();

    if ($secondsUntilStart <= 0) {
        return [
            'skip_send' => true,
            'reason' => 'appointment already started/past',
        ];
    }

    $minHoursBeforeStartRaw = $_ENV['REMINDER_MIN_HOURS_BEFORE_START'] ?? getenv('REMINDER_MIN_HOURS_BEFORE_START') ?: '2';
    $minHoursBeforeStart = (int) $minHoursBeforeStartRaw;
    if ($minHoursBeforeStart < 0) {
        $minHoursBeforeStart = 0;
    }

    $maxHoursBeforeStartRaw = $_ENV['REMINDER_MAX_HOURS_BEFORE_START'] ?? getenv('REMINDER_MAX_HOURS_BEFORE_START') ?: '25';
    $maxHoursBeforeStart = (int) $maxHoursBeforeStartRaw;
    if ($maxHoursBeforeStart <= 0) {
        $maxHoursBeforeStart = 25;
    }

    $maxSeconds = $maxHoursBeforeStart * 3600;
    if ($secondsUntilStart > $maxSeconds) {
        return [
            'skip_send' => true,
            'reason' => "too early for reminder (> {$maxHoursBeforeStart}h)",
        ];
    }

    $minSeconds = $minHoursBeforeStart * 3600;
    if ($secondsUntilStart < $minSeconds) {
        return [
            'skip_send' => true,
            'reason' => "too close to appointment (< {$minHoursBeforeStart}h)",
        ];
    }

    return [
        'skip_send' => false,
        'reason' => '',
    ];
}
