<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for staff weekly schedules.
 * 
 * SCHEMA NOTE:
 * - staff_schedules: staff_id, day_of_week (1-7 ISO), start_time, end_time
 * - Supports multiple time ranges per day (split shifts)
 */
final class StaffScheduleRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Get weekly schedule for a staff member.
     * Returns array grouped by day_of_week (1-7).
     * 
     * @return array<int, array<array{start_time: string, end_time: string}>>
     */
    public function getByStaffId(int $staffId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, day_of_week, start_time, end_time
             FROM staff_schedules
             WHERE staff_id = ?
             ORDER BY day_of_week ASC, start_time ASC'
        );
        $stmt->execute([$staffId]);
        $rows = $stmt->fetchAll();

        // Group by day
        $result = [];
        for ($day = 1; $day <= 7; $day++) {
            $result[$day] = [];
        }

        foreach ($rows as $row) {
            $day = (int) $row['day_of_week'];
            $result[$day][] = [
                'id' => (int) $row['id'],
                'start_time' => $row['start_time'],
                'end_time' => $row['end_time'],
            ];
        }

        return $result;
    }

    /**
     * Get schedules for multiple staff members.
     * 
     * @param int[] $staffIds
     * @return array<int, array<int, array<array{start_time: string, end_time: string}>>>
     */
    public function getByStaffIds(array $staffIds): array
    {
        if (empty($staffIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($staffIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT staff_id, day_of_week, start_time, end_time
             FROM staff_schedules
             WHERE staff_id IN ($placeholders)
             ORDER BY staff_id ASC, day_of_week ASC, start_time ASC"
        );
        $stmt->execute($staffIds);
        $rows = $stmt->fetchAll();

        // Initialize result with empty days for each staff
        $result = [];
        foreach ($staffIds as $staffId) {
            $result[$staffId] = [];
            for ($day = 1; $day <= 7; $day++) {
                $result[$staffId][$day] = [];
            }
        }

        foreach ($rows as $row) {
            $staffId = (int) $row['staff_id'];
            $day = (int) $row['day_of_week'];
            $result[$staffId][$day][] = [
                'start_time' => $row['start_time'],
                'end_time' => $row['end_time'],
            ];
        }

        return $result;
    }

    /**
     * Save weekly schedule for a staff member (replaces existing).
     * 
     * @param int $staffId
     * @param array<int, array<array{start_time: string, end_time: string}>> $weeklySchedule
     */
    public function saveForStaff(int $staffId, array $weeklySchedule): void
    {
        $pdo = $this->db->getPdo();

        // Delete existing schedules
        $deleteStmt = $pdo->prepare('DELETE FROM staff_schedules WHERE staff_id = ?');
        $deleteStmt->execute([$staffId]);

        // Insert new schedules
        $insertStmt = $pdo->prepare(
            'INSERT INTO staff_schedules (staff_id, day_of_week, start_time, end_time) 
             VALUES (?, ?, ?, ?)'
        );

        foreach ($weeklySchedule as $dayOfWeek => $shifts) {
            if (!is_int($dayOfWeek) || $dayOfWeek < 1 || $dayOfWeek > 7) {
                continue;
            }

            foreach ($shifts as $shift) {
                if (empty($shift['start_time']) || empty($shift['end_time'])) {
                    continue;
                }

                $insertStmt->execute([
                    $staffId,
                    $dayOfWeek,
                    $shift['start_time'],
                    $shift['end_time'],
                ]);
            }
        }
    }

    /**
     * Delete all schedules for a staff member.
     */
    public function deleteForStaff(int $staffId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM staff_schedules WHERE staff_id = ?'
        );
        return $stmt->execute([$staffId]);
    }

    /**
     * Check if staff has any schedule defined.
     */
    public function hasSchedule(int $staffId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM staff_schedules WHERE staff_id = ? LIMIT 1'
        );
        $stmt->execute([$staffId]);
        return $stmt->fetchColumn() !== false;
    }

    /**
     * Copy schedule from one staff to another.
     */
    public function copySchedule(int $fromStaffId, int $toStaffId): void
    {
        $schedule = $this->getByStaffId($fromStaffId);
        $this->saveForStaff($toStaffId, $schedule);
    }
}
