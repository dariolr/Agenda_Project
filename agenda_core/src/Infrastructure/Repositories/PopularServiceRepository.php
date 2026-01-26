<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use PDO;

/**
 * Repository for popular_services table.
 * Stores top 5 most booked services per staff member.
 */
final class PopularServiceRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Get popular services for a staff member with service and category info.
     * 
     * @param int $staffId
     * @return array Array of popular services with service details and category name
     */
    public function findByStaffId(int $staffId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                ps.`rank`,
                ps.booking_count,
                s.id AS service_id,
                s.name AS service_name,
                s.category_id,
                sc.name AS category_name,
                sv.price,
                sv.duration_minutes,
                sv.color_hex AS color
             FROM popular_services ps
             JOIN services s ON ps.service_id = s.id
             JOIN staff_locations sl ON sl.staff_id = ps.staff_id
             JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = sl.location_id
             LEFT JOIN service_categories sc ON s.category_id = sc.id
             WHERE ps.staff_id = ? AND s.is_active = 1 AND sv.is_active = 1
             ORDER BY ps.`rank` ASC'
        );
        $stmt->execute([$staffId]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Compute and store popular services for a staff member.
     * Analyzes booking_items from the last 90 days.
     * 
     * @param int $staffId
     * @return int Number of popular services stored (0-5)
     */
    public function computeForStaff(int $staffId): int
    {
        $pdo = $this->db->getPdo();

        // Query per trovare i top 5 servizi più prenotati negli ultimi 90 giorni per questo staff
        $stmt = $pdo->prepare(
            'SELECT 
                bi.service_id,
                COUNT(*) AS booking_count
             FROM booking_items bi
             JOIN bookings b ON bi.booking_id = b.id
             JOIN services s ON bi.service_id = s.id
             WHERE bi.staff_id = ?
               AND b.status IN ("confirmed", "completed")
               AND bi.start_time >= DATE_SUB(NOW(), INTERVAL 90 DAY)
               AND s.is_active = 1
             GROUP BY bi.service_id
             ORDER BY booking_count DESC
             LIMIT 5'
        );
        $stmt->execute([$staffId]);
        $topServices = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($topServices)) {
            return 0;
        }

        // Cancella i record esistenti per lo staff
        $deleteStmt = $pdo->prepare('DELETE FROM popular_services WHERE staff_id = ?');
        $deleteStmt->execute([$staffId]);

        // Inserisce i nuovi record
        $insertStmt = $pdo->prepare(
            'INSERT INTO popular_services (staff_id, service_id, `rank`, booking_count, computed_at)
             VALUES (?, ?, ?, ?, NOW())'
        );

        $rank = 1;
        foreach ($topServices as $service) {
            $insertStmt->execute([
                $staffId,
                $service['service_id'],
                $rank,
                $service['booking_count'],
            ]);
            $rank++;
        }

        return count($topServices);
    }

    /**
     * Compute popular services for all active staff members.
     * 
     * @return array Summary of computation: ['staff_processed' => int, 'total_services' => int]
     */
    public function computeForAllStaff(): array
    {
        $pdo = $this->db->getPdo();

        // Get all active staff
        $stmt = $pdo->query(
            'SELECT id FROM staff WHERE is_active = 1'
        );
        $staffIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

        $staffProcessed = 0;
        $totalServices = 0;

        foreach ($staffIds as $staffId) {
            $count = $this->computeForStaff((int) $staffId);
            $staffProcessed++;
            $totalServices += $count;
        }

        return [
            'staff_processed' => $staffProcessed,
            'total_services' => $totalServices,
        ];
    }

    /**
     * Get the timestamp of last computation for a staff member.
     * 
     * @param int $staffId
     * @return string|null ISO timestamp or null if never computed
     */
    public function getLastComputedAt(int $staffId): ?string
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT MAX(computed_at) FROM popular_services WHERE staff_id = ?'
        );
        $stmt->execute([$staffId]);
        $result = $stmt->fetchColumn();

        return $result ?: null;
    }

    /**
     * Get total count of services for a staff's location.
     * Used to determine if popular section should be shown (>= 25 services).
     * 
     * @param int $staffId
     * @return int
     */
    public function getTotalServicesCountForStaff(int $staffId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(DISTINCT s.id)
             FROM services s
             JOIN service_variants sv ON s.id = sv.service_id
             JOIN staff_locations sl ON sv.location_id = sl.location_id
             WHERE sl.staff_id = ? AND s.is_active = 1 AND sv.is_active = 1'
        );
        $stmt->execute([$staffId]);

        return (int) $stmt->fetchColumn();
    }

    /**
     * Get count of services enabled for a specific staff member.
     * Uses staff_services table to count only services the staff can perform.
     * 
     * @param int $staffId
     * @return int
     */
    public function getEnabledServicesCountForStaff(int $staffId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(DISTINCT ss.service_id)
             FROM staff_services ss
             JOIN services s ON ss.service_id = s.id
             WHERE ss.staff_id = ? AND s.is_active = 1'
        );
        $stmt->execute([$staffId]);

        return (int) $stmt->fetchColumn();
    }
}
