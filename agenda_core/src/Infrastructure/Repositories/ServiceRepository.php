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

    /**
     * Find service by ID only (for authorization checks).
     * Returns base service info without location-specific variant.
     */
    public function findServiceById(int $serviceId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT s.id, s.business_id, s.category_id, s.name, s.description, 
                    s.is_active, s.sort_order
             FROM services s
             WHERE s.id = ? AND s.is_active = 1'
        );
        $stmt->execute([$serviceId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

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

    // ===== CRUD Methods =====

    /**
     * Create a new service with variant for a location.
     */
    public function create(
        int $businessId,
        int $locationId,
        string $name,
        ?int $categoryId = null,
        ?string $description = null,
        int $durationMinutes = 30,
        float $price = 0.0,
        ?string $colorHex = null,
        bool $isBookableOnline = true,
        bool $isPriceStartingFrom = false
    ): array {
        $pdo = $this->db->getPdo();
        
        $pdo->beginTransaction();
        try {
            // Get next sort_order
            $stmt = $pdo->prepare('SELECT COALESCE(MAX(sort_order), -1) + 1 FROM services WHERE business_id = ?');
            $stmt->execute([$businessId]);
            $sortOrder = (int) $stmt->fetchColumn();

            // Insert service
            $stmt = $pdo->prepare(
                'INSERT INTO services (business_id, category_id, name, description, sort_order, is_active, created_at)
                 VALUES (?, ?, ?, ?, ?, 1, NOW())'
            );
            $stmt->execute([$businessId, $categoryId, $name, $description, $sortOrder]);
            $serviceId = (int) $pdo->lastInsertId();

            // Insert service_variant for the location
            $stmt = $pdo->prepare(
                'INSERT INTO service_variants (service_id, location_id, duration_minutes, price, color_hex, is_bookable_online, is_price_starting_from, is_active, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, 1, NOW())'
            );
            $stmt->execute([
                $serviceId,
                $locationId,
                $durationMinutes,
                $price,
                $colorHex ?? '#CCCCCC',
                $isBookableOnline ? 1 : 0,
                $isPriceStartingFrom ? 1 : 0,
            ]);
            $variantId = (int) $pdo->lastInsertId();

            $pdo->commit();

            return $this->findById($serviceId, $locationId) + ['service_variant_id' => $variantId];
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Update a service and its variant.
     */
    public function update(
        int $serviceId,
        int $locationId,
        ?string $name = null,
        ?int $categoryId = null,
        ?string $description = null,
        ?int $durationMinutes = null,
        ?float $price = null,
        ?string $colorHex = null,
        ?bool $isBookableOnline = null,
        ?bool $isPriceStartingFrom = null,
        ?int $sortOrder = null
    ): ?array {
        $pdo = $this->db->getPdo();

        $pdo->beginTransaction();
        try {
            // Update service fields if provided
            $serviceUpdates = [];
            $serviceParams = [];
            if ($name !== null) {
                $serviceUpdates[] = 'name = ?';
                $serviceParams[] = $name;
            }
            if ($categoryId !== null) {
                $serviceUpdates[] = 'category_id = ?';
                $serviceParams[] = $categoryId;
            }
            if ($description !== null) {
                $serviceUpdates[] = 'description = ?';
                $serviceParams[] = $description;
            }
            if ($sortOrder !== null) {
                $serviceUpdates[] = 'sort_order = ?';
                $serviceParams[] = $sortOrder;
            }

            if (!empty($serviceUpdates)) {
                $serviceParams[] = $serviceId;
                $stmt = $pdo->prepare(
                    'UPDATE services SET ' . implode(', ', $serviceUpdates) . ', updated_at = NOW() WHERE id = ?'
                );
                $stmt->execute($serviceParams);
            }

            // Update variant fields if provided
            $variantUpdates = [];
            $variantParams = [];
            if ($durationMinutes !== null) {
                $variantUpdates[] = 'duration_minutes = ?';
                $variantParams[] = $durationMinutes;
            }
            if ($price !== null) {
                $variantUpdates[] = 'price = ?';
                $variantParams[] = $price;
            }
            if ($colorHex !== null) {
                $variantUpdates[] = 'color_hex = ?';
                $variantParams[] = $colorHex;
            }
            if ($isBookableOnline !== null) {
                $variantUpdates[] = 'is_bookable_online = ?';
                $variantParams[] = $isBookableOnline ? 1 : 0;
            }
            if ($isPriceStartingFrom !== null) {
                $variantUpdates[] = 'is_price_starting_from = ?';
                $variantParams[] = $isPriceStartingFrom ? 1 : 0;
            }

            if (!empty($variantUpdates)) {
                $variantParams[] = $serviceId;
                $variantParams[] = $locationId;
                $stmt = $pdo->prepare(
                    'UPDATE service_variants SET ' . implode(', ', $variantUpdates) . ', updated_at = NOW() WHERE service_id = ? AND location_id = ?'
                );
                $stmt->execute($variantParams);
            }

            $pdo->commit();

            return $this->findById($serviceId, $locationId);
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Soft delete a service (sets is_active = 0).
     */
    public function delete(int $serviceId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE services SET is_active = 0, updated_at = NOW() WHERE id = ?'
        );
        return $stmt->execute([$serviceId]);
    }

    // ===== Category CRUD =====

    /**
     * Create a new service category.
     */
    public function createCategory(
        int $businessId,
        string $name,
        ?string $description = null
    ): array {
        $pdo = $this->db->getPdo();

        // Get next sort_order
        $stmt = $pdo->prepare('SELECT COALESCE(MAX(sort_order), -1) + 1 FROM service_categories WHERE business_id = ?');
        $stmt->execute([$businessId]);
        $sortOrder = (int) $stmt->fetchColumn();

        $stmt = $pdo->prepare(
            'INSERT INTO service_categories (business_id, name, description, sort_order, created_at)
             VALUES (?, ?, ?, ?, NOW())'
        );
        $stmt->execute([$businessId, $name, $description, $sortOrder]);
        $categoryId = (int) $pdo->lastInsertId();

        return [
            'id' => $categoryId,
            'business_id' => $businessId,
            'name' => $name,
            'description' => $description,
            'sort_order' => $sortOrder,
        ];
    }

    /**
     * Update a service category.
     */
    public function updateCategory(
        int $categoryId,
        ?string $name = null,
        ?string $description = null,
        ?int $sortOrder = null
    ): ?array {
        $pdo = $this->db->getPdo();

        $updates = [];
        $params = [];
        if ($name !== null) {
            $updates[] = 'name = ?';
            $params[] = $name;
        }
        if ($description !== null) {
            $updates[] = 'description = ?';
            $params[] = $description;
        }
        if ($sortOrder !== null) {
            $updates[] = 'sort_order = ?';
            $params[] = $sortOrder;
        }

        if (empty($updates)) {
            // Nothing to update, just return current
            $stmt = $pdo->prepare('SELECT * FROM service_categories WHERE id = ?');
            $stmt->execute([$categoryId]);
            return $stmt->fetch() ?: null;
        }

        $params[] = $categoryId;
        $stmt = $pdo->prepare(
            'UPDATE service_categories SET ' . implode(', ', $updates) . ', updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute($params);

        $stmt = $pdo->prepare('SELECT * FROM service_categories WHERE id = ?');
        $stmt->execute([$categoryId]);
        return $stmt->fetch() ?: null;
    }

    /**
     * Delete a service category.
     * Services in this category will have category_id set to NULL.
     */
    public function deleteCategory(int $categoryId): bool
    {
        $pdo = $this->db->getPdo();

        $pdo->beginTransaction();
        try {
            // Set category_id to NULL for all services in this category
            $stmt = $pdo->prepare('UPDATE services SET category_id = NULL, updated_at = NOW() WHERE category_id = ?');
            $stmt->execute([$categoryId]);

            // Delete the category
            $stmt = $pdo->prepare('DELETE FROM service_categories WHERE id = ?');
            $stmt->execute([$categoryId]);

            $pdo->commit();
            return true;
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Get a single category by ID.
     */
    public function getCategoryById(int $categoryId): ?array
    {
        $stmt = $this->db->getPdo()->prepare('SELECT * FROM service_categories WHERE id = ?');
        $stmt->execute([$categoryId]);
        return $stmt->fetch() ?: null;
    }
}
