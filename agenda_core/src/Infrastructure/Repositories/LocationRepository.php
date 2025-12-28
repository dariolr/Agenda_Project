<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

final class LocationRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findById(int $locationId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT l.id, l.business_id, l.name, l.address, l.city, l.region, l.country,
                    l.phone, l.email, l.latitude, l.longitude, l.currency, l.timezone,
                    l.is_default, l.is_active, l.created_at, l.updated_at,
                    b.name AS business_name,
                    b.email AS business_email
             FROM locations l
             JOIN businesses b ON l.business_id = b.id
             WHERE l.id = ? AND l.is_active = 1'
        );
        $stmt->execute([$locationId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function findByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, address, city, region, country, 
                    phone, email, latitude, longitude, currency, timezone,
                    is_default, is_active, created_at, updated_at
             FROM locations
             WHERE business_id = ? AND is_active = 1
             ORDER BY name ASC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll();
    }

    public function getBusinessIdByLocationId(int $locationId): ?int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT business_id FROM locations WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$locationId]);
        $result = $stmt->fetchColumn();

        return $result !== false ? (int) $result : null;
    }

    public function exists(int $locationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM locations WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$locationId]);

        return $stmt->fetchColumn() !== false;
    }

    public function getTimezone(int $locationId): ?string
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT timezone FROM locations WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$locationId]);
        $result = $stmt->fetchColumn();

        return $result !== false ? $result : null;
    }

    public function create(int $businessId, string $name, array $data = []): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO locations (business_id, name, address, phone, email, timezone, settings) 
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $name,
            $data['address'] ?? null,
            $data['phone'] ?? null,
            $data['email'] ?? null,
            $data['timezone'] ?? 'Europe/Rome',
            isset($data['settings']) ? json_encode($data['settings']) : null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function update(int $locationId, array $data): bool
    {
        $fields = [];
        $values = [];

        foreach (['name', 'address', 'phone', 'email', 'timezone'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "{$field} = ?";
                $values[] = $data[$field];
            }
        }

        if (array_key_exists('settings', $data)) {
            $fields[] = 'settings = ?';
            $values[] = json_encode($data['settings']);
        }

        if (empty($fields)) {
            return false;
        }

        $values[] = $locationId;

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE locations SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE id = ?'
        );

        return $stmt->execute($values);
    }
}
