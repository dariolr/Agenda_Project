<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BusinessWhatsappSettingsRepository;
use Agenda\Infrastructure\Repositories\WhatsappRepository;
use Agenda\Infrastructure\Support\Json;
use Agenda\UseCases\Whatsapp\QueueWhatsappNotification;
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
        'class_booking_confirmed',
        'class_booking_waitlisted',
        'class_booking_promoted',
        'class_booking_cancelled',
        'class_booking_updated',
        'class_booking_reminder',
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

        $type = (string) ($data['type'] ?? 'email');
        $invalidRecipientReason = $this->invalidRecipientEmailReason($type, $data['recipient_email'] ?? null);
        if ($type === 'email' && isset($data['recipient_email'])) {
            $data['recipient_email'] = trim((string) $data['recipient_email']);
        }
        $status = $invalidRecipientReason === null ? 'pending' : 'skipped';
        $failedAt = $invalidRecipientReason === null
            ? null
            : $this->resolveCurrentTimeForOptionalBooking($data['booking_id'] ?? null)->format('Y-m-d H:i:s');

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO notification_queue
             (type, channel, recipient_type, recipient_id, recipient_email, recipient_name,
              subject, payload, priority, scheduled_at, max_attempts, business_id, booking_id, class_booking_id,
              status, failed_at, error_message)
             VALUES
             (:type, :channel, :recipient_type, :recipient_id, :recipient_email, :recipient_name,
              :subject, :payload, :priority, :scheduled_at, :max_attempts, :business_id, :booking_id, :class_booking_id,
              :status, :failed_at, :error_message)'
        );

        $params = [
            'type' => $type,
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
            'class_booking_id' => $data['class_booking_id'] ?? null,
            'status' => $status,
            'failed_at' => $failedAt,
            'error_message' => $invalidRecipientReason,
        ];
        $stmt->execute($params);
        $id = (int) $this->db->getPdo()->lastInsertId();

        $this->queueWhatsappMirror([
            ...$params,
            'id' => $id,
            'payload' => $data['payload'] ?? [],
        ]);

        if ($invalidRecipientReason !== null) {
            $this->createBookingNotificationSkippedEvent($id, $invalidRecipientReason);
        }

        return $id;
    }

    /**
     * Queue additional notifications for location's notification_emails (staff recipients).
     * Parses comma-separated emails and queues one notification per email.
     */
    public function queueForNotificationEmails(
        string $notificationEmails,
        string $channel,
        string $subject,
        array $variables,
        int $businessId,
        ?int $bookingId = null,
        ?int $classBookingId = null,
    ): void {
        $emails = array_map('trim', explode(',', $notificationEmails));
        $emails = array_filter($emails, static fn(string $email): bool => $email !== '');

        if (empty($emails)) {
            return;
        }

        $staffSubject = '[Staff] ' . $subject;

        foreach ($emails as $email) {
            $this->queue([
                'type' => 'email',
                'channel' => $channel,
                'recipient_type' => 'staff',
                'recipient_id' => 0,
                'recipient_email' => $email,
                'recipient_name' => null,
                'subject' => $staffSubject,
                'payload' => [
                    'template' => $channel,
                    'variables' => $variables,
                    'is_staff_notification' => true,
                ],
                'priority' => 5,
                'business_id' => $businessId,
                'booking_id' => $bookingId,
                'class_booking_id' => $classBookingId,
            ]);
        }
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
             WHERE status IN ("sent", "failed", "skipped")
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
        $this->deletePendingWhatsappBookingReminders($bookingId);

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
        $this->deletePendingWhatsappBookingRemindersForRecurringSeries($recurrenceRuleId);
        
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
        $this->deletePendingWhatsappBookingRemindersForFutureRecurrences($recurrenceRuleId, $fromIndex);
        
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
     * Writes booking audit event for notifications skipped before send attempt.
     */
    private function createBookingNotificationSkippedEvent(int $notificationId, string $reason): void
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

            $createdAt = $this->resolveCurrentTimeForBooking($bookingId);
            $payload = Json::encode([
                'notification_id' => (int) ($notification['id'] ?? $notificationId),
                'channel' => (string) ($notification['channel'] ?? ''),
                'recipient_email' => $notification['recipient_email'] ?? null,
                'subject' => $notification['subject'] ?? null,
                'reason' => $reason,
                'skipped_at' => $createdAt->format('Y-m-d H:i:s'),
            ]);

            $insert = $this->db->getPdo()->prepare(
                'INSERT INTO booking_events
                 (booking_id, event_type, actor_type, actor_id, actor_name, payload_json, correlation_id, created_at)
                 VALUES
                 (:booking_id, :event_type, :actor_type, NULL, :actor_name, :payload_json, NULL, :created_at)'
            );
            $insert->execute([
                'booking_id' => $bookingId,
                'event_type' => 'booking_notification_skipped',
                'actor_type' => 'system',
                'actor_name' => 'Notification Queue',
                'payload_json' => $payload ?: '{}',
                'created_at' => $createdAt->format('Y-m-d H:i:s'),
            ]);
        } catch (\Throwable $e) {
            error_log("Failed to create booking_notification_skipped event for notification {$notificationId}: " . $e->getMessage());
        }
    }

    private function invalidRecipientEmailReason(string $type, mixed $email): ?string
    {
        if ($type !== 'email') {
            return null;
        }

        $normalized = trim((string) $email);
        if ($normalized === '') {
            return 'Invalid recipient email: empty address';
        }

        if (!filter_var($normalized, FILTER_VALIDATE_EMAIL)) {
            return "Invalid recipient email: {$normalized}";
        }

        return null;
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

    private function resolveCurrentTimeForOptionalBooking(mixed $bookingId): DateTimeImmutable
    {
        if (!is_numeric($bookingId) || (int) $bookingId <= 0) {
            return new DateTimeImmutable('now', new DateTimeZone('Europe/Rome'));
        }

        return $this->resolveCurrentTimeForBooking((int) $bookingId);
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
     * Check if a class booking notification was already sent recently (deduplication).
     *
     * Returns false (allow send) if the class booking was re-booked (booked_at updated)
     * after the last sent notification — this covers the cancel-then-re-add scenario.
     * Both booked_at and created_at are stored in UTC, so the comparison is safe.
     */
    public function wasRecentlySentForClassBooking(string $channel, int $classBookingId, int $withinMinutes = 60): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT nq.created_at
             FROM notification_queue nq
             WHERE nq.channel = :channel
               AND nq.class_booking_id = :class_booking_id
               AND nq.status = "sent"
               AND nq.sent_at > DATE_SUB(NOW(), INTERVAL :minutes MINUTE)
             ORDER BY nq.sent_at DESC
             LIMIT 1'
        );
        $stmt->execute([
            'channel' => $channel,
            'class_booking_id' => $classBookingId,
            'minutes' => $withinMinutes,
        ]);

        $row = $stmt->fetch();
        if ($row === false) {
            return false;
        }

        // booked_at (UTC) vs created_at (UTC): se il booking è stato rinnovato
        // dopo la creazione dell'ultima notifica, è un nuovo evento → permetti re-invio.
        $bookedAtStmt = $this->db->getPdo()->prepare(
            'SELECT booked_at FROM class_bookings WHERE id = :id LIMIT 1'
        );
        $bookedAtStmt->execute(['id' => $classBookingId]);
        $booking = $bookedAtStmt->fetch();
        if ($booking && !empty($booking['booked_at']) && $booking['booked_at'] > $row['created_at']) {
            return false;
        }

        return true;
    }

    /**
     * Delete pending reminders for a class booking.
     */
    public function deletePendingClassBookingReminders(int $classBookingId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM notification_queue
             WHERE class_booking_id = :class_booking_id
               AND channel = "class_booking_reminder"
               AND status = "pending"'
        );
        $stmt->execute(['class_booking_id' => $classBookingId]);
        $this->deletePendingWhatsappClassBookingReminders($classBookingId);

        return $stmt->rowCount();
    }

    private function queueWhatsappMirror(array $notification): void
    {
        try {
            if (($notification['recipient_type'] ?? '') !== 'client') {
                return;
            }
            $queue = new QueueWhatsappNotification(
                $this->db,
                new WhatsappRepository($this->db),
                new BusinessWhatsappSettingsRepository($this->db)
            );
            $queue->queueFromNotificationRow($notification);
        } catch (\Throwable $e) {
            error_log('Failed to queue WhatsApp mirror notification: ' . $e->getMessage());
        }
    }

    private function deletePendingWhatsappBookingReminders(int $bookingId): void
    {
        try {
            (new WhatsappRepository($this->db))->deletePendingBookingReminders($bookingId);
        } catch (\Throwable $e) {
            error_log("Failed to delete WhatsApp booking reminders for booking {$bookingId}: " . $e->getMessage());
        }
    }

    private function deletePendingWhatsappBookingRemindersForRecurringSeries(int $recurrenceRuleId): void
    {
        try {
            (new WhatsappRepository($this->db))->deletePendingBookingRemindersForRecurringSeries($recurrenceRuleId);
        } catch (\Throwable $e) {
            error_log("Failed to delete WhatsApp booking reminders for recurrence rule {$recurrenceRuleId}: " . $e->getMessage());
        }
    }

    private function deletePendingWhatsappBookingRemindersForFutureRecurrences(int $recurrenceRuleId, int $fromIndex): void
    {
        try {
            (new WhatsappRepository($this->db))->deletePendingBookingRemindersForFutureRecurrences($recurrenceRuleId, $fromIndex);
        } catch (\Throwable $e) {
            error_log("Failed to delete future WhatsApp booking reminders for recurrence rule {$recurrenceRuleId}: " . $e->getMessage());
        }
    }

    private function deletePendingWhatsappClassBookingReminders(int $classBookingId): void
    {
        try {
            (new WhatsappRepository($this->db))->deletePendingClassBookingReminders($classBookingId);
        } catch (\Throwable $e) {
            error_log("Failed to delete WhatsApp class booking reminders for class booking {$classBookingId}: " . $e->getMessage());
        }
    }

    /**
     * Find booking notifications for a business with pagination and filters.
     *
     * @param int $businessId
     * @param array<string, mixed> $filters
     * @return array{notifications: array<int, array<string, mixed>>, total: int, available_booking_kinds: list<string>}
     */
    public function findBookingNotificationsWithFilters(
        int $businessId,
        array $filters = [],
        int $limit = 50,
        int $offset = 0
    ): array {
        $sortBy = (string) ($filters['sort_by'] ?? 'created');
        $sortOrder = strtoupper((string) ($filters['sort_order'] ?? 'DESC'));
        if (!in_array($sortOrder, ['ASC', 'DESC'], true)) {
            $sortOrder = 'DESC';
        }
        $safeLimit = max(1, min(100, $limit));
        $safeOffset = max(0, $offset);

        $providerFilters = $this->stringListFilter($filters['provider'] ?? null);
        $kindFilters = $this->bookingKindFilters($filters['booking_kind'] ?? null);
        $availableBookingKinds = $this->availableBookingKinds($businessId);
        $includeEmail = $providerFilters === []
            || in_array('email', $providerFilters, true)
            || count(array_diff($providerFilters, ['whatsapp'])) > 0;
        $includeWhatsapp = ($providerFilters === [] || in_array('whatsapp', $providerFilters, true))
            && $this->isWhatsappEnabledForBookingNotifications($businessId);

        $selects = [];
        $countSelects = [];
        $params = [];
        $countParams = [];

        if ($includeEmail && ($kindFilters === [] || in_array('service', $kindFilters, true))) {
            [$emailSelect, $emailCount, $emailParams] = $this->bookingEmailNotificationsSql(
                $businessId,
                $filters,
                $providerFilters
            );
            $selects[] = $emailSelect;
            $countSelects[] = $emailCount;
            $params = array_merge($params, $emailParams);
            $countParams = array_merge($countParams, $emailParams);
        }

        if ($includeEmail && ($kindFilters === [] || in_array('class', $kindFilters, true))) {
            [$classEmailSelect, $classEmailCount, $classEmailParams] = $this->classBookingEmailNotificationsSql(
                $businessId,
                $filters,
                $providerFilters
            );
            $selects[] = $classEmailSelect;
            $countSelects[] = $classEmailCount;
            $params = array_merge($params, $classEmailParams);
            $countParams = array_merge($countParams, $classEmailParams);
        }

        if ($includeWhatsapp && ($kindFilters === [] || in_array('service', $kindFilters, true))) {
            [$whatsappSelect, $whatsappCount, $whatsappParams] = $this->bookingWhatsappNotificationsSql(
                $businessId,
                $filters
            );
            $selects[] = $whatsappSelect;
            $countSelects[] = $whatsappCount;
            $params = array_merge($params, $whatsappParams);
            $countParams = array_merge($countParams, $whatsappParams);
        }

        if ($includeWhatsapp && ($kindFilters === [] || in_array('class', $kindFilters, true))) {
            [$classWhatsappSelect, $classWhatsappCount, $classWhatsappParams] = $this->classBookingWhatsappNotificationsSql(
                $businessId,
                $filters
            );
            $selects[] = $classWhatsappSelect;
            $countSelects[] = $classWhatsappCount;
            $params = array_merge($params, $classWhatsappParams);
            $countParams = array_merge($countParams, $classWhatsappParams);
        }

        if ($selects === []) {
            return [
                'notifications' => [],
                'total' => 0,
                'available_booking_kinds' => $availableBookingKinds,
            ];
        }

        $orderByColumn = match ($sortBy) {
            'scheduled' => 'scheduled_at',
            'sent' => 'sent_at',
            'last_attempt' => 'last_attempt_at',
            'appointment' => 'first_start_time',
            default => 'created_at',
        };
        $orderBy = " ORDER BY {$orderByColumn} {$sortOrder}, created_at {$sortOrder}, id DESC";

        $countSql = 'SELECT SUM(total) FROM (' . implode(' UNION ALL ', $countSelects) . ') counts';
        $countStmt = $this->db->getPdo()->prepare($countSql);
        $countStmt->execute($countParams);
        $total = (int) $countStmt->fetchColumn();

        $sql = 'SELECT * FROM (' . implode(' UNION ALL ', $selects) . ') booking_notifications'
            . $orderBy
            . " LIMIT {$safeLimit} OFFSET {$safeOffset}";
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $notifications = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        return [
            'notifications' => $notifications,
            'total' => $total,
            'available_booking_kinds' => $availableBookingKinds,
        ];
    }

    /**
     * @return array{0:string,1:string,2:array<int,mixed>}
     */
    private function bookingEmailNotificationsSql(int $businessId, array $filters, array $providerFilters): array
    {
        $where = ['nq.business_id = ?', 'nq.booking_id IS NOT NULL'];
        $params = [$businessId];

        $this->appendListWhere($where, $params, 'nq.status', $filters['status'] ?? null);
        $this->appendChannelWhere($where, $params, 'nq.channel', $filters['channel'] ?? null, 'service');

        $emailProviderFilters = array_values(array_filter(
            $providerFilters,
            static fn(string $provider): bool => !in_array($provider, ['email', 'whatsapp'], true)
        ));
        if ($emailProviderFilters !== []) {
            $this->appendListWhere($where, $params, 'nq.provider_used', $emailProviderFilters);
        }

        if (!empty($filters['search'])) {
            $search = '%' . trim((string) $filters['search']) . '%';
            $where[] = '(nq.recipient_name LIKE ? OR nq.recipient_email LIKE ? OR nq.subject LIKE ? OR b.client_name LIKE ? OR c.first_name LIKE ? OR c.last_name LIKE ?)';
            array_push($params, $search, $search, $search, $search, $search, $search);
        }
        $this->appendDateWhere($where, $params, 'nq.created_at', $filters);

        $whereClause = ' WHERE ' . implode(' AND ', $where);
        $from = '
            FROM notification_queue nq
            LEFT JOIN bookings b ON nq.booking_id = b.id
            LEFT JOIN clients c ON b.client_id = c.id
            LEFT JOIN locations l ON b.location_id = l.id
            LEFT JOIN (
                SELECT booking_id, MIN(start_time) AS first_start_time, MAX(end_time) AS last_end_time
                FROM booking_items
                GROUP BY booking_id
            ) bi_range ON bi_range.booking_id = b.id
        ';

        $select = '
            SELECT nq.id, "email" AS transport, nq.id AS source_id, nq.type, nq.channel,
                   nq.recipient_type, nq.recipient_id, nq.recipient_email, nq.recipient_name,
                   nq.subject, nq.payload, nq.status, nq.priority, nq.attempts, nq.max_attempts,
                   nq.scheduled_at, nq.last_attempt_at, nq.sent_at, nq.failed_at, nq.error_message,
                   COALESCE(NULLIF(nq.provider_used, ""), "email") AS provider_used,
                   nq.business_id, nq.booking_id, NULL AS class_booking_id, "service" AS booking_kind,
                   nq.created_at, nq.updated_at,
                   b.location_id, l.name AS location_name, b.client_name AS booking_client_name,
                   c.first_name AS client_first_name, c.last_name AS client_last_name,
                   bi_range.first_start_time, bi_range.last_end_time
        ' . $from . $whereClause;

        return [$select, 'SELECT COUNT(*) AS total ' . $from . $whereClause, $params];
    }

    /**
     * @return array{0:string,1:string,2:array<int,mixed>}
     */
    private function classBookingEmailNotificationsSql(int $businessId, array $filters, array $providerFilters): array
    {
        $where = ['nq.business_id = ?', 'nq.class_booking_id IS NOT NULL'];
        $params = [$businessId];

        $this->appendListWhere($where, $params, 'nq.status', $filters['status'] ?? null);
        $this->appendChannelWhere($where, $params, 'nq.channel', $filters['channel'] ?? null, 'class');

        $emailProviderFilters = array_values(array_filter(
            $providerFilters,
            static fn(string $provider): bool => !in_array($provider, ['email', 'whatsapp'], true)
        ));
        if ($emailProviderFilters !== []) {
            $this->appendListWhere($where, $params, 'nq.provider_used', $emailProviderFilters);
        }

        if (!empty($filters['search'])) {
            $search = '%' . trim((string) $filters['search']) . '%';
            $where[] = '(nq.recipient_name LIKE ? OR nq.recipient_email LIKE ? OR nq.subject LIKE ? OR ct.name LIKE ? OR c.first_name LIKE ? OR c.last_name LIKE ?)';
            array_push($params, $search, $search, $search, $search, $search, $search);
        }
        $this->appendDateWhere($where, $params, 'nq.created_at', $filters);

        $whereClause = ' WHERE ' . implode(' AND ', $where);
        $from = '
            FROM notification_queue nq
            LEFT JOIN class_bookings cb ON nq.class_booking_id = cb.id
            LEFT JOIN class_events ce ON cb.class_event_id = ce.id
            LEFT JOIN class_types ct ON ce.class_type_id = ct.id
            LEFT JOIN clients c ON cb.customer_id = c.id
            LEFT JOIN locations l ON ce.location_id = l.id
        ';

        $select = '
            SELECT nq.id, "email" AS transport, nq.id AS source_id, nq.type, nq.channel,
                   nq.recipient_type, nq.recipient_id, nq.recipient_email, nq.recipient_name,
                   nq.subject, nq.payload, nq.status, nq.priority, nq.attempts, nq.max_attempts,
                   nq.scheduled_at, nq.last_attempt_at, nq.sent_at, nq.failed_at, nq.error_message,
                   COALESCE(NULLIF(nq.provider_used, ""), "email") AS provider_used,
                   nq.business_id, NULL AS booking_id, nq.class_booking_id, "class" AS booking_kind,
                   nq.created_at, nq.updated_at,
                   ce.location_id, l.name AS location_name, ct.name AS booking_client_name,
                   c.first_name AS client_first_name, c.last_name AS client_last_name,
                   ce.starts_at AS first_start_time, ce.ends_at AS last_end_time
        ' . $from . $whereClause;

        return [$select, 'SELECT COUNT(*) AS total ' . $from . $whereClause, $params];
    }

    /**
     * @return array{0:string,1:string,2:array<int,mixed>}
     */
    private function bookingWhatsappNotificationsSql(int $businessId, array $filters): array
    {
        $where = ['wo.business_id = ?', 'wo.booking_id IS NOT NULL'];
        $params = [$businessId];

        $statuses = $this->stringListFilter($filters['status'] ?? null);
        if ($statuses !== []) {
            $mapped = [];
            foreach ($statuses as $status) {
                $mapped[] = $status === 'pending' ? 'queued' : $status;
            }
            $this->appendListWhere($where, $params, 'wo.status', $mapped);
        }
        $this->appendWhatsappChannelWhere($where, $params, 'wo.message_type', $filters['channel'] ?? null, 'service');

        if (!empty($filters['search'])) {
            $search = '%' . trim((string) $filters['search']) . '%';
            $where[] = '(wo.recipient_phone_e164 LIKE ? OR wo.recipient_phone LIKE ? OR wo.template_name LIKE ? OR b.client_name LIKE ? OR c.first_name LIKE ? OR c.last_name LIKE ?)';
            array_push($params, $search, $search, $search, $search, $search, $search);
        }
        $this->appendDateWhere($where, $params, 'wo.created_at', $filters);

        $whereClause = ' WHERE ' . implode(' AND ', $where);
        $from = '
            FROM whatsapp_outbox wo
            LEFT JOIN bookings b ON wo.booking_id = b.id
            LEFT JOIN clients c ON b.client_id = c.id
            LEFT JOIN locations l ON b.location_id = l.id
            LEFT JOIN (
                SELECT booking_id, MIN(start_time) AS first_start_time, MAX(end_time) AS last_end_time
                FROM booking_items
                GROUP BY booking_id
            ) bi_range ON bi_range.booking_id = b.id
        ';

        $select = '
            SELECT -wo.id AS id, "whatsapp" AS transport, wo.id AS source_id, "whatsapp" AS type,
                   CASE wo.message_type
                       WHEN "booking_confirmation" THEN "booking_confirmed"
                       WHEN "booking_cancellation" THEN "booking_cancelled"
                       WHEN "booking_reschedule" THEN "booking_rescheduled"
                       ELSE wo.message_type
                   END AS channel,
                   "client" AS recipient_type, wo.client_id AS recipient_id,
                   COALESCE(NULLIF(wo.recipient_phone_e164, ""), wo.recipient_phone) AS recipient_email,
                   COALESCE(NULLIF(b.client_name, ""), CONCAT_WS(" ", c.first_name, c.last_name)) AS recipient_name,
                   wo.template_name AS subject, COALESCE(wo.template_variables_json, wo.template_payload) AS payload,
                   CASE wo.status WHEN "queued" THEN "pending" WHEN "cancelled" THEN "skipped" ELSE wo.status END AS status,
                   5 AS priority, wo.attempts, wo.max_attempts, wo.scheduled_at, wo.last_attempt_at,
                   wo.sent_at, wo.failed_at, COALESCE(wo.provider_error_message, wo.error_message) AS error_message,
                   "whatsapp" AS provider_used, wo.business_id, wo.booking_id, NULL AS class_booking_id,
                   "service" AS booking_kind, wo.created_at, wo.updated_at,
                   b.location_id, l.name AS location_name, b.client_name AS booking_client_name,
                   c.first_name AS client_first_name, c.last_name AS client_last_name,
                   bi_range.first_start_time, bi_range.last_end_time
        ' . $from . $whereClause;

        return [$select, 'SELECT COUNT(*) AS total ' . $from . $whereClause, $params];
    }

    /**
     * @return array{0:string,1:string,2:array<int,mixed>}
     */
    private function classBookingWhatsappNotificationsSql(int $businessId, array $filters): array
    {
        $where = ['wo.business_id = ?', 'wo.class_booking_id IS NOT NULL'];
        $params = [$businessId];

        $statuses = $this->stringListFilter($filters['status'] ?? null);
        if ($statuses !== []) {
            $mapped = [];
            foreach ($statuses as $status) {
                $mapped[] = $status === 'pending' ? 'queued' : $status;
            }
            $this->appendListWhere($where, $params, 'wo.status', $mapped);
        }
        $this->appendWhatsappChannelWhere($where, $params, 'wo.message_type', $filters['channel'] ?? null, 'class');

        if (!empty($filters['search'])) {
            $search = '%' . trim((string) $filters['search']) . '%';
            $where[] = '(wo.recipient_phone_e164 LIKE ? OR wo.recipient_phone LIKE ? OR wo.template_name LIKE ? OR ct.name LIKE ? OR c.first_name LIKE ? OR c.last_name LIKE ?)';
            array_push($params, $search, $search, $search, $search, $search, $search);
        }
        $this->appendDateWhere($where, $params, 'wo.created_at', $filters);

        $whereClause = ' WHERE ' . implode(' AND ', $where);
        $from = '
            FROM whatsapp_outbox wo
            LEFT JOIN class_bookings cb ON wo.class_booking_id = cb.id
            LEFT JOIN class_events ce ON cb.class_event_id = ce.id
            LEFT JOIN class_types ct ON ce.class_type_id = ct.id
            LEFT JOIN clients c ON cb.customer_id = c.id
            LEFT JOIN locations l ON ce.location_id = l.id
        ';

        $select = '
            SELECT -wo.id AS id, "whatsapp" AS transport, wo.id AS source_id, "whatsapp" AS type,
                   CASE wo.message_type
                       WHEN "class_booking_confirmation" THEN "class_booking_confirmed"
                       WHEN "class_booking_cancellation" THEN "class_booking_cancelled"
                       WHEN "class_booking_reminder" THEN "class_booking_reminder"
                       ELSE wo.message_type
                   END AS channel,
                   "client" AS recipient_type, wo.client_id AS recipient_id,
                   COALESCE(NULLIF(wo.recipient_phone_e164, ""), wo.recipient_phone) AS recipient_email,
                   CONCAT_WS(" ", c.first_name, c.last_name) AS recipient_name,
                   wo.template_name AS subject, COALESCE(wo.template_variables_json, wo.template_payload) AS payload,
                   CASE wo.status WHEN "queued" THEN "pending" WHEN "cancelled" THEN "skipped" ELSE wo.status END AS status,
                   5 AS priority, wo.attempts, wo.max_attempts, wo.scheduled_at, wo.last_attempt_at,
                   wo.sent_at, wo.failed_at, COALESCE(wo.provider_error_message, wo.error_message) AS error_message,
                   "whatsapp" AS provider_used, wo.business_id, NULL AS booking_id, wo.class_booking_id,
                   "class" AS booking_kind, wo.created_at, wo.updated_at,
                   ce.location_id, l.name AS location_name, ct.name AS booking_client_name,
                   c.first_name AS client_first_name, c.last_name AS client_last_name,
                   ce.starts_at AS first_start_time, ce.ends_at AS last_end_time
        ' . $from . $whereClause;

        return [$select, 'SELECT COUNT(*) AS total ' . $from . $whereClause, $params];
    }

    private function isWhatsappEnabledForBookingNotifications(int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM business_whatsapp_settings
             WHERE business_id = ?
               AND whatsapp_enabled = 1
               AND messages_enabled = 1
               AND business_messages_enabled = 1
             LIMIT 1'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchColumn() !== false;
    }

    /**
     * @return list<string>
     */
    private function availableBookingKinds(int $businessId): array
    {
        $kinds = [];

        $serviceStmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM services s
             JOIN service_variants sv ON sv.service_id = s.id AND sv.is_active = 1
             WHERE s.business_id = ?
               AND s.is_active = 1
             LIMIT 1'
        );
        $serviceStmt->execute([$businessId]);
        if ($serviceStmt->fetchColumn() !== false) {
            $kinds[] = 'service';
        }

        $classStmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM class_types
             WHERE business_id = ?
               AND is_active = 1
             LIMIT 1'
        );
        $classStmt->execute([$businessId]);
        if ($classStmt->fetchColumn() !== false) {
            $kinds[] = 'class';
        }

        return $kinds;
    }

    /**
     * @return list<string>
     */
    private function bookingKindFilters(mixed $value): array
    {
        return array_values(array_intersect(
            $this->stringListFilter($value),
            ['service', 'class']
        ));
    }

    /**
     * @return list<string>
     */
    private function channelFiltersForKind(mixed $value, string $kind): array
    {
        $channels = $this->stringListFilter($value);
        if ($channels === []) {
            return [];
        }

        $prefix = $kind === 'class' ? 'class_booking_' : 'booking_';
        return array_values(array_filter(
            $channels,
            static fn(string $channel): bool => str_starts_with($channel, $prefix)
        ));
    }

    /**
     * @return list<string>
     */
    private function whatsappMessageTypeFilters(mixed $value, string $kind): array
    {
        $channels = $this->channelFiltersForKind($value, $kind);
        if ($channels === []) {
            return [];
        }

        $map = [
            'booking_confirmed' => 'booking_confirmation',
            'booking_cancelled' => 'booking_cancellation',
            'booking_rescheduled' => 'booking_reschedule',
            'booking_reminder' => 'booking_reminder',
            'class_booking_confirmed' => 'class_booking_confirmation',
            'class_booking_promoted' => 'class_booking_confirmation',
            'class_booking_cancelled' => 'class_booking_cancellation',
            'class_booking_reminder' => 'class_booking_reminder',
        ];

        return array_values(array_unique(array_filter(array_map(
            static fn(string $channel): ?string => $map[$channel] ?? null,
            $channels
        ))));
    }

    /**
     * @param list<string> $where
     * @param list<mixed> $params
     */
    private function appendChannelWhere(array &$where, array &$params, string $column, mixed $value, string $kind): void
    {
        $requested = $this->stringListFilter($value);
        if ($requested === []) {
            return;
        }

        $channels = $this->channelFiltersForKind($requested, $kind);
        if ($channels === []) {
            $where[] = '1 = 0';
            return;
        }

        $this->appendListWhere($where, $params, $column, $channels);
    }

    /**
     * @param list<string> $where
     * @param list<mixed> $params
     */
    private function appendWhatsappChannelWhere(array &$where, array &$params, string $column, mixed $value, string $kind): void
    {
        $requested = $this->stringListFilter($value);
        if ($requested === []) {
            return;
        }

        $messageTypes = $this->whatsappMessageTypeFilters($requested, $kind);
        if ($messageTypes === []) {
            $where[] = '1 = 0';
            return;
        }

        $this->appendListWhere($where, $params, $column, $messageTypes);
    }

    /**
     * @return list<string>
     */
    private function stringListFilter(mixed $value): array
    {
        $items = is_array($value) ? $value : ($value === null || $value === '' ? [] : [$value]);
        return array_values(array_filter(array_map(
            static fn(mixed $item): string => trim((string) $item),
            $items
        ), static fn(string $item): bool => $item !== ''));
    }

    /**
     * @param list<string> $where
     * @param list<mixed> $params
     */
    private function appendListWhere(array &$where, array &$params, string $column, mixed $value): void
    {
        $items = $this->stringListFilter($value);
        if ($items === []) {
            return;
        }
        $where[] = $column . ' IN (' . implode(',', array_fill(0, count($items), '?')) . ')';
        array_push($params, ...$items);
    }

    /**
     * @param list<string> $where
     * @param list<mixed> $params
     * @param array<string,mixed> $filters
     */
    private function appendDateWhere(array &$where, array &$params, string $column, array $filters): void
    {
        if (!empty($filters['start_date'])) {
            $where[] = $column . ' >= ?';
            $params[] = (string) $filters['start_date'] . ' 00:00:00';
        }
        if (!empty($filters['end_date'])) {
            $where[] = $column . ' <= ?';
            $params[] = (string) $filters['end_date'] . ' 23:59:59';
        }
    }
}
