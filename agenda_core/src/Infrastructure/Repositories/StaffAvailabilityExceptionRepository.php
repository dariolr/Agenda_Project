<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for staff availability exceptions.
 * 
 * Manages exceptions to the weekly schedule template:
 * - available: adds extra availability
 * - unavailable: removes availability (vacation, sick leave, etc.)
 */
final class StaffAvailabilityExceptionRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Get all exceptions for a staff member within a date range.
     */
    public function getByStaffId(int $staffId, ?string $fromDate = null, ?string $toDate = null): array
    {
        $sql = 'SELECT id, staff_id, exception_date, start_time, end_time, 
                       exception_type, reason_code, reason, created_at, updated_at
                FROM staff_availability_exceptions
                WHERE staff_id = ?';
        $params = [$staffId];

        if ($fromDate !== null) {
            $sql .= ' AND exception_date >= ?';
            $params[] = $fromDate;
        }

        if ($toDate !== null) {
            $sql .= ' AND exception_date <= ?';
            $params[] = $toDate;
        }

        $sql .= ' ORDER BY exception_date ASC, start_time ASC';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return array_map([$this, 'formatException'], $stmt->fetchAll());
    }

    /**
     * Get all exceptions for multiple staff members within a date range.
     */
    public function getByStaffIds(array $staffIds, ?string $fromDate = null, ?string $toDate = null): array
    {
        if (empty($staffIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($staffIds), '?'));
        $sql = "SELECT id, staff_id, exception_date, start_time, end_time, 
                       exception_type, reason_code, reason, created_at, updated_at
                FROM staff_availability_exceptions
                WHERE staff_id IN ({$placeholders})";
        $params = $staffIds;

        if ($fromDate !== null) {
            $sql .= ' AND exception_date >= ?';
            $params[] = $fromDate;
        }

        if ($toDate !== null) {
            $sql .= ' AND exception_date <= ?';
            $params[] = $toDate;
        }

        $sql .= ' ORDER BY staff_id ASC, exception_date ASC, start_time ASC';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return array_map([$this, 'formatException'], $stmt->fetchAll());
    }

    /**
     * Get all exceptions for a specific date (all staff).
     */
    public function getByDate(string $date): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, staff_id, exception_date, start_time, end_time, 
                    exception_type, reason_code, reason, created_at, updated_at
             FROM staff_availability_exceptions
             WHERE exception_date = ?
             ORDER BY staff_id ASC, start_time ASC'
        );
        $stmt->execute([$date]);

        return array_map([$this, 'formatException'], $stmt->fetchAll());
    }

    /**
     * Get a single exception by ID.
     */
    public function findById(int $id): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, staff_id, exception_date, start_time, end_time, 
                    exception_type, reason_code, reason, created_at, updated_at
             FROM staff_availability_exceptions
             WHERE id = ?'
        );
        $stmt->execute([$id]);
        $result = $stmt->fetch();

        return $result ? $this->formatException($result) : null;
    }

    /**
     * Create a new exception.
     */
    public function create(array $data): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO staff_availability_exceptions 
             (staff_id, exception_date, start_time, end_time, exception_type, reason_code, reason)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $data['staff_id'],
            $data['date'],
            $data['start_time'] ?? null,
            $data['end_time'] ?? null,
            $data['type'] ?? 'unavailable',
            $data['reason_code'] ?? null,
            $data['reason'] ?? null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Update an existing exception.
     */
    public function update(int $id, array $data): bool
    {
        $fields = [];
        $params = [];

        if (isset($data['date'])) {
            $fields[] = 'exception_date = ?';
            $params[] = $data['date'];
        }
        if (array_key_exists('start_time', $data)) {
            $fields[] = 'start_time = ?';
            $params[] = $data['start_time'];
        }
        if (array_key_exists('end_time', $data)) {
            $fields[] = 'end_time = ?';
            $params[] = $data['end_time'];
        }
        if (isset($data['type'])) {
            $fields[] = 'exception_type = ?';
            $params[] = $data['type'];
        }
        if (array_key_exists('reason_code', $data)) {
            $fields[] = 'reason_code = ?';
            $params[] = $data['reason_code'];
        }
        if (array_key_exists('reason', $data)) {
            $fields[] = 'reason = ?';
            $params[] = $data['reason'];
        }

        if (empty($fields)) {
            return false;
        }

        $params[] = $id;
        $sql = 'UPDATE staff_availability_exceptions SET ' . implode(', ', $fields) . ' WHERE id = ?';

        $stmt = $this->db->getPdo()->prepare($sql);
        return $stmt->execute($params);
    }

    /**
     * Delete an exception.
     */
    public function delete(int $id): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM staff_availability_exceptions WHERE id = ?'
        );
        return $stmt->execute([$id]);
    }

    /**
     * Get the staff_id for an exception (for authorization checks).
     */
    public function getStaffIdForException(int $exceptionId): ?int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT staff_id FROM staff_availability_exceptions WHERE id = ?'
        );
        $stmt->execute([$exceptionId]);
        $result = $stmt->fetchColumn();

        return $result !== false ? (int) $result : null;
    }

    /**
     * Format exception for API response.
     */
    private function formatException(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'staff_id' => (int) $row['staff_id'],
            'date' => $row['exception_date'],
            'start_time' => $row['start_time'] ? substr($row['start_time'], 0, 5) : null,
            'end_time' => $row['end_time'] ? substr($row['end_time'], 0, 5) : null,
            'type' => $row['exception_type'],
            'reason_code' => $row['reason_code'],
            'reason' => $row['reason'],
        ];
    }
}
