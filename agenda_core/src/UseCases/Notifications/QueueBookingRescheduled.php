<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Queue booking rescheduled email.
 * Notifications ALWAYS go to the CLIENT (not operator).
 */
final class QueueBookingRescheduled
{
    public function __construct(
        private readonly Connection $db,
        private readonly NotificationRepository $notificationRepo,
    ) {}

    /**
     * Queue a booking rescheduled email.
     * 
     * @param array $booking Booking data with client_id and new timing info
     */
    public function execute(array $booking): int
    {
        // Don't send rescheduled email if NEW appointment start time has already passed
        // Use location timezone for accurate comparison
        $newStartTimeString = $booking['new_start_time'] ?? $booking['start_time'] ?? null;
        if ($newStartTimeString) {
            $locationTz = new DateTimeZone($booking['location_timezone'] ?? 'Europe/Rome');
            $newStartTime = new DateTimeImmutable($newStartTimeString, $locationTz);
            $now = new DateTimeImmutable('now', $locationTz);
            if ($newStartTime < $now) {
                return 0; // New appointment time already passed, no email needed
            }
        }

        // Check if already sent (deduplication)
        // Note: use different key to allow multiple reschedules
        $deduplicationKey = ($booking['booking_id'] ?? 0) . '_' . ($booking['new_start_time'] ?? '');
        if ($this->notificationRepo->wasRecentlySent('booking_rescheduled', (int) $booking['booking_id'])) {
            return 0;
        }

        // Check if notifications are enabled
        $settings = $this->notificationRepo->getSettings((int) $booking['business_id']);
        if ($settings && !($settings['email_booking_rescheduled'] ?? true)) {
            return 0;
        }

        // Get recipient email - notifications go to CLIENT
        $recipientType = 'client';
        $recipientId = null;
        $recipientEmail = null;
        $clientName = $this->extractFirstName($booking['client_name'] ?? null);
        $locale = $this->resolveLocale($booking);
        
        if (isset($booking['client_id']) && !empty($booking['client_id'])) {
            $recipientId = (int) $booking['client_id'];
            $recipientEmail = [
                'email' => $booking['client_email'] ?? null,
                'name' => $clientName,
            ];
            
            // Fallback: if email not provided, query clients table
            if (empty($recipientEmail['email'])) {
                $recipientEmail = $this->getClientEmail($recipientId);
                if ($recipientEmail) {
                    $clientName = $recipientEmail['name'];
                }
            }
        }
        
        // No client = no notification
        if (!$recipientEmail || empty($recipientEmail['email'])) {
            return 0;
        }
        $recipientEmail['name'] = $this->extractFirstName($recipientEmail['name'] ?? null);
        $clientName = $this->extractFirstName($clientName);

        // Prepare template variables
        $oldStartTime = isset($booking['old_start_time']) 
            ? new DateTimeImmutable($booking['old_start_time']) 
            : null;
        $newStartTime = new DateTimeImmutable($booking['new_start_time'] ?? $booking['start_time']);
        
        $locationName = $booking['location_name'] ?? '';
        $locationAddress = $booking['location_address'] ?? '';
        $strings = EmailTemplateRenderer::strings($locale);
        $hasMultipleLocations = $this->hasMultipleLocations((int) ($booking['business_id'] ?? 0));
        $locationBlockHtml = $hasMultipleLocations
            ? sprintf(
                '<span style="color:#666;">📍 %s</span><br><strong style="color:#333;">%s</strong><br><span style="color:#666;font-size:14px;">%s</span><br>',
                $strings['where_label'],
                $locationName,
                $locationAddress
            )
            : '';
        $locationBlockText = $hasMultipleLocations
            ? sprintf("📍 %s: %s, %s\n", $strings['where_label'], $locationName, $locationAddress)
            : '';

        $variables = [
            'client_name' => $clientName,
            'business_name' => $booking['business_name'] ?? '',
            'business_email' => $booking['business_email'] ?? '',
            'location_name' => $locationName,
            'location_email' => $booking['location_email'] ?? '',
            'sender_email' => $booking['sender_email'] ?? '',
            'sender_name' => $booking['sender_name'] ?? '',
            'location_address' => $locationAddress,
            'location_city' => $booking['location_city'] ?? '',
            'location_phone' => $booking['location_phone'] ?? '',
            'old_date' => $oldStartTime ? EmailTemplateRenderer::formatLongDate($oldStartTime, $locale) : '',
            'old_time' => $oldStartTime ? $oldStartTime->format('H:i') : '',
            'new_date' => EmailTemplateRenderer::formatLongDate($newStartTime, $locale),
            'new_time' => $newStartTime->format('H:i'),
            'date' => EmailTemplateRenderer::formatLongDate($newStartTime, $locale),
            'time' => $newStartTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'manage_url' => $booking['manage_url'] ?? '#',
            'booking_url' => $booking['booking_url'] ?? '#',
            'location_block_html' => $locationBlockHtml,
            'location_block_text' => $locationBlockText,
        ];
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $variables['client_name'] = $recipientEmail['name'] ?? $strings['client_fallback'];
        } else {
            $variables['client_name'] = $this->extractFirstName($variables['client_name']);
        }
        
        $template = EmailTemplateRenderer::bookingRescheduled($locale);
        
        return $this->notificationRepo->queue([
            'type' => 'email',
            'channel' => 'booking_rescheduled',
            'recipient_type' => $recipientType,
            'recipient_id' => $recipientId,
            'recipient_email' => $recipientEmail['email'],
            'recipient_name' => $recipientEmail['name'],
            'subject' => EmailTemplateRenderer::render($template['subject'], $variables),
            'payload' => [
                'template' => 'booking_rescheduled',
                'variables' => $variables,
            ],
            'priority' => 2, // High priority
            'business_id' => $booking['business_id'],
            'booking_id' => $booking['booking_id'],
        ]);
    }
    
    private function getClientEmail(int $clientId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT email, first_name as name 
             FROM clients WHERE id = :id'
        );
        $stmt->execute(['id' => $clientId]);
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;
    }

    private function extractFirstName(?string $fullName): string
    {
        $name = trim((string) $fullName);
        if ($name === '') {
            return '';
        }

        $parts = preg_split('/\s+/', $name);
        return $parts[0] ?? $name;
    }

    private function hasMultipleLocations(int $businessId): bool
    {
        if ($businessId <= 0) {
            return false;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM locations WHERE business_id = ? AND is_active = 1'
        );
        $stmt->execute([$businessId]);

        return (int) $stmt->fetchColumn() > 1;
    }

    private function resolveLocale(array $booking): string
    {
        return EmailTemplateRenderer::normalizeLocale(
            $booking['locale'] ?? $booking['business_locale'] ?? null
        );
    }
}
