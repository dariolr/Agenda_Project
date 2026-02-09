<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for service_variant_resource_requirements.
 * Manages the M:N relationship between service variants and resources.
 */
final class ServiceVariantResourceRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Get all resource requirements for a service variant.
     */
    public function findByVariantId(int $serviceVariantId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT svrr.id, svrr.service_variant_id, svrr.resource_id, svrr.quantity,
                   r.name AS resource_name, r.quantity AS resource_total_quantity
            FROM service_variant_resource_requirements svrr
            JOIN resources r ON svrr.resource_id = r.id
            WHERE svrr.service_variant_id = :variant_id AND r.is_active = 1
            ORDER BY r.name ASC
        ');
        $stmt->execute(['variant_id' => $serviceVariantId]);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Get all resource requirements for multiple service variants at once.
     * Returns array keyed by service_variant_id.
     */
    public function findByVariantIds(array $variantIds): array
    {
        if (empty($variantIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($variantIds), '?'));
        $stmt = $this->db->getPdo()->prepare("
            SELECT svrr.id, svrr.service_variant_id, svrr.resource_id, svrr.quantity,
                   r.name AS resource_name, r.quantity AS resource_total_quantity
            FROM service_variant_resource_requirements svrr
            JOIN resources r ON svrr.resource_id = r.id
            WHERE svrr.service_variant_id IN ({$placeholders}) AND r.is_active = 1
            ORDER BY svrr.service_variant_id, r.name ASC
        ");
        $stmt->execute($variantIds);
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        // Group by service_variant_id
        $result = [];
        foreach ($rows as $row) {
            $variantId = (int) $row['service_variant_id'];
            if (!isset($result[$variantId])) {
                $result[$variantId] = [];
            }
            $result[$variantId][] = $row;
        }

        return $result;
    }

    /**
     * Get all resource requirements for a location (all service variants in that location).
     */
    public function findByLocationId(int $locationId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT svrr.id, svrr.service_variant_id, svrr.resource_id, svrr.quantity,
                   r.name AS resource_name, r.quantity AS resource_total_quantity
            FROM service_variant_resource_requirements svrr
            JOIN resources r ON svrr.resource_id = r.id
            JOIN service_variants sv ON svrr.service_variant_id = sv.id
            WHERE sv.location_id = :location_id AND r.is_active = 1 AND sv.is_active = 1
            ORDER BY sv.id, r.name ASC
        ');
        $stmt->execute(['location_id' => $locationId]);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Set resource requirements for a service variant (replace all).
     * 
     * @param int $serviceVariantId The service variant ID
     * @param array $requirements Array of ['resource_id' => int, 'quantity' => int]
     */
    public function setRequirements(int $serviceVariantId, array $requirements): void
    {
        $pdo = $this->db->getPdo();
        
        $pdo->beginTransaction();
        try {
            // Delete existing requirements
            $stmt = $pdo->prepare('DELETE FROM service_variant_resource_requirements WHERE service_variant_id = ?');
            $stmt->execute([$serviceVariantId]);

            // Insert new requirements
            if (!empty($requirements)) {
                $stmt = $pdo->prepare('
                    INSERT INTO service_variant_resource_requirements (service_variant_id, resource_id, quantity)
                    VALUES (?, ?, ?)
                ');
                foreach ($requirements as $req) {
                    $stmt->execute([
                        $serviceVariantId,
                        (int) $req['resource_id'],
                        (int) ($req['quantity'] ?? 1),
                    ]);
                }
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Add a single resource requirement.
     */
    public function addRequirement(int $serviceVariantId, int $resourceId, int $quantity = 1): int
    {
        $stmt = $this->db->getPdo()->prepare('
            INSERT INTO service_variant_resource_requirements (service_variant_id, resource_id, quantity)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)
        ');
        $stmt->execute([$serviceVariantId, $resourceId, $quantity]);
        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Remove a single resource requirement.
     */
    public function removeRequirement(int $serviceVariantId, int $resourceId): bool
    {
        $stmt = $this->db->getPdo()->prepare('
            DELETE FROM service_variant_resource_requirements 
            WHERE service_variant_id = ? AND resource_id = ?
        ');
        return $stmt->execute([$serviceVariantId, $resourceId]);
    }

    /**
     * Update quantity for a resource requirement.
     */
    public function updateQuantity(int $serviceVariantId, int $resourceId, int $quantity): bool
    {
        $stmt = $this->db->getPdo()->prepare('
            UPDATE service_variant_resource_requirements 
            SET quantity = ?
            WHERE service_variant_id = ? AND resource_id = ?
        ');
        return $stmt->execute([$quantity, $serviceVariantId, $resourceId]);
    }

    /**
     * Get business_id for a service variant (for authorization).
     */
    public function getBusinessIdForVariant(int $serviceVariantId): ?int
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT l.business_id
            FROM service_variants sv
            JOIN locations l ON sv.location_id = l.id
            WHERE sv.id = ?
        ');
        $stmt->execute([$serviceVariantId]);
        $result = $stmt->fetchColumn();
        return $result !== false ? (int) $result : null;
    }

    /**
     * Get variant details including location_id and business_id.
     */
    public function getVariantDetails(int $serviceVariantId): ?array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT sv.id, sv.service_id, sv.location_id, l.business_id
            FROM service_variants sv
            JOIN locations l ON sv.location_id = l.id
            WHERE sv.id = ?
        ');
        $stmt->execute([$serviceVariantId]);
        $result = $stmt->fetch(\PDO::FETCH_ASSOC);
        return $result ?: null;
    }

    /**
     * Validate that all resource_ids belong to the same location as the service variant.
     */
    public function validateResourcesForVariant(int $serviceVariantId, array $resourceIds): bool
    {
        if (empty($resourceIds)) {
            return true;
        }

        // Get location_id for the variant
        $stmt = $this->db->getPdo()->prepare('SELECT location_id FROM service_variants WHERE id = ?');
        $stmt->execute([$serviceVariantId]);
        $locationId = $stmt->fetchColumn();

        if (!$locationId) {
            return false;
        }

        // Check all resources belong to this location
        $placeholders = implode(',', array_fill(0, count($resourceIds), '?'));
        $params = array_merge($resourceIds, [(int) $locationId]);
        
        $stmt = $this->db->getPdo()->prepare("
            SELECT COUNT(*) FROM resources 
            WHERE id IN ({$placeholders}) AND location_id = ? AND is_active = 1
        ");
        $stmt->execute($params);

        return (int) $stmt->fetchColumn() === count($resourceIds);
    }

    /**
     * Get all service variants that require a specific resource.
     */
    public function findVariantsByResourceId(int $resourceId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT svrr.id, svrr.service_variant_id, svrr.resource_id, svrr.quantity,
                   sv.service_id, s.name AS service_name, s.category_id,
                   sc.name AS category_name
            FROM service_variant_resource_requirements svrr
            JOIN service_variants sv ON svrr.service_variant_id = sv.id
            JOIN services s ON sv.service_id = s.id
            LEFT JOIN service_categories sc ON s.category_id = sc.id
            WHERE svrr.resource_id = :resource_id 
              AND sv.is_active = 1 
              AND s.is_active = 1
            ORDER BY s.name ASC
        ');
        $stmt->execute(['resource_id' => $resourceId]);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Set service variants that require a specific resource (replace all).
     * 
     * @param int $resourceId The resource ID
     * @param array $variantRequirements Array of ['service_variant_id' => int, 'quantity' => int]
     */
    public function setVariantsForResource(int $resourceId, array $variantRequirements): void
    {
        $pdo = $this->db->getPdo();
        
        $pdo->beginTransaction();
        try {
            // Delete existing requirements for this resource
            $stmt = $pdo->prepare('DELETE FROM service_variant_resource_requirements WHERE resource_id = ?');
            $stmt->execute([$resourceId]);

            // Insert new requirements
            if (!empty($variantRequirements)) {
                $stmt = $pdo->prepare('
                    INSERT INTO service_variant_resource_requirements (service_variant_id, resource_id, quantity)
                    VALUES (?, ?, ?)
                ');
                foreach ($variantRequirements as $req) {
                    $stmt->execute([
                        (int) $req['service_variant_id'],
                        $resourceId,
                        (int) ($req['quantity'] ?? 1),
                    ]);
                }
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Get location_id for a resource.
     */
    public function getLocationIdForResource(int $resourceId): ?int
    {
        $stmt = $this->db->getPdo()->prepare('SELECT location_id FROM resources WHERE id = ? AND is_active = 1');
        $stmt->execute([$resourceId]);
        $result = $stmt->fetchColumn();
        return $result !== false ? (int) $result : null;
    }

    /**
     * Get business_id for a resource (for authorization).
     */
    public function getBusinessIdForResource(int $resourceId): ?int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT l.business_id
             FROM resources r
             JOIN locations l ON r.location_id = l.id
             WHERE r.id = ? AND r.is_active = 1
             LIMIT 1'
        );
        $stmt->execute([$resourceId]);
        $result = $stmt->fetchColumn();

        return $result !== false ? (int) $result : null;
    }

    /**
     * Validate that all service_variant_ids belong to the same location as the resource.
     */
    public function validateVariantsForResource(int $resourceId, array $variantIds): bool
    {
        if (empty($variantIds)) {
            return true;
        }

        // Get location_id for the resource
        $locationId = $this->getLocationIdForResource($resourceId);
        if (!$locationId) {
            return false;
        }

        // Check all variants belong to this location
        $placeholders = implode(',', array_fill(0, count($variantIds), '?'));
        $params = array_merge($variantIds, [$locationId]);
        
        $stmt = $this->db->getPdo()->prepare("
            SELECT COUNT(*) FROM service_variants 
            WHERE id IN ({$placeholders}) AND location_id = ? AND is_active = 1
        ");
        $stmt->execute($params);

        return (int) $stmt->fetchColumn() === count($variantIds);
    }

    /**
     * Cap all service variant requirements for a resource to a maximum quantity.
     * Called when a resource's quantity is reduced to ensure data consistency.
     * 
     * @param int $resourceId The resource ID
     * @param int $maxQuantity The new maximum quantity allowed
     * @return int Number of rows updated
     */
    public function capQuantityForResource(int $resourceId, int $maxQuantity): int
    {
        $stmt = $this->db->getPdo()->prepare('
            UPDATE service_variant_resource_requirements 
            SET quantity = ?
            WHERE resource_id = ? AND quantity > ?
        ');
        $stmt->execute([$maxQuantity, $resourceId, $maxQuantity]);
        return $stmt->rowCount();
    }

    /**
     * Get resource usage for a time range at a location.
     * Returns how many units of each resource are in use at each booking_item.
     * 
     * @param int $locationId
     * @param \DateTimeImmutable $start
     * @param \DateTimeImmutable $end
     * @param int|null $excludeBookingId Exclude this booking from the count
     * @return array Array of ['resource_id', 'quantity_used', 'start_time', 'end_time']
     */
    public function getResourceUsageInRange(int $locationId, \DateTimeImmutable $start, \DateTimeImmutable $end, ?int $excludeBookingId = null): array
    {
        $excludeClause = $excludeBookingId ? 'AND bi.booking_id != ?' : '';
        $params = [
            $locationId,
            $end->format('Y-m-d H:i:s'),   // bi.start_time < end
            $start->format('Y-m-d H:i:s'), // bi.end_time > start
        ];
        if ($excludeBookingId) {
            $params[] = $excludeBookingId;
        }

        $stmt = $this->db->getPdo()->prepare("
            SELECT 
                svrr.resource_id,
                svrr.quantity AS quantity_used,
                bi.start_time,
                bi.end_time
            FROM booking_items bi
            JOIN bookings b ON bi.booking_id = b.id
            JOIN service_variant_resource_requirements svrr ON bi.service_variant_id = svrr.service_variant_id
            WHERE bi.location_id = ?
              AND bi.start_time < ?
              AND bi.end_time > ?
              AND b.status NOT IN ('cancelled', 'no_show')
              {$excludeClause}
            ORDER BY bi.start_time
        ");
        $stmt->execute($params);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Get total quantity available for each resource at a location.
     * 
     * @param int $locationId
     * @return array Keyed by resource_id => total_quantity
     */
    public function getResourceCapacities(int $locationId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, quantity
            FROM resources
            WHERE location_id = ? AND is_active = 1
        ');
        $stmt->execute([$locationId]);
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        
        $result = [];
        foreach ($rows as $row) {
            $result[(int)$row['id']] = (int)$row['quantity'];
        }
        return $result;
    }

    /**
     * Get resource requirements for specific service variant IDs.
     * Returns aggregated requirements (resource_id => total quantity needed).
     * 
     * @param array $variantIds
     * @return array Keyed by resource_id => quantity needed
     */
    public function getAggregatedRequirements(array $variantIds): array
    {
        if (empty($variantIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($variantIds), '?'));
        $stmt = $this->db->getPdo()->prepare("
            SELECT resource_id, SUM(quantity) AS total_quantity
            FROM service_variant_resource_requirements
            WHERE service_variant_id IN ({$placeholders})
            GROUP BY resource_id
        ");
        $stmt->execute($variantIds);
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        
        $result = [];
        foreach ($rows as $row) {
            $result[(int)$row['resource_id']] = (int)$row['total_quantity'];
        }
        return $result;
    }
}
