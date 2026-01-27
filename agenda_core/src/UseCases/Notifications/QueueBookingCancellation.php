<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Queue booking cancellation email.
 */
final class QueueBookingCancellation
{
    public function __construct(
        private readonly Connection $db,
        private readonly NotificationRepository $notificationRepo,
    ) {}

    /**
     * Queue a booking cancellation email.
     * Supports both 'user_id' (operators) and 'client_id' (customers).
     * Notifications ALWAYS go to the CLIENT.
     */
    public function execute(array $booking): int
    {
        // Don't send cancellation if appointment start time has already passed
        // Use location timezone for accurate comparison
        if (isset($booking['start_time'])) {
            $locationTz = new DateTimeZone($booking['location_timezone'] ?? 'Europe/Rome');
            $startTime = new DateTimeImmutable($booking['start_time'], $locationTz);
            $now = new DateTimeImmutable('now', $locationTz);
            if ($startTime < $now) {
                return 0; // Appointment already started, no cancellation email needed
            }
        }

        // Check if already sent
        if ($this->notificationRepo->wasRecentlySent('booking_cancelled', (int) $booking['booking_id'])) {
            return 0;
        }

        // Check if notifications are enabled
        $settings = $this->notificationRepo->getSettings((int) $booking['business_id']);
        if ($settings && !$settings['email_booking_cancelled']) {
            return 0;
        }

        // Notifications go ONLY to clients, never to operators
        if (!isset($booking['client_id']) || empty($booking['client_id'])) {
            return 0; // No client = no notification
        }
        
        $recipientType = 'client';
        $recipientId = (int) $booking['client_id'];
        $clientName = $this->extractFirstName($booking['client_name'] ?? null);
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
        
        if (!$recipientEmail || empty($recipientEmail['email'])) {
            return 0;
        }
        $recipientEmail['name'] = $this->extractFirstName($recipientEmail['name'] ?? null);
        $clientName = $this->extractFirstName($clientName);

        // Prepare template variables
        $locale = $this->resolveLocale($booking);
        $startTime = new DateTimeImmutable($booking['start_time']);
        
        // Location block for multi-location businesses
        $locationName = $booking['location_name'] ?? '';
        $locationAddress = $booking['location_address'] ?? '';
        $strings = EmailTemplateRenderer::strings($locale);
        $hasMultipleLocations = $this->hasMultipleLocations((int) ($booking['business_id'] ?? 0));
        $locationBlockHtml = $hasMultipleLocations ? sprintf(
            '<tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;">📍 %s</span><br>
                                        <strong style="color:#333;">%s</strong><br>
                                        <span style="color:#666;font-size:14px;">%s</span>
                                    </td>
                                </tr>',
            $strings['where_label'],
            $locationName,
            $locationAddress
        ) : '';
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
            'date' => EmailTemplateRenderer::formatLongDate($startTime, $locale),
            'time' => $startTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'booking_url' => $booking['booking_url'] ?? '#',
            'location_block_html' => $locationBlockHtml,
            'location_block_text' => $locationBlockText,
        ];
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $strings = EmailTemplateRenderer::strings($locale);
            $variables['client_name'] = $recipientEmail['name'] ?? $strings['client_fallback'];
        } else {
            $variables['client_name'] = $this->extractFirstName($variables['client_name']);
        }
        
        $template = EmailTemplateRenderer::bookingCancelled($locale);
        
        return $this->notificationRepo->queue([
            'type' => 'email',
            'channel' => 'booking_cancelled',
            'recipient_type' => $recipientType,
            'recipient_id' => $recipientId,
            'recipient_email' => $recipientEmail['email'],
            'recipient_name' => $recipientEmail['name'],
            'subject' => EmailTemplateRenderer::render($template['subject'], $variables),
            'payload' => [
                'template' => 'booking_cancelled',
                'variables' => $variables,
            ],
            'priority' => 2,
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

    private function resolveLocale(array $booking): string
    {
        return EmailTemplateRenderer::normalizeLocale(
            $booking['locale'] ?? $booking['business_locale'] ?? null
        );
    }

    private function hasMultipleLocations(int $businessId): bool
    {
        if ($businessId <= 0) {
            return false;
        }
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM locations WHERE business_id = :business_id AND is_active = 1'
        );
        $stmt->execute(['business_id' => $businessId]);
        return (int) $stmt->fetchColumn() > 1;
    }
}
