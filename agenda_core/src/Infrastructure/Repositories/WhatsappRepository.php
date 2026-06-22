<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;

final class WhatsappRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function getConfigsByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, waba_id, phone_number_id, display_phone_number,
                    access_token_encrypted, status, is_default, last_health_check_at,
                    last_error_code, last_error_message, created_at, updated_at
             FROM whatsapp_business_config
             WHERE business_id = ?
             ORDER BY is_default DESC, id DESC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function findConfigById(int $businessId, int $configId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, waba_id, phone_number_id, display_phone_number,
                    access_token_encrypted, status, is_default, last_health_check_at,
                    last_error_code, last_error_message, created_at, updated_at
             FROM whatsapp_business_config
             WHERE business_id = ? AND id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $configId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public function createConfig(
        int $businessId,
        string $wabaId,
        string $phoneNumberId,
        string $accessTokenEncrypted,
        string $status,
        bool $isDefault,
        ?string $displayPhoneNumber = null
    ): int {
        if ($isDefault) {
            $this->clearDefaultConfig($businessId);
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_business_config
             (business_id, waba_id, phone_number_id, display_phone_number, access_token_encrypted, status, is_default)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $wabaId,
            $phoneNumberId,
            $displayPhoneNumber,
            $accessTokenEncrypted,
            $status,
            $isDefault ? 1 : 0,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function findConfigByPhoneNumberId(int $businessId, string $phoneNumberId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, waba_id, phone_number_id, display_phone_number,
                    access_token_encrypted, status, is_default, last_health_check_at,
                    last_error_code, last_error_message, created_at, updated_at
             FROM whatsapp_business_config
             WHERE business_id = ? AND phone_number_id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $phoneNumberId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public function findConfigByPhoneNumberIdGlobal(string $phoneNumberId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, waba_id, phone_number_id, display_phone_number,
                    access_token_encrypted, status, is_default, last_health_check_at,
                    last_error_code, last_error_message, created_at, updated_at
             FROM whatsapp_business_config
             WHERE phone_number_id = ?
             ORDER BY id DESC
             LIMIT 1'
        );
        $stmt->execute([$phoneNumberId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public function upsertConfigByPhoneNumberId(
        int $businessId,
        string $wabaId,
        string $phoneNumberId,
        string $accessTokenEncrypted,
        string $status,
        bool $isDefault,
        ?string $displayPhoneNumber = null
    ): int {
        $existing = $this->findConfigByPhoneNumberId($businessId, $phoneNumberId);
        if ($isDefault) {
            $this->clearDefaultConfig($businessId);
        }

        if ($existing !== null) {
            $fields = [
                'waba_id = ?',
                'display_phone_number = ?',
                'access_token_encrypted = ?',
                'status = ?',
                'is_default = ?',
                'last_health_check_at = NULL',
                'last_error_code = NULL',
                'last_error_message = NULL',
                'updated_at = NOW()',
            ];
            $params = [
                $wabaId,
                $displayPhoneNumber,
                $accessTokenEncrypted,
                $status,
                $isDefault ? 1 : 0,
                $businessId,
                (int) $existing['id'],
            ];
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE whatsapp_business_config
                 SET ' . implode(', ', $fields) . '
                 WHERE business_id = ? AND id = ?'
            );
            $stmt->execute($params);

            return (int) $existing['id'];
        }

        return $this->createConfig(
            $businessId,
            $wabaId,
            $phoneNumberId,
            $accessTokenEncrypted,
            $status,
            $isDefault,
            $displayPhoneNumber
        );
    }

    public function updateConfig(int $businessId, int $configId, array $data): bool
    {
        $fields = [];
        $params = [];

        if (array_key_exists('waba_id', $data)) {
            $fields[] = 'waba_id = ?';
            $params[] = $data['waba_id'];
        }
        if (array_key_exists('phone_number_id', $data)) {
            $fields[] = 'phone_number_id = ?';
            $params[] = $data['phone_number_id'];
        }
        if (array_key_exists('access_token_encrypted', $data)) {
            $fields[] = 'access_token_encrypted = ?';
            $params[] = $data['access_token_encrypted'];
        }
        if (array_key_exists('status', $data)) {
            $fields[] = 'status = ?';
            $params[] = $data['status'];
        }
        if (
            array_key_exists('waba_id', $data)
            || array_key_exists('phone_number_id', $data)
            || array_key_exists('access_token_encrypted', $data)
            || (($data['status'] ?? null) === 'active')
        ) {
            $fields[] = 'last_health_check_at = NULL';
            $fields[] = 'last_error_code = NULL';
            $fields[] = 'last_error_message = NULL';
        }
        if (array_key_exists('is_default', $data)) {
            if ((bool) $data['is_default']) {
                $this->clearDefaultConfig($businessId);
            }
            $fields[] = 'is_default = ?';
            $params[] = (bool) $data['is_default'] ? 1 : 0;
        }

        if (empty($fields)) {
            return false;
        }

        $params[] = $businessId;
        $params[] = $configId;

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_business_config
             SET ' . implode(', ', $fields) . ', updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute($params);
    }

    public function markConfigError(
        int $businessId,
        int $configId,
        ?string $errorCode,
        ?string $errorMessage
    ): bool {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_business_config
             SET status = "error",
                 last_health_check_at = NOW(),
                 last_error_code = ?,
                 last_error_message = ?,
                 updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([
            $errorCode !== null ? mb_substr($errorCode, 0, 120) : null,
            $errorMessage !== null ? mb_substr($errorMessage, 0, 500) : null,
            $businessId,
            $configId,
        ]);
    }

    public function markConfigHealthy(int $businessId, int $configId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_business_config
             SET status = "active",
                 last_health_check_at = NOW(),
                 last_error_code = NULL,
                 last_error_message = NULL,
                 updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$businessId, $configId]);
    }

    public function deleteConfig(int $businessId, int $configId): bool
    {
        $pdo = $this->db->getPdo();
        $startedTransaction = !$pdo->inTransaction();
        if ($startedTransaction) {
            $pdo->beginTransaction();
        }

        try {
            $stmt = $pdo->prepare(
                'UPDATE whatsapp_outbox
                 SET status = "cancelled",
                     error_message = "whatsapp_config_removed",
                     provider_error_message = "whatsapp_config_removed",
                     updated_at = NOW()
                 WHERE business_id = ?
                   AND whatsapp_config_id = ?
                   AND status IN ("queued", "processing")'
            );
            $stmt->execute([$businessId, $configId]);

            $stmt = $pdo->prepare(
                'DELETE FROM whatsapp_location_mapping
                 WHERE business_id = ? AND whatsapp_config_id = ?'
            );
            $stmt->execute([$businessId, $configId]);

            $stmt = $pdo->prepare(
                'DELETE FROM whatsapp_business_config
                 WHERE business_id = ? AND id = ?'
            );
            $ok = $stmt->execute([$businessId, $configId]);

            if ($startedTransaction) {
                $pdo->commit();
            }

            return $ok;
        } catch (\Throwable $e) {
            if ($startedTransaction && $pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    public function getMappingsByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, location_id, whatsapp_config_id, created_at, updated_at
             FROM whatsapp_location_mapping
             WHERE business_id = ?
             ORDER BY location_id ASC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function findMappingById(int $businessId, int $mappingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, location_id, whatsapp_config_id, created_at, updated_at
             FROM whatsapp_location_mapping
             WHERE business_id = ? AND id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $mappingId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public function upsertMapping(int $businessId, int $locationId, int $configId): int
    {
        $existing = $this->findMappingByLocation($businessId, $locationId);
        if ($existing !== null) {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE whatsapp_location_mapping
                 SET whatsapp_config_id = ?, updated_at = NOW()
                 WHERE id = ?'
            );
            $stmt->execute([$configId, (int) $existing['id']]);

            return (int) $existing['id'];
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_location_mapping
             (business_id, location_id, whatsapp_config_id)
             VALUES (?, ?, ?)'
        );
        $stmt->execute([$businessId, $locationId, $configId]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function deleteMapping(int $businessId, int $mappingId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM whatsapp_location_mapping
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$businessId, $mappingId]);
    }

    public function listOutbox(
        int $businessId,
        ?string $status,
        int $limit,
        int $offset
    ): array {
        $params = [$businessId];
        $where = ['business_id = ?'];
        if ($status !== null && $status !== '') {
            $where[] = 'status = ?';
            $params[] = $status;
        }

        $safeLimit = max(1, min(100, $limit));
        $safeOffset = max(0, $offset);
        $sql = 'SELECT id, business_id, booking_id, location_id, whatsapp_config_id,
                       recipient_phone, template_name, template_language, template_payload,
                       status, attempts, max_attempts, provider_message_id, error_message,
                       scheduled_at, last_attempt_at, sent_at, delivered_at, read_at,
                       created_at, updated_at
                FROM whatsapp_outbox
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY created_at DESC, id DESC
                LIMIT ' . $safeLimit . ' OFFSET ' . $safeOffset;
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function countOutbox(int $businessId, ?string $status): int
    {
        $params = [$businessId];
        $where = ['business_id = ?'];
        if ($status !== null && $status !== '') {
            $where[] = 'status = ?';
            $params[] = $status;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM whatsapp_outbox WHERE ' . implode(' AND ', $where)
        );
        $stmt->execute($params);

        return (int) $stmt->fetchColumn();
    }

    public function createOutbox(array $data): int
    {
        $dedupeKey = $data['dedupe_key'] ?? null;
        if ($dedupeKey !== null && $this->findOutboxIdByDedupeKey((string) $dedupeKey) !== null) {
            return (int) $this->findOutboxIdByDedupeKey((string) $dedupeKey);
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_outbox
             (business_id, booking_id, class_booking_id, client_id, location_id, whatsapp_config_id,
              recipient_phone, recipient_phone_e164, template_name, template_language, template_payload,
              template_variables_json, message_type, status, attempts, max_attempts, scheduled_at, dedupe_key)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, "queued", 0, ?, ?, ?)'
        );
        $payload = Json::encode($data['template_payload'] ?? $data['template_variables'] ?? []);
        $stmt->execute([
            (int) $data['business_id'],
            $data['booking_id'] ?? null,
            $data['class_booking_id'] ?? null,
            $data['client_id'] ?? null,
            $data['location_id'] ?? null,
            $data['whatsapp_config_id'] ?? null,
            (string) ($data['recipient_phone'] ?? $data['recipient_phone_e164'] ?? ''),
            (string) ($data['recipient_phone_e164'] ?? $data['recipient_phone'] ?? ''),
            (string) $data['template_name'],
            (string) ($data['template_language'] ?? 'it'),
            $payload,
            $payload,
            (string) ($data['message_type'] ?? 'test'),
            (int) ($data['max_attempts'] ?? 3),
            $data['scheduled_at'] ?? null,
            $dedupeKey,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function getPendingOutbox(int $limit = 100, ?int $businessId = null): array
    {
        $params = [];
        $where = [
            'status = "queued"',
            '(scheduled_at IS NULL OR scheduled_at <= NOW())',
            'attempts < max_attempts',
        ];
        if ($businessId !== null && $businessId > 0) {
            $where[] = 'business_id = ?';
            $params[] = $businessId;
        }

        $safeLimit = max(1, min(500, $limit));
        $sql = 'SELECT id, business_id, location_id, whatsapp_config_id, booking_id, class_booking_id, client_id,
                       recipient_phone, recipient_phone_e164, template_name, template_language,
                       template_payload, template_variables_json, message_type, max_attempts, attempts, scheduled_at
                FROM whatsapp_outbox
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY scheduled_at ASC, id ASC
                LIMIT ' . $safeLimit;
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function markOutboxProcessing(int $businessId, int $outboxId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox
             SET status = "processing",
                 attempts = attempts + 1,
                 last_attempt_at = NOW(),
                 updated_at = NOW()
             WHERE business_id = ?
               AND id = ?
               AND status = "queued"
               AND attempts < max_attempts'
        );
        $stmt->execute([$businessId, $outboxId]);

        return $stmt->rowCount() === 1;
    }

    public function findOutboxIdByDedupeKey(string $dedupeKey): ?int
    {
        if ($dedupeKey === '') {
            return null;
        }
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id FROM whatsapp_outbox WHERE dedupe_key = ? LIMIT 1'
        );
        $stmt->execute([$dedupeKey]);
        $id = $stmt->fetchColumn();

        return $id === false ? null : (int) $id;
    }

    public function deletePendingBookingReminders(int $bookingId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox
             SET status = "cancelled", updated_at = NOW()
             WHERE booking_id = ?
               AND message_type = "booking_reminder"
               AND status IN ("queued", "processing")'
        );
        $stmt->execute([$bookingId]);

        return $stmt->rowCount();
    }

    public function deletePendingBookingRemindersForRecurringSeries(int $recurrenceRuleId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox wo
             INNER JOIN bookings b ON wo.booking_id = b.id
             SET wo.status = "cancelled", wo.updated_at = NOW()
             WHERE b.recurrence_rule_id = ?
               AND wo.message_type = "booking_reminder"
               AND wo.status IN ("queued", "processing")'
        );
        $stmt->execute([$recurrenceRuleId]);

        return $stmt->rowCount();
    }

    public function deletePendingBookingRemindersForFutureRecurrences(int $recurrenceRuleId, int $fromIndex): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox wo
             INNER JOIN bookings b ON wo.booking_id = b.id
             SET wo.status = "cancelled", wo.updated_at = NOW()
             WHERE b.recurrence_rule_id = ?
               AND b.recurrence_index >= ?
               AND wo.message_type = "booking_reminder"
               AND wo.status IN ("queued", "processing")'
        );
        $stmt->execute([$recurrenceRuleId, $fromIndex]);

        return $stmt->rowCount();
    }

    public function deletePendingClassBookingReminders(int $classBookingId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox
             SET status = "cancelled", updated_at = NOW()
             WHERE class_booking_id = ?
               AND message_type = "class_booking_reminder"
               AND status IN ("queued", "processing")'
        );
        $stmt->execute([$classBookingId]);

        return $stmt->rowCount();
    }

    public function findOutboxById(int $businessId, int $outboxId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, booking_id, location_id, whatsapp_config_id,
                    recipient_phone, template_name, template_language, template_payload,
                    status, attempts, max_attempts, provider_message_id, error_message,
                    provider_error_code, provider_error_message,
                    scheduled_at, last_attempt_at, sent_at, delivered_at, read_at,
                    created_at, updated_at
             FROM whatsapp_outbox
             WHERE business_id = ? AND id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $outboxId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public function markOutboxSent(int $businessId, int $outboxId, ?string $providerMessageId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox
             SET status = "sent",
                 provider_message_id = COALESCE(?, provider_message_id),
                 error_message = NULL,
                 provider_error_code = NULL,
                 provider_error_message = NULL,
                 last_attempt_at = NOW(),
                 sent_at = NOW(),
                 updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        $ok = $stmt->execute([$providerMessageId, $businessId, $outboxId]);
        if ($ok) {
            $this->createOutboxBookingEvent($businessId, $outboxId, 'booking_whatsapp_sent');
        }

        return $ok;
    }

    public function retryOutbox(int $businessId, int $outboxId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox
             SET status = "queued",
                 scheduled_at = NOW(),
                 updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$businessId, $outboxId]);
    }

    public function updateOutboxStatus(
        int $businessId,
        int $outboxId,
        string $status,
        ?string $errorMessage = null
    ): bool {
        $timestampField = match ($status) {
            'delivered' => 'delivered_at',
            'read' => 'read_at',
            default => null,
        };

        $sql = 'UPDATE whatsapp_outbox
                SET status = ?,
                    error_message = ?,
                    provider_error_message = ?,
                    updated_at = NOW()';
        if ($timestampField !== null) {
            $sql .= ', ' . $timestampField . ' = NOW()';
        }
        $sql .= ' WHERE business_id = ? AND id = ?';

        $stmt = $this->db->getPdo()->prepare($sql);

        return $stmt->execute([$status, $errorMessage, $errorMessage, $businessId, $outboxId]);
    }

    public function markOutboxSendFailure(
        int $businessId,
        int $outboxId,
        string $status,
        ?string $errorCode,
        ?string $errorMessage,
        ?string $scheduledAt = null
    ): bool {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_outbox
             SET status = ?,
                 error_message = ?,
                 provider_error_code = ?,
                 provider_error_message = ?,
                 scheduled_at = ?,
                 last_attempt_at = NOW(),
                 failed_at = CASE WHEN ? = "failed" THEN NOW() ELSE failed_at END,
                 updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        $ok = $stmt->execute([
            $status,
            $errorMessage,
            $errorCode,
            $errorMessage,
            $scheduledAt,
            $status,
            $businessId,
            $outboxId,
        ]);
        if ($ok && in_array($status, ['failed', 'skipped'], true)) {
            $this->createOutboxBookingEvent(
                $businessId,
                $outboxId,
                $status === 'skipped' ? 'booking_whatsapp_skipped' : 'booking_whatsapp_failed'
            );
        }

        return $ok;
    }

    private function createOutboxBookingEvent(int $businessId, int $outboxId, string $eventType): void
    {
        try {
            $stmt = $this->db->getPdo()->prepare(
                'SELECT id, booking_id, message_type, status, recipient_phone_e164, provider_message_id,
                        provider_error_code, provider_error_message, error_message
                 FROM whatsapp_outbox
                 WHERE business_id = ? AND id = ?
                 LIMIT 1'
            );
            $stmt->execute([$businessId, $outboxId]);
            $row = $stmt->fetch(\PDO::FETCH_ASSOC);
            if (!$row || empty($row['booking_id'])) {
                return;
            }

            $payload = Json::encode([
                'whatsapp_outbox_id' => (int) $row['id'],
                'message_type' => $row['message_type'] ?? null,
                'status' => $row['status'] ?? null,
                'recipient_phone_e164' => $row['recipient_phone_e164'] ?? null,
                'provider_message_id' => $row['provider_message_id'] ?? null,
                'provider_error_code' => $row['provider_error_code'] ?? null,
                'provider_error_message' => $row['provider_error_message'] ?? $row['error_message'] ?? null,
            ]);

            $insert = $this->db->getPdo()->prepare(
                'INSERT INTO booking_events
                 (booking_id, event_type, actor_type, actor_id, actor_name, payload_json, correlation_id, created_at)
                 VALUES (?, ?, "system", NULL, "WhatsApp Worker", ?, NULL, NOW())'
            );
            $insert->execute([(int) $row['booking_id'], $eventType, $payload ?: '{}']);
        } catch (\Throwable) {
        }
    }

    public function updateOutboxStatusByProviderMessageId(
        int $businessId,
        string $providerMessageId,
        string $status,
        ?string $errorMessage = null
    ): bool {
        $timestampField = match ($status) {
            'delivered' => 'delivered_at',
            'read' => 'read_at',
            default => null,
        };

        $sql = 'UPDATE whatsapp_outbox
                SET status = ?,
                    error_message = ?,
                    updated_at = NOW()';
        if ($timestampField !== null) {
            $sql .= ', ' . $timestampField . ' = NOW()';
        }
        $sql .= ' WHERE business_id = ? AND provider_message_id = ?';

        $stmt = $this->db->getPdo()->prepare($sql);

        return $stmt->execute([$status, $errorMessage, $businessId, $providerMessageId]);
    }

    public function isWebhookEventProcessed(string $eventId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM whatsapp_webhook_events WHERE event_id = ? LIMIT 1'
        );
        $stmt->execute([$eventId]);

        return $stmt->fetchColumn() !== false;
    }

    public function storeWebhookEvent(string $eventId, int $businessId, array $payload): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_webhook_events (event_id, business_id, payload_json, processed_at)
             VALUES (?, ?, ?, NOW())'
        );
        $stmt->execute([$eventId, $businessId, Json::encode($payload)]);
    }

    public function upsertOptIn(int $businessId, int $clientId, bool $optIn): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_client_optins (business_id, client_id, opt_in, updated_at)
             VALUES (?, ?, ?, NOW())
             ON DUPLICATE KEY UPDATE opt_in = VALUES(opt_in), updated_at = NOW()'
        );
        $stmt->execute([$businessId, $clientId, $optIn ? 1 : 0]);
    }

    public function optOutByPhone(int $businessId, string $rawPhone, string $source = 'whatsapp_stop'): bool
    {
        $normalized = preg_replace('/[^\d+]/', '', $rawPhone) ?? '';
        if ($normalized === '') {
            return false;
        }

        $clientStmt = $this->db->getPdo()->prepare(
            'SELECT id
             FROM clients
             WHERE business_id = ?
               AND is_archived = 0
               AND REPLACE(REPLACE(REPLACE(phone, " ", ""), "-", ""), ".", "") = ?
             LIMIT 1'
        );
        $clientStmt->execute([$businessId, $normalized]);
        $clientId = $clientStmt->fetchColumn();
        if ($clientId === false) {
            return false;
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_client_optins (business_id, client_id, opt_in, source, updated_at)
             VALUES (?, ?, 0, ?, NOW())
             ON DUPLICATE KEY UPDATE opt_in = 0, source = VALUES(source), updated_at = NOW()'
        );
        $stmt->execute([$businessId, (int) $clientId, $source]);

        return true;
    }

    public function hasActiveOptIn(int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM whatsapp_client_optins
             WHERE business_id = ? AND opt_in = 1
             LIMIT 1'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchColumn() !== false;
    }

    public function hasApprovedUtilityTemplate(int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM whatsapp_templates
             WHERE (business_id = ? OR business_id IS NULL) AND category = "utility" AND status = "approved"
             LIMIT 1'
        );
        $stmt->execute([$businessId]);

        if ($stmt->fetchColumn() !== false) {
            return true;
        }

        return trim((string) ($_ENV['WHATSAPP_REMINDER_TEMPLATE_NAME'] ?? getenv('WHATSAPP_REMINDER_TEMPLATE_NAME') ?? 'promemoria_appuntamento_ita_24h')) !== '';
    }

    public function listTemplatesByBusiness(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, provider_code, template_name, language_code, category, status,
                    message_type, body_preview, variables_schema_json, provider_template_id,
                    created_at, updated_at
             FROM whatsapp_templates
             WHERE business_id = ? OR business_id IS NULL
             ORDER BY business_id IS NULL ASC, message_type ASC, language_code ASC, template_name ASC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function findTemplateById(int $businessId, int $templateId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, provider_code, template_name, language_code, category, status,
                    message_type, body_preview, variables_schema_json, provider_template_id,
                    created_at, updated_at
             FROM whatsapp_templates
             WHERE id = ? AND (business_id = ? OR business_id IS NULL)
             LIMIT 1'
        );
        $stmt->execute([$templateId, $businessId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public function upsertTemplate(int $businessId, array $data): int
    {
        $templateId = (int) ($data['id'] ?? 0);
        $templateBusinessId = (bool) ($data['is_global'] ?? false) ? null : $businessId;
        $variablesSchema = $data['variables_schema_json'] ?? $data['variables_schema'] ?? null;
        $variablesJson = is_array($variablesSchema) ? Json::encode($variablesSchema) : $variablesSchema;

        if ($templateId > 0) {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE whatsapp_templates
                 SET business_id = ?,
                     template_name = ?,
                     language_code = ?,
                     category = ?,
                     status = ?,
                     message_type = ?,
                     body_preview = ?,
                     variables_schema_json = ?,
                     provider_template_id = ?,
                     updated_at = NOW()
                 WHERE id = ? AND (business_id = ? OR business_id IS NULL)'
            );
            $stmt->execute([
                $templateBusinessId,
                $data['template_name'],
                $data['language_code'],
                $data['category'] ?? 'utility',
                $data['status'] ?? 'draft',
                $data['message_type'] ?? null,
                $data['body_preview'] ?? null,
                $variablesJson,
                $data['provider_template_id'] ?? null,
                $templateId,
                $businessId,
            ]);

            return $templateId;
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_templates
             (business_id, provider_code, template_name, language_code, category, status,
              message_type, body_preview, variables_schema_json, provider_template_id)
             VALUES (?, "meta", ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $templateBusinessId,
            $data['template_name'],
            $data['language_code'],
            $data['category'] ?? 'utility',
            $data['status'] ?? 'draft',
            $data['message_type'] ?? null,
            $data['body_preview'] ?? null,
            $variablesJson,
            $data['provider_template_id'] ?? null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function disableTemplate(int $businessId, int $templateId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_templates
             SET status = "disabled", updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$businessId, $templateId]);
    }

    public function listTemplateAssignments(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT a.id, a.business_id, a.location_id, a.message_type, a.language_code,
                    a.whatsapp_template_id, a.is_active, a.created_at, a.updated_at,
                    t.template_name, t.status AS template_status, t.body_preview
             FROM whatsapp_template_assignments a
             JOIN whatsapp_templates t ON t.id = a.whatsapp_template_id
             WHERE a.business_id = ?
             ORDER BY a.location_id IS NULL DESC, a.location_id ASC, a.message_type ASC, a.language_code ASC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function findTemplateAssignment(
        int $businessId,
        ?int $locationId,
        string $messageType,
        string $languageCode
    ): ?array {
        $sql = 'SELECT a.id, a.business_id, a.location_id, a.message_type, a.language_code,
                       a.whatsapp_template_id, a.is_active, a.created_at, a.updated_at,
                       t.template_name, t.status AS template_status, t.body_preview
                FROM whatsapp_template_assignments a
                JOIN whatsapp_templates t ON t.id = a.whatsapp_template_id
                WHERE a.business_id = ?
                  AND a.message_type = ?
                  AND a.language_code = ?
                  AND a.is_active = 1
                  AND ';
        $params = [$businessId, $messageType, $languageCode];
        if ($locationId !== null && $locationId > 0) {
            $sql .= 'a.location_id = ?';
            $params[] = $locationId;
        } else {
            $sql .= 'a.location_id IS NULL';
        }
        $sql .= ' LIMIT 1';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public function upsertTemplateAssignment(
        int $businessId,
        ?int $locationId,
        string $messageType,
        string $languageCode,
        int $templateId,
        bool $isActive
    ): int {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_template_assignments
             (business_id, location_id, message_type, language_code, whatsapp_template_id, is_active)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               whatsapp_template_id = VALUES(whatsapp_template_id),
               is_active = VALUES(is_active),
               updated_at = NOW()'
        );
        $stmt->execute([
            $businessId,
            $locationId !== null && $locationId > 0 ? $locationId : null,
            $messageType,
            $languageCode,
            $templateId,
            $isActive ? 1 : 0,
        ]);

        $assignment = $this->findTemplateAssignment(
            $businessId,
            $locationId,
            $messageType,
            $languageCode
        );

        return (int) ($assignment['id'] ?? $this->db->getPdo()->lastInsertId());
    }

    public function deleteTemplateAssignment(int $businessId, int $assignmentId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM whatsapp_template_assignments
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$businessId, $assignmentId]);
    }

    public function resolveTemplateForNotification(
        int $businessId,
        ?int $locationId,
        string $messageType,
        string $languageCode
    ): ?array {
        $language = $this->normalizeTemplateLanguage($languageCode);
        if ($locationId !== null && $locationId > 0) {
            $assigned = $this->findAssignedApprovedTemplate($businessId, $locationId, $messageType, $language);
            if ($assigned !== null) {
                return $assigned;
            }
        }

        $assigned = $this->findAssignedApprovedTemplate($businessId, null, $messageType, $language);
        if ($assigned !== null) {
            return $assigned;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, template_name, language_code, message_type, status
             FROM whatsapp_templates
             WHERE business_id = ?
               AND (message_type = ? OR template_name = ?)
               AND language_code IN (?, "it")
               AND status = "approved"
             ORDER BY language_code = ? DESC
             LIMIT 1'
        );
        $stmt->execute([$businessId, $messageType, $messageType, $language, $language]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        if ($row !== false) {
            return $row;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, template_name, language_code, message_type, status
             FROM whatsapp_templates
             WHERE business_id IS NULL
               AND (message_type = ? OR template_name = ?)
               AND language_code IN (?, "it")
               AND status = "approved"
             ORDER BY language_code = ? DESC
             LIMIT 1'
        );
        $stmt->execute([$messageType, $messageType, $language, $language]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    private function findAssignedApprovedTemplate(
        int $businessId,
        ?int $locationId,
        string $messageType,
        string $languageCode
    ): ?array {
        $sql = 'SELECT t.id, t.business_id, t.template_name, t.language_code, t.message_type, t.status
                FROM whatsapp_template_assignments a
                JOIN whatsapp_templates t ON t.id = a.whatsapp_template_id
                WHERE a.business_id = ?
                  AND a.message_type = ?
                  AND a.language_code = ?
                  AND a.is_active = 1
                  AND t.status = "approved"
                  AND (t.business_id = ? OR t.business_id IS NULL)
                  AND ';
        $params = [$businessId, $messageType, $languageCode, $businessId];
        if ($locationId !== null && $locationId > 0) {
            $sql .= 'a.location_id = ?';
            $params[] = $locationId;
        } else {
            $sql .= 'a.location_id IS NULL';
        }
        $sql .= ' LIMIT 1';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    private function normalizeTemplateLanguage(string $languageCode): string
    {
        $value = strtolower(trim($languageCode));
        if ($value === '') {
            return 'it';
        }

        return str_starts_with($value, 'en') ? 'en' : $value;
    }

    public function hasWebhookEventForBusiness(int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM whatsapp_webhook_events WHERE business_id = ? LIMIT 1'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchColumn() !== false;
    }

    public function isEmbeddedSignupEnabled(
        int $businessId,
        bool $defaultEnabled = false
    ): bool {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT setting_value
             FROM business_application_settings
             WHERE business_id = ? AND setting_key = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, 'whatsapp_embedded_signup_enabled']);
        $raw = $stmt->fetchColumn();
        if ($raw === false || $raw === null) {
            return $defaultEnabled;
        }

        $decoded = json_decode((string) $raw, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            $decoded = null;
        }
        if (is_array($decoded) && array_key_exists('enabled', $decoded)) {
            return (bool) $decoded['enabled'];
        }
        if (is_bool($decoded)) {
            return $decoded;
        }
        if (is_numeric($decoded)) {
            return ((int) $decoded) === 1;
        }
        if (is_string($decoded)) {
            return in_array(strtolower(trim($decoded)), ['1', 'true', 'yes', 'on'], true);
        }

        return $defaultEnabled;
    }

    public function findConfigForLocation(int $businessId, int $locationId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT c.id, c.business_id, c.waba_id, c.phone_number_id, c.display_phone_number,
                    c.access_token_encrypted, c.status, c.is_default, c.last_health_check_at,
                    c.last_error_code, c.last_error_message, c.created_at, c.updated_at
             FROM whatsapp_location_mapping m
             JOIN whatsapp_business_config c ON c.id = m.whatsapp_config_id
             WHERE m.business_id = ? AND m.location_id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $locationId]);
        $mapped = $stmt->fetch(\PDO::FETCH_ASSOC);
        if ($mapped !== false) {
            return $mapped;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, waba_id, phone_number_id, display_phone_number,
                    access_token_encrypted, status, is_default, last_health_check_at,
                    last_error_code, last_error_message, created_at, updated_at
             FROM whatsapp_business_config
             WHERE business_id = ? AND is_default = 1
             LIMIT 1'
        );
        $stmt->execute([$businessId]);
        $default = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $default ?: null;
    }

    public function createTemplateIfMissing(
        int $businessId,
        string $templateName,
        string $category = 'utility',
        string $status = 'approved'
    ): void {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_templates (business_id, template_name, category, status, created_at, updated_at)
             VALUES (?, ?, ?, ?, NOW(), NOW())
             ON DUPLICATE KEY UPDATE
               category = VALUES(category),
               status = VALUES(status),
               updated_at = NOW()'
        );
        $stmt->execute([$businessId, $templateName, $category, $status]);
    }

    private function clearDefaultConfig(int $businessId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_business_config
             SET is_default = 0, updated_at = NOW()
             WHERE business_id = ?'
        );
        $stmt->execute([$businessId]);
    }

    public function findMappingByLocation(int $businessId, int $locationId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, location_id, whatsapp_config_id, created_at, updated_at
             FROM whatsapp_location_mapping
             WHERE business_id = ? AND location_id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $locationId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }
}
