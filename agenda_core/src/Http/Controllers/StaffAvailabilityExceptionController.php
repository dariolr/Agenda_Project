<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\StaffAvailabilityExceptionRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Controller for staff availability exceptions.
 * 
 * Routes:
 * - GET /v1/staff/{id}/availability-exceptions - Get exceptions for a staff member
 * - POST /v1/staff/{id}/availability-exceptions - Create a new exception
 * - PUT /v1/staff/availability-exceptions/{id} - Update an exception
 * - DELETE /v1/staff/availability-exceptions/{id} - Delete an exception
 * - GET /v1/businesses/{id}/staff/availability-exceptions - Get all exceptions for a business
 */
final class StaffAvailabilityExceptionController
{
    public function __construct(
        private readonly StaffAvailabilityExceptionRepository $exceptionRepo,
        private readonly StaffRepository $staffRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/staff/{id}/availability-exceptions
     * Get exceptions for a staff member.
     * Query params: from_date, to_date (YYYY-MM-DD)
     */
    public function indexForStaff(Request $request): Response
    {
        $staffId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $staff = $this->staffRepo->findById($staffId);
        if (!$staff) {
            return Response::notFound('Staff member not found', $request->traceId);
        }

        // Read-only access: any active operator in the business (viewer included).
        if (!$this->businessUserRepo->hasAccess($userId, (int) $staff['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $fromDate = $request->query['from_date'] ?? null;
        $toDate = $request->query['to_date'] ?? null;

        $exceptions = $this->exceptionRepo->getByStaffId($staffId, $fromDate, $toDate);

        return Response::success([
            'staff_id' => $staffId,
            'exceptions' => $exceptions,
        ]);
    }

    /**
     * GET /v1/businesses/{id}/staff/availability-exceptions
     * Get all exceptions for all staff of a business.
     * Query params: from_date, to_date (YYYY-MM-DD)
     */
    public function indexForBusiness(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        // Read-only access: any active operator in the business (viewer included).
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $fromDate = $request->query['from_date'] ?? null;
        $toDate = $request->query['to_date'] ?? null;

        // Get all staff for business
        $staffList = $this->staffRepo->findByBusinessId($businessId);
        $staffIds = array_map(fn($s) => (int) $s['id'], $staffList);

        // Get exceptions for all staff
        $exceptions = $this->exceptionRepo->getByStaffIds($staffIds, $fromDate, $toDate);

        // Group by staff_id
        $grouped = [];
        foreach ($exceptions as $exc) {
            $sid = $exc['staff_id'];
            if (!isset($grouped[$sid])) {
                $grouped[$sid] = [];
            }
            $grouped[$sid][] = $exc;
        }

        return Response::success([
            'exceptions' => $grouped,
        ]);
    }

    /**
     * POST /v1/staff/{id}/availability-exceptions
     * Create a new exception.
     * 
     * Body:
     * {
     *   "date": "2026-01-15",
     *   "start_time": "09:00",  // optional, null = all day
     *   "end_time": "12:00",    // optional, null = all day
     *   "type": "unavailable",  // "available" or "unavailable"
     *   "reason_code": "vacation",  // optional
     *   "reason": "Ferie"  // optional
     * }
     */
    public function store(Request $request): Response
    {
        $staffId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $staff = $this->staffRepo->findById($staffId);
        if (!$staff) {
            return Response::notFound('Staff member not found', $request->traceId);
        }

        // Write access: can_manage_staff OR scoped manager OR self-staff.
        if (!$this->canEditStaffAvailability((int) $userId, $staff, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();

        // Validate required fields
        if (empty($body['date'])) {
            return Response::error('Date is required', 'validation_error', 400, $request->traceId);
        }

        // Validate date format
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $body['date'])) {
            return Response::error('Invalid date format. Use YYYY-MM-DD', 'validation_error', 400, $request->traceId);
        }

        // Validate type
        $type = $body['type'] ?? 'unavailable';
        if (!in_array($type, ['available', 'unavailable'], true)) {
            return Response::error('Invalid type. Use "available" or "unavailable"', 'validation_error', 400, $request->traceId);
        }

        // Validate time format if provided
        $startTime = $body['start_time'] ?? null;
        $endTime = $body['end_time'] ?? null;

        if ($startTime !== null && !$this->isValidTime($startTime)) {
            return Response::error('Invalid start_time format. Use HH:MM', 'validation_error', 400, $request->traceId);
        }
        if ($endTime !== null && !$this->isValidTime($endTime)) {
            return Response::error('Invalid end_time format. Use HH:MM', 'validation_error', 400, $request->traceId);
        }

        // If one time is provided, both must be
        if (($startTime === null) !== ($endTime === null)) {
            return Response::error('Both start_time and end_time must be provided, or neither (for all-day)', 'validation_error', 400, $request->traceId);
        }

        // Validate time range
        if ($startTime !== null && $endTime !== null && $startTime >= $endTime) {
            return Response::error('start_time must be before end_time', 'validation_error', 400, $request->traceId);
        }

        $exceptionId = $this->exceptionRepo->create([
            'staff_id' => $staffId,
            'date' => $body['date'],
            'start_time' => $startTime,
            'end_time' => $endTime,
            'type' => $type,
            'reason_code' => $body['reason_code'] ?? null,
            'reason' => $body['reason'] ?? null,
        ]);

        $exception = $this->exceptionRepo->findById($exceptionId);

        return Response::created([
            'exception' => $exception,
        ]);
    }

    /**
     * PUT /v1/staff/availability-exceptions/{id}
     * Update an existing exception.
     */
    public function update(Request $request): Response
    {
        $exceptionId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        // Get exception and verify ownership
        $staffId = $this->exceptionRepo->getStaffIdForException($exceptionId);
        if ($staffId === null) {
            return Response::notFound('Exception not found', $request->traceId);
        }

        $staff = $this->staffRepo->findById($staffId);
        if (!$staff) {
            return Response::notFound('Staff member not found', $request->traceId);
        }

        // Write access: can_manage_staff OR scoped manager OR self-staff.
        if (!$this->canEditStaffAvailability((int) $userId, $staff, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();
        $updateData = [];

        if (isset($body['date'])) {
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $body['date'])) {
                return Response::error('Invalid date format. Use YYYY-MM-DD', 'validation_error', 400, $request->traceId);
            }
            $updateData['date'] = $body['date'];
        }

        if (array_key_exists('start_time', $body)) {
            if ($body['start_time'] !== null && !$this->isValidTime($body['start_time'])) {
                return Response::error('Invalid start_time format. Use HH:MM', 'validation_error', 400, $request->traceId);
            }
            $updateData['start_time'] = $body['start_time'];
        }

        if (array_key_exists('end_time', $body)) {
            if ($body['end_time'] !== null && !$this->isValidTime($body['end_time'])) {
                return Response::error('Invalid end_time format. Use HH:MM', 'validation_error', 400, $request->traceId);
            }
            $updateData['end_time'] = $body['end_time'];
        }

        if (isset($body['type'])) {
            if (!in_array($body['type'], ['available', 'unavailable'], true)) {
                return Response::error('Invalid type. Use "available" or "unavailable"', 'validation_error', 400, $request->traceId);
            }
            $updateData['type'] = $body['type'];
        }

        if (array_key_exists('reason_code', $body)) {
            $updateData['reason_code'] = $body['reason_code'];
        }

        if (array_key_exists('reason', $body)) {
            $updateData['reason'] = $body['reason'];
        }

        if (!empty($updateData)) {
            $this->exceptionRepo->update($exceptionId, $updateData);
        }

        $exception = $this->exceptionRepo->findById($exceptionId);

        return Response::success([
            'exception' => $exception,
        ]);
    }

    /**
     * DELETE /v1/staff/availability-exceptions/{id}
     * Delete an exception.
     */
    public function destroy(Request $request): Response
    {
        $exceptionId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        // Get exception and verify ownership
        $staffId = $this->exceptionRepo->getStaffIdForException($exceptionId);
        if ($staffId === null) {
            return Response::notFound('Exception not found', $request->traceId);
        }

        $staff = $this->staffRepo->findById($staffId);
        if (!$staff) {
            return Response::notFound('Staff member not found', $request->traceId);
        }

        // Write access: can_manage_staff OR scoped manager OR self-staff.
        if (!$this->canEditStaffAvailability((int) $userId, $staff, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $this->exceptionRepo->delete($exceptionId);

        return Response::success(['deleted' => true]);
    }

    /**
     * Validate time format HH:MM
     */
    private function isValidTime(string $time): bool
    {
        return preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/', $time) === 1;
    }

    /**
     * Write permissions for staff availability exceptions:
     * - full staff management permission
     * - role=staff for own staff_id
     * - role=manager for staff inside assigned location scope
     */
    private function canEditStaffAvailability(int $userId, array $staff, bool $isSuperadmin): bool
    {
        if ($isSuperadmin) {
            return true;
        }

        $businessId = (int) $staff['business_id'];
        $staffId = (int) $staff['id'];

        if ($this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_staff', false)) {
            return true;
        }

        $businessUser = $this->businessUserRepo->findByUserAndBusiness($userId, $businessId);
        if ($businessUser === null) {
            return false;
        }

        if (($businessUser['role'] ?? null) === 'staff'
            && (int) ($businessUser['staff_id'] ?? 0) === $staffId) {
            return true;
        }

        if (($businessUser['role'] ?? null) === 'manager') {
            if (($businessUser['scope_type'] ?? 'business') === 'business') {
                return true;
            }
            $managerLocationIds = $businessUser['location_ids'] ?? [];
            $staffLocationIds = $this->staffRepo->getLocationIds($staffId);
            return count(array_intersect($staffLocationIds, $managerLocationIds)) > 0;
        }

        return false;
    }
}
