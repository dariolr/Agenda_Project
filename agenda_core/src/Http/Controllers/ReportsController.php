<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Database\Connection;
use PDO;

final class ReportsController
{
    public function __construct(
        private Connection $db,
        private BusinessUserRepository $businessUserRepo,
        private UserRepository $userRepo
    ) {}

    public function appointments(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return Response::unauthorized('Unauthorized');
        }

        $businessId = (int) ($request->query['business_id'] ?? 0);
        if ($businessId === 0) {
            return Response::badRequest(['error' => 'business_id is required']);
        }

        if (!$this->hasReportAccess($userId, $businessId)) {
            return Response::forbidden('Access denied. Admin or owner role required.');
        }

        $startDate = $request->query['start_date'] ?? null;
        $endDate = $request->query['end_date'] ?? null;

        if (!$startDate || !$endDate) {
            return Response::badRequest(['error' => 'start_date and end_date are required']);
        }

        if (!$this->isValidDate($startDate) || !$this->isValidDate($endDate)) {
            return Response::badRequest(['error' => 'Invalid date format. Use Y-m-d']);
        }

        $locationIds = $request->query['location_ids'] ?? [];
        $staffIds = $request->query['staff_ids'] ?? [];
        $serviceIds = $request->query['service_ids'] ?? [];
        $statusFilter = $request->query['status'] ?? 'confirmed,completed';
        $statuses = array_filter(explode(',', $statusFilter));

        $report = $this->buildReport($businessId, $startDate, $endDate, $locationIds, $staffIds, $serviceIds, $statuses);

        return Response::ok($report);
    }

    private function hasReportAccess(int $userId, int $businessId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        $pdo = $this->db->getPdo();
        $stmt = $pdo->prepare('SELECT is_owner, can_manage_users FROM business_users WHERE user_id = ? AND business_id = ?');
        $stmt->execute([$userId, $businessId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            return false;
        }

        return (bool) $row['is_owner'] || (bool) $row['can_manage_users'];
    }

    private function isValidDate(string $date): bool
    {
        $d = \DateTime::createFromFormat('Y-m-d', $date);
        return $d && $d->format('Y-m-d') === $date;
    }

    private function buildReport(int $businessId, string $startDate, string $endDate, array $locationIds, array $staffIds, array $serviceIds, array $statuses): array
    {
        $pdo = $this->db->getPdo();

        $conditions = ['b.business_id = ?', 'DATE(bi.start_time) >= ?', 'DATE(bi.start_time) <= ?'];
        $params = [$businessId, $startDate, $endDate];

        if (!empty($statuses)) {
            $placeholders = implode(',', array_fill(0, count($statuses), '?'));
            $conditions[] = "b.status IN ($placeholders)";
            $params = array_merge($params, $statuses);
        }

        if (!empty($locationIds)) {
            $locationIds = array_map('intval', $locationIds);
            $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
            $conditions[] = "bi.location_id IN ($placeholders)";
            $params = array_merge($params, $locationIds);
        }

        if (!empty($staffIds)) {
            $staffIds = array_map('intval', $staffIds);
            $placeholders = implode(',', array_fill(0, count($staffIds), '?'));
            $conditions[] = "bi.staff_id IN ($placeholders)";
            $params = array_merge($params, $staffIds);
        }

        if (!empty($serviceIds)) {
            $serviceIds = array_map('intval', $serviceIds);
            $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
            $conditions[] = "bi.service_id IN ($placeholders)";
            $params = array_merge($params, $serviceIds);
        }

        $whereClause = implode(' AND ', $conditions);

        $summaryQuery = "SELECT 
            COUNT(bi.id) as total_appointments,
            COUNT(DISTINCT b.id) as total_bookings,
            COALESCE(SUM(bi.price), 0) as total_revenue,
            COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)), 0) as total_duration_minutes,
            COUNT(DISTINCT b.client_id) as unique_clients,
            SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_count,
            SUM(CASE WHEN b.source = 'online' THEN 1 ELSE 0 END) as online_count,
            SUM(CASE WHEN b.source = 'manual' OR b.source IS NULL THEN 1 ELSE 0 END) as manual_count
            FROM booking_items bi JOIN bookings b ON bi.booking_id = b.id WHERE $whereClause";
        
        $stmt = $pdo->prepare($summaryQuery);
        $stmt->execute($params);
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);

        $byStaffQuery = "SELECT st.id as staff_id, CONCAT(st.name, ' ', st.surname) as staff_name, st.color_hex as staff_color,
            COUNT(bi.id) as appointments, COALESCE(SUM(bi.price), 0) as revenue,
            COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)), 0) as duration_minutes
            FROM booking_items bi JOIN bookings b ON bi.booking_id = b.id JOIN staff st ON bi.staff_id = st.id
            WHERE $whereClause GROUP BY st.id ORDER BY revenue DESC";
        $stmt = $pdo->prepare($byStaffQuery);
        $stmt->execute($params);
        $byStaff = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $byLocationQuery = "SELECT l.id as location_id, l.name as location_name,
            COUNT(bi.id) as appointments, COALESCE(SUM(bi.price), 0) as revenue,
            COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)), 0) as duration_minutes
            FROM booking_items bi JOIN bookings b ON bi.booking_id = b.id JOIN locations l ON bi.location_id = l.id
            WHERE $whereClause GROUP BY l.id ORDER BY revenue DESC";
        $stmt = $pdo->prepare($byLocationQuery);
        $stmt->execute($params);
        $byLocation = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $byServiceQuery = "SELECT s.id as service_id, s.name as service_name, 
            MAX(sc.name) as category_name,
            COUNT(bi.id) as appointments, COALESCE(SUM(bi.price), 0) as revenue,
            COALESCE(AVG(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)), 0) as avg_duration_minutes
            FROM booking_items bi JOIN bookings b ON bi.booking_id = b.id JOIN services s ON bi.service_id = s.id
            LEFT JOIN service_categories sc ON s.category_id = sc.id
            WHERE $whereClause GROUP BY s.id ORDER BY appointments DESC";
        $stmt = $pdo->prepare($byServiceQuery);
        $stmt->execute($params);
        $byService = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $byDayOfWeekQuery = "SELECT DAYOFWEEK(bi.start_time) as day_of_week,
            COUNT(bi.id) as appointments, COALESCE(SUM(bi.price), 0) as revenue
            FROM booking_items bi JOIN bookings b ON bi.booking_id = b.id
            WHERE $whereClause GROUP BY DAYOFWEEK(bi.start_time) ORDER BY day_of_week";
        $stmt = $pdo->prepare($byDayOfWeekQuery);
        $stmt->execute($params);
        $byDayOfWeek = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $startDt = new \DateTime($startDate);
        $endDt = new \DateTime($endDate);
        $daysDiff = (int) $startDt->diff($endDt)->days + 1;

        if ($daysDiff <= 31) {
            $periodGroupAndSelect = "DATE(bi.start_time)";
            $granularity = 'day';
        } elseif ($daysDiff <= 90) {
            $periodGroupAndSelect = "DATE(DATE_SUB(bi.start_time, INTERVAL WEEKDAY(bi.start_time) DAY))";
            $granularity = 'week';
        } else {
            $periodGroupAndSelect = "DATE_FORMAT(bi.start_time, '%Y-%m-01')";
            $granularity = 'month';
        }

        $byPeriodQuery = "SELECT $periodGroupAndSelect as period_start,
            COUNT(bi.id) as appointments, COALESCE(SUM(bi.price), 0) as revenue,
            COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)), 0) as duration_minutes
            FROM booking_items bi JOIN bookings b ON bi.booking_id = b.id
            WHERE $whereClause GROUP BY $periodGroupAndSelect ORDER BY period_start ASC";
        $stmt = $pdo->prepare($byPeriodQuery);
        $stmt->execute($params);
        $byPeriod = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $byHourQuery = "SELECT HOUR(bi.start_time) as hour,
            COUNT(bi.id) as appointments, COALESCE(SUM(bi.price), 0) as revenue
            FROM booking_items bi JOIN bookings b ON bi.booking_id = b.id
            WHERE $whereClause GROUP BY HOUR(bi.start_time) ORDER BY hour ASC";
        $stmt = $pdo->prepare($byHourQuery);
        $stmt->execute($params);
        $byHour = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $summary['total_appointments'] = (int) $summary['total_appointments'];
        $summary['total_bookings'] = (int) $summary['total_bookings'];
        $summary['total_revenue'] = (float) $summary['total_revenue'];
        $summary['total_duration_minutes'] = (int) $summary['total_duration_minutes'];
        $summary['unique_clients'] = (int) $summary['unique_clients'];
        $summary['cancelled_count'] = (int) $summary['cancelled_count'];
        $summary['online_count'] = (int) $summary['online_count'];
        $summary['manual_count'] = (int) $summary['manual_count'];

        // Calculate available hours from staff planning
        $availableMinutes = $this->calculateAvailableMinutes($pdo, $businessId, $startDate, $endDate, $staffIds, $locationIds);
        $summary['available_minutes'] = $availableMinutes;
        $summary['occupancy_percentage'] = $availableMinutes > 0 
            ? round(($summary['total_duration_minutes'] / $availableMinutes) * 100, 1) 
            : 0;

        foreach ($byStaff as &$row) {
            $row['staff_id'] = (int) $row['staff_id'];
            $row['appointments'] = (int) $row['appointments'];
            $row['revenue'] = (float) $row['revenue'];
            $row['duration_minutes'] = (int) $row['duration_minutes'];
        }
        foreach ($byLocation as &$row) {
            $row['location_id'] = (int) $row['location_id'];
            $row['appointments'] = (int) $row['appointments'];
            $row['revenue'] = (float) $row['revenue'];
            $row['duration_minutes'] = (int) $row['duration_minutes'];
        }
        foreach ($byService as &$row) {
            $row['service_id'] = (int) $row['service_id'];
            $row['appointments'] = (int) $row['appointments'];
            $row['revenue'] = (float) $row['revenue'];
            $row['avg_duration_minutes'] = (int) round((float) $row['avg_duration_minutes']);
        }
        foreach ($byDayOfWeek as &$row) {
            $row['day_of_week'] = (int) $row['day_of_week'];
            $row['appointments'] = (int) $row['appointments'];
            $row['revenue'] = (float) $row['revenue'];
        }
        foreach ($byPeriod as &$row) {
            $row['appointments'] = (int) $row['appointments'];
            $row['revenue'] = (float) $row['revenue'];
            $row['duration_minutes'] = (int) $row['duration_minutes'];
        }
        foreach ($byHour as &$row) {
            $row['hour'] = (int) $row['hour'];
            $row['appointments'] = (int) $row['appointments'];
            $row['revenue'] = (float) $row['revenue'];
        }

        return [
            'summary' => $summary,
            'by_staff' => $byStaff,
            'by_location' => $byLocation,
            'by_service' => $byService,
            'by_day_of_week' => $byDayOfWeek,
            'by_period' => ['granularity' => $granularity, 'data' => $byPeriod],
            'by_hour' => $byHour,
            'filters' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
                'location_ids' => array_map('intval', $locationIds),
                'staff_ids' => array_map('intval', $staffIds),
                'service_ids' => array_map('intval', $serviceIds),
                'statuses' => $statuses,
            ],
        ];
    }

    /**
     * Calculate total available minutes from staff planning for the given period.
     */
    private function calculateAvailableMinutes(PDO $pdo, int $businessId, string $startDate, string $endDate, array $staffIds, array $locationIds): int
    {
        $logFile = __DIR__ . '/../../../logs/debug.log';
        try {
            file_put_contents($logFile, date('Y-m-d H:i:s') . " calculateAvailableMinutes: businessId=$businessId, startDate=$startDate, endDate=$endDate\n", FILE_APPEND);
            
            // Get all staff for this business (filtered by staff if specified)
            // Note: staff has business_id directly, not location_id
            $staffQuery = "SELECT DISTINCT s.id FROM staff s 
                WHERE s.business_id = ? AND s.is_active = 1";
            $staffParams = [$businessId];

            // locationIds filter is ignored since staff doesn't have location_id

            if (!empty($staffIds)) {
                $staffIds = array_map('intval', $staffIds);
                $placeholders = implode(',', array_fill(0, count($staffIds), '?'));
                $staffQuery .= " AND s.id IN ($placeholders)";
                $staffParams = array_merge($staffParams, $staffIds);
            }

            $stmt = $pdo->prepare($staffQuery);
            $stmt->execute($staffParams);
            $staffList = $stmt->fetchAll(PDO::FETCH_COLUMN);

            file_put_contents($logFile, date('Y-m-d H:i:s') . " calculateAvailableMinutes: found " . count($staffList) . " staff: " . implode(",", $staffList) . "\n", FILE_APPEND);

            if (empty($staffList)) {
                file_put_contents($logFile, date('Y-m-d H:i:s') . " calculateAvailableMinutes: no staff found, returning 0\n", FILE_APPEND);
                return 0;
            }

            $totalMinutes = 0;
            $start = new \DateTime($startDate);
            $end = new \DateTime($endDate);
            $end->modify('+1 day'); // Include end date

            $interval = new \DateInterval('P1D');
            $period = new \DatePeriod($start, $interval, $end);

            foreach ($staffList as $staffId) {
                // Get all plannings for this staff
                $planningQuery = "SELECT sp.id, sp.type, sp.valid_from, sp.valid_to 
                    FROM staff_planning sp 
                    WHERE sp.staff_id = ? 
                    ORDER BY sp.valid_from DESC";
                $stmt = $pdo->prepare($planningQuery);
                $stmt->execute([$staffId]);
                $plannings = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if (empty($plannings)) {
                    continue; // No planning for this staff
                }

                // Get all exceptions for this staff in the period
                $exceptionQuery = "SELECT exception_date, start_time, end_time, exception_type 
                    FROM staff_availability_exceptions 
                    WHERE staff_id = ? AND exception_date BETWEEN ? AND ?";
                $stmt = $pdo->prepare($exceptionQuery);
                $stmt->execute([$staffId, $startDate, $endDate]);
                $exceptions = [];
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $exc) {
                    $exceptions[$exc['exception_date']][] = $exc;
                }

                foreach ($period as $date) {
                    $dateStr = $date->format('Y-m-d');
                    $dayOfWeek = (int) $date->format('N'); // 1=Monday, 7=Sunday

                    // Check if there's an exception for this date
                    if (isset($exceptions[$dateStr])) {
                        foreach ($exceptions[$dateStr] as $exc) {
                            if ($exc['exception_type'] === 'available' && $exc['start_time'] && $exc['end_time']) {
                                // Working exception - add these hours
                                $excStart = new \DateTime($exc['start_time']);
                                $excEnd = new \DateTime($exc['end_time']);
                                $totalMinutes += (int) (($excEnd->getTimestamp() - $excStart->getTimestamp()) / 60);
                            }
                            // If unavailable or full day off, don't add hours from planning
                        }
                        continue; // Exception overrides planning
                    }

                    // Find valid planning for this date
                    $validPlanning = null;
                    foreach ($plannings as $planning) {
                        $validFrom = $planning['valid_from'];
                        $validTo = $planning['valid_to'];

                        if ($dateStr >= $validFrom && ($validTo === null || $dateStr <= $validTo)) {
                            $validPlanning = $planning;
                            break;
                        }
                    }

                    if (!$validPlanning) {
                        continue; // No valid planning for this date
                    }

                    // Determine week label (A or B for biweekly)
                    $weekLabel = 'A';
                    if ($validPlanning['type'] === 'biweekly') {
                        $validFromDate = new \DateTime($validPlanning['valid_from']);
                        $weeksDiff = (int) floor($validFromDate->diff($date)->days / 7);
                        $weekLabel = ($weeksDiff % 2 === 0) ? 'A' : 'B';
                    }

                    // Get template for this day
                    $templateQuery = "SELECT slots FROM staff_planning_week_template 
                        WHERE staff_planning_id = ? AND week_label = ? AND day_of_week = ?";
                    $stmt = $pdo->prepare($templateQuery);
                    $stmt->execute([$validPlanning['id'], $weekLabel, $dayOfWeek]);
                    $template = $stmt->fetch(PDO::FETCH_ASSOC);

                    if ($template && $template['slots']) {
                        $slots = json_decode($template['slots'], true);
                        if (is_array($slots)) {
                            // Slots are indices (each slot = 15 minutes)
                            // E.g., slot 36 = 09:00, slot 40 = 10:00
                            $totalMinutes += count($slots) * 15;
                        }
                    }
                }
            }

            file_put_contents($logFile, date('Y-m-d H:i:s') . " calculateAvailableMinutes: returning totalMinutes=$totalMinutes\n", FILE_APPEND);
            return $totalMinutes;
        } catch (\Exception $e) {
            // Log error but don't fail the entire report
            file_put_contents($logFile, date('Y-m-d H:i:s') . " calculateAvailableMinutes error: " . $e->getMessage() . " at " . $e->getFile() . ":" . $e->getLine() . "\n", FILE_APPEND);
            return 0;
        }
    }
}
