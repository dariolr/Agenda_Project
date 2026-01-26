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
                    l.allow_customer_choose_staff, l.is_default, l.is_active, l.created_at, l.updated_at,
                    l.slot_interval_minutes, l.slot_display_mode, l.min_gap_minutes,
                    l.min_booking_notice_hours, l.max_booking_advance_days,
                    b.name AS business_name,
                    b.email AS business_email,
                    b.slug AS business_slug
             FROM locations l
             JOIN businesses b ON l.business_id = b.id
             WHERE l.id = ? AND l.is_active = 1'
        );
        $stmt->execute([$locationId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    /**
     * Find locations by business ID
     * @param bool $includeInactive If true, include inactive locations (for admin/gestionale)
     */
    public function findByBusinessId(int $businessId, bool $includeInactive = false): array
    {
        $sql = 'SELECT id, business_id, name, address, city, region, country, 
                    phone, email, latitude, longitude, currency, timezone,
                    allow_customer_choose_staff,
                    slot_interval_minutes, slot_display_mode, min_gap_minutes,
                    is_default, sort_order, is_active, created_at, updated_at
             FROM locations
             WHERE business_id = ?';
        
        if (!$includeInactive) {
            $sql .= ' AND is_active = 1';
        }
        
        $sql .= ' ORDER BY sort_order ASC, name ASC';
        
        $stmt = $this->db->getPdo()->prepare($sql);
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

    public function getCancellationPolicy(int $locationId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT l.cancellation_hours as location_cancellation_hours,
                    b.cancellation_hours as business_cancellation_hours
             FROM locations l
             JOIN businesses b ON l.business_id = b.id
             WHERE l.id = ? AND l.is_active = 1'
        );
        $stmt->execute([$locationId]);
        $result = $stmt->fetch();

        if (!$result) {
            return [
                'location_cancellation_hours' => null,
                'business_cancellation_hours' => null,
            ];
        }

        return $result;
    }

    /**
     * Find the default location for a business.
     * Returns the location with is_default=1, or the first active location if none is marked default.
     */
    public function findDefaultByBusinessId(int $businessId): ?array
    {
        // First try to find the explicitly marked default location
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, address, city, region, country,
                    phone, email, latitude, longitude, currency, timezone,
                    allow_customer_choose_staff,
                    is_default, is_active, created_at, updated_at
             FROM locations
             WHERE business_id = ? AND is_default = 1 AND is_active = 1
             LIMIT 1'
        );
        $stmt->execute([$businessId]);
        $result = $stmt->fetch();

        if ($result) {
            return $result;
        }

        // Fallback: return the first active location
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, address, city, region, country,
                    phone, email, latitude, longitude, currency, timezone,
                    allow_customer_choose_staff,
                    is_default, is_active, created_at, updated_at
             FROM locations
             WHERE business_id = ? AND is_active = 1
             ORDER BY id ASC
             LIMIT 1'
        );
        $stmt->execute([$businessId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function create(int $businessId, string $name, array $data = []): int
    {
        $isActive = $data['is_active'] ?? 1;
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO locations (business_id, name, address, phone, email, timezone, min_booking_notice_hours, max_booking_advance_days, allow_customer_choose_staff, is_active) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $name,
            $data['address'] ?? null,
            $data['phone'] ?? null,
            $data['email'] ?? null,
            $data['timezone'] ?? 'Europe/Rome',
            $data['min_booking_notice_hours'] ?? 1,
            $data['max_booking_advance_days'] ?? 90,
            !empty($data['allow_customer_choose_staff']) ? 1 : 0,
            $isActive ? 1 : 0,
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

        // Integer fields
        foreach (['min_booking_notice_hours', 'max_booking_advance_days', 'slot_interval_minutes', 'min_gap_minutes'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "{$field} = ?";
                $values[] = (int) $data[$field];
            }
        }

        // ENUM field: slot_display_mode
        if (array_key_exists('slot_display_mode', $data)) {
            $mode = $data['slot_display_mode'];
            if (in_array($mode, ['all', 'min_gap'], true)) {
                $fields[] = 'slot_display_mode = ?';
                $values[] = $mode;
            }
        }

        if (array_key_exists('is_active', $data)) {
            $fields[] = 'is_active = ?';
            $values[] = $data['is_active'] ? 1 : 0;
        }

        if (array_key_exists('allow_customer_choose_staff', $data)) {
            $fields[] = 'allow_customer_choose_staff = ?';
            $values[] = $data['allow_customer_choose_staff'] ? 1 : 0;
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

    /**
     * Soft delete a location (set is_active = 0)
     */
    public function delete(int $locationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE locations SET is_active = 0, updated_at = NOW() WHERE id = ?'
        );
        return $stmt->execute([$locationId]);
    }

    /**
     * Check if location is the only active one for the business
     */
    public function isOnlyActiveLocation(int $locationId, int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM locations WHERE business_id = ? AND is_active = 1'
        );
        $stmt->execute([$businessId]);
        return (int) $stmt->fetchColumn() <= 1;
    }

    /**
     * Batch update sort_order for multiple locations.
     * Used for drag & drop reordering.
     * 
     * @param array $locationList Array of ['id' => int, 'sort_order' => int]
     */
    public function batchUpdateSortOrder(array $locationList): bool
    {
        if (empty($locationList)) {
            return true;
        }

        $pdo = $this->db->getPdo();
        $stmt = $pdo->prepare(
            'UPDATE locations SET sort_order = ?, updated_at = NOW() WHERE id = ?'
        );

        foreach ($locationList as $item) {
            $stmt->execute([(int) $item['sort_order'], (int) $item['id']]);
        }

        return true;
    }

    /**
     * Check if all location IDs belong to the same business.
     */
    public function allBelongToSameBusiness(array $locationIds): ?int
    {
        if (empty($locationIds)) {
            return null;
        }

        $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT DISTINCT business_id FROM locations WHERE id IN ({$placeholders}) AND is_active = 1"
        );
        $stmt->execute(array_map('intval', $locationIds));
        $businesses = $stmt->fetchAll(\PDO::FETCH_COLUMN);

        if (count($businesses) !== 1) {
            return null;
        }

        return (int) $businesses[0];
    }
}
