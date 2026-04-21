<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Domain\Booking\RecurrenceRule;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\TimeBlockRepository;
use Agenda\Infrastructure\Repositories\TimeBlockRecurrenceRuleRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use DateTimeImmutable;

/**
 * Controller for time blocks (unavailability periods).
 *
 * Routes:
 * - GET  /v1/locations/{location_id}/time-blocks        – list blocks for a location
 * - POST /v1/locations/{location_id}/time-blocks        – create single or recurring blocks
 * - PUT  /v1/time-blocks/{id}                           – update a block (scope: this|all)
 * - DELETE /v1/time-blocks/{id}                         – delete a block (scope: this|all)
 */
final class TimeBlocksController
{
    public function __construct(
        private readonly TimeBlockRepository $blockRepo,
        private readonly TimeBlockRecurrenceRuleRepository $recurrenceRuleRepo,
        private readonly LocationRepository $locationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/locations/{location_id}/time-blocks
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
        $toDate   = $request->query['to_date']   ?? date('Y-m-d 23:59:59', strtotime('+30 days'));

        if (strlen($fromDate) === 10) {
            $fromDate .= ' 00:00:00';
        }
        if (strlen($toDate) === 10) {
            $toDate .= ' 23:59:59';
        }

        $blocks = $this->blockRepo->findByLocationAndDateRange($locationId, $fromDate, $toDate);

        return Response::success([
            'location_id' => $locationId,
            'time_blocks'  => $blocks,
        ]);
    }

    /**
     * POST /v1/locations/{location_id}/time-blocks
     *
     * Body for a single block:
     * { "start_time": "...", "end_time": "...", "staff_ids": [...], ... }
     *
     * Body for a recurring series (add "recurrence" key):
     * {
     *   "start_time": "2026-04-21 09:00:00",
     *   "end_time":   "2026-04-21 11:00:00",
     *   "staff_ids":  [1, 2],
     *   "recurrence": {
     *     "frequency": "weekly",
     *     "interval_value": 1,
     *     "max_occurrences": 10,   // or null
     *     "end_date": "2026-12-31" // or null
     *   },
     *   "excluded_indices": [2, 4]  // optional – 0-based occurrences to skip
     * }
     */
    public function store(Request $request): Response
    {
        $locationId  = (int) $request->getRouteParam('location_id');
        $userId      = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasPermission($userId, (int) $location['business_id'], 'can_manage_staff', $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();
        $businessId = (int) $location['business_id'];

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
        if (strtotime($body['start_time']) >= strtotime($body['end_time'])) {
            return Response::error('start_time must be before end_time', 'validation_error', 400, $request->traceId);
        }

        $commonData = [
            'business_id'                      => $businessId,
            'location_id'                      => $locationId,
            'staff_ids'                        => $body['staff_ids'],
            'is_all_day'                       => isset($body['is_all_day']) ? ((bool) $body['is_all_day'] ? 1 : 0) : 0,
            'allow_online_booking_during_block' => isset($body['allow_online_booking_during_block']) ? ((bool) $body['allow_online_booking_during_block'] ? 1 : 0) : 0,
            'reason'                           => $body['reason'] ?? null,
        ];

        // — Recurring series —
        if (!empty($body['recurrence']) && is_array($body['recurrence'])) {
            return $this->storeRecurring($request, $body, $commonData, $businessId);
        }

        // — Single block —
        $blockId = $this->blockRepo->create(array_merge($commonData, [
            'start_time' => $body['start_time'],
            'end_time'   => $body['end_time'],
        ]));

        return Response::created(['time_block' => $this->blockRepo->findById($blockId)]);
    }

    /**
     * PUT /v1/time-blocks/{id}
     *
     * Body:
     * { "start_time": "...", "end_time": "...", "reason": "...", "staff_ids": [...], "scope": "this"|"all" }
     *
     * scope=all|future updates shared fields (reason, is_all_day, allow_online_booking_during_block, staff_ids)
     * in the recurrence series. For scope=future, changes start from from_index (or current block index).
     * Times are never mass-updated.
     */
    public function update(Request $request): Response
    {
        $blockId     = (int) $request->getRouteParam('id');
        $userId      = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $block = $this->blockRepo->findById($blockId);
        if (!$block) {
            return Response::notFound('Time block not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasPermission($userId, (int) $block['business_id'], 'can_manage_staff', $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body  = $request->getBody();
        $scope = $body['scope'] ?? 'this';

        $ruleId = isset($block['recurrence_rule_id']) ? (int) $block['recurrence_rule_id'] : null;

        if (($scope === 'all' || $scope === 'future') && $ruleId !== null) {
            // Mass-update shared fields across recurrence series (all/future)
            $sharedData = [];
            foreach (['is_all_day', 'allow_online_booking_during_block', 'reason'] as $field) {
                if (array_key_exists($field, $body)) {
                    $sharedData[$field] = $field === 'reason' ? $body[$field] : ((bool) $body[$field] ? 1 : 0);
                }
            }
            if (isset($body['staff_ids']) && is_array($body['staff_ids'])) {
                $sharedData['staff_ids'] = $body['staff_ids'];
            }

            if (!empty($sharedData)) {
                if ($scope === 'all') {
                    $this->blockRepo->updateByRecurrenceRuleId($ruleId, $sharedData);
                } else {
                    $fromIndex = isset($body['from_index'])
                        ? (int) $body['from_index']
                        : (int) ($block['recurrence_index'] ?? 0);
                    $fromIndex = max(0, $fromIndex);
                    $this->blockRepo->updateByRecurrenceRuleIdFromIndex($ruleId, $fromIndex, $sharedData);
                }
            }

            return Response::success([
                'updated_scope' => $scope,
                'recurrence_rule_id' => $ruleId,
                'from_index' => $scope === 'future'
                    ? max(0, isset($body['from_index']) ? (int) $body['from_index'] : (int) ($block['recurrence_index'] ?? 0))
                    : null,
            ]);
        }

        // scope=this: update this block only
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
        if (array_key_exists('allow_online_booking_during_block', $body)) {
            $updateData['allow_online_booking_during_block'] = $body['allow_online_booking_during_block'] ? 1 : 0;
        }
        if (array_key_exists('reason', $body)) {
            $updateData['reason'] = $body['reason'];
        }
        if (isset($body['staff_ids']) && is_array($body['staff_ids'])) {
            $updateData['staff_ids'] = $body['staff_ids'];
        }

        $startTime = $updateData['start_time'] ?? $block['start_time'];
        $endTime   = $updateData['end_time']   ?? $block['end_time'];
        if (strtotime($startTime) >= strtotime($endTime)) {
            return Response::error('start_time must be before end_time', 'validation_error', 400, $request->traceId);
        }

        if (!empty($updateData)) {
            $this->blockRepo->update($blockId, $updateData);
        }

        return Response::success(['time_block' => $this->blockRepo->findById($blockId)]);
    }

    /**
     * DELETE /v1/time-blocks/{id}?scope=this|future|all&from_index=N
     */
    public function destroy(Request $request): Response
    {
        $blockId     = (int) $request->getRouteParam('id');
        $userId      = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $block = $this->blockRepo->findById($blockId);
        if (!$block) {
            return Response::notFound('Time block not found', $request->traceId);
        }

        if (!$this->businessUserRepo->hasPermission($userId, (int) $block['business_id'], 'can_manage_staff', $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $scope  = $request->query['scope'] ?? 'this';
        $ruleId = isset($block['recurrence_rule_id']) ? (int) $block['recurrence_rule_id'] : null;

        if (($scope === 'all' || $scope === 'future') && $ruleId !== null) {
            if ($scope === 'all') {
                $this->blockRepo->deleteByRecurrenceRuleId($ruleId);
                $this->recurrenceRuleRepo->delete($ruleId);
                return Response::success(['deleted' => true, 'deleted_scope' => 'all', 'recurrence_rule_id' => $ruleId]);
            }

            $fromIndex = isset($request->query['from_index'])
                ? max(0, (int) $request->query['from_index'])
                : max(0, (int) ($block['recurrence_index'] ?? 0));

            if ($fromIndex <= 0) {
                $this->blockRepo->deleteByRecurrenceRuleId($ruleId);
                $this->recurrenceRuleRepo->delete($ruleId);
                return Response::success([
                    'deleted' => true,
                    'deleted_scope' => 'all',
                    'recurrence_rule_id' => $ruleId,
                    'from_index' => 0,
                ]);
            }

            $this->blockRepo->deleteByRecurrenceRuleIdFromIndex($ruleId, $fromIndex);
            return Response::success([
                'deleted' => true,
                'deleted_scope' => 'future',
                'recurrence_rule_id' => $ruleId,
                'from_index' => $fromIndex,
            ]);
        }

        $this->blockRepo->delete($blockId);

        return Response::success(['deleted' => true, 'deleted_scope' => 'this']);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function storeRecurring(Request $request, array $body, array $commonData, int $businessId): Response
    {
        $rec = $body['recurrence'];

        if (empty($rec['frequency'])) {
            return Response::error('recurrence.frequency is required', 'validation_error', 400, $request->traceId);
        }

        $validFrequencies = [
            RecurrenceRule::FREQUENCY_DAILY,
            RecurrenceRule::FREQUENCY_WEEKLY,
            RecurrenceRule::FREQUENCY_MONTHLY,
            RecurrenceRule::FREQUENCY_CUSTOM,
        ];
        if (!in_array($rec['frequency'], $validFrequencies, true)) {
            return Response::error('Invalid recurrence frequency', 'validation_error', 400, $request->traceId);
        }

        $endDate = null;
        if (!empty($rec['end_date'])) {
            $endDate = new DateTimeImmutable($rec['end_date']);
        }

        $rule = new RecurrenceRule(
            id: null,
            businessId: $businessId,
            frequency: $rec['frequency'],
            intervalValue: (int) ($rec['interval_value'] ?? 1),
            maxOccurrences: isset($rec['max_occurrences']) ? (int) $rec['max_occurrences'] : null,
            endDate: $endDate,
            conflictStrategy: RecurrenceRule::CONFLICT_FORCE, // blocks don't conflict
            daysOfWeek: $rec['days_of_week'] ?? null,
            dayOfMonth: isset($rec['day_of_month']) ? (int) $rec['day_of_month'] : null,
        );

        $ruleId = $this->recurrenceRuleRepo->create($rule);

        $startDt  = new DateTimeImmutable($body['start_time']);
        $endDt    = new DateTimeImmutable($body['end_time']);
        $duration = $startDt->diff($endDt);

        $dates           = $rule->calculateDates($startDt);
        $excludedIndices = array_flip((array) ($body['excluded_indices'] ?? []));

        $createdBlocks = [];
        foreach ($dates as $index => $date) {
            if (isset($excludedIndices[$index])) {
                continue;
            }

            $blockStart = $date;
            $blockEnd   = $date->add($duration);

            $blockId = $this->blockRepo->create(array_merge($commonData, [
                'start_time'           => $blockStart->format('Y-m-d H:i:s'),
                'end_time'             => $blockEnd->format('Y-m-d H:i:s'),
                'recurrence_rule_id'   => $ruleId,
                'recurrence_index'     => $index,
                'is_recurrence_parent' => $index === 0 ? 1 : 0,
            ]));

            $createdBlocks[] = $this->blockRepo->findById($blockId);
        }

        return Response::created([
            'recurrence_rule_id' => $ruleId,
            'created_count'      => count($createdBlocks),
            'time_blocks'        => $createdBlocks,
        ]);
    }
}
