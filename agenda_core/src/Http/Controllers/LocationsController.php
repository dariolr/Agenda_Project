<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class LocationsController
{
    public function __construct(
        private readonly LocationRepository $locationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * Check if authenticated user has access to the given business.
     */
    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        // Superadmin has access to all businesses
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        // Normal user: check business_users table
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    /**
     * GET /v1/businesses/{business_id}/locations
     * List all locations for a business (authenticated - includes inactive)
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        // For authenticated users (gestionale), show ALL locations including inactive
        $locations = $this->locationRepo->findByBusinessId($businessId, includeInactive: true);

        return Response::success([
            'data' => array_map(fn($l) => $this->formatLocation($l), $locations),
        ]);
    }

    /**
     * GET /v1/businesses/{business_id}/locations/public
     * List all locations for a business (public - for booking flow, only active)
     */
    public function indexPublic(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');

        if ($businessId <= 0) {
            return Response::error('Invalid business_id', 'validation_error', 400, $request->traceId);
        }

        // For public (booking), show only active locations
        $locations = $this->locationRepo->findByBusinessId($businessId, includeInactive: false);

        return Response::success([
            'data' => array_map(fn($l) => $this->formatLocationPublic($l), $locations),
        ]);
    }

    /**
     * GET /v1/locations/{id}
     * Get a single location by ID
     */
    public function show(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('id');

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        // Authorization check
        $businessId = (int) $location['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Location not found', $request->traceId);
        }

        return Response::success($this->formatLocation($location));;
    }

    private function formatLocation(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'name' => $row['name'],
            'address' => $row['address'],
            'city' => $row['city'],
            'region' => $row['region'],
            'country' => $row['country'],
            'phone' => $row['phone'],
            'email' => $row['email'],
            'latitude' => $row['latitude'] ? (float) $row['latitude'] : null,
            'longitude' => $row['longitude'] ? (float) $row['longitude'] : null,
            'currency' => $row['currency'],
            'timezone' => $row['timezone'] ?? 'Europe/Rome',
            'min_booking_notice_hours' => (int) ($row['min_booking_notice_hours'] ?? 1),
            'max_booking_advance_days' => (int) ($row['max_booking_advance_days'] ?? 90),
            'allow_customer_choose_staff' => (bool) ($row['allow_customer_choose_staff'] ?? false),
            'is_default' => (bool) $row['is_default'],
            'sort_order' => (int) ($row['sort_order'] ?? 0),
            'is_active' => (bool) $row['is_active'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
        ];
    }

    /**
     * Format location for public display (limited fields for booking)
     */
    private function formatLocationPublic(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'name' => $row['name'],
            'address' => $row['address'],
            'city' => $row['city'],
            'phone' => $row['phone'],
            'timezone' => $row['timezone'] ?? 'Europe/Rome',
            'min_booking_notice_hours' => (int) ($row['min_booking_notice_hours'] ?? 1),
            'max_booking_advance_days' => (int) ($row['max_booking_advance_days'] ?? 90),
            'allow_customer_choose_staff' => (bool) ($row['allow_customer_choose_staff'] ?? false),
            'is_default' => (bool) $row['is_default'],
        ];
    }

    /**
     * POST /v1/businesses/{business_id}/locations
     * Create a new location for a business
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

        $locationId = $this->locationRepo->create($businessId, $body['name'], [
            'address' => $body['address'] ?? null,
            'phone' => $body['phone'] ?? null,
            'email' => $body['email'] ?? null,
            'timezone' => $body['timezone'] ?? 'Europe/Rome',
            'min_booking_notice_hours' => $body['min_booking_notice_hours'] ?? 1,
            'max_booking_advance_days' => $body['max_booking_advance_days'] ?? 90,
            'allow_customer_choose_staff' => $body['allow_customer_choose_staff'] ?? false,
            'is_active' => $body['is_active'] ?? true,
        ]);

        $location = $this->locationRepo->findById($locationId);

        return Response::created([
            'location' => $this->formatLocation($location),
        ]);
    }

    /**
     * PUT /v1/locations/{id}
     * Update a location
     */
    public function update(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, (int) $location['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();
        
        $updateData = [
            'name' => $body['name'] ?? $location['name'],
            'address' => array_key_exists('address', $body) ? $body['address'] : $location['address'],
            'phone' => array_key_exists('phone', $body) ? $body['phone'] : $location['phone'],
            'email' => array_key_exists('email', $body) ? $body['email'] : $location['email'],
            'timezone' => $body['timezone'] ?? $location['timezone'],
            'is_active' => array_key_exists('is_active', $body) ? $body['is_active'] : $location['is_active'],
        ];

        if (array_key_exists('allow_customer_choose_staff', $body)) {
            $updateData['allow_customer_choose_staff'] = (bool) $body['allow_customer_choose_staff'];
        }

        // Handle booking limits fields
        if (array_key_exists('min_booking_notice_hours', $body)) {
            $updateData['min_booking_notice_hours'] = (int) $body['min_booking_notice_hours'];
        }
        if (array_key_exists('max_booking_advance_days', $body)) {
            $updateData['max_booking_advance_days'] = (int) $body['max_booking_advance_days'];
        }

        $this->locationRepo->update($locationId, $updateData);

        $updated = $this->locationRepo->findById($locationId);

        return Response::success([
            'location' => $this->formatLocation($updated),
        ]);
    }

    /**
     * DELETE /v1/locations/{id}
     * Soft delete a location
     */
    public function destroy(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        $businessId = (int) $location['business_id'];

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        // Cannot delete the only location
        if ($this->locationRepo->isOnlyActiveLocation($locationId, $businessId)) {
            return Response::error('Cannot delete the only location', 'validation_error', 400, $request->traceId);
        }

        $this->locationRepo->delete($locationId);

        return Response::success(['deleted' => true]);
    }

    /**
     * POST /v1/locations/reorder
     * Batch update sort_order for multiple locations.
     * Body: { "locations": [{ "id": 1, "sort_order": 0 }, { "id": 2, "sort_order": 1 }] }
     */
    public function reorder(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $body = $request->getBody();
        $locationList = $body['locations'] ?? [];

        if (empty($locationList) || !is_array($locationList)) {
            return Response::error('locations array is required', 'validation_error', 400, $request->traceId);
        }

        // Validate structure
        foreach ($locationList as $item) {
            if (!isset($item['id']) || !isset($item['sort_order'])) {
                return Response::error('Each item must have id and sort_order', 'validation_error', 400, $request->traceId);
            }
        }

        // Check all locations belong to same business
        $locationIds = array_map(fn($l) => (int) $l['id'], $locationList);
        $businessId = $this->locationRepo->allBelongToSameBusiness($locationIds);

        if ($businessId === null) {
            return Response::error('Locations must belong to the same business', 'validation_error', 400, $request->traceId);
        }

        // Check user has access to this business
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        // Perform batch update
        $this->locationRepo->batchUpdateSortOrder($locationList);

        return Response::success(['updated' => count($locationList)]);
    }
}
