<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use PDO;

final class BusinessClosureRepository
{
    public function __construct(
        private Connection $db
    ) {}

    /**
     * Find all closures for a business
     */
    public function findByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, business_id, start_date, end_date, reason, created_at, updated_at
            FROM business_closures
            WHERE business_id = ?
            ORDER BY start_date ASC
        ');
        $stmt->execute([$businessId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Find closures for a business within a date range
     */
    public function findByBusinessIdAndDateRange(int $businessId, string $startDate, string $endDate): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, business_id, start_date, end_date, reason, created_at, updated_at
            FROM business_closures
            WHERE business_id = ?
              AND start_date <= ?
              AND end_date >= ?
            ORDER BY start_date ASC
        ');
        $stmt->execute([$businessId, $endDate, $startDate]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Check if a specific date falls within any closure period
     */
    public function isDateClosed(int $businessId, string $date): bool
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT COUNT(*) as cnt
            FROM business_closures
            WHERE business_id = ?
              AND start_date <= ?
              AND end_date >= ?
        ');
        $stmt->execute([$businessId, $date, $date]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return (int)$row['cnt'] > 0;
    }

    /**
     * Find the closure that contains a specific date (returns null if not closed)
     */
    public function findClosureForDate(int $businessId, string $date): ?array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, business_id, start_date, end_date, reason, created_at, updated_at
            FROM business_closures
            WHERE business_id = ?
              AND start_date <= ?
              AND end_date >= ?
            LIMIT 1
        ');
        $stmt->execute([$businessId, $date, $date]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    /**
     * Get all closed dates within a range (useful for availability calculation)
     */
    public function getClosedDatesInRange(int $businessId, string $startDate, string $endDate): array
    {
        $closures = $this->findByBusinessIdAndDateRange($businessId, $startDate, $endDate);
        
        $closedDates = [];
        foreach ($closures as $closure) {
            $start = new \DateTime($closure['start_date']);
            $end = new \DateTime($closure['end_date']);
            $rangeStart = new \DateTime($startDate);
            $rangeEnd = new \DateTime($endDate);
            
            // Clamp to requested range
            if ($start < $rangeStart) {
                $start = $rangeStart;
            }
            if ($end > $rangeEnd) {
                $end = $rangeEnd;
            }
            
            $interval = new \DateInterval('P1D');
            $period = new \DatePeriod($start, $interval, $end->modify('+1 day'));
            
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
            FROM business_closures
            WHERE id = ?
        ');
        $stmt->execute([$id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    /**
     * Create a new closure
     */
    public function create(int $businessId, string $startDate, string $endDate, ?string $reason): int
    {
        $stmt = $this->db->getPdo()->prepare('
            INSERT INTO business_closures (business_id, start_date, end_date, reason)
            VALUES (?, ?, ?, ?)
        ');
        $stmt->execute([$businessId, $startDate, $endDate, $reason]);
        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Update an existing closure
     */
    public function update(int $id, string $startDate, string $endDate, ?string $reason): bool
    {
        $stmt = $this->db->getPdo()->prepare('
            UPDATE business_closures
            SET start_date = ?, end_date = ?, reason = ?
            WHERE id = ?
        ');
        return $stmt->execute([$startDate, $endDate, $reason, $id]);
    }

    /**
     * Delete a closure
     */
    public function delete(int $id): bool
    {
        $stmt = $this->db->getPdo()->prepare('
            DELETE FROM business_closures WHERE id = ?
        ');
        return $stmt->execute([$id]);
    }

    /**
     * Check for overlapping closures (for validation)
     */
    public function hasOverlap(int $businessId, string $startDate, string $endDate, ?int $excludeId = null): bool
    {
        $sql = '
            SELECT COUNT(*) as cnt
            FROM business_closures
            WHERE business_id = ?
              AND start_date <= ?
              AND end_date >= ?
        ';
        $params = [$businessId, $endDate, $startDate];
        
        if ($excludeId !== null) {
            $sql .= ' AND id != ?';
            $params[] = $excludeId;
        }
        
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return (int)$row['cnt'] > 0;
    }

    /**
     * Calculate total closed days in a date range for a business
     * Used for reports to subtract from scheduled hours
     */
    public function countClosedDaysInRange(int $businessId, string $startDate, string $endDate): int
    {
        $closedDates = $this->getClosedDatesInRange($businessId, $startDate, $endDate);
        return count($closedDates);
    }
}
