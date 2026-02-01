<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessClosureRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class BusinessClosuresController
{
    public function __construct(
        private BusinessClosureRepository $closureRepo,
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

        if (!$this->hasBusinessAccess($userId, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $closures = $this->closureRepo->findByBusinessId($businessId);

        return Response::ok([
            'closures' => array_map(fn($c) => $this->formatClosure($c), $closures)
        ], $request->traceId);
    }

    /**
     * GET /v1/businesses/{business_id}/closures/{id}
     * Get a single closure
     */
    public function show(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $closureId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');

        if (!$this->hasBusinessAccess($userId, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $closure = $this->closureRepo->findById($closureId);

        if (!$closure || $closure['business_id'] !== $businessId) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        return Response::ok($this->formatClosure($closure), $request->traceId);
    }

    /**
     * POST /v1/businesses/{business_id}/closures
     * Create a new closure
     */
    public function store(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');

        if (!$this->hasBusinessAccess($userId, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $body = $request->body;

        // Validation
        $startDate = $body['start_date'] ?? null;
        $endDate = $body['end_date'] ?? null;
        $reason = $body['reason'] ?? null;

        if (!$startDate || !$endDate) {
            return Response::badRequest('start_date and end_date are required', $request->traceId);
        }

        // Validate date format
        if (!$this->isValidDate($startDate) || !$this->isValidDate($endDate)) {
            return Response::badRequest('Invalid date format. Use YYYY-MM-DD', $request->traceId);
        }

        // Validate date range
        if ($startDate > $endDate) {
            return Response::badRequest('start_date must be before or equal to end_date', $request->traceId);
        }

        // Check for overlaps
        if ($this->closureRepo->hasOverlap($businessId, $startDate, $endDate)) {
            return Response::conflict('This closure period overlaps with an existing one', $request->traceId);
        }

        $id = $this->closureRepo->create($businessId, $startDate, $endDate, $reason);
        $closure = $this->closureRepo->findById($id);

        return Response::created($this->formatClosure($closure), $request->traceId);
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

        $businessId = (int) $closure['business_id'];

        if (!$this->hasBusinessAccess($userId, $businessId)) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        $body = $request->body;

        $startDate = $body['start_date'] ?? $closure['start_date'];
        $endDate = $body['end_date'] ?? $closure['end_date'];
        $reason = array_key_exists('reason', $body) ? $body['reason'] : $closure['reason'];

        // Validate date format
        if (!$this->isValidDate($startDate) || !$this->isValidDate($endDate)) {
            return Response::badRequest('Invalid date format. Use YYYY-MM-DD', $request->traceId);
        }

        // Validate date range
        if ($startDate > $endDate) {
            return Response::badRequest('start_date must be before or equal to end_date', $request->traceId);
        }

        // Check for overlaps (excluding current closure)
        if ($this->closureRepo->hasOverlap($businessId, $startDate, $endDate, $closureId)) {
            return Response::conflict('This closure period overlaps with an existing one', $request->traceId);
        }

        $this->closureRepo->update($closureId, $startDate, $endDate, $reason);
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

        $businessId = (int) $closure['business_id'];

        if (!$this->hasBusinessAccess($userId, $businessId)) {
            return Response::notFound('Closure not found', $request->traceId);
        }

        $this->closureRepo->delete($closureId);

        return Response::noContent($request->traceId);
    }

    /**
     * GET /v1/businesses/{business_id}/closures/in-range
     * Get closures within a date range (for availability/reports)
     */
    public function inRange(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');

        if (!$this->hasBusinessAccess($userId, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $startDate = $request->query['start_date'] ?? null;
        $endDate = $request->query['end_date'] ?? null;

        if (!$startDate || !$endDate) {
            return Response::badRequest('start_date and end_date query parameters are required', $request->traceId);
        }

        $closures = $this->closureRepo->findByBusinessIdAndDateRange($businessId, $startDate, $endDate);
        $closedDates = $this->closureRepo->getClosedDatesInRange($businessId, $startDate, $endDate);

        return Response::ok([
            'closures' => array_map(fn($c) => $this->formatClosure($c), $closures),
            'closed_dates' => $closedDates,
            'total_closed_days' => count($closedDates)
        ], $request->traceId);
    }

    private function hasBusinessAccess(int $userId, int $businessId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    private function formatClosure(array $closure): array
    {
        return [
            'id' => (int) $closure['id'],
            'business_id' => (int) $closure['business_id'],
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
