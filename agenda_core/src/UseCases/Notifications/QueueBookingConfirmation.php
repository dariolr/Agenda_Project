<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use DateTimeImmutable;

/**
 * Queue booking confirmation email.
 */
final class QueueBookingConfirmation
{
    public function __construct(
        private readonly Connection $db,
        private readonly NotificationRepository $notificationRepo,
    ) {}

    /**
     * Queue a booking confirmation email.
     * 
     * @param array $booking Booking data with all required fields
     *                       Supports both 'user_id' (operators) and 'client_id' (customers)
     */
    public function execute(array $booking): int
    {
        // Check if already sent (deduplication)
        if ($this->notificationRepo->wasRecentlySent('booking_confirmed', (int) $booking['booking_id'])) {
            return 0;
        }

        // Check if notifications are enabled
        $settings = $this->notificationRepo->getSettings((int) $booking['business_id']);
        if ($settings && !$settings['email_booking_confirmed']) {
            return 0;
        }

        // Notifications go ONLY to clients, never to operators
        if (!isset($booking['client_id']) || empty($booking['client_id'])) {
            return 0; // No client = no notification
        }
        
        $recipientType = 'client';
        $recipientId = (int) $booking['client_id'];
        $recipientEmail = [
            'email' => $booking['client_email'] ?? null,
            'name' => $this->extractFirstName($booking['client_name'] ?? null),
        ];
        
        // Fallback: if email not provided, query clients table
        if (empty($recipientEmail['email'])) {
            $recipientEmail = $this->getClientEmail($recipientId);
        }
        
        if (!$recipientEmail || empty($recipientEmail['email'])) {
            return 0;
        }
        $recipientEmail['name'] = $this->extractFirstName($recipientEmail['name'] ?? null);

        $locale = $this->resolveLocale($booking);

        // Prepare template variables
        $variables = $this->prepareVariables($booking, $locale);
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $strings = EmailTemplateRenderer::strings($locale);
            $variables['client_name'] = $recipientEmail['name'] ?? $strings['client_fallback'];
        } else {
            $variables['client_name'] = $this->extractFirstName($variables['client_name']);
        }
        
        // Get template
        $template = EmailTemplateRenderer::bookingConfirmed($locale);
        
        // Queue notification
        return $this->notificationRepo->queue([
            'type' => 'email',
            'channel' => 'booking_confirmed',
            'recipient_type' => $recipientType,
            'recipient_id' => $recipientId,
            'recipient_email' => $recipientEmail['email'],
            'recipient_name' => $recipientEmail['name'],
            'subject' => EmailTemplateRenderer::render($template['subject'], $variables),
            'payload' => [
                'template' => 'booking_confirmed',
                'variables' => $variables,
            ],
            'priority' => 1, // High priority
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

    private function prepareVariables(array $booking, string $locale): array
    {
        $startTime = new DateTimeImmutable($booking['start_time']);
        $cancelDeadline = isset($booking['cancellation_hours']) 
            ? $startTime->modify("-{$booking['cancellation_hours']} hours")
            : $startTime->modify('-24 hours');
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

        return [
            'client_name' => $this->extractFirstName($booking['client_name'] ?? $strings['client_fallback']),
            'business_name' => $booking['business_name'] ?? '',
            'business_email' => $booking['business_email'] ?? '',
            'location_name' => $locationName,
            'location_email' => $booking['location_email'] ?? '',
            'sender_email' => $booking['sender_email'] ?? '',
            'sender_name' => $booking['sender_name'] ?? '',
            'location_address' => $locationAddress,
            'location_city' => $booking['location_city'] ?? '',
            'location_phone' => $booking['location_phone'] ?? '',
            'date' => EmailTemplateRenderer::formatLongDate($startTime, $locale),
            'time' => $startTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'total_price' => number_format((float) ($booking['total_price'] ?? 0), 2, ',', '.'),
            'cancel_deadline' => EmailTemplateRenderer::formatLongDateTime($cancelDeadline, $locale),
            'manage_url' => $booking['manage_url'] ?? '#',
            'booking_url' => $booking['booking_url'] ?? '#',
            'location_block_html' => $locationBlockHtml,
            'location_block_text' => $locationBlockText,
        ];
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
