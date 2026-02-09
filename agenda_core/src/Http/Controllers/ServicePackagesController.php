<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\ServicePackageRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class ServicePackagesController
{
    public function __construct(
        private readonly ServicePackageRepository $packageRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * Check if authenticated user has services permission in the given business.
     */
    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_services', false);
    }

    /**
     * GET /v1/locations/{location_id}/service-packages
     * Public endpoint - returns packages for a location.
     */
    public function index(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $packages = $this->packageRepo->findByLocationId($locationId);

        return Response::success([
            'location_id' => $locationId,
            'packages' => $packages,
        ]);
    }

    /**
     * GET /v1/locations/{location_id}/service-packages/{id}/expand
     * Public endpoint - expands a package to ordered service IDs and totals.
     */
    public function expand(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $packageId = (int) $request->getRouteParam('id');

        $expanded = $this->packageRepo->getExpanded($packageId, $locationId);
        if ($expanded === null) {
            return Response::notFound('Package not found', $request->traceId);
        }

        if (!$expanded['is_active']) {
            return Response::error('Package is not active', 'package_inactive', 409, $request->traceId);
        }

        if ($expanded['is_broken']) {
            return Response::conflict('package_broken', 'Package contains unavailable services', $request->traceId);
        }

        return Response::success($expanded);
    }

    /**
     * POST /v1/locations/{location_id}/service-packages
     * Create a new service package. Auth required.
     */
    public function store(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $businessId = $request->getAttribute('business_id');

        if ($businessId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        if (!$this->hasBusinessAccess($request, (int) $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody();
        $name = trim((string) ($body['name'] ?? ''));
        $categoryId = (int) ($body['category_id'] ?? 0);
        $serviceIds = $this->normalizeServiceIds($body['service_ids'] ?? null);

        if ($name === '') {
            return Response::error('Name is required', 'validation_error', 422, $request->traceId);
        }

        if ($categoryId <= 0) {
            return Response::error('category_id is required', 'validation_error', 422, $request->traceId);
        }

        if (empty($serviceIds)) {
            return Response::error('service_ids is required', 'validation_error', 422, $request->traceId);
        }

        if (!$this->packageRepo->validateCategory($categoryId, (int) $businessId)) {
            return Response::error('Invalid category', 'invalid_category', 400, $request->traceId);
        }

        if (!$this->packageRepo->validateServices($serviceIds, $locationId, (int) $businessId)) {
            return Response::error('One or more services are invalid', 'invalid_service', 400, $request->traceId);
        }

        $packageId = $this->packageRepo->create([
            'business_id' => (int) $businessId,
            'location_id' => $locationId,
            'category_id' => $categoryId,
            'name' => $name,
            'description' => $body['description'] ?? null,
            'override_price' => array_key_exists('override_price', $body) ? $body['override_price'] : null,
            'override_duration_minutes' => array_key_exists('override_duration_minutes', $body)
                ? $body['override_duration_minutes']
                : null,
            'is_active' => isset($body['is_active']) ? (int) (bool) $body['is_active'] : 1,
            'is_broken' => 0,
        ], $serviceIds);

        $created = $this->packageRepo->getDetailedById($packageId, $locationId);

        return Response::created([
            'package' => $created,
        ]);
    }

    /**
     * PUT /v1/locations/{location_id}/service-packages/{id}
     * Update a service package. Auth required.
     */
    public function update(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $packageId = (int) $request->getRouteParam('id');
        $businessId = $request->getAttribute('business_id');

        if ($businessId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        $existing = $this->packageRepo->findById($packageId);
        if (!$existing || (int) $existing['location_id'] !== $locationId) {
            return Response::notFound('Package not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $existing['business_id'])) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody();
        $updateData = [];

        if (array_key_exists('name', $body)) {
            $name = trim((string) $body['name']);
            if ($name === '') {
                return Response::error('Name is required', 'validation_error', 422, $request->traceId);
            }
            $updateData['name'] = $name;
        }

        if (array_key_exists('description', $body)) {
            $updateData['description'] = $body['description'];
        }

        if (array_key_exists('category_id', $body)) {
            $categoryId = (int) $body['category_id'];
            if ($categoryId <= 0) {
                return Response::error('category_id is required', 'validation_error', 422, $request->traceId);
            }
            if (!$this->packageRepo->validateCategory($categoryId, (int) $existing['business_id'])) {
                return Response::error('Invalid category', 'invalid_category', 400, $request->traceId);
            }
            $updateData['category_id'] = $categoryId;
        }

        if (array_key_exists('override_price', $body)) {
            $updateData['override_price'] = $body['override_price'];
        }

        if (array_key_exists('override_duration_minutes', $body)) {
            $updateData['override_duration_minutes'] = $body['override_duration_minutes'];
        }

        if (array_key_exists('is_active', $body)) {
            $updateData['is_active'] = (int) (bool) $body['is_active'];
        }

        $serviceIds = null;
        if (array_key_exists('service_ids', $body)) {
            $serviceIds = $this->normalizeServiceIds($body['service_ids'] ?? null);
            if (empty($serviceIds)) {
                return Response::error('service_ids is required', 'validation_error', 422, $request->traceId);
            }

            if (!$this->packageRepo->validateServices($serviceIds, $locationId, (int) $existing['business_id'])) {
                return Response::error('One or more services are invalid', 'invalid_service', 400, $request->traceId);
            }

            $updateData['is_broken'] = 0;
        }

        if (empty($updateData) && $serviceIds === null) {
            return Response::success(['message' => 'No changes']);
        }

        $this->packageRepo->update($packageId, $updateData, $serviceIds);

        $updated = $this->packageRepo->getDetailedById($packageId, $locationId);

        return Response::success([
            'package' => $updated,
        ]);
    }

    /**
     * DELETE /v1/locations/{location_id}/service-packages/{id}
     * Delete a service package. Auth required.
     */
    public function destroy(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $packageId = (int) $request->getRouteParam('id');

        $existing = $this->packageRepo->findById($packageId);
        if (!$existing || (int) $existing['location_id'] !== $locationId) {
            return Response::notFound('Package not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $existing['business_id'])) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $this->packageRepo->delete($packageId);

        return Response::success(['message' => 'Package deleted successfully']);
    }

    /**
     * POST /v1/service-packages/reorder
     * Batch update sort_order and category_id for multiple packages. Auth required.
     *
     * Payload:
     * {
     *   "packages": [{"id": 1, "category_id": 5, "sort_order": 0}, ...]
     * }
     */
    public function reorder(Request $request): Response
    {
        $body = $request->getBody();
        $packages = $body['packages'] ?? [];

        if (empty($packages) || !is_array($packages)) {
            return Response::error('packages array is required', 'validation_error', 400);
        }

        $firstPackageId = (int) $packages[0]['id'];
        $existing = $this->packageRepo->findById($firstPackageId);
        if (!$existing) {
            return Response::notFound('Package not found', $request->traceId);
        }

        $businessId = (int) $existing['business_id'];

        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $packageIds = array_map(fn($p) => (int) $p['id'], $packages);
        if (!$this->packageRepo->allBelongToSameBusiness($packageIds, $businessId)) {
            return Response::error('All packages must belong to the same business', 'validation_error', 400);
        }

        foreach ($packages as $pkg) {
            $this->packageRepo->updateSortOrder(
                (int) $pkg['id'],
                isset($pkg['category_id']) ? (int) $pkg['category_id'] : null,
                (int) $pkg['sort_order']
            );
        }

        return Response::success(['message' => 'Packages reordered successfully']);
    }

    private function normalizeServiceIds($serviceIds): array
    {
        if (!is_array($serviceIds)) {
            return [];
        }

        $normalized = [];
        $seen = [];

        foreach ($serviceIds as $serviceId) {
            $id = (int) $serviceId;
            if ($id <= 0 || isset($seen[$id])) {
                continue;
            }
            $seen[$id] = true;
            $normalized[] = $id;
        }

        return $normalized;
    }
}
