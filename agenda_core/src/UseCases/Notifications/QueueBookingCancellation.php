<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use DateTimeImmutable;

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
        $startTime = new DateTimeImmutable($booking['start_time']);
        $variables = [
            'client_name' => $clientName,
            'business_name' => $booking['business_name'] ?? '',
            'business_email' => $booking['business_email'] ?? '',
            'location_name' => $booking['location_name'] ?? '',
            'location_email' => $booking['location_email'] ?? '',
            'sender_email' => $booking['sender_email'] ?? '',
            'sender_name' => $booking['sender_name'] ?? '',
            'location_address' => $booking['location_address'] ?? '',
            'location_city' => $booking['location_city'] ?? '',
            'date' => $startTime->format('d/m/Y'),
            'time' => $startTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'booking_url' => $booking['booking_url'] ?? '#',
        ];
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $variables['client_name'] = $recipientEmail['name'] ?? 'Cliente';
        } else {
            $variables['client_name'] = $this->extractFirstName($variables['client_name']);
        }
        
        $template = EmailTemplateRenderer::bookingCancelled();
        
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
}
