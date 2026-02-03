<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use PDO;

/**
 * Repository for multi-location closures.
 * 
 * Structure:
 * - `closures` table: id, business_id, start_date, end_date, reason
 * - `closure_locations` pivot: closure_id, location_id (N:M)
 */
final class LocationClosureRepository
{
    public function __construct(
        private Connection $db
    ) {}

    // ========================================
    // READ METHODS
    // ========================================

    /**
     * Find all closures for a business
     */
    public function findByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT c.id, c.business_id, c.start_date, c.end_date, c.reason, c.created_at, c.updated_at
            FROM closures c
            WHERE c.business_id = ?
            ORDER BY c.start_date ASC
        ');
        $stmt->execute([$businessId]);
        $closures = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Add location_ids to each closure
        return array_map(fn($c) => $this->addLocationIds($c), $closures);
    }

    /**
     * Find all closures that apply to a specific location
     */
    public function findByLocationId(int $locationId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT c.id, c.business_id, c.start_date, c.end_date, c.reason, c.created_at, c.updated_at
            FROM closures c
            JOIN closure_locations cl ON cl.closure_id = c.id
            WHERE cl.location_id = ?
            ORDER BY c.start_date ASC
        ');
        $stmt->execute([$locationId]);
        $closures = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return array_map(fn($c) => $this->addLocationIds($c), $closures);
    }

    /**
     * Find closures for a location within a date range
     */
    public function findByLocationIdAndDateRange(int $locationId, string $startDate, string $endDate): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT c.id, c.business_id, c.start_date, c.end_date, c.reason, c.created_at, c.updated_at
            FROM closures c
            JOIN closure_locations cl ON cl.closure_id = c.id
            WHERE cl.location_id = ?
              AND c.start_date <= ?
              AND c.end_date >= ?
            ORDER BY c.start_date ASC
        ');
        $stmt->execute([$locationId, $endDate, $startDate]);
        $closures = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return array_map(fn($c) => $this->addLocationIds($c), $closures);
    }

    /**
     * Check if a specific date falls within any closure period for a location
     */
    public function isDateClosed(int $locationId, string $date): bool
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT COUNT(*) as cnt
            FROM closures c
            JOIN closure_locations cl ON cl.closure_id = c.id
            WHERE cl.location_id = ?
              AND c.start_date <= ?
              AND c.end_date >= ?
        ');
        $stmt->execute([$locationId, $date, $date]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return (int)$row['cnt'] > 0;
    }

    /**
     * Find the closure that contains a specific date (returns null if not closed)
     */
    public function findClosureForDate(int $locationId, string $date): ?array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT c.id, c.business_id, c.start_date, c.end_date, c.reason, c.created_at, c.updated_at
            FROM closures c
            JOIN closure_locations cl ON cl.closure_id = c.id
            WHERE cl.location_id = ?
              AND c.start_date <= ?
              AND c.end_date >= ?
            LIMIT 1
        ');
        $stmt->execute([$locationId, $date, $date]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$row) {
            return null;
        }
        
        return $this->addLocationIds($row);
    }

    /**
     * Get all closed dates within a range (useful for availability calculation)
     */
    public function getClosedDatesInRange(int $locationId, string $startDate, string $endDate): array
    {
        $closures = $this->findByLocationIdAndDateRange($locationId, $startDate, $endDate);
        
        $closedDates = [];
        foreach ($closures as $closure) {
            $start = new \DateTime($closure['start_date']);
            $end = new \DateTime($closure['end_date']);
            $rangeStart = new \DateTime($startDate);
            $rangeEnd = new \DateTime($endDate);
            
            // Clamp to requested range
            if ($start < $rangeStart) {
                $start = clone $rangeStart;
            }
            if ($end > $rangeEnd) {
                $end = clone $rangeEnd;
            }
            
            $interval = new \DateInterval('P1D');
            $endPlusOne = clone $end;
            $endPlusOne->modify('+1 day');
            $period = new \DatePeriod($start, $interval, $endPlusOne);
            
            foreach ($period as $date) {
                $closedDates[$date->format('Y-m-d')] = $closure['reason'] ?? 'Chiusura';
            }
        }
        
        return $closedDates;
    }

    /**
     * Find a single closure by ID
     */
    public function findById(int $id): ?array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, business_id, start_date, end_date, reason, created_at, updated_at
            FROM closures
            WHERE id = ?
        ');
        $stmt->execute([$id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$row) {
            return null;
        }
        
        return $this->addLocationIds($row);
    }

    /**
     * Get the business_id for a closure (for authorization checks)
     */
    public function getBusinessId(int $closureId): ?int
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT business_id FROM closures WHERE id = ?
        ');
        $stmt->execute([$closureId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ? (int)$row['business_id'] : null;
    }

    /**
     * Get location IDs for a closure
     */
    public function getLocationIds(int $closureId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT location_id FROM closure_locations WHERE closure_id = ?
        ');
        $stmt->execute([$closureId]);
        return array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'location_id');
    }

    // ========================================
    // WRITE METHODS
    // ========================================

    /**
     * Create a new closure with multiple locations
     * 
     * @param int $businessId
     * @param array $locationIds IDs of locations this closure applies to
     * @param string $startDate
     * @param string $endDate
     * @param string|null $reason
     * @return int The new closure ID
     */
    public function create(int $businessId, array $locationIds, string $startDate, string $endDate, ?string $reason): int
    {
        $pdo = $this->db->getPdo();
        
        $pdo->beginTransaction();
        try {
            // Insert closure
            $stmt = $pdo->prepare('
                INSERT INTO closures (business_id, start_date, end_date, reason)
                VALUES (?, ?, ?, ?)
            ');
            $stmt->execute([$businessId, $startDate, $endDate, $reason]);
            $closureId = (int) $pdo->lastInsertId();

            // Insert location associations
            $this->setLocationIds($closureId, $locationIds);

            $pdo->commit();
            return $closureId;
        } catch (\Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Update an existing closure
     * 
     * @param int $id Closure ID
     * @param array $locationIds New location IDs
     * @param string $startDate
     * @param string $endDate
     * @param string|null $reason
     */
    public function update(int $id, array $locationIds, string $startDate, string $endDate, ?string $reason): bool
    {
        $pdo = $this->db->getPdo();
        
        $pdo->beginTransaction();
        try {
            // Update closure
            $stmt = $pdo->prepare('
                UPDATE closures
                SET start_date = ?, end_date = ?, reason = ?
                WHERE id = ?
            ');
            $stmt->execute([$startDate, $endDate, $reason, $id]);

            // Update location associations
            $this->setLocationIds($id, $locationIds);

            $pdo->commit();
            return true;
        } catch (\Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Delete a closure
     */
    public function delete(int $id): bool
    {
        // closure_locations will be deleted via ON DELETE CASCADE
        $stmt = $this->db->getPdo()->prepare('
            DELETE FROM closures WHERE id = ?
        ');
        return $stmt->execute([$id]);
    }

    /**
     * Set location IDs for a closure (replaces existing)
     */
    private function setLocationIds(int $closureId, array $locationIds): void
    {
        $pdo = $this->db->getPdo();

        // Remove existing
        $stmt = $pdo->prepare('DELETE FROM closure_locations WHERE closure_id = ?');
        $stmt->execute([$closureId]);

        // Insert new
        if (!empty($locationIds)) {
            $stmt = $pdo->prepare('INSERT INTO closure_locations (closure_id, location_id) VALUES (?, ?)');
            foreach (array_unique($locationIds) as $locationId) {
                $stmt->execute([$closureId, $locationId]);
            }
        }
    }

    // ========================================
    // VALIDATION METHODS
    // ========================================

    /**
     * Check for overlapping closures on any of the given locations
     * 
     * @param array $locationIds Location IDs to check
     * @param string $startDate
     * @param string $endDate
     * @param int|null $excludeId Closure ID to exclude from check
     * @return array Array of location IDs that have overlapping closures
     */
    public function findOverlappingLocations(array $locationIds, string $startDate, string $endDate, ?int $excludeId = null): array
    {
        if (empty($locationIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
        $sql = "
            SELECT DISTINCT cl.location_id
            FROM closures c
            JOIN closure_locations cl ON cl.closure_id = c.id
            WHERE cl.location_id IN ($placeholders)
              AND c.start_date <= ?
              AND c.end_date >= ?
        ";
        $params = array_merge($locationIds, [$endDate, $startDate]);

        if ($excludeId !== null) {
            $sql .= ' AND c.id != ?';
            $params[] = $excludeId;
        }

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        return array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'location_id');
    }

    /**
     * Check if closure has overlap (legacy method - checks any location)
     */
    public function hasOverlap(int $locationId, string $startDate, string $endDate, ?int $excludeId = null): bool
    {
        $overlapping = $this->findOverlappingLocations([$locationId], $startDate, $endDate, $excludeId);
        return !empty($overlapping);
    }

    // ========================================
    // UTILITY METHODS
    // ========================================

    /**
     * Calculate total closed days in a date range for a location
     * Used for reports to subtract from scheduled hours
     */
    public function countClosedDaysInRange(int $locationId, string $startDate, string $endDate): int
    {
        $closedDates = $this->getClosedDatesInRange($locationId, $startDate, $endDate);
        return count($closedDates);
    }

    /**
     * Get all closed dates for multiple locations within a date range.
     * Returns a map keyed by location_id.
     * 
     * @param int[] $locationIds Location IDs to check
     * @return array<int, array<string, string>> Map of location_id => [date => reason]
     */
    public function getClosedDatesForLocationsInRange(array $locationIds, string $startDate, string $endDate): array
    {
        if (empty($locationIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
        $stmt = $this->db->getPdo()->prepare("
            SELECT cl.location_id, c.start_date, c.end_date, c.reason
            FROM closures c
            JOIN closure_locations cl ON cl.closure_id = c.id
            WHERE cl.location_id IN ($placeholders)
              AND c.start_date <= ?
              AND c.end_date >= ?
            ORDER BY c.start_date ASC
        ");
        $params = array_merge($locationIds, [$endDate, $startDate]);
        $stmt->execute($params);
        $closures = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $closedDatesByLocation = [];
        foreach ($closures as $closure) {
            $locId = (int)$closure['location_id'];
            $start = new \DateTime($closure['start_date']);
            $end = new \DateTime($closure['end_date']);
            $rangeStart = new \DateTime($startDate);
            $rangeEnd = new \DateTime($endDate);

            // Clamp to requested range
            if ($start < $rangeStart) {
                $start = clone $rangeStart;
            }
            if ($end > $rangeEnd) {
                $end = clone $rangeEnd;
            }

            $interval = new \DateInterval('P1D');
            $endPlusOne = clone $end;
            $endPlusOne->modify('+1 day');
            $period = new \DatePeriod($start, $interval, $endPlusOne);

            foreach ($period as $date) {
                $dateStr = $date->format('Y-m-d');
                if (!isset($closedDatesByLocation[$locId])) {
                    $closedDatesByLocation[$locId] = [];
                }
                $closedDatesByLocation[$locId][$dateStr] = $closure['reason'] ?? 'Chiusura';
            }
        }

        return $closedDatesByLocation;
    }

    /**
     * Add location_ids array to a closure row
     */
    private function addLocationIds(array $closure): array
    {
        $closure['location_ids'] = array_map('intval', $this->getLocationIds((int)$closure['id']));
        return $closure;
    }
}
