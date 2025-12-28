<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use DateTimeImmutable;

/**
 * Queue booking reminder emails (scheduled for X hours before appointment).
 */
final class QueueBookingReminder
{
    public function __construct(
        private readonly Connection $db,
        private readonly NotificationRepository $notificationRepo,
    ) {}

    /**
     * Queue reminder for a specific booking.
     */
    public function execute(array $booking, int $hoursBeforeDefault = 24): int
    {
        // Check if already queued
        if ($this->notificationRepo->wasRecentlySent('booking_reminder', (int) $booking['booking_id'])) {
            return 0;
        }

        // Get settings
        $settings = $this->notificationRepo->getSettings((int) $booking['business_id']);
        if ($settings && !$settings['email_reminder_enabled']) {
            return 0;
        }
        
        $hoursBefore = $settings['email_reminder_hours'] ?? $hoursBeforeDefault;

        // Get user email
        $userEmail = $this->getUserEmail((int) $booking['user_id']);
        if (!$userEmail) {
            return 0;
        }

        // Calculate scheduled time
        $startTime = new DateTimeImmutable($booking['start_time']);
        $scheduledAt = $startTime->modify("-{$hoursBefore} hours");
        
        // Don't schedule if already past
        if ($scheduledAt <= new DateTimeImmutable()) {
            return 0;
        }

        // Prepare variables
        $variables = [
            'client_name' => $userEmail['name'] ?? 'Cliente',
            'business_name' => $booking['business_name'] ?? '',
            'business_email' => $booking['business_email'] ?? '',
            'location_name' => $booking['location_name'] ?? '',
            'location_email' => $booking['location_email'] ?? '',
            'sender_email' => $booking['sender_email'] ?? '',
            'sender_name' => $booking['sender_name'] ?? '',
            'location_address' => $booking['location_address'] ?? '',
            'location_phone' => $booking['location_phone'] ?? '',
            'date' => $startTime->format('d/m/Y'),
            'time' => $startTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'manage_url' => $booking['manage_url'] ?? '#',
        ];
        
        $template = EmailTemplateRenderer::bookingReminder();
        
        return $this->notificationRepo->queue([
            'type' => 'email',
            'channel' => 'booking_reminder',
            'recipient_type' => 'user',
            'recipient_id' => $booking['user_id'],
            'recipient_email' => $userEmail['email'],
            'recipient_name' => $userEmail['name'],
            'subject' => EmailTemplateRenderer::render($template['subject'], $variables),
            'payload' => [
                'template' => 'booking_reminder',
                'variables' => $variables,
            ],
            'priority' => 5, // Normal priority
            'scheduled_at' => $scheduledAt->format('Y-m-d H:i:s'),
            'business_id' => $booking['business_id'],
            'booking_id' => $booking['booking_id'],
        ]);
    }

    /**
     * Batch queue reminders for all upcoming bookings.
     * Run this via cron daily.
     */
    public function queueUpcomingReminders(): int
    {
        // Find bookings starting in next 48 hours without reminder queued
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                b.id as booking_id,
                b.user_id,
                b.status,
                l.business_id,
                bus.name as business_name,
                l.name as location_name,
                l.address as location_address,
                l.phone as location_phone,
                MIN(bi.start_time) as start_time,
                GROUP_CONCAT(DISTINCT s.name SEPARATOR ", ") as services
             FROM bookings b
             JOIN locations l ON b.location_id = l.id
             JOIN businesses bus ON l.business_id = bus.id
             LEFT JOIN booking_items bi ON b.id = bi.booking_id
             LEFT JOIN service_variants sv ON bi.service_variant_id = sv.id
             LEFT JOIN services s ON sv.service_id = s.id
             WHERE b.status IN ("pending", "confirmed")
               AND b.user_id IS NOT NULL
               AND bi.start_time BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 48 HOUR)
               AND NOT EXISTS (
                   SELECT 1 FROM notification_queue nq 
                   WHERE nq.booking_id = b.id 
                     AND nq.channel = "booking_reminder"
                     AND nq.status IN ("pending", "processing", "sent")
               )
             GROUP BY b.id
             LIMIT 1000'
        );
        $stmt->execute();
        $bookings = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        $queued = 0;
        foreach ($bookings as $booking) {
            if ($this->execute($booking) > 0) {
                $queued++;
            }
        }

        return $queued;
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
