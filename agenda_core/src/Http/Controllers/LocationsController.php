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
            'is_default' => (bool) $row['is_default'],
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
        
        $this->locationRepo->update($locationId, [
            'name' => $body['name'] ?? $location['name'],
            'address' => array_key_exists('address', $body) ? $body['address'] : $location['address'],
            'phone' => array_key_exists('phone', $body) ? $body['phone'] : $location['phone'],
            'email' => array_key_exists('email', $body) ? $body['email'] : $location['email'],
            'timezone' => $body['timezone'] ?? $location['timezone'],
            'is_active' => array_key_exists('is_active', $body) ? $body['is_active'] : $location['is_active'],
        ]);

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
}
