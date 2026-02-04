<?php

declare(strict_types=1);

namespace Agenda\Http\Middleware;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Middleware that validates user access to a specific location.
 * 
 * Must run AFTER LocationContextMiddleware (which sets location_id and business_id).
 * 
 * Logic:
 * - Superadmin: Always allowed
 * - scope_type=business: Allowed (access to all locations)
 * - scope_type=locations: Check if location_id is in allowed list
 * - No access: HTTP 403
 * 
 * Sets in request attributes:
 * - allowed_location_ids: array|null (null = all locations)
 */
final class LocationAccessMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    public function handle(Request $request): ?Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        // Get location_id and business_id from prior middleware
        $locationId = $request->getAttribute('location_id');
        $businessId = $request->getAttribute('business_id');

        if ($locationId === null || $businessId === null) {
            // This middleware requires LocationContextMiddleware to run first
            return Response::validationError(
                'Location context not available',
                $request->traceId
            );
        }

        // Superadmin always has access
        if ($this->userRepo->isSuperadmin($userId)) {
            $request->setAttribute('allowed_location_ids', null);
            return null;
        }

        // Check if user has access to this specific location
        if (!$this->businessUserRepo->hasLocationAccess($userId, $businessId, $locationId)) {
            return Response::forbidden(
                'You do not have access to this location',
                $request->traceId
            );
        }

        // Store allowed locations for downstream use (e.g., reports filtering)
        $allowedLocationIds = $this->businessUserRepo->getAllowedLocationIds($userId, $businessId);
        $request->setAttribute('allowed_location_ids', $allowedLocationIds);

        return null;
    }
}
