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
                    access_token_encrypted, status, is_default, created_at, updated_at
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
                    access_token_encrypted, status, is_default, created_at, updated_at
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
        bool $isDefault
    ): int {
        if ($isDefault) {
            $this->clearDefaultConfig($businessId);
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_business_config
             (business_id, waba_id, phone_number_id, access_token_encrypted, status, is_default)
             VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $wabaId,
            $phoneNumberId,
            $accessTokenEncrypted,
            $status,
            $isDefault ? 1 : 0,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
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

    public function deleteConfig(int $businessId, int $configId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM whatsapp_business_config
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$businessId, $configId]);
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
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_outbox
             (business_id, booking_id, location_id, whatsapp_config_id,
              recipient_phone, template_name, template_language, template_payload,
              status, attempts, max_attempts, scheduled_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, "queued", 0, ?, ?)'
        );
        $stmt->execute([
            (int) $data['business_id'],
            $data['booking_id'] ?? null,
            $data['location_id'] ?? null,
            $data['whatsapp_config_id'] ?? null,
            (string) $data['recipient_phone'],
            (string) $data['template_name'],
            (string) ($data['template_language'] ?? 'it'),
            Json::encode($data['template_payload'] ?? []),
            (int) ($data['max_attempts'] ?? 3),
            $data['scheduled_at'] ?? null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function findOutboxById(int $businessId, int $outboxId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, booking_id, location_id, whatsapp_config_id,
                    recipient_phone, template_name, template_language, template_payload,
                    status, attempts, max_attempts, provider_message_id, error_message,
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
                 attempts = attempts + 1,
                 provider_message_id = COALESCE(?, provider_message_id),
                 error_message = NULL,
                 last_attempt_at = NOW(),
                 sent_at = NOW(),
                 updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$providerMessageId, $businessId, $outboxId]);
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
                    updated_at = NOW()';
        if ($timestampField !== null) {
            $sql .= ', ' . $timestampField . ' = NOW()';
        }
        $sql .= ' WHERE business_id = ? AND id = ?';

        $stmt = $this->db->getPdo()->prepare($sql);

        return $stmt->execute([$status, $errorMessage, $businessId, $outboxId]);
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
             WHERE business_id = ? AND category = "utility" AND status = "approved"
             LIMIT 1'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchColumn() !== false;
    }

    public function hasWebhookEventForBusiness(int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM whatsapp_webhook_events WHERE business_id = ? LIMIT 1'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchColumn() !== false;
    }

    public function findConfigForLocation(int $businessId, int $locationId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT c.id, c.business_id, c.waba_id, c.phone_number_id, c.display_phone_number,
                    c.access_token_encrypted, c.status, c.is_default, c.created_at, c.updated_at
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
                    access_token_encrypted, status, is_default, created_at, updated_at
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

    private function findMappingByLocation(int $businessId, int $locationId): ?array
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
