<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Ramsey\Uuid\Uuid;

final class WhatsAppRepository
{
    public function __construct(private readonly Connection $db)
    {
    }

    public function getConfig(int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare('SELECT * FROM business_whatsapp_config WHERE business_id = ? LIMIT 1');
        $stmt->execute([$businessId]);

        return $stmt->fetch() ?: null;
    }

    public function upsertConfig(int $businessId, string $wabaId, string $phoneNumberId, string $encryptedToken, ?string $tokenExpiresAt = null, string $status = 'active'): void
    {
        $existing = $this->getConfig($businessId);

        if ($existing === null) {
            $stmt = $this->db->getPdo()->prepare(
                'INSERT INTO business_whatsapp_config
                (id, business_id, waba_id, phone_number_id, access_token_encrypted, token_expires_at, connected_at, status)
                VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)'
            );
            $stmt->execute([Uuid::uuid4()->toString(), $businessId, $wabaId, $phoneNumberId, $encryptedToken, $tokenExpiresAt, $status]);
            return;
        }

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_whatsapp_config
             SET waba_id = ?, phone_number_id = ?, access_token_encrypted = ?, token_expires_at = ?, status = ?, updated_at = NOW()
             WHERE business_id = ?'
        );
        $stmt->execute([$wabaId, $phoneNumberId, $encryptedToken, $tokenExpiresAt, $status, $businessId]);
    }

    public function upsertTemplate(int $businessId, string $templateName, string $category, string $languageCode, string $status): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_templates (id, business_id, template_name, category, language_code, status)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE category = VALUES(category), status = VALUES(status)'
        );
        $stmt->execute([Uuid::uuid4()->toString(), $businessId, $templateName, $category, $languageCode, $status]);
    }

    public function listTemplates(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, template_name, category, language_code, status, created_at
             FROM whatsapp_templates WHERE business_id = ? ORDER BY created_at DESC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll() ?: [];
    }

    public function hasApprovedTemplate(int $businessId, string $templateName): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM whatsapp_templates WHERE business_id = ? AND template_name = ? AND status = "approved" LIMIT 1'
        );
        $stmt->execute([$businessId, $templateName]);

        return $stmt->fetchColumn() !== false;
    }

    public function saveConsent(int $businessId, int $customerId, bool $optIn, string $source, ?string $proofReference = null): void
    {
        $id = Uuid::uuid4()->toString();
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO customer_consents
            (id, customer_id, business_id, channel, opt_in, opt_in_at, source, proof_reference, revoked_at)
            VALUES (?, ?, ?, "whatsapp", ?, ?, ?, ?, ?)' 
        );

        $optInAt = $optIn ? date('Y-m-d H:i:s') : null;
        $revokedAt = $optIn ? null : date('Y-m-d H:i:s');

        $stmt->execute([$id, $customerId, $businessId, $optIn ? 1 : 0, $optInAt, $source, $proofReference, $revokedAt]);
    }

    public function hasValidConsent(int $businessId, int $customerId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT opt_in, revoked_at
             FROM customer_consents
             WHERE business_id = ? AND customer_id = ? AND channel = "whatsapp"
             ORDER BY created_at DESC LIMIT 1'
        );
        $stmt->execute([$businessId, $customerId]);
        $row = $stmt->fetch();

        if (!$row) {
            return false;
        }

        return (bool) $row['opt_in'] && $row['revoked_at'] === null;
    }

    public function queueOutbox(int $businessId, int $customerId, string $eventType, string $templateName, array $payload): string
    {
        $id = Uuid::uuid4()->toString();
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_notification_outbox
            (id, business_id, customer_id, channel, event_type, template_name, payload_json, status, retry_count)
            VALUES (?, ?, ?, "whatsapp", ?, ?, ?, "queued", 0)'
        );
        $stmt->execute([$id, $businessId, $customerId, $eventType, $templateName, json_encode($payload)]);

        return $id;
    }

    public function getDispatchableOutbox(int $limit = 50): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM whatsapp_notification_outbox
             WHERE status = "queued"
               AND (next_retry_at IS NULL OR next_retry_at <= NOW())
             ORDER BY created_at ASC
             LIMIT :limit'
        );
        $stmt->bindValue('limit', $limit, \PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll() ?: [];
    }

    public function markSent(string $id, string $providerMessageId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_notification_outbox SET status = "sent", provider_message_id = ?, error_code = NULL WHERE id = ?'
        );
        $stmt->execute([$providerMessageId, $id]);
    }

    public function markStatusByProviderMessageId(string $providerMessageId, string $status): void
    {
        $allowed = ['sent', 'delivered', 'read', 'failed'];
        if (!in_array($status, $allowed, true)) {
            return;
        }

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_notification_outbox SET status = ?, updated_at = NOW() WHERE provider_message_id = ?'
        );
        $stmt->execute([$status, $providerMessageId]);
    }

    public function markFailedWithRetry(string $id, string $errorCode): void
    {
        $stmt = $this->db->getPdo()->prepare('SELECT retry_count FROM whatsapp_notification_outbox WHERE id = ? LIMIT 1');
        $stmt->execute([$id]);
        $row = $stmt->fetch();
        if (!$row) {
            return;
        }

        $retryCount = ((int) $row['retry_count']) + 1;
        $isPermanent = in_array($errorCode, ['invalid_phone', 'template_rejected', 'policy_violation'], true);
        $isMaxRetries = $retryCount >= 5;

        if ($isPermanent || $isMaxRetries) {
            $update = $this->db->getPdo()->prepare(
                'UPDATE whatsapp_notification_outbox SET status = "failed", retry_count = ?, error_code = ?, next_retry_at = NULL WHERE id = ?'
            );
            $update->execute([$retryCount, $errorCode, $id]);
            return;
        }

        $delayMinutes = 2 ** min($retryCount, 5);
        $update = $this->db->getPdo()->prepare(
            'UPDATE whatsapp_notification_outbox
             SET status = "queued", retry_count = ?, error_code = ?, next_retry_at = DATE_ADD(NOW(), INTERVAL ? MINUTE)
             WHERE id = ?'
        );
        $update->execute([$retryCount, $errorCode, $delayMinutes, $id]);
    }

    public function logMessage(int $businessId, ?int $customerId, string $direction, string $messageType, ?string $contentSnapshot, ?string $providerMessageId, ?string $deliveryStatus = null): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO whatsapp_message_log
             (id, business_id, customer_id, direction, message_type, content_snapshot, provider_message_id, delivery_status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            Uuid::uuid4()->toString(),
            $businessId,
            $customerId,
            $direction,
            $messageType,
            $contentSnapshot,
            $providerMessageId,
            $deliveryStatus,
        ]);
    }

    public function countRecentBusinessSends(int $businessId, int $minutes): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM whatsapp_notification_outbox WHERE business_id = ? AND status IN ("sent", "delivered", "read") AND updated_at >= DATE_SUB(NOW(), INTERVAL ? MINUTE)'
        );
        $stmt->execute([$businessId, $minutes]);

        return (int) $stmt->fetchColumn();
    }

    public function countBusinessDailySends(int $businessId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM whatsapp_notification_outbox WHERE business_id = ? AND status IN ("sent", "delivered", "read") AND DATE(updated_at) = CURDATE()'
        );
        $stmt->execute([$businessId]);

        return (int) $stmt->fetchColumn();
    }
}
