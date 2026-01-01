<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\TimeBlockRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Controller for time blocks (unavailability periods).
 * 
 * Routes:
 * - GET /v1/locations/{location_id}/time-blocks - Get blocks for a location
 * - POST /v1/locations/{location_id}/time-blocks - Create a new block
 * - PUT /v1/time-blocks/{id} - Update a block
 * - DELETE /v1/time-blocks/{id} - Delete a block
 */
final class TimeBlocksController
{
    public function __construct(
        private readonly TimeBlockRepository $blockRepo,
        private readonly LocationRepository $locationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/locations/{location_id}/time-blocks
     * Get time blocks for a location in a date range.
     * Query params: from_date, to_date (YYYY-MM-DD HH:MM:SS or YYYY-MM-DD)
     */
    public function index(Request $request): Response
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

        $fromDate = $request->query['from_date'] ?? date('Y-m-d 00:00:00');
        $toDate = $request->query['to_date'] ?? date('Y-m-d 23:59:59', strtotime('+30 days'));
        
        // Ensure datetime format
        if (strlen($fromDate) === 10) {
            $fromDate .= ' 00:00:00';
        }
        if (strlen($toDate) === 10) {
            $toDate .= ' 23:59:59';
        }

        $blocks = $this->blockRepo->findByLocationAndDateRange($locationId, $fromDate, $toDate);

        return Response::success([
            'location_id' => $locationId,
            'time_blocks' => $blocks,
        ]);
    }

    /**
     * POST /v1/locations/{location_id}/time-blocks
     * Create a new time block.
     * 
     * Body:
     * {
     *   "start_time": "2026-01-15 09:00:00",
     *   "end_time": "2026-01-15 12:00:00",
     *   "staff_ids": [1, 2],
     *   "is_all_day": false,
     *   "reason": "Riunione"
     * }
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
        if (empty($body['start_time'])) {
            return Response::error('start_time is required', 'validation_error', 400, $request->traceId);
        }
        if (empty($body['end_time'])) {
            return Response::error('end_time is required', 'validation_error', 400, $request->traceId);
        }
        if (empty($body['staff_ids']) || !is_array($body['staff_ids'])) {
            return Response::error('staff_ids array is required', 'validation_error', 400, $request->traceId);
        }

        // Validate time range
        if (strtotime($body['start_time']) >= strtotime($body['end_time'])) {
            return Response::error('start_time must be before end_time', 'validation_error', 400, $request->traceId);
        }

        $blockId = $this->blockRepo->create([
            'business_id' => (int) $location['business_id'],
            'location_id' => $locationId,
            'start_time' => $body['start_time'],
            'end_time' => $body['end_time'],
            'staff_ids' => $body['staff_ids'],
            'is_all_day' => $body['is_all_day'] ?? false,
            'reason' => $body['reason'] ?? null,
        ]);

        $block = $this->blockRepo->findById($blockId);

        return Response::created([
            'time_block' => $block,
        ]);
    }

    /**
     * PUT /v1/time-blocks/{id}
     * Update a time block.
     */
    public function update(Request $request): Response
    {
        $blockId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $block = $this->blockRepo->findById($blockId);
        if (!$block) {
            return Response::notFound('Time block not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasAccess($userId, (int) $block['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();
        $updateData = [];

        if (isset($body['start_time'])) {
            $updateData['start_time'] = $body['start_time'];
        }
        if (isset($body['end_time'])) {
            $updateData['end_time'] = $body['end_time'];
        }
        if (array_key_exists('is_all_day', $body)) {
            $updateData['is_all_day'] = $body['is_all_day'] ? 1 : 0;
        }
        if (array_key_exists('reason', $body)) {
            $updateData['reason'] = $body['reason'];
        }
        if (isset($body['staff_ids']) && is_array($body['staff_ids'])) {
            $updateData['staff_ids'] = $body['staff_ids'];
        }

        // Validate time range if both provided
        $startTime = $updateData['start_time'] ?? $block['start_time'];
        $endTime = $updateData['end_time'] ?? $block['end_time'];
        if (strtotime($startTime) >= strtotime($endTime)) {
            return Response::error('start_time must be before end_time', 'validation_error', 400, $request->traceId);
        }

        if (!empty($updateData)) {
            $this->blockRepo->update($blockId, $updateData);
        }

        $updated = $this->blockRepo->findById($blockId);

        return Response::success([
            'time_block' => $updated,
        ]);
    }

    /**
     * DELETE /v1/time-blocks/{id}
     * Delete a time block.
     */
    public function destroy(Request $request): Response
    {
        $blockId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $block = $this->blockRepo->findById($blockId);
        if (!$block) {
            return Response::notFound('Time block not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasAccess($userId, (int) $block['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $this->blockRepo->delete($blockId);

        return Response::success(['deleted' => true]);
    }
}
