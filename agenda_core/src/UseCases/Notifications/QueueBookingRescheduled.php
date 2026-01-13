<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use DateTimeImmutable;

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
            'location_phone' => $booking['location_phone'] ?? '',
            'old_date' => $oldStartTime ? $oldStartTime->format('d/m/Y') : '',
            'old_time' => $oldStartTime ? $oldStartTime->format('H:i') : '',
            'new_date' => $newStartTime->format('d/m/Y'),
            'new_time' => $newStartTime->format('H:i'),
            'date' => $newStartTime->format('d/m/Y'),
            'time' => $newStartTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'manage_url' => $booking['manage_url'] ?? '#',
            'booking_url' => $booking['booking_url'] ?? '#',
        ];
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $variables['client_name'] = $recipientEmail['name'] ?? 'Cliente';
        } else {
            $variables['client_name'] = $this->extractFirstName($variables['client_name']);
        }
        
        $template = EmailTemplateRenderer::bookingRescheduled();
        
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
}
