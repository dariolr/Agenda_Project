<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for notification queue operations.
 */
final class NotificationRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Queue a notification for async processing.
     */
    public function queue(array $data): int
    {
        // TEST MODE: Override recipient email with nome.cognome@romeolab.it
        if (($_ENV['NOTIFICATION_TEST_MODE'] ?? 'false') === 'true') {
            $recipientName = $data['recipient_name'] ?? '';
            if (!empty($recipientName)) {
                $data['recipient_email'] = $this->buildTestEmail($recipientName);
            }
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO notification_queue 
             (type, channel, recipient_type, recipient_id, recipient_email, recipient_name, 
              subject, payload, priority, scheduled_at, business_id, booking_id, status)
             VALUES 
             (:type, :channel, :recipient_type, :recipient_id, :recipient_email, :recipient_name,
              :subject, :payload, :priority, :scheduled_at, :business_id, :booking_id, "pending")'
        );

        $stmt->execute([
            'type' => $data['type'] ?? 'email',
            'channel' => $data['channel'],
            'recipient_type' => $data['recipient_type'],
            'recipient_id' => $data['recipient_id'],
            'recipient_email' => $data['recipient_email'] ?? null,
            'recipient_name' => $data['recipient_name'] ?? null,
            'subject' => $data['subject'] ?? null,
            'payload' => json_encode($data['payload'] ?? []),
            'priority' => $data['priority'] ?? 5,
            'scheduled_at' => $data['scheduled_at'] ?? null,
            'business_id' => $data['business_id'] ?? null,
            'booking_id' => $data['booking_id'] ?? null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Get pending notifications ready to be sent.
     */
    public function getPending(int $limit = 50): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM notification_queue 
             WHERE status = "pending"
               AND (scheduled_at IS NULL OR scheduled_at <= NOW())
               AND attempts < max_attempts
             ORDER BY priority ASC, created_at ASC
             LIMIT :limit
             FOR UPDATE SKIP LOCKED'
        );
        $stmt->bindValue('limit', $limit, \PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Mark notification as processing.
     */
    public function markProcessing(int $id): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE notification_queue 
             SET status = "processing", attempts = attempts + 1, last_attempt_at = NOW()
             WHERE id = :id'
        );
        $stmt->execute(['id' => $id]);
    }

    /**
     * Mark notification as sent.
     */
    public function markSent(int $id): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE notification_queue 
             SET status = "sent", sent_at = NOW(), error_message = NULL, failed_at = NULL
             WHERE id = :id'
        );
        $stmt->execute(['id' => $id]);
    }

    /**
     * Mark notification as failed.
     */
    public function markFailed(int $id, string $error): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE notification_queue 
             SET status = CASE WHEN attempts >= max_attempts THEN "failed" ELSE "pending" END,
                 failed_at = CASE WHEN attempts >= max_attempts THEN NOW() ELSE NULL END,
                 error_message = :error
             WHERE id = :id'
        );
        $stmt->execute(['id' => $id, 'error' => $error]);
    }

    /**
     * Check if a similar notification was already sent recently (deduplication).
     */
    public function wasRecentlySent(string $channel, int $bookingId, int $withinMinutes = 60): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM notification_queue 
             WHERE channel = :channel 
               AND booking_id = :booking_id
               AND status = "sent"
               AND sent_at > DATE_SUB(NOW(), INTERVAL :minutes MINUTE)
             LIMIT 1'
        );
        $stmt->execute([
            'channel' => $channel,
            'booking_id' => $bookingId,
            'minutes' => $withinMinutes,
        ]);
        
        return $stmt->fetch() !== false;
    }

    /**
     * Get notification settings for a business.
     */
    public function getSettings(int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM notification_settings WHERE business_id = :business_id'
        );
        $stmt->execute(['business_id' => $businessId]);
        
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;
    }

    /**
     * Clean up old sent notifications (retention: 30 days).
     */
    public function cleanupOld(int $daysToKeep = 30): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM notification_queue 
             WHERE status IN ("sent", "failed")
               AND created_at < DATE_SUB(NOW(), INTERVAL :days DAY)'
        );
        $stmt->execute(['days' => $daysToKeep]);
        
        return $stmt->rowCount();
    }

    /**
     * Build test email from recipient name.
     * Converts "Mario Rossi" to "mario.rossi@romeolab.it"
     */
    private function buildTestEmail(string $name): string
    {
        // Normalize: lowercase, replace spaces with dots, remove special chars
        $email = strtolower(trim($name));
        $email = preg_replace('/\s+/', '.', $email);
        $email = preg_replace('/[^a-z0-9.]/', '', $email);
        $email = preg_replace('/\.+/', '.', $email); // Remove consecutive dots
        $email = trim($email, '.');
        
        if (empty($email)) {
            $email = 'test';
        }
        
        return $email . '@romeolab.it';
    }
}
