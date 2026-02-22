<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Domain\Helpers\Unicode;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class StaffController
{
    public function __construct(
        private readonly StaffRepository $staffRepository,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly LocationRepository $locationRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/staff?location_id=X
     * Public endpoint - returns staff members for a location.
     */
    public function index(Request $request): Response
    {
        $businessId = $request->getAttribute('business_id');
        $locationId = $request->getAttribute('location_id');

        if ($businessId === null || $locationId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        $staff = $this->staffRepository->findByLocationId($locationId, $businessId);

        return Response::success([
            'staff' => array_map(fn($s) => [
                'id' => (int) $s['id'],
                'name' => $s['name'],
                'surname' => $s['surname'],
                'display_name' => $s['display_name'],
                'color' => $s['color_hex'],
                'avatar_url' => $s['avatar_url'] ?? null,
                'service_ids' => $this->staffRepository->getServiceIds((int) $s['id']),
            ], $staff),
        ], 200);
    }

    /**
     * GET /v1/staff/{id}
     */
    public function show(Request $request, int $id): Response
    {
        $businessId = $request->getAttribute('business_id');
        $locationId = $request->getAttribute('location_id');
        
        $staff = $this->staffRepository->findById($id);

        if ($staff === null || (int) $staff['business_id'] !== $businessId) {
            return Response::error('Staff member not found', 'not_found', 404);
        }

        // Verify staff belongs to this location
        if ($locationId !== null && !$this->staffRepository->belongsToLocation($id, $locationId, false)) {
            return Response::error('Staff member not found', 'not_found', 404);
        }

        // Get services this staff member can perform
        $services = $this->staffRepository->getServicesForStaff($id, $locationId);

        return Response::success([
            'id' => (int) $staff['id'],
            'display_name' => $staff['display_name'],
            'color' => $staff['color_hex'],
            'avatar_url' => $staff['avatar_url'] ?? null,
            'services' => array_map(fn($s) => [
                'id' => (int) $s['id'],
                'name' => $s['name'],
                'duration_minutes' => (int) ($s['duration_minutes'] ?? 0),
                'price' => (float) ($s['price'] ?? 0),
            ], $services),
        ], 200);
    }

    /**
     * GET /v1/businesses/{business_id}/staff
     * List all staff members for a business.
     * Read access is allowed to any operator with business access
     * (including viewer), while write operations remain permission-based.
     */
    public function indexByBusiness(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        // Read-only access: any active operator in the business can read staff list.
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $staff = $this->staffRepository->findByBusinessId($businessId);

        return Response::success([
            'staff' => array_map(fn($s) => $this->formatStaff($s), $staff),
        ]);
    }

    /**
     * POST /v1/businesses/{business_id}/staff
     * Create a new staff member
     */
    public function store(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        // Write access: requires can_manage_staff permission.
        if (!$this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_staff', $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();

        // Validate required fields
        if (empty($body['name'])) {
            return Response::error('Name is required', 'validation_error', 400, $request->traceId);
        }

        $staffId = $this->staffRepository->create($businessId, $body['name'], [
            'surname' => $body['surname'] ?? '',
            'color_hex' => $body['color_hex'] ?? '#3B82F6',
            'avatar_url' => $body['avatar_url'] ?? null,
            'is_bookable_online' => $body['is_bookable_online'] ?? true,
        ]);

        // Assign to locations if provided
        if (!empty($body['location_ids']) && is_array($body['location_ids'])) {
            foreach ($body['location_ids'] as $locId) {
                $this->staffRepository->assignToLocation($staffId, (int) $locId);
            }
        }

        // Assign to services if provided
        if (isset($body['service_ids']) && is_array($body['service_ids'])) {
            $this->staffRepository->setServices($staffId, array_map('intval', $body['service_ids']));
        }

        $staff = $this->staffRepository->findById($staffId);
        $staff['location_ids'] = $this->staffRepository->getLocationIds($staffId);
        $staff['service_ids'] = $this->staffRepository->getServiceIds($staffId);

        return Response::created([
            'staff' => $this->formatStaff($staff),
        ]);
    }

    /**
     * PUT /v1/staff/{id}
     * Update a staff member
     */
    public function update(Request $request): Response
    {
        $staffId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $staff = $this->staffRepository->findById($staffId);
        if (!$staff) {
            return Response::notFound('Staff member not found', $request->traceId);
        }

        $businessId = (int) $staff['business_id'];
        $canManageStaff = $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_staff', $isSuperadmin);
        $isSelfStaffProfile = false;
        $isManagerInScope = false;
        $businessUser = null;
        if (!$isSuperadmin) {
            $businessUser = $this->businessUserRepo->findByUserAndBusiness((int) $userId, $businessId);
            $isSelfStaffProfile = $businessUser !== null
                && ($businessUser['role'] ?? null) === 'staff'
                && (int) ($businessUser['staff_id'] ?? 0) === $staffId;

            if ($businessUser !== null && ($businessUser['role'] ?? null) === 'manager') {
                $staffLocationIds = $this->staffRepository->getLocationIds($staffId);
                if (($businessUser['scope_type'] ?? 'business') === 'business') {
                    $isManagerInScope = true;
                } else {
                    $managerLocationIds = $businessUser['location_ids'] ?? [];
                    $isManagerInScope = count(array_intersect($staffLocationIds, $managerLocationIds)) > 0;
                }
            }
        }

        // Write access: requires can_manage_staff OR scoped manager OR self-profile edit for role=staff.
        if (!$canManageStaff && !$isSelfStaffProfile && !$isManagerInScope) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();

        // Scoped manager/self staff edit: limit editable fields to profile/services only.
        if (($isSelfStaffProfile || $isManagerInScope) && !$canManageStaff) {
            $allowedSelfFields = ['name', 'surname', 'color_hex', 'avatar_url', 'service_ids'];
            $body = array_intersect_key($body, array_flip($allowedSelfFields));
        }

        $updateData = [];
        if (isset($body['name'])) $updateData['name'] = $body['name'];
        if (isset($body['surname'])) $updateData['surname'] = $body['surname'];
        if (isset($body['color_hex'])) $updateData['color_hex'] = $body['color_hex'];
        if (isset($body['avatar_url'])) $updateData['avatar_url'] = $body['avatar_url'];
        if (isset($body['is_bookable_online'])) $updateData['is_bookable_online'] = $body['is_bookable_online'] ? 1 : 0;
        if (isset($body['sort_order'])) $updateData['sort_order'] = (int) $body['sort_order'];

        if (!empty($updateData)) {
            $this->staffRepository->update($staffId, $updateData);
        }

        // Update locations if provided
        if ($canManageStaff && isset($body['location_ids']) && is_array($body['location_ids'])) {
            $this->staffRepository->setLocations($staffId, array_map('intval', $body['location_ids']));
        }

        // Update services if provided
        if (($canManageStaff || $isSelfStaffProfile || $isManagerInScope) && isset($body['service_ids']) && is_array($body['service_ids'])) {
            $this->staffRepository->setServices($staffId, array_map('intval', $body['service_ids']));
        }

        $updated = $this->staffRepository->findById($staffId);
        $updated['location_ids'] = $this->staffRepository->getLocationIds($staffId);
        $updated['service_ids'] = $this->staffRepository->getServiceIds($staffId);

        return Response::success([
            'staff' => $this->formatStaff($updated),
        ]);
    }

    /**
     * DELETE /v1/staff/{id}
     * Soft delete a staff member
     */
    public function destroy(Request $request): Response
    {
        $staffId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $staff = $this->staffRepository->findById($staffId);
        if (!$staff) {
            return Response::notFound('Staff member not found', $request->traceId);
        }

        $businessId = (int) $staff['business_id'];
        $canManageStaff = $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_staff', $isSuperadmin);

        // Check user has access to business
        if (!$canManageStaff) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        // A staff operator cannot delete their own staff profile.
        if (!$isSuperadmin) {
            $businessUser = $this->businessUserRepo->findByUserAndBusiness((int) $userId, $businessId);
            $isSelfStaffProfile = $businessUser !== null
                && ($businessUser['role'] ?? null) === 'staff'
                && (int) ($businessUser['staff_id'] ?? 0) === $staffId;
            if ($isSelfStaffProfile) {
                return Response::error('You cannot delete your own staff profile', 'forbidden', 403, $request->traceId);
            }
        }

        $this->staffRepository->delete($staffId);

        return Response::success(['deleted' => true]);
    }

    /**
     * Format staff for API response
     */
    private function formatStaff(array $s): array
    {
        return [
            'id' => (int) $s['id'],
            'business_id' => (int) $s['business_id'],
            'name' => $s['name'],
            'surname' => $s['surname'] ?? '',
            'display_name' => $s['display_name'] ?? trim(
                $s['name'] . ' ' . Unicode::firstCharacter((string) ($s['surname'] ?? '')) . '.'
            ),
            'color_hex' => $s['color_hex'],
            'avatar_url' => $s['avatar_url'] ?? null,
            'is_bookable_online' => (bool) ($s['is_bookable_online'] ?? true),
            'sort_order' => (int) ($s['sort_order'] ?? 0),
            'location_ids' => $s['location_ids'] ?? [],
            'service_ids' => $s['service_ids'] ?? [],
        ];
    }

    /**
     * POST /v1/staff/reorder
     * Batch update sort_order for multiple staff members.
     * Body: { "staff": [{ "id": 1, "sort_order": 0 }, { "id": 2, "sort_order": 1 }] }
     */
    public function reorder(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $body = $request->getBody();
        $staffList = $body['staff'] ?? [];

        if (empty($staffList) || !is_array($staffList)) {
            return Response::error('staff array is required', 'validation_error', 400, $request->traceId);
        }

        // Validate structure
        foreach ($staffList as $item) {
            if (!isset($item['id']) || !isset($item['sort_order'])) {
                return Response::error('Each item must have id and sort_order', 'validation_error', 400, $request->traceId);
            }
        }

        // Check all staff belong to same business
        $staffIds = array_map(fn($s) => (int) $s['id'], $staffList);
        $businessId = $this->staffRepository->allBelongToSameBusiness($staffIds);

        if ($businessId === null) {
            return Response::error('Staff members must belong to the same business', 'validation_error', 400, $request->traceId);
        }

        // Check user has access to this business
        if (!$this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_staff', $isSuperadmin)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        // Perform batch update
        $this->staffRepository->batchUpdateSortOrder($staffList);

        return Response::success(['updated' => count($staffList)]);
    }

}
