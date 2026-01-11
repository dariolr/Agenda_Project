<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for time blocks (unavailability periods).
 */
final class TimeBlockRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Get all time blocks for a location in a date range.
     */
    public function findByLocationAndDateRange(
        int $locationId,
        string $fromDate,
        string $toDate
    ): array {
        $stmt = $this->db->getPdo()->prepare('
            SELECT tb.id, tb.business_id, tb.location_id, tb.start_time, tb.end_time,
                   tb.is_all_day, tb.reason, tb.created_at, tb.updated_at
            FROM time_blocks tb
            WHERE tb.location_id = :location_id
              AND tb.start_time < :to_date
              AND tb.end_time > :from_date
            ORDER BY tb.start_time ASC
        ');
        $stmt->execute([
            'location_id' => $locationId,
            'from_date' => $fromDate,
            'to_date' => $toDate,
        ]);
        
        $blocks = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        
        // Load staff_ids for each block
        foreach ($blocks as &$block) {
            $block['staff_ids'] = $this->getStaffIdsForBlock((int) $block['id']);
        }
        
        return $blocks;
    }

    /**
     * Get all time blocks for a business in a date range.
     */
    public function findByBusinessAndDateRange(
        int $businessId,
        string $fromDate,
        string $toDate
    ): array {
        $stmt = $this->db->getPdo()->prepare('
            SELECT tb.id, tb.business_id, tb.location_id, tb.start_time, tb.end_time,
                   tb.is_all_day, tb.reason, tb.created_at, tb.updated_at
            FROM time_blocks tb
            WHERE tb.business_id = :business_id
              AND tb.start_time < :to_date
              AND tb.end_time > :from_date
            ORDER BY tb.start_time ASC
        ');
        $stmt->execute([
            'business_id' => $businessId,
            'from_date' => $fromDate,
            'to_date' => $toDate,
        ]);
        
        $blocks = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        
        // Load staff_ids for each block
        foreach ($blocks as &$block) {
            $block['staff_ids'] = $this->getStaffIdsForBlock((int) $block['id']);
        }
        
        return $blocks;
    }

    /**
     * Find time blocks for a specific staff member on a specific date.
     * Returns blocks where the staff is assigned (via time_block_staff).
     */
    public function findByStaffAndDate(int $staffId, int $locationId, string $date): array
    {
        $dateStart = $date . ' 00:00:00';
        $dateEnd = $date . ' 23:59:59';

        $stmt = $this->db->getPdo()->prepare('
            SELECT tb.id, tb.business_id, tb.location_id, tb.start_time, tb.end_time,
                   tb.is_all_day, tb.reason
            FROM time_blocks tb
            INNER JOIN time_block_staff tbs ON tb.id = tbs.time_block_id
            WHERE tbs.staff_id = :staff_id
              AND tb.location_id = :location_id
              AND tb.start_time < :date_end
              AND tb.end_time > :date_start
            ORDER BY tb.start_time ASC
        ');
        $stmt->execute([
            'staff_id' => $staffId,
            'location_id' => $locationId,
            'date_start' => $dateStart,
            'date_end' => $dateEnd,
        ]);

        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Find a single time block by ID.
     */
    public function findById(int $id): ?array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, business_id, location_id, start_time, end_time,
                   is_all_day, reason, created_at, updated_at
            FROM time_blocks
            WHERE id = :id
        ');
        $stmt->execute(['id' => $id]);
        $result = $stmt->fetch(\PDO::FETCH_ASSOC);
        
        if (!$result) {
            return null;
        }
        
        $result['staff_ids'] = $this->getStaffIdsForBlock($id);
        return $result;
    }

    /**
     * Get staff IDs for a block.
     */
    private function getStaffIdsForBlock(int $blockId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT staff_id FROM time_block_staff WHERE time_block_id = :block_id
        ');
        $stmt->execute(['block_id' => $blockId]);
        return array_map('intval', $stmt->fetchAll(\PDO::FETCH_COLUMN));
    }

    /**
     * Create a new time block.
     */
    public function create(array $data): int
    {
        $pdo = $this->db->getPdo();
        
        $stmt = $pdo->prepare('
            INSERT INTO time_blocks (business_id, location_id, start_time, end_time, is_all_day, reason)
            VALUES (:business_id, :location_id, :start_time, :end_time, :is_all_day, :reason)
        ');
        $stmt->execute([
            'business_id' => $data['business_id'],
            'location_id' => $data['location_id'],
            'start_time' => $data['start_time'],
            'end_time' => $data['end_time'],
            'is_all_day' => $data['is_all_day'] ?? 0,
            'reason' => $data['reason'] ?? null,
        ]);
        
        $blockId = (int) $pdo->lastInsertId();
        
        // Insert staff associations
        if (!empty($data['staff_ids'])) {
            $this->setStaffForBlock($blockId, $data['staff_ids']);
        }
        
        return $blockId;
    }

    /**
     * Update an existing time block.
     */
    public function update(int $id, array $data): bool
    {
        $fields = [];
        $params = ['id' => $id];

        foreach (['start_time', 'end_time', 'is_all_day', 'reason'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = :$field";
                $params[$field] = $data[$field];
            }
        }

        if (!empty($fields)) {
            $sql = 'UPDATE time_blocks SET ' . implode(', ', $fields) . ' WHERE id = :id';
            $stmt = $this->db->getPdo()->prepare($sql);
            $stmt->execute($params);
        }
        
        // Update staff associations if provided
        if (array_key_exists('staff_ids', $data)) {
            $this->setStaffForBlock($id, $data['staff_ids']);
        }

        return true;
    }

    /**
     * Set staff for a block (replaces existing).
     */
    private function setStaffForBlock(int $blockId, array $staffIds): void
    {
        $pdo = $this->db->getPdo();
        
        // Delete existing
        $stmt = $pdo->prepare('DELETE FROM time_block_staff WHERE time_block_id = :block_id');
        $stmt->execute(['block_id' => $blockId]);
        
        // Insert new
        if (!empty($staffIds)) {
            $stmt = $pdo->prepare('
                INSERT INTO time_block_staff (time_block_id, staff_id) VALUES (:block_id, :staff_id)
            ');
            foreach ($staffIds as $staffId) {
                $stmt->execute(['block_id' => $blockId, 'staff_id' => $staffId]);
            }
        }
    }

    /**
     * Delete a time block.
     */
    public function delete(int $id): bool
    {
        // Staff associations deleted by CASCADE
        $stmt = $this->db->getPdo()->prepare('DELETE FROM time_blocks WHERE id = :id');
        return $stmt->execute(['id' => $id]);
    }

    /**
     * Get business_id for a time block.
     */
    public function getBusinessIdForBlock(int $blockId): ?int
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT business_id FROM time_blocks WHERE id = :id
        ');
        $stmt->execute(['id' => $blockId]);
        $result = $stmt->fetchColumn();
        return $result !== false ? (int) $result : null;
    }
}
