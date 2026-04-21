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
                   tb.is_all_day, tb.allow_online_booking_during_block, tb.reason,
                   tb.recurrence_rule_id, tb.recurrence_index, tb.is_recurrence_parent,
                   tb.created_at, tb.updated_at
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
                   tb.is_all_day, tb.allow_online_booking_during_block, tb.reason,
                   tb.recurrence_rule_id, tb.recurrence_index, tb.is_recurrence_parent,
                   tb.created_at, tb.updated_at
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

        foreach ($blocks as &$block) {
            $block['staff_ids'] = $this->getStaffIdsForBlock((int) $block['id']);
        }

        return $blocks;
    }

    /**
     * Find time blocks for a specific staff member on a specific date.
     */
    public function findByStaffAndDate(int $staffId, int $locationId, string $date): array
    {
        $dateStart = $date . ' 00:00:00';
        $dateEnd   = $date . ' 23:59:59';

        $stmt = $this->db->getPdo()->prepare('
            SELECT tb.id, tb.business_id, tb.location_id, tb.start_time, tb.end_time,
                   tb.is_all_day, tb.allow_online_booking_during_block, tb.reason,
                   tb.recurrence_rule_id, tb.recurrence_index, tb.is_recurrence_parent
            FROM time_blocks tb
            INNER JOIN time_block_staff tbs ON tb.id = tbs.time_block_id
            WHERE tbs.staff_id = :staff_id
              AND tb.location_id = :location_id
              AND tb.start_time < :date_end
              AND tb.end_time > :date_start
            ORDER BY tb.start_time ASC
        ');
        $stmt->execute([
            'staff_id'   => $staffId,
            'location_id' => $locationId,
            'date_start'  => $dateStart,
            'date_end'    => $dateEnd,
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
                   is_all_day, allow_online_booking_during_block, reason,
                   recurrence_rule_id, recurrence_index, is_recurrence_parent,
                   created_at, updated_at
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
     * Find all time blocks belonging to a recurrence series.
     * Returns rows ordered by recurrence_index ASC.
     */
    public function findByRecurrenceRuleId(int $ruleId): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, business_id, location_id, start_time, end_time,
                   is_all_day, allow_online_booking_during_block, reason,
                   recurrence_rule_id, recurrence_index, is_recurrence_parent,
                   created_at, updated_at
            FROM time_blocks
            WHERE recurrence_rule_id = :rule_id
            ORDER BY recurrence_index ASC
        ');
        $stmt->execute(['rule_id' => $ruleId]);
        $blocks = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        foreach ($blocks as &$block) {
            $block['staff_ids'] = $this->getStaffIdsForBlock((int) $block['id']);
        }

        return $blocks;
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
     * Returns the new block ID.
     */
    public function create(array $data): int
    {
        $pdo = $this->db->getPdo();

        $stmt = $pdo->prepare('
            INSERT INTO time_blocks (
                business_id, location_id, start_time, end_time,
                is_all_day, allow_online_booking_during_block, reason,
                recurrence_rule_id, recurrence_index, is_recurrence_parent
            ) VALUES (
                :business_id, :location_id, :start_time, :end_time,
                :is_all_day, :allow_online_booking_during_block, :reason,
                :recurrence_rule_id, :recurrence_index, :is_recurrence_parent
            )
        ');
        $stmt->execute([
            'business_id'                     => $data['business_id'],
            'location_id'                     => $data['location_id'],
            'start_time'                      => $data['start_time'],
            'end_time'                        => $data['end_time'],
            'is_all_day'                      => $data['is_all_day'] ?? 0,
            'allow_online_booking_during_block' => $data['allow_online_booking_during_block'] ?? 0,
            'reason'                          => $data['reason'] ?? null,
            'recurrence_rule_id'              => $data['recurrence_rule_id'] ?? null,
            'recurrence_index'                => $data['recurrence_index'] ?? null,
            'is_recurrence_parent'            => $data['is_recurrence_parent'] ?? 0,
        ]);

        $blockId = (int) $pdo->lastInsertId();

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

        foreach (['start_time', 'end_time', 'is_all_day', 'allow_online_booking_during_block', 'reason'] as $field) {
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

        if (array_key_exists('staff_ids', $data)) {
            $this->setStaffForBlock($id, $data['staff_ids']);
        }

        return true;
    }

    /**
     * Update shared fields (non-time) for all blocks in a recurrence series.
     * Only updates: reason, is_all_day, allow_online_booking_during_block.
     * Staff is updated via the join table for every block.
     */
    public function updateByRecurrenceRuleId(int $ruleId, array $data): void
    {
        $fields = [];
        $params = ['rule_id' => $ruleId];

        foreach (['is_all_day', 'allow_online_booking_during_block', 'reason'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = :$field";
                $params[$field] = $data[$field];
            }
        }

        if (!empty($fields)) {
            $sql = 'UPDATE time_blocks SET ' . implode(', ', $fields)
                . ' WHERE recurrence_rule_id = :rule_id';
            $this->db->getPdo()->prepare($sql)->execute($params);
        }

        // Update staff for every block in the series
        if (array_key_exists('staff_ids', $data)) {
            $blocks = $this->findByRecurrenceRuleId($ruleId);
            foreach ($blocks as $block) {
                $this->setStaffForBlock((int) $block['id'], $data['staff_ids']);
            }
        }
    }

    /**
     * Update shared fields (non-time) for blocks in a recurrence series
     * starting from a specific recurrence index (included).
     * Only updates: reason, is_all_day, allow_online_booking_during_block.
     * Staff is updated via the join table for every affected block.
     */
    public function updateByRecurrenceRuleIdFromIndex(int $ruleId, int $fromIndex, array $data): void
    {
        $fields = [];
        $params = [
            'rule_id' => $ruleId,
            'from_index' => $fromIndex,
        ];

        foreach (['is_all_day', 'allow_online_booking_during_block', 'reason'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = :$field";
                $params[$field] = $data[$field];
            }
        }

        if (!empty($fields)) {
            $sql = 'UPDATE time_blocks SET ' . implode(', ', $fields)
                . ' WHERE recurrence_rule_id = :rule_id AND recurrence_index >= :from_index';
            $this->db->getPdo()->prepare($sql)->execute($params);
        }

        if (array_key_exists('staff_ids', $data)) {
            $blocks = $this->findByRecurrenceRuleIdFromIndex($ruleId, $fromIndex);
            foreach ($blocks as $block) {
                $this->setStaffForBlock((int) $block['id'], $data['staff_ids']);
            }
        }
    }

    /**
     * Set staff for a block (replaces existing associations).
     */
    private function setStaffForBlock(int $blockId, array $staffIds): void
    {
        $pdo = $this->db->getPdo();

        $stmt = $pdo->prepare('DELETE FROM time_block_staff WHERE time_block_id = :block_id');
        $stmt->execute(['block_id' => $blockId]);

        if (!empty($staffIds)) {
            $stmt = $pdo->prepare('
                INSERT INTO time_block_staff (time_block_id, staff_id) VALUES (:block_id, :staff_id)
            ');
            foreach ($staffIds as $staffId) {
                $stmt->execute(['block_id' => $blockId, 'staff_id' => (int) $staffId]);
            }
        }
    }

    /**
     * Delete a single time block (staff CASCADE).
     */
    public function delete(int $id): bool
    {
        $stmt = $this->db->getPdo()->prepare('DELETE FROM time_blocks WHERE id = :id');
        return $stmt->execute(['id' => $id]);
    }

    /**
     * Delete all time blocks belonging to a recurrence series.
     */
    public function deleteByRecurrenceRuleId(int $ruleId): void
    {
        $this->db->getPdo()
            ->prepare('DELETE FROM time_blocks WHERE recurrence_rule_id = :rule_id')
            ->execute(['rule_id' => $ruleId]);
    }

    /**
     * Delete blocks in a recurrence series starting from recurrence_index >= fromIndex.
     */
    public function deleteByRecurrenceRuleIdFromIndex(int $ruleId, int $fromIndex): void
    {
        $this->db->getPdo()
            ->prepare('
                DELETE FROM time_blocks
                WHERE recurrence_rule_id = :rule_id
                  AND recurrence_index >= :from_index
            ')
            ->execute([
                'rule_id' => $ruleId,
                'from_index' => $fromIndex,
            ]);
    }

    /**
     * Find recurrence blocks from a given index (included).
     */
    private function findByRecurrenceRuleIdFromIndex(int $ruleId, int $fromIndex): array
    {
        $stmt = $this->db->getPdo()->prepare('
            SELECT id, business_id, location_id, start_time, end_time,
                   is_all_day, allow_online_booking_during_block, reason,
                   recurrence_rule_id, recurrence_index, is_recurrence_parent,
                   created_at, updated_at
            FROM time_blocks
            WHERE recurrence_rule_id = :rule_id
              AND recurrence_index >= :from_index
            ORDER BY recurrence_index ASC
        ');
        $stmt->execute([
            'rule_id' => $ruleId,
            'from_index' => $fromIndex,
        ]);
        $blocks = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        foreach ($blocks as &$block) {
            $block['staff_ids'] = $this->getStaffIdsForBlock((int) $block['id']);
        }

        return $blocks;
    }

    /**
     * Get business_id for a time block (used for auth checks).
     */
    public function getBusinessIdForBlock(int $blockId): ?int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT business_id FROM time_blocks WHERE id = :id'
        );
        $stmt->execute(['id' => $blockId]);
        $result = $stmt->fetchColumn();
        return $result !== false ? (int) $result : null;
    }
}
