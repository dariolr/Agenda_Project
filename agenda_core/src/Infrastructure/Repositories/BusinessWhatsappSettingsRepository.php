<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

final class BusinessWhatsappSettingsRepository
{
    private const SELECT_FIELDS = 'id, business_id, provider_code, whatsapp_enabled, messages_enabled,
        allow_location_mapping, default_channel_mode, existing_clients_opt_in_policy, existing_clients_opt_in_assumed_at,
        status, last_go_live_check_at, last_error_code, last_error_message, enabled_by_user_id,
        enabled_at, disabled_at, notes, created_at, updated_at';

    /** @var string[] */
    private const ALLOWED_CHANNEL_MODES = ['disabled', 'business_default', 'location_mapping'];

    /** @var string[] */
    private const ALLOWED_EXISTING_CLIENTS_OPT_IN_POLICIES = ['explicit_only', 'assume_existing_consented'];

    /** @var string[] */
    private const ALLOWED_STATUSES = [
        'not_enabled',
        'enabled',
        'onboarding',
        'pending_review',
        'active',
        'suspended',
        'error',
    ];

    public function __construct(private readonly Connection $db) {}

    public function defaultForBusiness(int $businessId): array
    {
        return [
            'id' => null,
            'business_id' => $businessId,
            'provider_code' => 'meta',
            'whatsapp_enabled' => 0,
            'messages_enabled' => 0,
            'allow_location_mapping' => 0,
            'default_channel_mode' => 'business_default',
            'existing_clients_opt_in_policy' => 'explicit_only',
            'existing_clients_opt_in_assumed_at' => null,
            'status' => 'not_enabled',
            'last_go_live_check_at' => null,
            'last_error_code' => null,
            'last_error_message' => null,
            'enabled_by_user_id' => null,
            'enabled_at' => null,
            'disabled_at' => null,
            'notes' => null,
            'created_at' => null,
            'updated_at' => null,
        ];
    }

    public function findByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT ' . self::SELECT_FIELDS . '
             FROM business_whatsapp_settings
             WHERE business_id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: $this->defaultForBusiness($businessId);
    }

    public function listForAdmin(array $filters = [], int $limit = 100, int $offset = 0): array
    {
        $where = [];
        $params = [];

        if (isset($filters['business_id']) && (int) $filters['business_id'] > 0) {
            $where[] = 'b.id = ?';
            $params[] = (int) $filters['business_id'];
        }
        if (($filters['status'] ?? '') !== '') {
            $where[] = 'COALESCE(s.status, "not_enabled") = ?';
            $params[] = (string) $filters['status'];
        }
        if (($filters['enabled'] ?? '') !== '') {
            $where[] = 'COALESCE(s.whatsapp_enabled, 0) = ?';
            $params[] = in_array(strtolower((string) $filters['enabled']), ['1', 'true', 'yes'], true) ? 1 : 0;
        }
        if (($filters['search'] ?? '') !== '') {
            $where[] = '(b.name LIKE ? OR b.slug LIKE ?)';
            $search = '%' . (string) $filters['search'] . '%';
            $params[] = $search;
            $params[] = $search;
        }

        $safeLimit = max(1, min(200, $limit));
        $safeOffset = max(0, $offset);
        $whereSql = $where === [] ? '' : 'WHERE ' . implode(' AND ', $where);

        $sql = 'SELECT b.id AS business_id, b.name AS business_name, b.slug AS business_slug,
                       s.id, s.provider_code, s.whatsapp_enabled, s.messages_enabled,
                       s.allow_location_mapping, s.default_channel_mode,
                       s.existing_clients_opt_in_policy, s.existing_clients_opt_in_assumed_at,
                       s.status, s.last_go_live_check_at, s.last_error_code, s.last_error_message,
                       s.enabled_by_user_id, s.enabled_at, s.disabled_at, s.notes, s.created_at, s.updated_at,
                       c.id AS default_config_id, c.status AS default_config_status,
                       c.display_phone_number, c.phone_number_id,
                       COALESCE(oc.outbox_30d_count, 0) AS outbox_30d_count,
                       COALESCE(oc.outbox_30d_failed_count, 0) AS outbox_30d_failed_count
                FROM businesses b
                LEFT JOIN business_whatsapp_settings s ON s.business_id = b.id
                LEFT JOIN whatsapp_business_config c ON c.business_id = b.id AND c.is_default = 1
                LEFT JOIN (
                    SELECT business_id,
                           COUNT(*) AS outbox_30d_count,
                           SUM(CASE WHEN status = "failed" THEN 1 ELSE 0 END) AS outbox_30d_failed_count
                    FROM whatsapp_outbox
                    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                    GROUP BY business_id
                ) oc ON oc.business_id = b.id
                ' . $whereSql . '
                ORDER BY b.name ASC
                LIMIT ' . $safeLimit . ' OFFSET ' . $safeOffset;

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function upsertByAdmin(int $businessId, int $userId, array $data): array
    {
        $current = $this->findByBusinessId($businessId);
        $wasEnabled = ((int) ($current['whatsapp_enabled'] ?? 0)) === 1;

        $whatsappEnabled = array_key_exists('whatsapp_enabled', $data)
            ? (bool) $data['whatsapp_enabled']
            : $wasEnabled;
        $messagesEnabled = array_key_exists('messages_enabled', $data)
            ? (bool) $data['messages_enabled']
            : ((int) ($current['messages_enabled'] ?? 0) === 1);

        $status = (string) ($data['status'] ?? ($current['status'] ?? 'not_enabled'));
        if (!in_array($status, self::ALLOWED_STATUSES, true)) {
            $status = $whatsappEnabled ? 'enabled' : 'not_enabled';
        }

        if (!$whatsappEnabled) {
            $messagesEnabled = false;
            $status = 'not_enabled';
        } elseif ($status === 'not_enabled') {
            $status = 'enabled';
        }

        $channelMode = (string) ($data['default_channel_mode'] ?? ($current['default_channel_mode'] ?? 'business_default'));
        if (!in_array($channelMode, self::ALLOWED_CHANNEL_MODES, true)) {
            $channelMode = 'business_default';
        }

        $currentExistingClientsOptInPolicy = (string) ($current['existing_clients_opt_in_policy'] ?? 'explicit_only');
        $existingClientsOptInPolicy = (string) ($data['existing_clients_opt_in_policy'] ?? $currentExistingClientsOptInPolicy);
        if (!in_array($existingClientsOptInPolicy, self::ALLOWED_EXISTING_CLIENTS_OPT_IN_POLICIES, true)) {
            $existingClientsOptInPolicy = 'explicit_only';
        }
        $existingClientsOptInAssumedAt = $current['existing_clients_opt_in_assumed_at'] ?? null;
        if ($existingClientsOptInPolicy === 'explicit_only') {
            $existingClientsOptInAssumedAt = null;
        } elseif (
            $existingClientsOptInPolicy !== $currentExistingClientsOptInPolicy
            || $existingClientsOptInAssumedAt === null
        ) {
            $existingClientsOptInAssumedAt = date('Y-m-d H:i:s');
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_whatsapp_settings
             (business_id, provider_code, whatsapp_enabled, messages_enabled,
              allow_location_mapping, default_channel_mode,
              existing_clients_opt_in_policy, existing_clients_opt_in_assumed_at, status,
              enabled_by_user_id, enabled_at, disabled_at, notes)
             VALUES (?, "meta", ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               whatsapp_enabled = VALUES(whatsapp_enabled),
               messages_enabled = VALUES(messages_enabled),
               allow_location_mapping = VALUES(allow_location_mapping),
               default_channel_mode = VALUES(default_channel_mode),
               existing_clients_opt_in_policy = VALUES(existing_clients_opt_in_policy),
               existing_clients_opt_in_assumed_at = VALUES(existing_clients_opt_in_assumed_at),
               status = VALUES(status),
               enabled_by_user_id = IF(VALUES(whatsapp_enabled) = 1 AND whatsapp_enabled = 0, VALUES(enabled_by_user_id), enabled_by_user_id),
               enabled_at = IF(VALUES(whatsapp_enabled) = 1 AND whatsapp_enabled = 0, NOW(), enabled_at),
               disabled_at = IF(VALUES(whatsapp_enabled) = 0, NOW(), disabled_at),
               notes = VALUES(notes),
               updated_at = NOW()'
        );
        $stmt->execute([
            $businessId,
            $whatsappEnabled ? 1 : 0,
            $messagesEnabled ? 1 : 0,
            array_key_exists('allow_location_mapping', $data)
                ? ((bool) $data['allow_location_mapping'] ? 1 : 0)
                : (int) ($current['allow_location_mapping'] ?? 0),
            $channelMode,
            $existingClientsOptInPolicy,
            $existingClientsOptInAssumedAt,
            $status,
            $whatsappEnabled && !$wasEnabled ? $userId : ($current['enabled_by_user_id'] ?? null),
            $whatsappEnabled && !$wasEnabled ? date('Y-m-d H:i:s') : ($current['enabled_at'] ?? null),
            $whatsappEnabled ? ($current['disabled_at'] ?? null) : date('Y-m-d H:i:s'),
            isset($data['notes']) ? mb_substr(trim((string) $data['notes']), 0, 500) : ($current['notes'] ?? null),
        ]);

        return $this->findByBusinessId($businessId);
    }

    public function updateStatus(int $businessId, string $status, ?string $errorCode = null, ?string $errorMessage = null): void
    {
        if (!in_array($status, self::ALLOWED_STATUSES, true)) {
            return;
        }

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_whatsapp_settings
             SET status = ?, last_error_code = ?, last_error_message = ?, updated_at = NOW()
             WHERE business_id = ?'
        );
        $stmt->execute([
            $status,
            $errorCode,
            $errorMessage !== null ? mb_substr($errorMessage, 0, 500) : null,
            $businessId,
        ]);
    }

    public function markGoLiveChecked(int $businessId, ?string $errorCode, ?string $errorMessage): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_whatsapp_settings
             SET last_go_live_check_at = NOW(), last_error_code = ?, last_error_message = ?, updated_at = NOW()
             WHERE business_id = ?'
        );
        $stmt->execute([
            $errorCode,
            $errorMessage !== null ? mb_substr($errorMessage, 0, 500) : null,
            $businessId,
        ]);
    }
}
