<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\ResourceRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Controller for resources (rooms, stations, equipment).
 * 
 * Routes:
 * - GET /v1/businesses/{business_id}/resources - Get all resources for a business
 * - GET /v1/locations/{location_id}/resources - Get resources for a location
 * - POST /v1/locations/{location_id}/resources - Create a new resource
 * - PUT /v1/resources/{id} - Update a resource
 * - DELETE /v1/resources/{id} - Delete a resource (soft delete)
 */
final class ResourcesController
{
    public function __construct(
        private readonly ResourceRepository $resourceRepo,
        private readonly LocationRepository $locationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/businesses/{business_id}/resources
     * Get all resources for a business.
     */
    public function indexByBusiness(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $resources = $this->resourceRepo->findByBusinessId($businessId);

        return Response::success([
            'resources' => $resources,
        ]);
    }

    /**
     * GET /v1/locations/{location_id}/resources
     * Get resources for a specific location.
     */
    public function indexByLocation(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasAccess($userId, (int) $location['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $resources = $this->resourceRepo->findByLocationId($locationId);

        return Response::success([
            'location_id' => $locationId,
            'resources' => $resources,
        ]);
    }

    /**
     * POST /v1/locations/{location_id}/resources
     * Create a new resource.
     */
    public function store(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasAccess($userId, (int) $location['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();

        // Validate required fields
        if (empty($body['name'])) {
            return Response::error('Name is required', 'validation_error', 400, $request->traceId);
        }

        $resourceId = $this->resourceRepo->create([
            'location_id' => $locationId,
            'name' => $body['name'],
            'type' => $body['type'] ?? null,
            'quantity' => $body['quantity'] ?? 1,
            'note' => $body['note'] ?? null,
            'sort_order' => $body['sort_order'] ?? 0,
        ]);

        $resource = $this->resourceRepo->findById($resourceId);

        return Response::created([
            'resource' => $resource,
        ]);
    }

    /**
     * PUT /v1/resources/{id}
     * Update a resource.
     */
    public function update(Request $request): Response
    {
        $resourceId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $resource = $this->resourceRepo->findById($resourceId);
        if (!$resource) {
            return Response::notFound('Resource not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasAccess($userId, (int) $resource['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();
        $updateData = [];

        foreach (['name', 'type', 'quantity', 'note', 'sort_order'] as $field) {
            if (array_key_exists($field, $body)) {
                $updateData[$field] = $body[$field];
            }
        }

        if (!empty($updateData)) {
            $this->resourceRepo->update($resourceId, $updateData);
        }

        $updated = $this->resourceRepo->findById($resourceId);

        return Response::success([
            'resource' => $updated,
        ]);
    }

    /**
     * DELETE /v1/resources/{id}
     * Soft delete a resource.
     */
    public function destroy(Request $request): Response
    {
        $resourceId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $resource = $this->resourceRepo->findById($resourceId);
        if (!$resource) {
            return Response::notFound('Resource not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasAccess($userId, (int) $resource['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $this->resourceRepo->delete($resourceId);

        return Response::success(['deleted' => true]);
    }
}
