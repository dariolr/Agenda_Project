<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\LocationClosureRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Controller for managing closures with multi-location support.
 * 
 * A closure can apply to one or more locations of the same business.
 */
final class LocationClosuresController
{
    public function __construct(
        private LocationClosureRepository $closureRepo,
        private LocationRepository $locationRepo,
        private BusinessUserRepository $businessUserRepo,
        private UserRepository $userRepo
    ) {}

    /**
     * GET /v1/businesses/{business_id}/closures
     * List all closures for a business
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');

        if (!$this->hasBusinessReadAccess($userId, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $closures = $this->closureRepo->findByBusinessId($businessId);

        return Response::ok([
            'closures' => array_map(fn($c) => $this->formatClosure($c), $closures)
        ], $request->traceId);
    }

    /**
     * GET /v1/businesses/{business_id}/closures/in-range
     * List closures within a date range
     */
    public function inRange(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');

        if (!$this->hasBusinessReadAccess($userId, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $startDate = $request->query['start_date'] ?? null;
        $endDate = $request->query['end_date'] ?? null;
        $locationId = isset($request->query['location_id']) ? (int)$request->query['location_id'] : null;

        if (!$startDate || !$endDate) {
            return Response::badRequest('start_date and end_date query parameters are required', $request->traceId);
        }

        // If locationId is specified, filter by that location
        if ($locationId !== null) {
            $closures = $this->closureRepo->findByLocationIdAndDateRange($locationId, $startDate, $endDate);
        } else {
            // Get all closures for the business and filter by date
            $allClosures = $this->closureRepo->findByBusinessId($businessId);
            $closures = array_filter($allClosures, function($c) use ($startDate, $endDate) {
                return $c['start_date'] <= $endDate && $c['end_date'] >= $startDate;
            });
            $closures = array_values($closures);
        }

        return Response::ok([
            'closures' => array_map(fn($c) => $this->formatClosure($c), $closures)
        ], $request->traceId);
    }

    /**
     * POST /v1/businesses/{business_id}/closures
     * Create a new closure
     */
    public function store(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');

        if (!$this->hasBusinessWriteAccess($userId, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $body = $request->body;

        // Validation
        $startDate = $body['start_date'] ?? null;
        $endDate = $body['end_date'] ?? null;
        $reason = $body['reason'] ?? null;
        $locationIds = $body['location_ids'] ?? [];

        if (!$startDate || !$endDate) {
            return Response::badRequest('start_date and end_date are required', $request->traceId);
        }

        if (empty($locationIds) || !is_array($locationIds)) {
            return Response::badRequest('location_ids is required and must be a non-empty array', $request->traceId);
        }

        // Ensure location_ids are integers
        $locationIds = array_map('intval', $locationIds);

        // Validate date format
        if (!$this->isValidDate($startDate) || !$this->isValidDate($endDate)) {
            return Response::badRequest('Invalid date format. Use YYYY-MM-DD', $request->traceId);
        }

        // Validate date range
        if ($startDate > $endDate) {
            return Response::badRequest('start_date must be before or equal to end_date', $request->traceId);
        }

        // Validate all locations belong to this business
        foreach ($locationIds as $locId) {
            $location = $this->locationRepo->findById($locId);
            if (!$location || (int)$location['business_id'] !== $businessId) {
                return Response::badRequest("Location $locId does not belong to this business", $request->traceId);
            }
        }

        // Check for overlaps
        $overlappingLocations = $this->closureRepo->findOverlappingLocations($locationIds, $startDate, $endDate);
        if (!empty($overlappingLocations)) {
            $locationNames = [];
            foreach ($overlappingLocations as $locId) {
                $loc = $this->locationRepo->findById($locId);
                $locationNames[] = $loc['name'] ?? "ID $locId";
            }
            return Response::conflict(
                'This closure period overlaps with existing closures for locations: ' . implode(', ', $locationNames),
                $request->traceId
            );
        }

        $id = $this->closureRepo->create($businessId, $locationIds, $startDate, $endDate, $reason);
        $closure = $this->closureRepo->findById($id);

        return Response::created($this->formatClosure($closure), $request->traceId);
    }

    /**
     * GET /v1/closures/{id}
     * Get a single closure
     */
    public function show(Request $request): Response
    {
        $closureId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');

        $closure = $this->closureRepo->findById($closureId);

        if (!$closure) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        if (!$this->hasBusinessReadAccess($userId, (int)$closure['business_id'])) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        return Response::ok($this->formatClosure($closure), $request->traceId);
    }

    /**
     * PUT /v1/closures/{id}
     * Update a closure
     */
    public function update(Request $request): Response
    {
        $closureId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');

        $closure = $this->closureRepo->findById($closureId);

        if (!$closure) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        $businessId = (int)$closure['business_id'];
        
        if (!$this->hasBusinessWriteAccess($userId, $businessId)) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        $body = $request->body;

        $startDate = $body['start_date'] ?? $closure['start_date'];
        $endDate = $body['end_date'] ?? $closure['end_date'];
        $reason = array_key_exists('reason', $body) ? $body['reason'] : $closure['reason'];
        $locationIds = $body['location_ids'] ?? $closure['location_ids'] ?? [];

        if (empty($locationIds) || !is_array($locationIds)) {
            return Response::badRequest('location_ids is required and must be a non-empty array', $request->traceId);
        }

        // Ensure location_ids are integers
        $locationIds = array_map('intval', $locationIds);

        // Validate date format
        if (!$this->isValidDate($startDate) || !$this->isValidDate($endDate)) {
            return Response::badRequest('Invalid date format. Use YYYY-MM-DD', $request->traceId);
        }

        // Validate date range
        if ($startDate > $endDate) {
            return Response::badRequest('start_date must be before or equal to end_date', $request->traceId);
        }

        // Validate all locations belong to this business
        foreach ($locationIds as $locId) {
            $location = $this->locationRepo->findById($locId);
            if (!$location || (int)$location['business_id'] !== $businessId) {
                return Response::badRequest("Location $locId does not belong to this business", $request->traceId);
            }
        }

        // Check for overlaps (excluding current closure)
        $overlappingLocations = $this->closureRepo->findOverlappingLocations($locationIds, $startDate, $endDate, $closureId);
        if (!empty($overlappingLocations)) {
            $locationNames = [];
            foreach ($overlappingLocations as $locId) {
                $loc = $this->locationRepo->findById($locId);
                $locationNames[] = $loc['name'] ?? "ID $locId";
            }
            return Response::conflict(
                'This closure period overlaps with existing closures for locations: ' . implode(', ', $locationNames),
                $request->traceId
            );
        }

        $this->closureRepo->update($closureId, $locationIds, $startDate, $endDate, $reason);
        $updated = $this->closureRepo->findById($closureId);

        return Response::ok($this->formatClosure($updated), $request->traceId);
    }

    /**
     * DELETE /v1/closures/{id}
     * Delete a closure
     */
    public function destroy(Request $request): Response
    {
        $closureId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');

        $closure = $this->closureRepo->findById($closureId);

        if (!$closure) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        if (!$this->hasBusinessWriteAccess($userId, (int)$closure['business_id'])) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        $this->closureRepo->delete($closureId);

        return Response::noContent($request->traceId);
    }

    private function hasBusinessReadAccess(int $userId, int $businessId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    private function hasBusinessWriteAccess(int $userId, int $businessId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_staff', false);
    }

    private function formatClosure(array $closure): array
    {
        return [
            'id' => (int) $closure['id'],
            'business_id' => (int) $closure['business_id'],
            'location_ids' => $closure['location_ids'] ?? [],
            'start_date' => $closure['start_date'],
            'end_date' => $closure['end_date'],
            'reason' => $closure['reason'],
            'created_at' => $closure['created_at'],
            'updated_at' => $closure['updated_at'],
        ];
    }

    private function isValidDate(string $date): bool
    {
        $d = \DateTime::createFromFormat('Y-m-d', $date);
        return $d && $d->format('Y-m-d') === $date;
    }
}
