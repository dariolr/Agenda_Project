<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for resources (rooms, stations, equipment).
 */
final class ResourceRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Get all resources for a location.
     */
    public function findByLocationId(int $locationId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, location_id, name, type, quantity, note, is_active, sort_order,
                   created_at, updated_at
            FROM resources
            WHERE location_id = :location_id AND is_active = 1
            ORDER BY sort_order ASC, name ASC
        ');
        $stmt->execute(['location_id' => $locationId]);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Get all resources for a business (all locations).
     */
    public function findByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT r.id, r.location_id, r.name, r.type, r.quantity, r.note, 
                   r.is_active, r.sort_order, r.created_at, r.updated_at
            FROM resources r
            JOIN locations l ON r.location_id = l.id
            WHERE l.business_id = :business_id AND r.is_active = 1
            ORDER BY r.location_id, r.sort_order ASC, r.name ASC
        ');
        $stmt->execute(['business_id' => $businessId]);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Find a single resource by ID.
     */
    public function findById(int $id): ?array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT r.id, r.location_id, r.name, r.type, r.quantity, r.note,
                   r.is_active, r.sort_order, r.created_at, r.updated_at,
                   l.business_id
            FROM resources r
            JOIN locations l ON r.location_id = l.id
            WHERE r.id = :id
        ');
        $stmt->execute(['id' => $id]);
        $result = $stmt->fetch(\PDO::FETCH_ASSOC);
        return $result ?: null;
    }

    /**
     * Create a new resource.
     */
    public function create(array $data): int
    {
        $stmt = $this->db->getPdo()->prepare('
            INSERT INTO resources (location_id, name, type, quantity, note, is_active, sort_order)
            VALUES (:location_id, :name, :type, :quantity, :note, :is_active, :sort_order)
        ');
        $stmt->execute([
            'location_id' => $data['location_id'],
            'name' => $data['name'],
            'type' => $data['type'] ?? null,
            'quantity' => $data['quantity'] ?? 1,
            'note' => $data['note'] ?? null,
            'is_active' => $data['is_active'] ?? 1,
            'sort_order' => $data['sort_order'] ?? 0,
        ]);
        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Update an existing resource.
     */
    public function update(int $id, array $data): bool
    {
        $fields = [];
        $params = ['id' => $id];

        foreach (['name', 'type', 'quantity', 'note', 'is_active', 'sort_order'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = :$field";
                $params[$field] = $data[$field];
            }
        }

        if (empty($fields)) {
            return false;
        }

        $sql = 'UPDATE resources SET ' . implode(', ', $fields) . ' WHERE id = :id';
        $stmt = $this->db->getPdo()->prepare($sql);
        return $stmt->execute($params);
    }

    /**
     * Soft delete a resource (set is_active = 0).
     */
    public function delete(int $id): bool
    {
        $stmt = $this->db->getPdo()->prepare('
            UPDATE resources SET is_active = 0 WHERE id = :id
        ');
        return $stmt->execute(['id' => $id]);
    }

    /**
     * Get business_id for a resource.
     */
    public function getBusinessIdForResource(int $resourceId): ?int
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT l.business_id
            FROM resources r
            JOIN locations l ON r.location_id = l.id
            WHERE r.id = :id
        ');
        $stmt->execute(['id' => $resourceId]);
        $result = $stmt->fetchColumn();
        return $result !== false ? (int) $result : null;
    }

    /**
     * Get location_id for a resource.
     */
    public function getLocationIdForResource(int $resourceId): ?int
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT location_id FROM resources WHERE id = :id
        ');
        $stmt->execute(['id' => $resourceId]);
        $result = $stmt->fetchColumn();
        return $result !== false ? (int) $result : null;
    }
}
