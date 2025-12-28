<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for staff members.
 * 
 * SCHEMA NOTE:
 * - staff: name, surname, color_hex, is_bookable_online
 * - staff_locations: N:M relationship staff <-> locations
 */
final class StaffRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findById(int $staffId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, surname, color_hex, avatar_url, 
                    is_bookable_online, is_active, sort_order
             FROM staff
             WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$staffId]);
        $result = $stmt->fetch();

        if ($result) {
            $result['display_name'] = trim($result['name'] . ' ' . substr($result['surname'], 0, 1) . '.');
        }

        return $result ?: null;
    }

    public function findByLocationId(int $locationId, int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT s.id, s.business_id, s.name, s.surname, s.color_hex, s.avatar_url, 
                    s.is_bookable_online, s.is_active, s.sort_order
             FROM staff s
             JOIN staff_locations sl ON s.id = sl.staff_id
             WHERE sl.location_id = ? AND s.business_id = ? AND s.is_active = 1 AND s.is_bookable_online = 1
             ORDER BY s.sort_order ASC, s.name ASC'
        );
        $stmt->execute([$locationId, $businessId]);

        $results = $stmt->fetchAll();
        foreach ($results as &$result) {
            $result['display_name'] = trim($result['name'] . ' ' . substr($result['surname'], 0, 1) . '.');
        }

        return $results;
    }

    public function findByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, surname, color_hex, avatar_url, 
                    is_bookable_online, is_active, sort_order
             FROM staff
             WHERE business_id = ? AND is_active = 1
             ORDER BY sort_order ASC, name ASC'
        );
        $stmt->execute([$businessId]);

        $results = $stmt->fetchAll();
        foreach ($results as &$result) {
            $result['display_name'] = trim($result['name'] . ' ' . substr($result['surname'], 0, 1) . '.');
        }

        return $results;
    }

    public function belongsToLocation(int $staffId, int $locationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM staff s
             JOIN staff_locations sl ON s.id = sl.staff_id
             WHERE s.id = ? AND sl.location_id = ? AND s.is_active = 1 AND s.is_bookable_online = 1'
        );
        $stmt->execute([$staffId, $locationId]);

        return $stmt->fetchColumn() !== false;
    }

    public function belongsToBusiness(int $staffId, int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM staff 
             WHERE id = ? AND business_id = ? AND is_active = 1 AND is_bookable_online = 1'
        );
        $stmt->execute([$staffId, $businessId]);

        return $stmt->fetchColumn() !== false;
    }

    /**
     * Check if staff can perform all given services.
     * Checks staff_services table if exists, otherwise allows all services.
     */
    public function canPerformServices(int $staffId, array $serviceIds, int $locationId, int $businessId): bool
    {
        // First verify staff belongs to location
        if (!$this->belongsToLocation($staffId, $locationId)) {
            return false;
        }
        
        // Check if staff has service restrictions
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM staff_services WHERE staff_id = ?'
        );
        $stmt->execute([$staffId]);
        $restrictionCount = $stmt->fetchColumn();
        
        // No restrictions = can perform all services
        if ($restrictionCount == 0) {
            return true;
        }
        
        // Check if staff can perform ALL requested services
        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT COUNT(DISTINCT service_id) 
             FROM staff_services 
             WHERE staff_id = ? AND service_id IN ($placeholders)"
        );
        $stmt->execute([$staffId, ...$serviceIds]);
        $matchCount = $stmt->fetchColumn();
        
        return $matchCount == count($serviceIds);
    }

    /**
     * Get services for a staff member at a specific location.
     * Returns all active services from service_variants for this location.
     */
    public function getServicesForStaff(int $staffId, ?int $locationId = null): array
    {
        // Get business_id for staff
        $staff = $this->findById($staffId);
        if (!$staff) {
            return [];
        }

        $businessId = (int) $staff['business_id'];

        if ($locationId !== null) {
            // Get services available at this location via service_variants
            $stmt = $this->db->getPdo()->prepare(
                'SELECT s.id, s.name, sv.duration_minutes, sv.price
                 FROM services s
                 JOIN service_variants sv ON s.id = sv.service_id
                 WHERE s.business_id = ? AND sv.location_id = ? AND s.is_active = 1 AND sv.is_bookable_online = 1
                 ORDER BY s.sort_order ASC, s.name ASC'
            );
            $stmt->execute([$businessId, $locationId]);
        } else {
            // Get all services for business (no variants)
            $stmt = $this->db->getPdo()->prepare(
                'SELECT s.id, s.name, 0 as duration_minutes, 0 as price
                 FROM services s
                 WHERE s.business_id = ? AND s.is_active = 1
                 ORDER BY s.sort_order ASC, s.name ASC'
            );
            $stmt->execute([$businessId]);
        }

        return $stmt->fetchAll();
    }

    /**
     * Get working hours for a staff member on a specific day.
     * Queries location_schedules table for working hours.
     */
    public function getWorkingHours(int $staffId, int $dayOfWeek): ?array
    {
        // Get staff to find their location
        $staff = $this->findById($staffId);
        if (!$staff || empty($staff['location_id'])) {
            return null;
        }
        
        $locationId = (int) $staff['location_id'];
        
        // Query location_schedules
        $stmt = $this->db->getPdo()->prepare(
            'SELECT open_time, close_time, is_closed 
             FROM location_schedules 
             WHERE location_id = ? AND day_of_week = ?'
        );
        $stmt->execute([$locationId, $dayOfWeek]);
        $schedule = $stmt->fetch();
        
        // If no schedule found, use default (9:00-18:00, Mon-Fri working)
        if (!$schedule) {
            return [
                'staff_id' => $staffId,
                'day_of_week' => $dayOfWeek,
                'start_time' => '09:00:00',
                'end_time' => '18:00:00',
                'is_working' => $dayOfWeek >= 1 && $dayOfWeek <= 5, // Mon-Fri
            ];
        }
        
        return [
            'staff_id' => $staffId,
            'day_of_week' => $dayOfWeek,
            'start_time' => $schedule['open_time'],
            'end_time' => $schedule['close_time'],
            'is_working' => !$schedule['is_closed'],
        ];
    }

    /**
     * Get all working hours for a staff member.
     */
    public function getAllWorkingHours(int $staffId): array
    {
        // MVP: Return default working hours for all days
        $hours = [];
        for ($day = 1; $day <= 7; $day++) {
            $hours[] = $this->getWorkingHours($staffId, $day);
        }
        return $hours;
    }
}
