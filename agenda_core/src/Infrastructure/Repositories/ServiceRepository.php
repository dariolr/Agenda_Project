<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for services and service_variants.
 * 
 * SCHEMA NOTE:
 * - services: base service info (name, description, category)
 * - service_variants: location-specific duration, price, color
 */
final class ServiceRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findById(int $serviceId, int $locationId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT s.id, s.business_id, s.category_id, s.name, s.description, 
                    s.is_active, s.sort_order,
                    sv.duration_minutes, sv.price, sv.color_hex AS color,
                    sv.is_bookable_online, sv.is_price_starting_from AS is_price_from
             FROM services s
             LEFT JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = ?
             WHERE s.id = ? AND s.is_active = 1'
        );
        $stmt->execute([$locationId, $serviceId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function findByLocationId(int $locationId, int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT s.id, s.business_id, s.category_id, s.name, s.description, 
                    s.is_active, s.sort_order,
                    sv.id AS service_variant_id,
                    sv.duration_minutes, sv.price, sv.color_hex AS color,
                    sv.is_bookable_online, sv.is_price_starting_from AS is_price_from,
                    sc.name AS category_name
             FROM services s
             JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = ?
             LEFT JOIN service_categories sc ON s.category_id = sc.id
             WHERE s.business_id = ? AND s.is_active = 1 AND sv.is_active = 1
             ORDER BY s.sort_order ASC, s.name ASC'
        );
        $stmt->execute([$locationId, $businessId]);

        return $stmt->fetchAll();
    }

    public function findByIds(array $serviceIds, int $locationId, int $businessId): array
    {
        if (empty($serviceIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $params = array_merge([$locationId], $serviceIds, [$businessId]);

        $stmt = $this->db->getPdo()->prepare(
            "SELECT s.id, s.business_id, s.category_id, s.name, s.description,
                    sv.id AS service_variant_id, sv.duration_minutes, sv.price, sv.color_hex AS color,
                    sv.is_price_starting_from AS is_price_from
             FROM services s
             JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = ?
             WHERE s.id IN ({$placeholders}) AND s.business_id = ? AND s.is_active = 1"
        );
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    public function getCategories(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, description, sort_order
             FROM service_categories
             WHERE business_id = ?
             ORDER BY sort_order ASC, name ASC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll();
    }

    public function getTotalDuration(array $serviceIds, int $locationId, int $businessId): int
    {
        if (empty($serviceIds)) {
            return 0;
        }

        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $params = array_merge([$locationId], $serviceIds, [$businessId]);

        $stmt = $this->db->getPdo()->prepare(
            "SELECT SUM(sv.duration_minutes) as total
             FROM services s
             JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = ?
             WHERE s.id IN ({$placeholders}) AND s.business_id = ? AND s.is_active = 1"
        );
        $stmt->execute($params);

        return (int) ($stmt->fetchColumn() ?? 0);
    }

    public function getTotalPrice(array $serviceIds, int $locationId, int $businessId): float
    {
        if (empty($serviceIds)) {
            return 0.0;
        }

        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $params = array_merge([$locationId], $serviceIds, [$businessId]);

        $stmt = $this->db->getPdo()->prepare(
            "SELECT SUM(sv.price) as total
             FROM services s
             JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = ?
             WHERE s.id IN ({$placeholders}) AND s.business_id = ? AND s.is_active = 1"
        );
        $stmt->execute($params);

        return (float) ($stmt->fetchColumn() ?? 0);
    }

    public function allBelongToBusiness(array $serviceIds, int $locationId, int $businessId): bool
    {
        if (empty($serviceIds)) {
            return true;
        }

        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $params = array_merge([$locationId], $serviceIds, [$businessId]);

        $stmt = $this->db->getPdo()->prepare(
            "SELECT COUNT(*) FROM services s
             JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = ?
             WHERE s.id IN ({$placeholders}) AND s.business_id = ? AND s.is_active = 1"
        );
        $stmt->execute($params);

        return (int) $stmt->fetchColumn() === count($serviceIds);
    }
}
