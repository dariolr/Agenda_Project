<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

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
                'display_name' => $s['display_name'],
                'color' => $s['color_hex'],
                'avatar_url' => $s['avatar_url'] ?? null,
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
        if ($locationId !== null && !$this->staffRepository->belongsToLocation($id, $locationId)) {
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
     * List all staff members for a business (admin view - all staff, not just bookable)
     */
    public function indexByBusiness(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        // Check user has access to business
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

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
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

        $staff = $this->staffRepository->findById($staffId);
        $staff['location_ids'] = $this->staffRepository->getLocationIds($staffId);

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

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, (int) $staff['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();

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
        if (isset($body['location_ids']) && is_array($body['location_ids'])) {
            $this->staffRepository->setLocations($staffId, array_map('intval', $body['location_ids']));
        }

        $updated = $this->staffRepository->findById($staffId);
        $updated['location_ids'] = $this->staffRepository->getLocationIds($staffId);

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

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, (int) $staff['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
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
            'display_name' => $s['display_name'] ?? trim($s['name'] . ' ' . substr($s['surname'] ?? '', 0, 1) . '.'),
            'color_hex' => $s['color_hex'],
            'avatar_url' => $s['avatar_url'] ?? null,
            'is_bookable_online' => (bool) ($s['is_bookable_online'] ?? true),
            'sort_order' => (int) ($s['sort_order'] ?? 0),
            'location_ids' => $s['location_ids'] ?? [],
        ];
    }
}
