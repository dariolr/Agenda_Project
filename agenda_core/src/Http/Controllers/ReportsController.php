<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\LocationClosureRepository;
use Agenda\Infrastructure\Database\Connection;
use PDO;

final class ReportsController
{
    private ?LocationClosureRepository $locationClosureRepo;
    
    public function __construct(
        private Connection $db,
        private BusinessUserRepository $businessUserRepo,
        private UserRepository $userRepo,
        ?LocationClosureRepository $locationClosureRepo = null
    ) {
        $this->locationClosureRepo = $locationClosureRepo;
    }

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

        // Enforce location restrictions based on user's scope
        $locationIds = $this->enforceLocationScope($userId, $businessId, $locationIds);
        if ($locationIds === false) {
            // User has locations scope but none of their locations were in the filter
            return Response::ok([
                'summary' => [
                    'total_appointments' => 0,
                    'total_bookings' => 0,
                    'total_revenue' => 0,
                    'total_duration_minutes' => 0,
                    'unique_clients' => 0,
                    'cancelled_count' => 0,
                    'online_count' => 0,
                    'manual_count' => 0,
                ],
                'by_staff' => [],
                'by_location' => [],
                'by_service' => [],
                'by_day_of_week' => [],
                'by_period' => [],
                'filters' => [
                    'business_id' => $businessId,
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                    'location_ids' => [],
                ],
            ]);
        }

        $report = $this->buildReport($businessId, $startDate, $endDate, $locationIds, $staffIds, $serviceIds, $statuses);

        return Response::ok($report);
    }

    /**
     * Enforce location scope restrictions.
     * 
     * @param int $userId
     * @param int $businessId
     * @param array $requestedLocationIds Location IDs from request
     * @return array|false Filtered location IDs, or false if no valid locations
     */
    private function enforceLocationScope(int $userId, int $businessId, array $requestedLocationIds): array|false
    {
        // Superadmin has full access
        if ($this->userRepo->isSuperadmin($userId)) {
            return $requestedLocationIds;
        }

        // Get user's business context
        $businessUser = $this->businessUserRepo->findByUserAndBusiness($userId, $businessId);
        if ($businessUser === null) {
            return false;
        }

        // If user has business scope, no filtering needed
        if (($businessUser['scope_type'] ?? 'business') === 'business') {
            return $requestedLocationIds;
        }

        // User has locations scope - enforce restrictions
        $allowedLocations = $businessUser['location_ids'] ?? [];
        if (empty($allowedLocations)) {
            return false;
        }

        if (empty($requestedLocationIds)) {
            // No filter specified - return only allowed locations
            return $allowedLocations;
        }

        // Intersect requested with allowed
        $filteredLocations = array_intersect(
            array_map('intval', $requestedLocationIds),
            array_map('intval', $allowedLocations)
        );

        if (empty($filteredLocations)) {
            return false;
        }

        return array_values($filteredLocations);
    }

    private function hasReportAccess(int $userId, int $businessId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_view_reports', false);
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

    /**
     * GET /v1/reports/work-hours
     * Report on worked hours vs scheduled hours (including time blocks/absences)
     */
    public function workHours(Request $request): Response
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

        // Enforce location restrictions based on user's scope
        $locationIds = $this->enforceLocationScope($userId, $businessId, $locationIds);
        if ($locationIds === false) {
            // User has locations scope but none of their locations were in the filter
            return Response::ok([
                'summary' => [
                    'total_scheduled_minutes' => 0,
                    'total_worked_minutes' => 0,
                    'total_blocked_minutes' => 0,
                    'total_exception_off_minutes' => 0,
                    'total_available_minutes' => 0,
                    'overall_utilization_percentage' => 0,
                ],
                'by_staff' => [],
                'filters' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                    'location_ids' => [],
                    'staff_ids' => [],
                ],
            ]);
        }

        $report = $this->buildWorkHoursReport($businessId, $startDate, $endDate, $locationIds, $staffIds);

        return Response::ok($report);
    }

    /**
     * Build the work hours report for each staff member.
     */
    private function buildWorkHoursReport(int $businessId, string $startDate, string $endDate, array $locationIds, array $staffIds): array
    {
        $pdo = $this->db->getPdo();
        
        // Get all business locations or filtered locations
        $targetLocationIds = [];
        if (!empty($locationIds)) {
            $targetLocationIds = array_map('intval', $locationIds);
        } else {
            // Get all business locations
            $locStmt = $pdo->prepare('SELECT id FROM locations WHERE business_id = ? AND is_active = 1');
            $locStmt->execute([$businessId]);
            $targetLocationIds = array_column($locStmt->fetchAll(PDO::FETCH_ASSOC), 'id');
        }
        
        // Get location closed dates in period (map: locationId => [date => reason])
        $closedDatesByLocation = [];
        if ($this->locationClosureRepo !== null && !empty($targetLocationIds)) {
            $closedDatesByLocation = $this->locationClosureRepo->getClosedDatesForLocationsInRange($targetLocationIds, $startDate, $endDate);
        }

        // Get all staff for this business
        $staffQuery = "SELECT s.id, CONCAT(s.name, ' ', s.surname) as full_name, s.color_hex 
            FROM staff s WHERE s.business_id = ? AND s.is_active = 1";
        $staffParams = [$businessId];

        if (!empty($staffIds)) {
            $staffIds = array_map('intval', $staffIds);
            $placeholders = implode(',', array_fill(0, count($staffIds), '?'));
            $staffQuery .= " AND s.id IN ($placeholders)";
            $staffParams = array_merge($staffParams, $staffIds);
        }

        $staffQuery .= " ORDER BY s.sort_order, s.name";
        $stmt = $pdo->prepare($staffQuery);
        $stmt->execute($staffParams);
        $staffList = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        if (empty($staffList)) {
            return [
                'summary' => [
                    'total_scheduled_minutes' => 0,
                    'total_worked_minutes' => 0,
                    'total_blocked_minutes' => 0,
                    'total_exception_off_minutes' => 0,
                ],
                'by_staff' => [],
                'filters' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                    'location_ids' => array_map('intval', $locationIds),
                    'staff_ids' => array_map('intval', $staffIds),
                ],
            ];
        }

        $start = new \DateTime($startDate);
        $end = new \DateTime($endDate);
        $end->modify('+1 day'); // Include end date
        $interval = new \DateInterval('P1D');
        $period = new \DatePeriod($start, $interval, $end);

        $byStaff = [];
        $totalScheduled = 0;
        $totalWorked = 0;
        $totalBlocked = 0;
        $totalExceptionOff = 0;

        foreach ($staffList as $staff) {
            $staffId = (int) $staff['id'];
            $staffName = $staff['full_name'];
            $staffColor = $staff['color_hex'];

            // Get staff locations (for closure checking)
            $staffLocStmt = $pdo->prepare('SELECT location_id FROM staff_locations WHERE staff_id = ?');
            $staffLocStmt->execute([$staffId]);
            $staffLocationIds = array_column($staffLocStmt->fetchAll(PDO::FETCH_ASSOC), 'location_id');
            
            // If filtering by locations, intersect with staff locations
            if (!empty($locationIds)) {
                $staffLocationIds = array_intersect($staffLocationIds, array_map('intval', $locationIds));
            }

            // Get all plannings for this staff
            $planningQuery = "SELECT sp.id, sp.type, sp.valid_from, sp.valid_to 
                FROM staff_planning sp WHERE sp.staff_id = ? ORDER BY sp.valid_from DESC";
            $stmt = $pdo->prepare($planningQuery);
            $stmt->execute([$staffId]);
            $plannings = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            // Get all exceptions for this staff in the period
            $exceptionQuery = "SELECT exception_date, start_time, end_time, exception_type, reason 
                FROM staff_availability_exceptions 
                WHERE staff_id = ? AND exception_date BETWEEN ? AND ?";
            $stmt = $pdo->prepare($exceptionQuery);
            $stmt->execute([$staffId, $startDate, $endDate]);
            $exceptions = [];
            foreach ($stmt->fetchAll(\PDO::FETCH_ASSOC) as $exc) {
                $exceptions[$exc['exception_date']][] = $exc;
            }

            // Get time blocks for this staff in the period
            $blockQuery = "SELECT tb.start_time, tb.end_time, tb.reason, tb.is_all_day
                FROM time_blocks tb
                JOIN time_block_staff tbs ON tb.id = tbs.time_block_id
                JOIN locations l ON tb.location_id = l.id
                WHERE tbs.staff_id = ? 
                AND l.business_id = ?
                AND DATE(tb.start_time) >= ? AND DATE(tb.end_time) <= ?";
            $blockParams = [$staffId, $businessId, $startDate, $endDate];

            if (!empty($locationIds)) {
                $locationIds = array_map('intval', $locationIds);
                $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
                $blockQuery .= " AND tb.location_id IN ($placeholders)";
                $blockParams = array_merge($blockParams, $locationIds);
            }

            $stmt = $pdo->prepare($blockQuery);
            $stmt->execute($blockParams);
            $blocks = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            // Index blocks by date
            $blocksByDate = [];
            foreach ($blocks as $block) {
                $blockStart = new \DateTime($block['start_time']);
                $blockEnd = new \DateTime($block['end_time']);
                $blockDate = $blockStart->format('Y-m-d');
                
                if (!isset($blocksByDate[$blockDate])) {
                    $blocksByDate[$blockDate] = [];
                }
                $blocksByDate[$blockDate][] = [
                    'start' => $blockStart,
                    'end' => $blockEnd,
                    'reason' => $block['reason'],
                    'is_all_day' => (bool) $block['is_all_day'],
                ];
            }

            // Get worked minutes from booking_items
            $workedQuery = "SELECT COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)), 0) as worked_minutes
                FROM booking_items bi
                JOIN bookings b ON bi.booking_id = b.id
                WHERE bi.staff_id = ? 
                AND b.business_id = ?
                AND DATE(bi.start_time) >= ? AND DATE(bi.start_time) <= ?
                AND b.status IN ('confirmed', 'completed')";
            $workedParams = [$staffId, $businessId, $startDate, $endDate];

            if (!empty($locationIds)) {
                $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
                $workedQuery .= " AND bi.location_id IN ($placeholders)";
                $workedParams = array_merge($workedParams, $locationIds);
            }

            $stmt = $pdo->prepare($workedQuery);
            $stmt->execute($workedParams);
            $workedMinutes = (int) $stmt->fetchColumn();

            $scheduledMinutes = 0;
            $blockedMinutes = 0;
            $exceptionOffMinutes = 0;

            foreach ($period as $date) {
                $dateStr = $date->format('Y-m-d');
                $dayOfWeek = (int) $date->format('N'); // 1=Monday, 7=Sunday

                // Skip if ALL staff locations are closed on this date
                // (staff is only unavailable if all their locations are closed)
                if (!empty($staffLocationIds) && !empty($closedDatesByLocation)) {
                    $allLocationsClosed = true;
                    foreach ($staffLocationIds as $locId) {
                        if (!isset($closedDatesByLocation[$locId][$dateStr])) {
                            $allLocationsClosed = false;
                            break;
                        }
                    }
                    if ($allLocationsClosed) {
                        continue;
                    }
                }

                // Check if there's an unavailable exception for this date (day off)
                if (isset($exceptions[$dateStr])) {
                    $hasUnavailableException = false;
                    $exceptionMinutesToday = 0;
                    
                    foreach ($exceptions[$dateStr] as $exc) {
                        if ($exc['exception_type'] === 'unavailable') {
                            $hasUnavailableException = true;
                            // This is a day off - calculate how many minutes they would have worked
                            $plannedMinutes = $this->getPlannedMinutesForDay($pdo, $plannings, $date, $dayOfWeek);
                            $exceptionMinutesToday += $plannedMinutes;
                        } elseif ($exc['exception_type'] === 'available' && $exc['start_time'] && $exc['end_time']) {
                            // Working exception - add these hours to scheduled
                            $excStart = new \DateTime($exc['start_time']);
                            $excEnd = new \DateTime($exc['end_time']);
                            $scheduledMinutes += (int) (($excEnd->getTimestamp() - $excStart->getTimestamp()) / 60);
                        }
                    }
                    
                    if ($hasUnavailableException) {
                        $exceptionOffMinutes += $exceptionMinutesToday;
                        continue; // Skip normal planning for this day
                    }
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
                $template = $stmt->fetch(\PDO::FETCH_ASSOC);

                if ($template && $template['slots']) {
                    $slots = json_decode($template['slots'], true);
                    if (is_array($slots)) {
                        $plannedMinutesToday = count($slots) * 15;
                        $scheduledMinutes += $plannedMinutesToday;
                    }
                }

                // Calculate blocked minutes for this day from time_blocks
                if (isset($blocksByDate[$dateStr])) {
                    foreach ($blocksByDate[$dateStr] as $block) {
                        if ($block['is_all_day']) {
                            // All day block - count all planned hours as blocked
                            $plannedMinutes = $this->getPlannedMinutesForDay($pdo, $plannings, $date, $dayOfWeek);
                            $blockedMinutes += $plannedMinutes;
                        } else {
                            $blockDuration = (int) (($block['end']->getTimestamp() - $block['start']->getTimestamp()) / 60);
                            $blockedMinutes += $blockDuration;
                        }
                    }
                }
            }

            $byStaff[] = [
                'staff_id' => $staffId,
                'staff_name' => $staffName,
                'staff_color' => $staffColor,
                'scheduled_minutes' => $scheduledMinutes,
                'worked_minutes' => $workedMinutes,
                'blocked_minutes' => $blockedMinutes,
                'exception_off_minutes' => $exceptionOffMinutes,
                'available_minutes' => max(0, $scheduledMinutes - $blockedMinutes),
                'utilization_percentage' => $scheduledMinutes > 0 
                    ? round(($workedMinutes / ($scheduledMinutes - $blockedMinutes)) * 100, 1) 
                    : 0,
            ];

            $totalScheduled += $scheduledMinutes;
            $totalWorked += $workedMinutes;
            $totalBlocked += $blockedMinutes;
            $totalExceptionOff += $exceptionOffMinutes;
        }

        return [
            'summary' => [
                'total_scheduled_minutes' => $totalScheduled,
                'total_worked_minutes' => $totalWorked,
                'total_blocked_minutes' => $totalBlocked,
                'total_exception_off_minutes' => $totalExceptionOff,
                'total_available_minutes' => max(0, $totalScheduled - $totalBlocked),
                'overall_utilization_percentage' => ($totalScheduled - $totalBlocked) > 0
                    ? round(($totalWorked / ($totalScheduled - $totalBlocked)) * 100, 1)
                    : 0,
            ],
            'by_staff' => $byStaff,
            'filters' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
                'location_ids' => array_map('intval', $locationIds),
                'staff_ids' => array_map('intval', $staffIds),
            ],
        ];
    }

    /**
     * Get planned minutes for a specific day from planning templates.
     */
    private function getPlannedMinutesForDay(\PDO $pdo, array $plannings, \DateTime $date, int $dayOfWeek): int
    {
        $dateStr = $date->format('Y-m-d');
        
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
            return 0;
        }

        // Determine week label
        $weekLabel = 'A';
        if ($validPlanning['type'] === 'biweekly') {
            $validFromDate = new \DateTime($validPlanning['valid_from']);
            $weeksDiff = (int) floor($validFromDate->diff($date)->days / 7);
            $weekLabel = ($weeksDiff % 2 === 0) ? 'A' : 'B';
        }

        // Get template
        $templateQuery = "SELECT slots FROM staff_planning_week_template 
            WHERE staff_planning_id = ? AND week_label = ? AND day_of_week = ?";
        $stmt = $pdo->prepare($templateQuery);
        $stmt->execute([$validPlanning['id'], $weekLabel, $dayOfWeek]);
        $template = $stmt->fetch(\PDO::FETCH_ASSOC);

        if ($template && $template['slots']) {
            $slots = json_decode($template['slots'], true);
            if (is_array($slots)) {
                return count($slots) * 15;
            }
        }

        return 0;
    }
}
