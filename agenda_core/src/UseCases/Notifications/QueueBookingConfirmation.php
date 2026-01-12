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
            'name' => $booking['client_name'] ?? null,
        ];
        
        // Fallback: if email not provided, query clients table
        if (empty($recipientEmail['email'])) {
            $recipientEmail = $this->getClientEmail($recipientId);
        }
        
        if (!$recipientEmail || empty($recipientEmail['email'])) {
            return 0;
        }

        // Prepare template variables
        $variables = $this->prepareVariables($booking);
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $variables['client_name'] = $recipientEmail['name'] ?? 'Cliente';
        }
        
        // Get template
        $template = EmailTemplateRenderer::bookingConfirmed();
        
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
            'SELECT email, CONCAT(first_name, " ", last_name) as name 
             FROM clients WHERE id = :id'
        );
        $stmt->execute(['id' => $clientId]);
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;
    }

    private function prepareVariables(array $booking): array
    {
        $startTime = new DateTimeImmutable($booking['start_time']);
        $cancelDeadline = isset($booking['cancellation_hours']) 
            ? $startTime->modify("-{$booking['cancellation_hours']} hours")
            : $startTime->modify('-24 hours');

        return [
            'client_name' => $booking['client_name'] ?? 'Cliente',
            'business_name' => $booking['business_name'] ?? '',
            'business_email' => $booking['business_email'] ?? '',
            'location_name' => $booking['location_name'] ?? '',
            'location_email' => $booking['location_email'] ?? '',
            'sender_email' => $booking['sender_email'] ?? '',
            'sender_name' => $booking['sender_name'] ?? '',
            'location_address' => $booking['location_address'] ?? '',
            'location_city' => $booking['location_city'] ?? '',
            'location_phone' => $booking['location_phone'] ?? '',
            'date' => $startTime->format('d/m/Y'),
            'time' => $startTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'total_price' => number_format((float) ($booking['total_price'] ?? 0), 2, ',', '.'),
            'cancel_deadline' => $cancelDeadline->format('d/m/Y H:i'),
            'manage_url' => $booking['manage_url'] ?? '#',
            'booking_url' => $booking['booking_url'] ?? '#',
        ];
    }
}
