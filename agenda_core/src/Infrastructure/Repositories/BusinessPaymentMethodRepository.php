<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use PDO;

final class BusinessPaymentMethodRepository
{
    private const DEFAULT_METHODS = [
        ['code' => 'cash', 'name' => 'Contanti', 'sort_order' => 10, 'icon_key' => 'cash'],
        ['code' => 'card', 'name' => 'Carte di Pagamento/Bancomat', 'sort_order' => 20, 'icon_key' => 'card'],
        ['code' => 'voucher', 'name' => 'Buono/Pacchetto', 'sort_order' => 30, 'icon_key' => 'voucher'],
        ['code' => 'other', 'name' => 'Altro', 'sort_order' => 40, 'icon_key' => 'other'],
    ];

    public function __construct(
        private readonly Connection $db,
    ) {}

    public function ensureDefaultsForBusiness(int $businessId, ?int $updatedByUserId = null): void
    {
        $pdo = $this->db->getPdo();

        $countStmt = $pdo->prepare('SELECT COUNT(*) FROM business_payment_methods WHERE business_id = ?');
        $countStmt->execute([$businessId]);
        $count = (int) $countStmt->fetchColumn();
        if ($count > 0) {
            return;
        }

        $insertStmt = $pdo->prepare(
            'INSERT INTO business_payment_methods
                (business_id, code, name, sort_order, icon_key, is_active, updated_by_user_id)
             VALUES (?, ?, ?, ?, ?, 1, ?)'
        );

        foreach (self::DEFAULT_METHODS as $method) {
            $insertStmt->execute([
                $businessId,
                $method['code'],
                $method['name'],
                $method['sort_order'],
                $method['icon_key'],
                $updatedByUserId,
            ]);
        }
    }

    /**
     * @return list<array<string,mixed>>
     */
    public function listByBusinessId(int $businessId, bool $includeInactive = false): array
    {
        $this->ensureDefaultsForBusiness($businessId);

        $sql = 'SELECT id, business_id, code, name, sort_order, icon_key, is_active
                FROM business_payment_methods
                WHERE business_id = ?';

        if (!$includeInactive) {
            $sql .= ' AND is_active = 1';
        }

        $sql .= ' ORDER BY sort_order ASC, id ASC';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute([$businessId]);

        return array_map(
            static fn(array $row): array => [
                'id' => (int) $row['id'],
                'business_id' => (int) $row['business_id'],
                'code' => (string) $row['code'],
                'name' => (string) $row['name'],
                'sort_order' => (int) $row['sort_order'],
                'icon_key' => $row['icon_key'] !== null ? (string) $row['icon_key'] : null,
                'is_active' => (bool) ((int) ($row['is_active'] ?? 0)),
            ],
            $stmt->fetchAll(PDO::FETCH_ASSOC)
        );
    }

    /**
     * @return list<array<string,mixed>>
     */
    public function listActiveByBusinessId(int $businessId): array
    {
        return $this->listByBusinessId($businessId, false);
    }

    public function findByIdInBusiness(int $businessId, int $methodId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, code, name, sort_order, icon_key, is_active
             FROM business_payment_methods
             WHERE business_id = ? AND id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $methodId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            return null;
        }

        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'code' => (string) $row['code'],
            'name' => (string) $row['name'],
            'sort_order' => (int) $row['sort_order'],
            'icon_key' => $row['icon_key'] !== null ? (string) $row['icon_key'] : null,
            'is_active' => (bool) ((int) ($row['is_active'] ?? 0)),
        ];
    }

    public function codeExistsInBusiness(int $businessId, string $code, ?int $excludeId = null): bool
    {
        $sql = 'SELECT 1 FROM business_payment_methods WHERE business_id = ? AND code = ?';
        $params = [$businessId, $code];

        if ($excludeId !== null) {
            $sql .= ' AND id <> ?';
            $params[] = $excludeId;
        }

        $sql .= ' LIMIT 1';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return (bool) $stmt->fetchColumn();
    }

    public function create(array $payload): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_payment_methods
                (business_id, code, name, sort_order, icon_key, is_active, updated_by_user_id)
             VALUES (?, ?, ?, ?, ?, 1, ?)'
        );

        $stmt->execute([
            $payload['business_id'],
            $payload['code'],
            $payload['name'],
            $payload['sort_order'],
            $payload['icon_key'] ?? null,
            $payload['updated_by_user_id'] ?? null,
        ]);

        $id = (int) $this->db->getPdo()->lastInsertId();

        return $this->findByIdInBusiness((int) $payload['business_id'], $id) ?? [
            'id' => $id,
            'business_id' => (int) $payload['business_id'],
            'code' => (string) $payload['code'],
            'name' => (string) $payload['name'],
            'sort_order' => (int) $payload['sort_order'],
            'icon_key' => $payload['icon_key'] ?? null,
            'is_active' => true,
        ];
    }

    public function updateInBusiness(int $businessId, int $methodId, array $payload): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_payment_methods
             SET name = ?, sort_order = ?, icon_key = ?, updated_by_user_id = ?, updated_at = CURRENT_TIMESTAMP
             WHERE business_id = ? AND id = ?'
        );

        $stmt->execute([
            $payload['name'],
            $payload['sort_order'],
            $payload['icon_key'] ?? null,
            $payload['updated_by_user_id'] ?? null,
            $businessId,
            $methodId,
        ]);

        return $this->findByIdInBusiness($businessId, $methodId);
    }

    public function deactivateInBusiness(int $businessId, int $methodId, ?int $updatedByUserId = null): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_payment_methods
             SET is_active = 0, updated_by_user_id = ?, updated_at = CURRENT_TIMESTAMP
             WHERE business_id = ? AND id = ? AND is_active = 1'
        );
        $stmt->execute([$updatedByUserId, $businessId, $methodId]);

        return $stmt->rowCount() > 0;
    }

    public function countActiveByBusinessId(int $businessId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM business_payment_methods WHERE business_id = ? AND is_active = 1'
        );
        $stmt->execute([$businessId]);

        return (int) $stmt->fetchColumn();
    }
}
