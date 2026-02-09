<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\ServiceVariantResourceRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Controller for service variant resource requirements.
 * Manages the M:N relationship between service variants and resources.
 * 
 * Routes:
 * - GET /v1/service-variants/{id}/resources - Get resource requirements for a variant
 * - PUT /v1/service-variants/{id}/resources - Set resource requirements (replace all)
 * - POST /v1/service-variants/{id}/resources - Add a resource requirement
 * - DELETE /v1/service-variants/{id}/resources/{resource_id} - Remove a resource requirement
 */
final class ServiceVariantResourceController
{
    public function __construct(
        private readonly ServiceVariantResourceRepository $variantResourceRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * Check if authenticated user has services permission in the business.
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
     * GET /v1/service-variants/{id}/resources
     * Get all resource requirements for a service variant.
     */
    public function index(Request $request): Response
    {
        $variantId = (int) $request->getRouteParam('id');

        // Get variant details for authorization
        $variantDetails = $this->variantResourceRepo->getVariantDetails($variantId);
        if (!$variantDetails) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $variantDetails['business_id'])) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        $requirements = $this->variantResourceRepo->findByVariantId($variantId);

        return Response::success([
            'service_variant_id' => $variantId,
            'resource_requirements' => array_map(fn($req) => [
                'id' => (int) $req['id'],
                'resource_id' => (int) $req['resource_id'],
                'resource_name' => $req['resource_name'],
                'quantity' => (int) $req['quantity'],
                'resource_total_quantity' => (int) $req['resource_total_quantity'],
            ], $requirements),
        ]);
    }

    /**
     * PUT /v1/service-variants/{id}/resources
     * Set resource requirements for a service variant (replace all).
     * 
     * Body: { "resources": [{ "resource_id": 1, "quantity": 1 }, ...] }
     */
    public function update(Request $request): Response
    {
        $variantId = (int) $request->getRouteParam('id');

        // Get variant details for authorization
        $variantDetails = $this->variantResourceRepo->getVariantDetails($variantId);
        if (!$variantDetails) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $variantDetails['business_id'])) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        $body = $request->getBody();
        $resources = $body['resources'] ?? [];

        // Validate resources array
        if (!is_array($resources)) {
            return Response::error('resources must be an array', 'validation_error', 400, $request->traceId);
        }

        // Extract resource_ids and validate structure
        $resourceIds = [];
        $requirements = [];
        foreach ($resources as $idx => $res) {
            if (!isset($res['resource_id'])) {
                return Response::error("resources[$idx].resource_id is required", 'validation_error', 400, $request->traceId);
            }
            $resourceId = (int) $res['resource_id'];
            $quantity = (int) ($res['quantity'] ?? 1);
            if ($quantity < 1) {
                $quantity = 1;
            }
            $resourceIds[] = $resourceId;
            $requirements[] = [
                'resource_id' => $resourceId,
                'quantity' => $quantity,
            ];
        }

        // Validate all resources belong to the same location as the variant
        if (!empty($resourceIds) && !$this->variantResourceRepo->validateResourcesForVariant($variantId, $resourceIds)) {
            return Response::error(
                'All resources must belong to the same location as the service',
                'validation_error',
                400,
                $request->traceId
            );
        }

        // Set requirements (replace all)
        $this->variantResourceRepo->setRequirements($variantId, $requirements);

        // Return updated list
        $updatedRequirements = $this->variantResourceRepo->findByVariantId($variantId);

        return Response::success([
            'service_variant_id' => $variantId,
            'resource_requirements' => array_map(fn($req) => [
                'id' => (int) $req['id'],
                'resource_id' => (int) $req['resource_id'],
                'resource_name' => $req['resource_name'],
                'quantity' => (int) $req['quantity'],
                'resource_total_quantity' => (int) $req['resource_total_quantity'],
            ], $updatedRequirements),
        ]);
    }

    /**
     * POST /v1/service-variants/{id}/resources
     * Add a single resource requirement.
     * 
     * Body: { "resource_id": 1, "quantity": 1 }
     */
    public function store(Request $request): Response
    {
        $variantId = (int) $request->getRouteParam('id');

        // Get variant details for authorization
        $variantDetails = $this->variantResourceRepo->getVariantDetails($variantId);
        if (!$variantDetails) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $variantDetails['business_id'])) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        $body = $request->getBody();

        if (!isset($body['resource_id'])) {
            return Response::error('resource_id is required', 'validation_error', 400, $request->traceId);
        }

        $resourceId = (int) $body['resource_id'];
        $quantity = (int) ($body['quantity'] ?? 1);
        if ($quantity < 1) {
            $quantity = 1;
        }

        // Validate resource belongs to same location
        if (!$this->variantResourceRepo->validateResourcesForVariant($variantId, [$resourceId])) {
            return Response::error(
                'Resource must belong to the same location as the service',
                'validation_error',
                400,
                $request->traceId
            );
        }

        $this->variantResourceRepo->addRequirement($variantId, $resourceId, $quantity);

        $requirements = $this->variantResourceRepo->findByVariantId($variantId);

        return Response::created([
            'service_variant_id' => $variantId,
            'resource_requirements' => array_map(fn($req) => [
                'id' => (int) $req['id'],
                'resource_id' => (int) $req['resource_id'],
                'resource_name' => $req['resource_name'],
                'quantity' => (int) $req['quantity'],
                'resource_total_quantity' => (int) $req['resource_total_quantity'],
            ], $requirements),
        ]);
    }

    /**
     * DELETE /v1/service-variants/{id}/resources/{resource_id}
     * Remove a single resource requirement.
     */
    public function destroy(Request $request): Response
    {
        $variantId = (int) $request->getRouteParam('id');
        $resourceId = (int) $request->getRouteParam('resource_id');

        // Get variant details for authorization
        $variantDetails = $this->variantResourceRepo->getVariantDetails($variantId);
        if (!$variantDetails) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $variantDetails['business_id'])) {
            return Response::notFound('Service variant not found', $request->traceId);
        }

        $this->variantResourceRepo->removeRequirement($variantId, $resourceId);

        return Response::success(['message' => 'Resource requirement removed']);
    }

    /**
     * GET /v1/resources/{id}/services
     * Get all services that require this resource.
     */
    public function servicesByResource(Request $request): Response
    {
        $resourceId = (int) $request->getRouteParam('id');

        // Get resource business for authorization
        $businessId = $this->variantResourceRepo->getBusinessIdForResource($resourceId);
        if ($businessId === null) {
            return Response::notFound('Resource not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Resource not found', $request->traceId);
        }

        $services = $this->variantResourceRepo->findVariantsByResourceId($resourceId);

        return Response::success([
            'resource_id' => $resourceId,
            'services' => array_map(fn($s) => [
                'service_variant_id' => (int) $s['service_variant_id'],
                'service_id' => (int) $s['service_id'],
                'service_name' => $s['service_name'],
                'category_id' => $s['category_id'] ? (int) $s['category_id'] : null,
                'category_name' => $s['category_name'],
                'quantity' => (int) $s['quantity'],
            ], $services),
        ]);
    }

    /**
     * PUT /v1/resources/{id}/services
     * Set services that require this resource (replace all).
     * 
     * Body: { "services": [{ "service_variant_id": 1, "quantity": 1 }, ...] }
     */
    public function updateServicesByResource(Request $request): Response
    {
        $resourceId = (int) $request->getRouteParam('id');

        // Get resource business for authorization
        $businessId = $this->variantResourceRepo->getBusinessIdForResource($resourceId);
        if ($businessId === null) {
            return Response::notFound('Resource not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Resource not found', $request->traceId);
        }

        $body = $request->getBody();
        $services = $body['services'] ?? [];

        // Validate services array
        if (!is_array($services)) {
            return Response::error('services must be an array', 'validation_error', 400, $request->traceId);
        }

        // Extract variant_ids and validate structure
        $variantIds = [];
        $requirements = [];
        foreach ($services as $idx => $svc) {
            if (!isset($svc['service_variant_id'])) {
                return Response::error("services[$idx].service_variant_id is required", 'validation_error', 400, $request->traceId);
            }
            $variantId = (int) $svc['service_variant_id'];
            $quantity = (int) ($svc['quantity'] ?? 1);
            if ($quantity < 1) {
                $quantity = 1;
            }
            $variantIds[] = $variantId;
            $requirements[] = [
                'service_variant_id' => $variantId,
                'quantity' => $quantity,
            ];
        }

        // Validate all variants belong to the same location as the resource
        if (!empty($variantIds) && !$this->variantResourceRepo->validateVariantsForResource($resourceId, $variantIds)) {
            return Response::error(
                'All services must belong to the same location as the resource',
                'validation_error',
                400,
                $request->traceId
            );
        }

        // Set variants for resource (replace all)
        $this->variantResourceRepo->setVariantsForResource($resourceId, $requirements);

        // Return updated list
        $updatedServices = $this->variantResourceRepo->findVariantsByResourceId($resourceId);

        return Response::success([
            'resource_id' => $resourceId,
            'services' => array_map(fn($s) => [
                'service_variant_id' => (int) $s['service_variant_id'],
                'service_id' => (int) $s['service_id'],
                'service_name' => $s['service_name'],
                'category_id' => $s['category_id'] ? (int) $s['category_id'] : null,
                'category_name' => $s['category_name'],
                'quantity' => (int) $s['quantity'],
            ], $updatedServices),
        ]);
    }
}
