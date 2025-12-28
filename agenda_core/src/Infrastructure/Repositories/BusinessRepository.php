<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

final class BusinessRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findAll(): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, name, slug, email, phone, timezone, currency, 
                    is_active, created_at, updated_at
             FROM businesses
             WHERE is_active = 1
             ORDER BY name ASC'
        );
        $stmt->execute();

        return $stmt->fetchAll();
    }

    public function findById(int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, name, slug, email, phone, timezone, currency,
                    is_active, created_at, updated_at
             FROM businesses
             WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$businessId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function exists(int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM businesses WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchColumn() !== false;
    }

    public function create(string $name, string $slug, array $data = []): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO businesses (name, slug, email, phone, timezone, currency) 
             VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $name,
            $slug,
            $data['email'] ?? null,
            $data['phone'] ?? null,
            $data['timezone'] ?? 'Europe/Rome',
            $data['currency'] ?? 'EUR',
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function update(int $businessId, array $data): bool
    {
        $fields = [];
        $params = [];

        if (isset($data['name'])) {
            $fields[] = 'name = ?';
            $params[] = $data['name'];
        }
        if (isset($data['slug'])) {
            $fields[] = 'slug = ?';
            $params[] = $data['slug'];
        }
        if (isset($data['email'])) {
            $fields[] = 'email = ?';
            $params[] = $data['email'];
        }
        if (isset($data['phone'])) {
            $fields[] = 'phone = ?';
            $params[] = $data['phone'];
        }
        if (isset($data['timezone'])) {
            $fields[] = 'timezone = ?';
            $params[] = $data['timezone'];
        }
        if (isset($data['currency'])) {
            $fields[] = 'currency = ?';
            $params[] = $data['currency'];
        }

        if (empty($fields)) {
            return false;
        }

        $params[] = $businessId;
        $sql = 'UPDATE businesses SET ' . implode(', ', $fields) . ' WHERE id = ?';
        $stmt = $this->db->getPdo()->prepare($sql);

        return $stmt->execute($params);
    }

    public function delete(int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE businesses SET is_active = 0 WHERE id = ?'
        );

        return $stmt->execute([$businessId]);
    }

    /**
     * Find all businesses with search and pagination.
     * Used by superadmin listing.
     */
    public function findAllWithSearch(?string $search, int $limit, int $offset): array
    {
        $sql = 'SELECT id, name, slug, email, phone, timezone, currency, 
                       is_active, created_at, updated_at
                FROM businesses WHERE is_active = 1';
        $params = [];

        if ($search !== null && $search !== '') {
            $sql .= ' AND (name LIKE ? OR slug LIKE ? OR email LIKE ?)';
            $searchTerm = '%' . $search . '%';
            $params = [$searchTerm, $searchTerm, $searchTerm];
        }

        $sql .= ' ORDER BY name ASC LIMIT ? OFFSET ?';
        $params[] = $limit;
        $params[] = $offset;

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /**
     * Count all active businesses (with optional search).
     */
    public function countAll(?string $search = null): int
    {
        $sql = 'SELECT COUNT(*) FROM businesses WHERE is_active = 1';
        $params = [];

        if ($search !== null && $search !== '') {
            $sql .= ' AND (name LIKE ? OR slug LIKE ? OR email LIKE ?)';
            $searchTerm = '%' . $search . '%';
            $params = [$searchTerm, $searchTerm, $searchTerm];
        }

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return (int) $stmt->fetchColumn();
    }

    public function findBySlug(string $slug): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, name, slug, email, phone, timezone, currency,
                    is_active, created_at, updated_at
             FROM businesses
             WHERE slug = ?'
        );
        $stmt->execute([$slug]);
        $result = $stmt->fetch();

        return $result ?: null;
    }
}
