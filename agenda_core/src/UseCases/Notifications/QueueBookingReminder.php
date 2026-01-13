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
     * Supports both 'user_id' (operators) and 'client_id' (customers).
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

        // Get recipient email - support both client_id (customers) and user_id (operators)
        $recipientType = 'user';
        $recipientId = null;
        $recipientEmail = null;
        $clientName = $this->extractFirstName($booking['client_name'] ?? null);
        
        // Notifications go ONLY to clients, never to operators
        if (!isset($booking['client_id']) || empty($booking['client_id'])) {
            return 0; // No client = no notification
        }
        
        $recipientType = 'client';
        $recipientId = (int) $booking['client_id'];
        $clientName = $this->extractFirstName($booking['client_name'] ?? 'Cliente');
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

        // Calculate scheduled time
        $startTime = new DateTimeImmutable($booking['start_time']);
        $scheduledAt = $startTime->modify("-{$hoursBefore} hours");
        
        // Don't schedule if already past
        if ($scheduledAt <= new DateTimeImmutable()) {
            return 0;
        }

        // Prepare variables
        $variables = [
            'client_name' => $clientName,
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
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $variables['client_name'] = $recipientEmail['name'] ?? 'Cliente';
        } else {
            $variables['client_name'] = $this->extractFirstName($variables['client_name']);
        }
        
        $template = EmailTemplateRenderer::bookingReminder();
        
        return $this->notificationRepo->queue([
            'type' => 'email',
            'channel' => 'booking_reminder',
            'recipient_type' => $recipientType,
            'recipient_id' => $recipientId,
            'recipient_email' => $recipientEmail['email'],
            'recipient_name' => $recipientEmail['name'],
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
        // Support both client_id (customers) and user_id (legacy operators)
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                b.id as booking_id,
                b.user_id,
                b.client_id,
                b.client_name,
                b.status,
                l.business_id,
                bus.name as business_name,
                bus.email as business_email,
                bus.slug as business_slug,
                l.name as location_name,
                l.address as location_address,
                l.phone as location_phone,
                l.email as location_email,
                c.email as client_email,
                c.first_name as client_first_name,
                MIN(bi.start_time) as start_time,
                GROUP_CONCAT(DISTINCT s.name SEPARATOR ", ") as services
             FROM bookings b
             JOIN locations l ON b.location_id = l.id
             JOIN businesses bus ON l.business_id = bus.id
             LEFT JOIN clients c ON b.client_id = c.id
             LEFT JOIN booking_items bi ON b.id = bi.booking_id
             LEFT JOIN service_variants sv ON bi.service_variant_id = sv.id
             LEFT JOIN services s ON sv.service_id = s.id
             WHERE b.status IN ("pending", "confirmed")
               AND (b.client_id IS NOT NULL OR b.user_id IS NOT NULL)
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
        
        // Get frontend URL from env
        $frontendUrl = getenv('FRONTEND_URL') ?: 'https://prenota.romeolab.it';
        
        // Process bookings to set client_name and manage_url properly
        foreach ($bookings as &$booking) {
            if (!empty($booking['client_first_name'])) {
                $booking['client_name'] = $booking['client_first_name'];
            }
            // Build manage_url from business slug
            $slug = $booking['business_slug'] ?? '';
            $booking['manage_url'] = $frontendUrl . '/' . $slug . '/my-bookings';
        }

        $queued = 0;
        foreach ($bookings as $booking) {
            if ($this->execute($booking) > 0) {
                $queued++;
            }
        }

        return $queued;
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
