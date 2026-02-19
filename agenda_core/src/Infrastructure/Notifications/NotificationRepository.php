<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;

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
        // TEST MODE: Override recipient email with configured test address
        if (($_ENV['NOTIFICATION_TEST_MODE'] ?? 'false') === 'true') {
            $testEmail = $_ENV['NOTIFICATION_TEST_EMAIL'] ?? 'dariolarosa@romeolab.it';
            $data['recipient_email'] = $testEmail;
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
            'payload' => Json::encode($data['payload'] ?? []),
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
    public function markSent(int $id, bool $writeBookingAuditEvent = true): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE notification_queue 
             SET status = "sent", sent_at = NOW(), error_message = NULL, failed_at = NULL
             WHERE id = :id'
        );
        $stmt->execute(['id' => $id]);

        if ($writeBookingAuditEvent) {
            $this->createBookingNotificationSentEvent($id);
        }
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
     * Delete pending reminders for a specific booking.
     * Called when a booking is cancelled to avoid sending reminders for deleted bookings.
     * 
     * @param int $bookingId The booking ID
     * @return int Number of deleted notifications
     */
    public function deletePendingReminders(int $bookingId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM notification_queue 
             WHERE booking_id = :booking_id
               AND channel = "booking_reminder"
               AND status = "pending"'
        );
        $stmt->execute(['booking_id' => $bookingId]);
        
        return $stmt->rowCount();
    }

    /**
     * Delete pending reminders for all bookings in a recurring series.
     * Called when a recurring series is cancelled.
     * 
     * @param int $recurrenceRuleId The recurrence rule ID
     * @return int Number of deleted notifications
     */
    public function deletePendingRemindersForRecurringSeries(int $recurrenceRuleId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE nq FROM notification_queue nq
             INNER JOIN bookings b ON nq.booking_id = b.id
             WHERE b.recurrence_rule_id = :rule_id
               AND nq.channel = "booking_reminder"
               AND nq.status = "pending"'
        );
        $stmt->execute(['rule_id' => $recurrenceRuleId]);
        
        return $stmt->rowCount();
    }

    /**
     * Delete pending reminders for future bookings in a recurring series.
     * Called when future recurring bookings are cancelled.
     * 
     * @param int $recurrenceRuleId The recurrence rule ID
     * @param int $fromIndex The recurrence index to start from
     * @return int Number of deleted notifications
     */
    public function deletePendingRemindersForFutureRecurrences(int $recurrenceRuleId, int $fromIndex): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE nq FROM notification_queue nq
             INNER JOIN bookings b ON nq.booking_id = b.id
             WHERE b.recurrence_rule_id = :rule_id
               AND b.recurrence_index >= :from_index
               AND nq.channel = "booking_reminder"
               AND nq.status = "pending"'
        );
        $stmt->execute(['rule_id' => $recurrenceRuleId, 'from_index' => $fromIndex]);
        
        return $stmt->rowCount();
    }

    /**
     * Writes booking audit event for sent notification (if linked to a booking).
     */
    private function createBookingNotificationSentEvent(int $notificationId): void
    {
        try {
            $stmt = $this->db->getPdo()->prepare(
                'SELECT id, booking_id, channel, recipient_email, subject
                 FROM notification_queue
                 WHERE id = :id
                 LIMIT 1'
            );
            $stmt->execute(['id' => $notificationId]);
            $notification = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$notification) {
                return;
            }

            $bookingId = isset($notification['booking_id']) ? (int) $notification['booking_id'] : 0;
            if ($bookingId <= 0) {
                return;
            }

            $payload = Json::encode([
                'notification_id' => (int) ($notification['id'] ?? $notificationId),
                'channel' => (string) ($notification['channel'] ?? ''),
                'recipient_email' => $notification['recipient_email'] ?? null,
                'subject' => $notification['subject'] ?? null,
                'sent_at' => gmdate('Y-m-d H:i:s'),
            ]);

            $insert = $this->db->getPdo()->prepare(
                'INSERT INTO booking_events
                 (booking_id, event_type, actor_type, actor_id, actor_name, payload_json, correlation_id, created_at)
                 VALUES
                 (:booking_id, :event_type, :actor_type, NULL, :actor_name, :payload_json, NULL, NOW())'
            );
            $insert->execute([
                'booking_id' => $bookingId,
                'event_type' => 'booking_notification_sent',
                'actor_type' => 'system',
                'actor_name' => 'Notification Worker',
                'payload_json' => $payload ?: '{}',
            ]);
        } catch (\Throwable $e) {
            error_log("Failed to create booking_notification_sent event for notification {$notificationId}: " . $e->getMessage());
        }
    }

    /**
     * Find booking notifications for a business with pagination and filters.
     *
     * @param int $businessId
     * @param array<string, mixed> $filters
     * @return array{notifications: array<int, array<string, mixed>>, total: int}
     */
    public function findBookingNotificationsWithFilters(
        int $businessId,
        array $filters = [],
        int $limit = 50,
        int $offset = 0
    ): array {
        $baseSelect = '
            SELECT nq.id, nq.type, nq.channel, nq.recipient_type, nq.recipient_id,
                   nq.recipient_email, nq.recipient_name, nq.subject,
                   nq.status, nq.priority, nq.attempts, nq.max_attempts,
                   nq.scheduled_at, nq.sent_at, nq.failed_at, nq.error_message,
                   nq.business_id, nq.booking_id, nq.created_at, nq.updated_at,
                   b.location_id, l.name AS location_name,
                   b.client_name AS booking_client_name,
                   c.first_name AS client_first_name, c.last_name AS client_last_name,
                   bi_range.first_start_time, bi_range.last_end_time
            FROM notification_queue nq
            LEFT JOIN bookings b ON nq.booking_id = b.id
            LEFT JOIN clients c ON b.client_id = c.id
            LEFT JOIN locations l ON b.location_id = l.id
            LEFT JOIN (
                SELECT booking_id,
                       MIN(start_time) AS first_start_time,
                       MAX(end_time) AS last_end_time
                FROM booking_items
                GROUP BY booking_id
            ) bi_range ON bi_range.booking_id = b.id
        ';

        $countSelect = '
            SELECT COUNT(DISTINCT nq.id)
            FROM notification_queue nq
            LEFT JOIN bookings b ON nq.booking_id = b.id
            LEFT JOIN clients c ON b.client_id = c.id
        ';

        $where = ['nq.business_id = ?', 'nq.booking_id IS NOT NULL'];
        $params = [$businessId];

        if (!empty($filters['status'])) {
            if (is_array($filters['status'])) {
                $placeholders = implode(',', array_fill(0, count($filters['status']), '?'));
                $where[] = "nq.status IN ($placeholders)";
                $params = array_merge($params, $filters['status']);
            } else {
                $where[] = 'nq.status = ?';
                $params[] = (string) $filters['status'];
            }
        }

        if (!empty($filters['channel'])) {
            if (is_array($filters['channel'])) {
                $placeholders = implode(',', array_fill(0, count($filters['channel']), '?'));
                $where[] = "nq.channel IN ($placeholders)";
                $params = array_merge($params, $filters['channel']);
            } else {
                $where[] = 'nq.channel = ?';
                $params[] = (string) $filters['channel'];
            }
        }

        if (!empty($filters['search'])) {
            $search = '%' . trim((string) $filters['search']) . '%';
            $where[] = '(nq.recipient_name LIKE ? OR nq.recipient_email LIKE ? OR nq.subject LIKE ? OR b.client_name LIKE ? OR c.first_name LIKE ? OR c.last_name LIKE ?)';
            $params[] = $search;
            $params[] = $search;
            $params[] = $search;
            $params[] = $search;
            $params[] = $search;
            $params[] = $search;
        }

        if (!empty($filters['start_date'])) {
            $where[] = 'nq.created_at >= ?';
            $params[] = (string) $filters['start_date'] . ' 00:00:00';
        }

        if (!empty($filters['end_date'])) {
            $where[] = 'nq.created_at <= ?';
            $params[] = (string) $filters['end_date'] . ' 23:59:59';
        }

        $whereClause = ' WHERE ' . implode(' AND ', $where);

        $sortBy = (string) ($filters['sort_by'] ?? 'created');
        $sortOrder = strtoupper((string) ($filters['sort_order'] ?? 'DESC'));
        if (!in_array($sortOrder, ['ASC', 'DESC'], true)) {
            $sortOrder = 'DESC';
        }

        $orderByColumn = match ($sortBy) {
            'scheduled' => 'nq.scheduled_at',
            'sent' => 'nq.sent_at',
            default => 'nq.created_at',
        };
        $orderBy = " ORDER BY $orderByColumn $sortOrder, nq.id DESC";

        $countStmt = $this->db->getPdo()->prepare($countSelect . $whereClause);
        $countStmt->execute($params);
        $total = (int) $countStmt->fetchColumn();

        $safeLimit = max(1, min(100, $limit));
        $safeOffset = max(0, $offset);
        $sql = $baseSelect . $whereClause . $orderBy . " LIMIT $safeLimit OFFSET $safeOffset";
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $notifications = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        return [
            'notifications' => $notifications,
            'total' => $total,
        ];
    }
}
