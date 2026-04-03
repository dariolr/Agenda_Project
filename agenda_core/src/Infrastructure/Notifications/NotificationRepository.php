<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Repository for notification queue operations.
 */
final class NotificationRepository
{
    /** @var string[] */
    private const ALLOWED_CHANNELS = [
        'booking_confirmed',
        'booking_reminder',
        'booking_cancelled',
        'booking_rescheduled',
    ];

    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Queue a notification for async processing.
     */
    public function queue(array $data): int
    {
        $channel = (string) ($data['channel'] ?? '');
        if (!in_array($channel, self::ALLOWED_CHANNELS, true)) {
            throw new \InvalidArgumentException("Unsupported notification channel: {$channel}");
        }

        // TEST MODE: Override recipient email with configured test address
        if (($_ENV['NOTIFICATION_TEST_MODE'] ?? 'false') === 'true') {
            $testEmail = $_ENV['NOTIFICATION_TEST_EMAIL'] ?? 'test@example.com';
            $data['recipient_email'] = $testEmail;
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO notification_queue 
             (type, channel, recipient_type, recipient_id, recipient_email, recipient_name, 
              subject, payload, priority, scheduled_at, max_attempts, business_id, booking_id, status)
             VALUES 
             (:type, :channel, :recipient_type, :recipient_id, :recipient_email, :recipient_name,
              :subject, :payload, :priority, :scheduled_at, :max_attempts, :business_id, :booking_id, "pending")'
        );

        $stmt->execute([
            'type' => $data['type'] ?? 'email',
            'channel' => $channel,
            'recipient_type' => $data['recipient_type'],
            'recipient_id' => $data['recipient_id'],
            'recipient_email' => $data['recipient_email'] ?? null,
            'recipient_name' => $data['recipient_name'] ?? null,
            'subject' => $data['subject'] ?? null,
            'payload' => Json::encode($data['payload'] ?? []),
            'priority' => $data['priority'] ?? 5,
            'scheduled_at' => $data['scheduled_at'] ?? null,
            'max_attempts' => $data['max_attempts'] ?? 3,
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
        $reminderLookaheadHoursRaw = $_ENV['REMINDER_FETCH_LOOKAHEAD_HOURS']
            ?? getenv('REMINDER_FETCH_LOOKAHEAD_HOURS')
            ?: '3';
        $reminderLookaheadHours = (int) $reminderLookaheadHoursRaw;
        if ($reminderLookaheadHours < 0) {
            $reminderLookaheadHours = 0;
        }

        $candidateLimit = max($limit * 5, $limit);
        if ($candidateLimit > 5000) {
            $candidateLimit = 5000;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT nq.*, l.timezone AS location_timezone
             FROM notification_queue nq
             LEFT JOIN bookings b ON b.id = nq.booking_id
             LEFT JOIN locations l ON l.id = b.location_id
             WHERE nq.status = "pending"
               AND nq.attempts < nq.max_attempts
             ORDER BY
                nq.priority ASC,
                CASE WHEN nq.channel = "booking_reminder" THEN COALESCE(nq.scheduled_at, nq.created_at) ELSE nq.created_at END ASC,
                nq.created_at ASC
             LIMIT :limit
             FOR UPDATE SKIP LOCKED'
        );
        $stmt->bindValue('limit', $candidateLimit, \PDO::PARAM_INT);
        $stmt->execute();

        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        $ready = [];
        foreach ($rows as $row) {
            if (!$this->isNotificationReadyBySchedule($row, $reminderLookaheadHours)) {
                continue;
            }

            $ready[] = $row;
            if (count($ready) >= $limit) {
                break;
            }
        }

        return $ready;
    }

    /**
     * Mark notification as processing.
     */
    public function markProcessing(int $id): void
    {
        $now = $this->resolveCurrentTimeForNotification($id);
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE notification_queue 
             SET status = "processing", attempts = attempts + 1, last_attempt_at = :last_attempt_at
             WHERE id = :id'
        );
        $stmt->execute([
            'id' => $id,
            'last_attempt_at' => $now->format('Y-m-d H:i:s'),
        ]);
    }

    /**
     * Mark notification as sent.
     */
    public function markSent(
        int $id,
        bool $writeBookingAuditEvent = true,
        ?string $providerUsed = null,
    ): void
    {
        $now = $this->resolveCurrentTimeForNotification($id);
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE notification_queue 
             SET status = "sent",
                 sent_at = :sent_at,
                 error_message = NULL,
                 failed_at = NULL,
                 provider_used = :provider_used
             WHERE id = :id'
        );
        $stmt->execute([
            'id' => $id,
            'sent_at' => $now->format('Y-m-d H:i:s'),
            'provider_used' => $providerUsed,
        ]);

        if ($writeBookingAuditEvent) {
            $this->createBookingNotificationSentEvent($id);
        }
    }

    /**
     * Mark notification as failed.
     */
    public function markFailed(int $id, string $error, ?string $retryScheduledAt = null): void
    {
        $now = $this->resolveCurrentTimeForNotification($id);
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE notification_queue 
             SET status = CASE WHEN attempts >= max_attempts THEN "failed" ELSE "pending" END,
                 failed_at = CASE WHEN attempts >= max_attempts THEN :failed_at ELSE NULL END,
                 scheduled_at = CASE
                    WHEN attempts >= max_attempts THEN scheduled_at
                    WHEN :retry_scheduled_at_check IS NOT NULL THEN :retry_scheduled_at_value
                    ELSE scheduled_at
                 END,
                 error_message = :error
             WHERE id = :id'
        );
        $stmt->execute([
            'id' => $id,
            'error' => $error,
            'failed_at' => $now->format('Y-m-d H:i:s'),
            'retry_scheduled_at_check' => $retryScheduledAt,
            'retry_scheduled_at_value' => $retryScheduledAt,
        ]);
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
                'SELECT id, booking_id, channel, recipient_email, subject, provider_used
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

            $createdAt = $this->resolveCurrentTimeForBooking($bookingId);
            $payload = Json::encode([
                'notification_id' => (int) ($notification['id'] ?? $notificationId),
                'channel' => (string) ($notification['channel'] ?? ''),
                'recipient_email' => $notification['recipient_email'] ?? null,
                'subject' => $notification['subject'] ?? null,
                'provider_used' => $notification['provider_used'] ?? null,
                'sent_at' => $createdAt->format('Y-m-d H:i:s'),
            ]);

            $insert = $this->db->getPdo()->prepare(
                'INSERT INTO booking_events
                 (booking_id, event_type, actor_type, actor_id, actor_name, payload_json, correlation_id, created_at)
                 VALUES
                 (:booking_id, :event_type, :actor_type, NULL, :actor_name, :payload_json, NULL, :created_at)'
            );
            $insert->execute([
                'booking_id' => $bookingId,
                'event_type' => 'booking_notification_sent',
                'actor_type' => 'system',
                'actor_name' => 'Notification Worker',
                'payload_json' => $payload ?: '{}',
                'created_at' => $createdAt->format('Y-m-d H:i:s'),
            ]);
        } catch (\Throwable $e) {
            error_log("Failed to create booking_notification_sent event for notification {$notificationId}: " . $e->getMessage());
        }
    }

    /**
     * Reminder candidates are considered ready inside a configurable look-ahead
     * window using the booking location timezone.
     *
     * @param array<string, mixed> $notification
     */
    private function isNotificationReadyBySchedule(array $notification, int $lookaheadHours): bool
    {
        $scheduledAtRaw = $notification['scheduled_at'] ?? null;
        if (!is_string($scheduledAtRaw) || trim($scheduledAtRaw) === '') {
            return true;
        }

        $timezone = $this->safeTimezone((string) ($notification['location_timezone'] ?? 'Europe/Rome'));
        try {
            $scheduledAt = new DateTimeImmutable($scheduledAtRaw, $timezone);
        } catch (\Throwable) {
            return true;
        }

        $hoursAhead = 0;
        if (($notification['channel'] ?? '') === 'booking_reminder') {
            $hoursAhead = max(0, $lookaheadHours);
        }

        $readyUntil = (new DateTimeImmutable('now', $timezone))
            ->modify('+' . $hoursAhead . ' hours');

        return $scheduledAt <= $readyUntil;
    }

    private function resolveCurrentTimeForNotification(int $notificationId): DateTimeImmutable
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT l.timezone
             FROM notification_queue nq
             LEFT JOIN bookings b ON b.id = nq.booking_id
             LEFT JOIN locations l ON l.id = b.location_id
             WHERE nq.id = ?
             LIMIT 1'
        );
        $stmt->execute([$notificationId]);
        $timezoneName = (string) ($stmt->fetchColumn() ?: 'Europe/Rome');

        return new DateTimeImmutable('now', $this->safeTimezone($timezoneName));
    }

    private function safeTimezone(string $timezoneName): DateTimeZone
    {
        try {
            return new DateTimeZone($timezoneName);
        } catch (\Throwable) {
            return new DateTimeZone('Europe/Rome');
        }
    }

    private function resolveCurrentTimeForBooking(int $bookingId): DateTimeImmutable
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT l.timezone
             FROM bookings b
             JOIN locations l ON l.id = b.location_id
             WHERE b.id = ?
             LIMIT 1'
        );
        $stmt->execute([$bookingId]);
        $timezoneName = (string) ($stmt->fetchColumn() ?: 'Europe/Rome');

        try {
            $timezone = new DateTimeZone($timezoneName);
        } catch (\Throwable) {
            $timezone = new DateTimeZone('Europe/Rome');
        }

        return new DateTimeImmutable('now', $timezone);
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
                   nq.recipient_email, nq.recipient_name, nq.subject, nq.payload,
                   nq.status, nq.priority, nq.attempts, nq.max_attempts,
                   nq.scheduled_at, nq.last_attempt_at, nq.sent_at, nq.failed_at, nq.error_message, nq.provider_used,
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
            'last_attempt' => 'nq.last_attempt_at',
            'appointment' => 'bi_range.first_start_time',
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
