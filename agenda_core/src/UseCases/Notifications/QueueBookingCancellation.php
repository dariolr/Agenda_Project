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

        // Get user email
        $userEmail = $this->getUserEmail((int) $booking['user_id']);
        if (!$userEmail) {
            return 0;
        }

        // Prepare template variables
        $startTime = new DateTimeImmutable($booking['start_time']);
        $variables = [
            'client_name' => $userEmail['name'] ?? 'Cliente',
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
        
        $template = EmailTemplateRenderer::bookingCancelled();
        
        return $this->notificationRepo->queue([
            'type' => 'email',
            'channel' => 'booking_cancelled',
            'recipient_type' => 'user',
            'recipient_id' => $booking['user_id'],
            'recipient_email' => $userEmail['email'],
            'recipient_name' => $userEmail['name'],
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

    private function getUserEmail(int $userId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT email, CONCAT(first_name, " ", last_name) as name 
             FROM users WHERE id = :id'
        );
        $stmt->execute(['id' => $userId]);
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;
    }
}
