<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Domain\Helpers\ColorHex;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BookingDirectLinkRepository;
use Agenda\Infrastructure\Repositories\ClassEventRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\UseCases\Notifications\QueueClassBookingNotification;

final class ClassEventsController
{
    public function __construct(
        private readonly ClassEventRepository $classEventRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly LocationRepository $locationRepo,
        private readonly UserRepository $userRepo,
        private readonly ?ClientRepository $clientRepo = null,
        private readonly ?QueueClassBookingNotification $queueClassBookingNotification = null,
        private readonly ?BookingDirectLinkRepository $directLinkRepo = null,
    ) {}

    public function indexTypes(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canRead($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $includeInactive = (string) ($request->queryParam('include_inactive') ?? '') === '1';
        $items = $this->classEventRepo->findClassTypes($businessId, $includeInactive);
        $classTypeIds = array_map(static fn (array $row): int => (int) $row['id'], $items);
        $locationMap = $this->classEventRepo->findClassTypeLocationsMap($businessId, $classTypeIds);

        if (!$this->userRepo->isSuperadmin($userId)) {
            $allowedLocationIds = $this->businessUserRepo->getAllowedLocationIds($userId, $businessId);
            if (is_array($allowedLocationIds)) {
                $allowedLocationSet = [];
                foreach ($allowedLocationIds as $locationId) {
                    $allowedLocationSet[(int) $locationId] = true;
                }

                $items = array_values(array_filter(
                    $items,
                    function (array $row) use ($locationMap, $allowedLocationSet): bool {
                        $classTypeId = (int) $row['id'];
                        $boundLocationIds = $locationMap[$classTypeId] ?? [];

                        // No explicit bindings means type is available in all locations.
                        if (empty($boundLocationIds)) {
                            return true;
                        }

                        foreach ($boundLocationIds as $locationId) {
                            if (isset($allowedLocationSet[(int) $locationId])) {
                                return true;
                            }
                        }

                        return false;
                    }
                ));
            }
        }

        return Response::success([
            'items' => array_map(
                fn (array $row): array => $this->formatClassType(
                    $row,
                    $locationMap[(int) $row['id']] ?? []
                ),
                $items
            ),
        ]);
    }

    public function storeType(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $name = trim((string) ($body['name'] ?? ''));
        if ($name == '') {
            return Response::error('name is required', 'validation_error', 400, $request->traceId);
        }
        if (mb_strlen($name) > 255) {
            return Response::error('name too long', 'validation_error', 400, $request->traceId);
        }

        $locationIdsResult = $this->resolveClassTypeLocationIdsForMutation($request, $userId, $businessId, $body, true);
        if (isset($locationIdsResult['error'])) {
            return Response::error((string) $locationIdsResult['error'], 'validation_error', 400, $request->traceId);
        }
        $locationIds = $locationIdsResult['location_ids'] ?? null;
        $colorHexResult = ColorHex::normalizeOptional($body['color_hex'] ?? null, 'color_hex');
        if (isset($colorHexResult['error'])) {
            return Response::error((string) $colorHexResult['error'], 'validation_error', 400, $request->traceId);
        }
        $colorHex = $colorHexResult['value'] ?? null;
        $serviceCategoryResult = $this->normalizeServiceCategoryId(
            $businessId,
            $body['service_category_id'] ?? null,
            true
        );
        if (isset($serviceCategoryResult['error'])) {
            return Response::error((string) $serviceCategoryResult['error'], 'validation_error', 400, $request->traceId);
        }
        $serviceCategoryId = $serviceCategoryResult['value'] ?? null;

        try {
            $id = $this->classEventRepo->createClassType($businessId, [
                'name' => $name,
                'description' => array_key_exists('description', $body) ? $body['description'] : null,
                'color_hex' => $colorHex,
                'service_category_id' => $serviceCategoryId,
            ]);
            if ($locationIds !== null) {
                $this->classEventRepo->setClassTypeLocations($businessId, $id, $locationIds);
            }
        } catch (\Throwable $e) {
            if ($this->isDuplicateKeyError($e)) {
                return Response::conflict('class_type_name_exists', 'Class type name already exists', $request->traceId);
            }
            return Response::serverError('Unable to create class type', $request->traceId);
        }

        $created = $this->classEventRepo->findClassTypeById($businessId, $id);
        if ($created === null) {
            return Response::created(['id' => $id]);
        }
        $createdLocationMap = $this->classEventRepo->findClassTypeLocationsMap($businessId, [$id]);
        return Response::created(
            $this->formatClassType($created, $createdLocationMap[$id] ?? [])
        );
    }

    public function updateType(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classTypeId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        if (!array_key_exists('service_category_id', $body)) {
            return Response::error('service_category_id is required', 'validation_error', 400, $request->traceId);
        }
        if (array_key_exists('name', $body)) {
            $name = trim((string) $body['name']);
            if ($name == '') {
                return Response::error('name is required', 'validation_error', 400, $request->traceId);
            }
            if (mb_strlen($name) > 255) {
                return Response::error('name too long', 'validation_error', 400, $request->traceId);
            }
            $body['name'] = $name;
        }
        if (array_key_exists('color_hex', $body)) {
            $colorHexResult = ColorHex::normalizeOptional($body['color_hex'], 'color_hex');
            if (isset($colorHexResult['error'])) {
                return Response::error((string) $colorHexResult['error'], 'validation_error', 400, $request->traceId);
            }
            $body['color_hex'] = $colorHexResult['value'] ?? null;
        }
        if (array_key_exists('sort_order', $body)) {
            if (!is_int($body['sort_order']) && !(is_string($body['sort_order']) && ctype_digit(trim($body['sort_order'])))) {
                return Response::error('sort_order must be an integer', 'validation_error', 400, $request->traceId);
            }
            $sortOrder = (int) $body['sort_order'];
            if ($sortOrder < 0) {
                return Response::error('sort_order must be >= 0', 'validation_error', 400, $request->traceId);
            }
            $body['sort_order'] = $sortOrder;
        }
        if (array_key_exists('service_category_id', $body)) {
            $serviceCategoryResult = $this->normalizeServiceCategoryId(
                $businessId,
                $body['service_category_id'],
                true
            );
            if (isset($serviceCategoryResult['error'])) {
                return Response::error((string) $serviceCategoryResult['error'], 'validation_error', 400, $request->traceId);
            }
            $body['service_category_id'] = $serviceCategoryResult['value'] ?? null;
        }

        $locationIdsResult = $this->resolveClassTypeLocationIdsForMutation($request, $userId, $businessId, $body, false);
        if (isset($locationIdsResult['error'])) {
            return Response::error((string) $locationIdsResult['error'], 'validation_error', 400, $request->traceId);
        }
        $locationIds = $locationIdsResult['location_ids'] ?? null;

        try {
            $this->classEventRepo->updateClassType($businessId, $classTypeId, $body);
            if ($locationIds !== null) {
                $this->classEventRepo->setClassTypeLocations($businessId, $classTypeId, $locationIds);
            }
        } catch (\Throwable $e) {
            if ($this->isDuplicateKeyError($e)) {
                return Response::conflict('class_type_name_exists', 'Class type name already exists', $request->traceId);
            }
            return Response::serverError('Unable to update class type', $request->traceId);
        }
        $updated = $this->classEventRepo->findClassTypeById($businessId, $classTypeId);
        if ($updated === null) {
            return Response::notFound('Class type not found', $request->traceId);
        }
        $updatedLocationMap = $this->classEventRepo->findClassTypeLocationsMap($businessId, [$classTypeId]);
        return Response::success($this->formatClassType($updated, $updatedLocationMap[$classTypeId] ?? []));
    }

    public function destroyType(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classTypeId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $existing = $this->classEventRepo->findClassTypeById($businessId, $classTypeId);
        if ($existing === null) {
            return Response::notFound('Class type not found', $request->traceId);
        }
        if ($this->classEventRepo->hasFutureClassEvents($businessId, $classTypeId)) {
            return Response::conflict('class_type_has_future_events', 'Cannot delete event type because there are future scheduled events', $request->traceId);
        }

        try {
            $deleted = $this->classEventRepo->deleteClassType($businessId, $classTypeId);
        } catch (\Throwable $e) {
            return Response::serverError('Unable to delete class type', $request->traceId);
        }

        if (!$deleted) {
            return Response::notFound('Class type not found', $request->traceId);
        }
        return Response::success(['deleted' => true]);
    }

    /**
     * Public listing of scheduled class events for the customer booking portal.
     * No authentication required. Only SCHEDULED + PUBLIC events are returned.
     * business_id and location_id are injected by the location_query middleware.
     *
     * GET /v1/class-events?location_id=X
     * Query params:
     *   location_id   int (required, via middleware)
     *   from          ISO8601 UTC (optional, default: now)
     *   to            ISO8601 UTC (optional, default: from + 90 days)
     *   class_type_id int (optional)
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $locationId = (int) $request->getAttribute('location_id');

        $now = new \DateTimeImmutable('now', new \DateTimeZone('UTC'));

        $fromRaw = (string) ($request->queryParam('from') ?? '');
        $toRaw   = (string) ($request->queryParam('to')   ?? '');

        $fromUtc = $fromRaw !== ''
            ? $fromRaw
            : $now->format('Y-m-d H:i:s');

        $toUtc = $toRaw !== ''
            ? $toRaw
            : $now->modify('+90 days')->format('Y-m-d H:i:s');

        $classTypeId = $request->queryParam('class_type_id');
        $directLinkScope = $this->directLinkScopeFromQuery($request, $businessId, $locationId);

        $items = $this->classEventRepo->findPublicByBusinessAndRange(
            $businessId,
            $fromUtc,
            $toUtc,
            $locationId,
            $classTypeId !== null && $classTypeId !== '' ? (int) $classTypeId : null,
            $directLinkScope
        );

        $eventIds = array_map(static fn (array $row): int => (int) $row['id'], $items);
        $resourceRequirements = $this->classEventRepo->findResourceRequirementsForEvents($businessId, $eventIds);

        return Response::success([
            'items' => array_map(
                fn (array $row): array => $this->formatClassEventPublic(
                    $row,
                    $resourceRequirements[(int) $row['id']] ?? []
                ),
                $items
            ),
        ]);
    }

    public function indexByBusiness(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canRead($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $fromRaw = (string) ($request->queryParam('from') ?? '');
        $toRaw = (string) ($request->queryParam('to') ?? '');
        if ($fromRaw === '' || $toRaw === '') {
            return Response::error('from and to are required', 'validation_error', 400, $request->traceId);
        }

        $locationId = $request->queryParam('location_id');
        $locationIdInt = $locationId !== null && $locationId !== '' ? (int) $locationId : null;

        try {
            $fromUtc = $this->toSqlUtcForFilter($fromRaw, $locationIdInt);
            $toUtc = $this->toSqlUtcForFilter($toRaw, $locationIdInt);
        } catch (\Throwable $e) {
            return Response::error(
                $e->getMessage() !== '' ? $e->getMessage() : 'Invalid from/to datetime format',
                'validation_error',
                400,
                $request->traceId
            );
        }

        $classTypeId = $request->queryParam('class_type_id');

        $items = $this->classEventRepo->findByBusinessAndRange(
            $businessId,
            $fromUtc,
            $toUtc,
            $locationIdInt,
            $classTypeId !== null && $classTypeId !== '' ? (int) $classTypeId : null,
            $this->resolveCustomerId($businessId, $userId)
        );

        $eventIds = array_map(static fn (array $row): int => (int) $row['id'], $items);
        $resourceRequirements = $this->classEventRepo->findResourceRequirementsForEvents($businessId, $eventIds);

        return Response::success([
            'items' => array_map(
                fn (array $row): array => $this->formatClassEvent(
                    $row,
                    $resourceRequirements[(int) $row['id']] ?? []
                ),
                $items
            ),
        ]);
    }

    public function show(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canRead($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $event = $this->classEventRepo->findById(
            $businessId,
            $classEventId,
            $this->resolveCustomerId($businessId, $userId)
        );
        if ($event === null) {
            return Response::notFound('Class event not found', $request->traceId);
        }

        $resourceRequirements = $this->classEventRepo->findResourceRequirementsForEvents($businessId, [$classEventId]);
        return Response::success($this->formatClassEvent($event, $resourceRequirements[$classEventId] ?? []));
    }

    public function participants(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canRead($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $status = $request->queryParam('status');
        $items = $this->classEventRepo->findParticipants($businessId, $classEventId, $status);
        return Response::success(['items' => array_map([$this, 'formatClassBooking'], $items)]);
    }

    public function store(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $onlineVisibility = $this->validatedOnlineVisibility($body, $request);
        if ($onlineVisibility instanceof Response) {
            return $onlineVisibility;
        }
        $validationError = $this->validateCreateOrUpdate($body, true);
        if ($validationError !== null) {
            return Response::error($validationError, 'validation_error', 400, $request->traceId);
        }

        $startsAtInput = (string) ($body['starts_at'] ?? $body['starts_at_utc']);
        $endsAtInput = (string) ($body['ends_at'] ?? $body['ends_at_utc']);
        $bookingOpenAtInput = $body['booking_open_at'] ?? $body['booking_open_at_utc'] ?? null;
        $bookingCloseAtInput = $body['booking_close_at'] ?? $body['booking_close_at_utc'] ?? null;
        $resourceRequirements = $this->normalizeResourceRequirements($body);
        $staffIdInput = $body['staff_id'] ?? $body['instructor_staff_id'] ?? null;
        $classTypeId = (int) $body['class_type_id'];
        $locationId = (int) $body['location_id'];
        $staffId = (int) $staffIdInput;
        if (!$this->classEventRepo->classTypeExists($businessId, $classTypeId)) {
            return Response::error('class_type_id not found for this business', 'validation_error', 400, $request->traceId);
        }
        if (!$this->classEventRepo->locationExistsInBusiness($businessId, $locationId)) {
            return Response::error('location_id not found for this business', 'validation_error', 400, $request->traceId);
        }
        if (!$this->classEventRepo->classTypeAllowsLocation($businessId, $classTypeId, $locationId)) {
            return Response::error(
                'class_type_id is not enabled for location_id',
                'validation_error',
                400,
                $request->traceId
            );
        }
        if (!$this->canManageLocation($userId, $businessId, $locationId)) {
            return Response::forbidden('Access denied for this location', $request->traceId);
        }
        if (!$this->classEventRepo->staffExistsInBusiness($businessId, $staffId)) {
            return Response::error('staff_id not found for this business', 'validation_error', 400, $request->traceId);
        }
        $resourceIds = $this->extractResourceIds($resourceRequirements);
        if (!$this->classEventRepo->resourcesBelongToLocation($businessId, $locationId, $resourceIds)) {
            return Response::error('resource_requirements must belong to event location', 'validation_error', 400, $request->traceId);
        }

        $id = $this->classEventRepo->create([
            'business_id' => $businessId,
            'class_type_id' => $classTypeId,
            'starts_at' => $this->toSqlUtcForLocation($startsAtInput, $locationId),
            'ends_at' => $this->toSqlUtcForLocation($endsAtInput, $locationId),
            'location_id' => $locationId,
            'staff_id' => $staffId,
            'capacity_total' => isset($body['capacity_total']) ? max(1, (int) $body['capacity_total']) : 1,
            'capacity_reserved' => isset($body['capacity_reserved']) ? max(0, (int) $body['capacity_reserved']) : 0,
            'confirmed_count' => 0,
            'waitlist_count' => 0,
            'waitlist_enabled' => isset($body['waitlist_enabled']) ? (bool) $body['waitlist_enabled'] : true,
            'is_bookable_online' => isset($body['is_bookable_online']) ? (bool) $body['is_bookable_online'] : true,
            'online_visibility' => $onlineVisibility,
            'booking_open_at' => $bookingOpenAtInput !== null
                ? $this->toSqlUtcForLocation((string) $bookingOpenAtInput, $locationId)
                : null,
            'booking_close_at' => $bookingCloseAtInput !== null
                ? $this->toSqlUtcForLocation((string) $bookingCloseAtInput, $locationId)
                : null,
            'cancel_cutoff_minutes' => isset($body['cancel_cutoff_minutes']) ? max(0, (int) $body['cancel_cutoff_minutes']) : 0,
            'status' => isset($body['status']) ? strtoupper((string) $body['status']) : 'SCHEDULED',
            'visibility' => isset($body['visibility']) ? strtoupper((string) $body['visibility']) : 'PUBLIC',
            'price_cents' => isset($body['price_cents']) ? (int) $body['price_cents'] : null,
            'currency' => $body['currency'] ?? null,
            'resource_requirements' => $resourceRequirements,
        ]);

        $event = $this->classEventRepo->findById($businessId, $id, null);
        if ($event === null) {
            return Response::created(['id' => $id]);
        }
        if ($onlineVisibility === 'direct_link') {
            $this->directLinkRepo?->createOrUpdateForTarget(
                $businessId,
                BookingDirectLinkRepository::TARGET_CLASS_EVENT,
                $id,
                $locationId,
                (string) ($event['class_type_name'] ?? $event['name'] ?? 'class-event')
            );
        }
        $createdResourceRequirements = $this->classEventRepo->findResourceRequirementsForEvents($businessId, [$id]);
        return Response::created($this->formatClassEvent($event, $createdResourceRequirements[$id] ?? []));
    }

    public function update(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $onlineVisibility = $this->validatedOnlineVisibility($body, $request);
        if ($onlineVisibility instanceof Response) {
            return $onlineVisibility;
        }
        $notifyCustomer = $this->readBoolFromBody($body, 'notify_customer', false);
        $notificationCustomerIds = $this->normalizeOptionalCustomerIds(
            $body['notification_customer_ids'] ?? null
        );
        $validationError = $this->validateCreateOrUpdate($body, false);
        if ($validationError !== null) {
            return Response::error($validationError, 'validation_error', 400, $request->traceId);
        }

        $currentEvent = $this->classEventRepo->findById($businessId, $classEventId, null);
        if ($currentEvent === null) {
            return Response::notFound('Class event not found', $request->traceId);
        }

        $payload = [];
        $map = [
            'class_type_id',
            'location_id',
            'staff_id',
            'capacity_total',
            'capacity_reserved',
            'waitlist_enabled',
            'is_bookable_online',
            'online_visibility',
            'cancel_cutoff_minutes',
            'status',
            'visibility',
            'price_cents',
            'currency',
        ];
        foreach ($map as $field) {
            if (array_key_exists($field, $body)) {
                $payload[$field] = $body[$field];
            }
        }
        if ($onlineVisibility !== null) {
            $payload['online_visibility'] = $onlineVisibility;
        }
        if (array_key_exists('instructor_staff_id', $body)) {
            $payload['staff_id'] = $body['instructor_staff_id'];
        }
        if (isset($payload['status'])) {
            $payload['status'] = strtoupper((string) $payload['status']);
        }
        if (isset($payload['visibility'])) {
            $payload['visibility'] = strtoupper((string) $payload['visibility']);
        }
        $effectiveLocationId = array_key_exists('location_id', $payload)
            ? (int) $payload['location_id']
            : (int) $currentEvent['location_id'];

        if (isset($body['starts_at']) || isset($body['starts_at_utc'])) {
            $payload['starts_at'] = $this->toSqlUtcForLocation(
                (string) ($body['starts_at'] ?? $body['starts_at_utc']),
                $effectiveLocationId
            );
        }
        if (isset($body['ends_at']) || isset($body['ends_at_utc'])) {
            $payload['ends_at'] = $this->toSqlUtcForLocation(
                (string) ($body['ends_at'] ?? $body['ends_at_utc']),
                $effectiveLocationId
            );
        }
        if (array_key_exists('booking_open_at', $body) || array_key_exists('booking_open_at_utc', $body)) {
            $bookingOpenAt = $body['booking_open_at'] ?? $body['booking_open_at_utc'] ?? null;
            $payload['booking_open_at'] = $bookingOpenAt !== null
                ? $this->toSqlUtcForLocation((string) $bookingOpenAt, $effectiveLocationId)
                : null;
        }
        if (array_key_exists('booking_close_at', $body) || array_key_exists('booking_close_at_utc', $body)) {
            $bookingCloseAt = $body['booking_close_at'] ?? $body['booking_close_at_utc'] ?? null;
            $payload['booking_close_at'] = $bookingCloseAt !== null
                ? $this->toSqlUtcForLocation((string) $bookingCloseAt, $effectiveLocationId)
                : null;
        }
        if (array_key_exists('resource_requirements', $body) || array_key_exists('resource_id', $body)) {
            $payload['resource_requirements'] = $this->normalizeResourceRequirements($body);
        }
        if (array_key_exists('class_type_id', $payload)) {
            $classTypeId = (int) $payload['class_type_id'];
            if (!$this->classEventRepo->classTypeExists($businessId, $classTypeId)) {
                return Response::error('class_type_id not found for this business', 'validation_error', 400, $request->traceId);
            }
        }

        $effectiveClassTypeId = array_key_exists('class_type_id', $payload)
            ? (int) $payload['class_type_id']
            : (int) $currentEvent['class_type_id'];
        $effectiveStaffId = array_key_exists('staff_id', $payload)
            ? (int) $payload['staff_id']
            : (int) $currentEvent['staff_id'];

        if (!$this->classEventRepo->locationExistsInBusiness($businessId, $effectiveLocationId)) {
            return Response::error('location_id not found for this business', 'validation_error', 400, $request->traceId);
        }
        if (!$this->classEventRepo->classTypeAllowsLocation($businessId, $effectiveClassTypeId, $effectiveLocationId)) {
            return Response::error(
                'class_type_id is not enabled for location_id',
                'validation_error',
                400,
                $request->traceId
            );
        }
        if (!$this->canManageLocation($userId, $businessId, $effectiveLocationId)) {
            return Response::forbidden('Access denied for this location', $request->traceId);
        }
        if (!$this->classEventRepo->staffExistsInBusiness($businessId, $effectiveStaffId)) {
            return Response::error('staff_id not found for this business', 'validation_error', 400, $request->traceId);
        }

        $effectiveRequirements = array_key_exists('resource_requirements', $payload)
            ? $payload['resource_requirements']
            : $this->classEventRepo->findResourceRequirementsForEvent($businessId, $classEventId);
        $resourceIds = $this->extractResourceIds(is_array($effectiveRequirements) ? $effectiveRequirements : []);
        if (!$this->classEventRepo->resourcesBelongToLocation($businessId, $effectiveLocationId, $resourceIds)) {
            return Response::error('resource_requirements must belong to event location', 'validation_error', 400, $request->traceId);
        }

        $this->classEventRepo->update($businessId, $classEventId, $payload);
        $event = $this->classEventRepo->findById($businessId, $classEventId, null);
        if ($event === null) {
            return Response::notFound('Class event not found', $request->traceId);
        }
        if ($onlineVisibility === 'direct_link') {
            $this->directLinkRepo?->createOrUpdateForTarget(
                $businessId,
                BookingDirectLinkRepository::TARGET_CLASS_EVENT,
                $classEventId,
                (int) ($event['location_id'] ?? 0),
                (string) ($event['class_type_name'] ?? $event['name'] ?? 'class-event')
            );
        }
        if ($notifyCustomer) {
            $this->queueClassEventNotifications(
                $businessId,
                $classEventId,
                'class_booking_updated',
                $notificationCustomerIds
            );
        }

        $updatedResourceRequirements = $this->classEventRepo->findResourceRequirementsForEvents($businessId, [$classEventId]);
        return Response::success($this->formatClassEvent($event, $updatedResourceRequirements[$classEventId] ?? []));
    }

    public function cancel(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $notifyCustomer = $this->readBoolFromBody($body, 'notify_customer', false);
        if ($notifyCustomer) {
            $this->queueClassEventNotifications(
                $businessId,
                $classEventId,
                'class_booking_cancelled'
            );
        }
        $ok = $this->classEventRepo->cancelEvent($businessId, $classEventId);
        if (!$ok) {
            return Response::notFound('Class event not found', $request->traceId);
        }
        return Response::success(['cancelled' => true]);
    }

    public function destroy(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $event = $this->classEventRepo->findById($businessId, $classEventId, null);
        if ($event === null) {
            return Response::notFound('Class event not found', $request->traceId);
        }
        if (!$this->canManageLocation($userId, $businessId, (int) $event['location_id'])) {
            return Response::forbidden('Access denied for this location', $request->traceId);
        }

        $deleted = $this->classEventRepo->deleteEvent($businessId, $classEventId);
        if (!$deleted) {
            return Response::notFound('Class event not found', $request->traceId);
        }

        return Response::success(['deleted' => true]);
    }

    public function book(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $customerId = isset($body['customer_id'])
            ? (int) $body['customer_id']
            : $this->resolveCustomerId($businessId, $userId);
        $targetStatus = isset($body['target_status']) ? strtolower((string) $body['target_status']) : null;
        $notifyCustomer = $this->readBoolFromBody($body, 'notify_customer', true);
        if ($customerId === null || $customerId <= 0) {
            return Response::error('customer_id is required', 'validation_error', 400, $request->traceId);
        }
        if ($targetStatus !== null && !in_array($targetStatus, ['confirmed', 'waitlisted'], true)) {
            return Response::error(
                'target_status must be confirmed or waitlisted',
                'validation_error',
                400,
                $request->traceId
            );
        }

        try {
            $existingBooking = $this->classEventRepo->findBookingByCustomer(
                $businessId,
                $classEventId,
                $customerId
            );
            $booking = $this->classEventRepo->book(
                $businessId,
                $classEventId,
                $customerId,
                $targetStatus,
                true,
                true
            );
        } catch (\RuntimeException $e) {
            return match ($e->getMessage()) {
                'class_event_not_found' => Response::notFound('Class event not found', $request->traceId),
                'class_event_not_bookable' => Response::conflict('class_event_not_bookable', 'Class event is not bookable', $request->traceId),
                'class_event_full' => Response::conflict('class_event_full', 'Class is full', $request->traceId),
                'customer_not_found' => Response::notFound('Customer not found for this business', $request->traceId),
                'class_event_waitlist_disabled' => Response::conflict(
                    'class_event_waitlist_disabled',
                    'Waitlist is disabled for this class',
                    $request->traceId
                ),
                'invalid_target_status' => Response::error(
                    'target_status must be confirmed or waitlisted',
                    'validation_error',
                    400,
                    $request->traceId
                ),
                'class_booking_fetch_failed' => Response::error(
                    'Booking created but failed to reload booking payload',
                    'class_booking_fetch_failed',
                    500,
                    $request->traceId
                ),
                'class_booking_missing_timezone' => Response::error(
                    'Location timezone missing for class booking',
                    'class_booking_missing_timezone',
                    500,
                    $request->traceId
                ),
                'class_booking_invalid_timezone' => Response::error(
                    'Location timezone invalid for class booking',
                    'class_booking_invalid_timezone',
                    500,
                    $request->traceId
                ),
                'Missing location timezone for class event' => Response::error(
                    'Location timezone missing for class event',
                    'class_event_missing_timezone',
                    500,
                    $request->traceId
                ),
                'Invalid location timezone for class event' => Response::error(
                    'Location timezone invalid for class event',
                    'class_event_invalid_timezone',
                    500,
                    $request->traceId
                ),
                default => Response::serverError('Unable to create class booking', $request->traceId),
            };
        } catch (\Throwable) {
            return Response::serverError('Unable to create class booking', $request->traceId);
        }

        if ($notifyCustomer && $this->queueClassBookingNotification !== null && !empty($booking['id'])) {
            $previousStatus = strtoupper((string) ($existingBooking['status'] ?? ''));
            $status = strtoupper((string) ($booking['status'] ?? ''));
            $channel = match (true) {
                $previousStatus === 'WAITLISTED' && $status === 'CONFIRMED' => 'class_booking_promoted',
                $status === 'WAITLISTED' => 'class_booking_waitlisted',
                default => 'class_booking_confirmed',
            };
            try {
                $this->queueClassBookingNotification->execute(
                    (int) $booking['id'],
                    $businessId,
                    $channel
                );
            } catch (\Throwable) {
                // notification failure must not block booking response
            }
        }

        return Response::success($this->formatClassBooking($booking));
    }

    public function cancelBooking(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $customerId = isset($body['customer_id'])
            ? (int) $body['customer_id']
            : $this->resolveCustomerId($businessId, $userId);
        $notifyCustomer = $this->readBoolFromBody($body, 'notify_customer', true);
        if ($customerId === null || $customerId <= 0) {
            return Response::error('customer_id is required', 'validation_error', 400, $request->traceId);
        }

        $existingBooking = $this->classEventRepo->findBookingByCustomer(
            $businessId,
            $classEventId,
            $customerId
        );

        try {
            $result = $this->classEventRepo->cancelBooking($businessId, $classEventId, $customerId);
        } catch (\Throwable) {
            return Response::serverError('Unable to cancel class booking', $request->traceId);
        }

        if (!$result['ok']) {
            return Response::notFound('Class booking not found', $request->traceId);
        }
        if ($notifyCustomer && $this->queueClassBookingNotification !== null) {
            if ($existingBooking !== null && !empty($existingBooking['id'])) {
                try {
                    $this->queueClassBookingNotification->execute(
                        (int) $existingBooking['id'],
                        $businessId,
                        'class_booking_cancelled'
                    );
                } catch (\Throwable) {
                    // notification failure must not block booking response
                }
            }
            if ($result['promotedClassBookingId'] !== null) {
                try {
                    $this->queueClassBookingNotification->execute(
                        $result['promotedClassBookingId'],
                        $businessId,
                        'class_booking_promoted'
                    );
                } catch (\Throwable) {
                    // notification failure must not block booking response
                }
            }
        }
        return Response::success(['cancelled' => true]);
    }

    public function reorderWaitlist(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $classEventId = (int) $request->getRouteParam('id');
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        if (!$this->canManage($userId, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $customerIdsRaw = $body['customer_ids'] ?? null;
        if (!is_array($customerIdsRaw)) {
            return Response::error('customer_ids must be an array', 'validation_error', 400, $request->traceId);
        }

        $customerIds = array_values(array_map(static fn ($id): int => (int) $id, $customerIdsRaw));
        $customerIds = array_values(array_filter($customerIds, static fn (int $id): bool => $id > 0));
        if (count($customerIds) !== count($customerIdsRaw)) {
            return Response::error('customer_ids must contain only positive integers', 'validation_error', 400, $request->traceId);
        }
        if (count(array_unique($customerIds)) !== count($customerIds)) {
            return Response::error('customer_ids must be unique', 'validation_error', 400, $request->traceId);
        }

        try {
            $this->classEventRepo->reorderWaitlist($businessId, $classEventId, $customerIds);
        } catch (\RuntimeException $e) {
            return match ($e->getMessage()) {
                'class_event_not_found' => Response::notFound('Class event not found', $request->traceId),
                'invalid_waitlist_order' => Response::error(
                    'Invalid waitlist order payload',
                    'invalid_waitlist_order',
                    400,
                    $request->traceId
                ),
                default => Response::serverError('Unable to reorder waitlist', $request->traceId),
            };
        } catch (\Throwable) {
            return Response::serverError('Unable to reorder waitlist', $request->traceId);
        }

        return Response::success(['reordered' => true]);
    }

    /**
     * POST /v1/customer/{business_id}/class-events/{id}/book
     * Prenota un posto in un evento di classe come cliente autenticato.
     * Middleware: customer_auth  →  attributes: client_id, business_id
     */
    public function bookCustomer(Request $request): Response
    {
        $routeBusinessId = (int) $request->getRouteParam('business_id');
        $classEventId    = (int) $request->getRouteParam('id');
        $clientId        = $request->getAttribute('client_id');
        $tokenBusinessId = $request->getAttribute('business_id');

        if ($clientId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401, $request->traceId);
        }

        // Il JWT deve appartenere allo stesso business
        if ((int) $tokenBusinessId !== $routeBusinessId) {
            return Response::error('Invalid token for this business', 'unauthorized', 401, $request->traceId);
        }

        // Verifica che il cliente non sia bloccato/archiviato
        if ($this->clientRepo !== null) {
            $client = $this->clientRepo->findByIdUnfiltered((int) $clientId);
            if ($client === null || !empty($client['is_archived']) || !empty($client['blocked'])) {
                return Response::error('Customer account is disabled', 'unauthorized', 401, $request->traceId);
            }
        }

        // Carica l'evento
        $event = $this->classEventRepo->findById($routeBusinessId, $classEventId, null);
        if ($event === null) {
            return Response::notFound('Class event not found', $request->traceId);
        }

        $body = $request->getBody();
        $body = is_array($body) ? $body : [];
        $directLinkSlug = trim((string) ($body['booking_direct_link_slug'] ?? ''));

        // Solo eventi schedulati, pubblici e abilitati online sono prenotabili online.
        if (
            ($event['status'] ?? '') !== 'SCHEDULED' ||
            ($event['visibility'] ?? '') !== 'PUBLIC' ||
            (int) ($event['is_bookable_online'] ?? 1) !== 1 ||
            (string) ($event['online_visibility'] ?? 'public') === 'hidden'
        ) {
            return Response::conflict('class_event_not_bookable', 'Class event is not bookable', $request->traceId);
        }
        if ((string) ($event['online_visibility'] ?? 'public') === 'direct_link') {
            if (
                $directLinkSlug === '' ||
                $this->directLinkRepo === null ||
                !$this->directLinkRepo->authorizesClassEvent($routeBusinessId, $directLinkSlug, $classEventId)
            ) {
                return Response::conflict('class_event_not_bookable', 'Class event is not bookable', $request->traceId);
            }
        }

        // Controlla finestra di prenotazione
        $now = new \DateTimeImmutable('now', new \DateTimeZone('UTC'));
        if (!empty($event['booking_open_at'])) {
            $openAt = new \DateTimeImmutable($event['booking_open_at'], new \DateTimeZone('UTC'));
            if ($now < $openAt) {
                return Response::conflict('booking_not_open', 'Booking is not open yet', $request->traceId);
            }
        }
        if (!empty($event['booking_close_at'])) {
            $closeAt = new \DateTimeImmutable($event['booking_close_at'], new \DateTimeZone('UTC'));
            if ($now > $closeAt) {
                return Response::conflict('booking_closed', 'Booking window has closed', $request->traceId);
            }
        }

        try {
            $booking = $this->classEventRepo->book($routeBusinessId, $classEventId, (int) $clientId);
        } catch (\RuntimeException $e) {
            return match ($e->getMessage()) {
                'class_event_not_found'    => Response::notFound('Class event not found', $request->traceId),
                'class_event_not_bookable' => Response::conflict('class_event_not_bookable', 'Class event is not bookable', $request->traceId),
                'class_event_full'         => Response::conflict('class_event_full', 'Class is full and waitlist is disabled', $request->traceId),
                default                    => Response::serverError('Unable to create class booking', $request->traceId),
            };
        } catch (\Throwable) {
            return Response::serverError('Unable to create class booking', $request->traceId);
        }

        // Notifica: confirmed o waitlisted a seconda dello status
        if ($this->queueClassBookingNotification !== null && !empty($booking['id'])) {
            $status = strtolower((string) ($booking['status'] ?? ''));
            $channel = $status === 'waitlisted' ? 'class_booking_waitlisted' : 'class_booking_confirmed';
            try {
                $this->queueClassBookingNotification->execute(
                    (int) $booking['id'],
                    $routeBusinessId,
                    $channel
                );
            } catch (\Throwable) {
                // notification failure must not block booking response
            }
        }

        return Response::created($this->formatClassBooking($booking));
    }

    /**
     * POST /v1/customer/{business_id}/class-events/{id}/cancel-booking
     * Cancella la prenotazione di un cliente autenticato.
     * Middleware: customer_auth  →  attributes: client_id, business_id
     */
    public function cancelBookingCustomer(Request $request): Response
    {
        $routeBusinessId = (int) $request->getRouteParam('business_id');
        $classEventId    = (int) $request->getRouteParam('id');
        $clientId        = $request->getAttribute('client_id');
        $tokenBusinessId = $request->getAttribute('business_id');

        if ($clientId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401, $request->traceId);
        }

        if ((int) $tokenBusinessId !== $routeBusinessId) {
            return Response::error('Invalid token for this business', 'unauthorized', 401, $request->traceId);
        }

        // Carica l'evento per il check del cancel_cutoff_minutes
        $event = $this->classEventRepo->findById($routeBusinessId, $classEventId, null);
        if ($event === null) {
            return Response::notFound('Class event not found', $request->traceId);
        }

        // Controlla cutoff cancellazione
        $cutoffMinutes = (int) ($event['cancel_cutoff_minutes'] ?? 0);
        if ($cutoffMinutes > 0 && !empty($event['starts_at'])) {
            $now      = new \DateTimeImmutable('now', new \DateTimeZone('UTC'));
            $startsAt = new \DateTimeImmutable($event['starts_at'], new \DateTimeZone('UTC'));
            $minutesToEvent = ($startsAt->getTimestamp() - $now->getTimestamp()) / 60;
            if ($minutesToEvent < $cutoffMinutes) {
                return Response::conflict(
                    'cancel_cutoff_passed',
                    'Cancellation is no longer allowed',
                    $request->traceId
                );
            }
        }

        // Recupera il booking ID prima di cancellare (per la notifica)
        $existingBooking = $this->classEventRepo->findBookingByCustomer(
            $routeBusinessId,
            $classEventId,
            (int) $clientId
        );

        try {
            $result = $this->classEventRepo->cancelBooking($routeBusinessId, $classEventId, (int) $clientId);
        } catch (\Throwable) {
            return Response::serverError('Unable to cancel class booking', $request->traceId);
        }

        if (!$result['ok']) {
            return Response::notFound('Class booking not found', $request->traceId);
        }

        if ($this->queueClassBookingNotification !== null) {
            // Notifica cancellazione al cliente che ha annullato
            if ($existingBooking !== null && !empty($existingBooking['id'])) {
                try {
                    $this->queueClassBookingNotification->execute(
                        (int) $existingBooking['id'],
                        $routeBusinessId,
                        'class_booking_cancelled'
                    );
                } catch (\Throwable) {}
            }
            // Notifica promozione da waitlist
            if ($result['promotedClassBookingId'] !== null) {
                try {
                    $this->queueClassBookingNotification->execute(
                        $result['promotedClassBookingId'],
                        $routeBusinessId,
                        'class_booking_promoted'
                    );
                } catch (\Throwable) {}
            }
        }

        return Response::success(['cancelled' => true]);
    }

    /**
     * GET /v1/customer/class-bookings
     * Restituisce le prenotazioni di classe del cliente autenticato suddivise in
     * upcoming / past / cancelled.
     * Middleware: customer_auth  →  attributes: client_id, business_id
     */
    public function myClassBookings(Request $request): Response
    {
        $clientId   = $request->getAttribute('client_id');
        $businessId = (int) $request->getAttribute('business_id');

        if ($clientId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401, $request->traceId);
        }

        $rows              = $this->classEventRepo->getCustomerClassBookings($businessId, (int) $clientId);
        $now               = new \DateTimeImmutable('now', new \DateTimeZone('UTC'));
        $cancelledStatuses = ['CANCELLED_BY_CUSTOMER', 'CANCELLED_BY_STAFF'];

        $upcoming  = [];
        $past      = [];
        $cancelled = [];

        foreach ($rows as $row) {
            $formatted = $this->formatCustomerClassBooking($row, $now);
            $status    = $row['status'] ?? '';

            if (in_array($status, $cancelledStatuses, true)) {
                $cancelled[] = $formatted;
            } elseif (!empty($row['starts_at']) &&
                new \DateTimeImmutable($row['starts_at'], new \DateTimeZone('UTC')) > $now) {
                $upcoming[] = $formatted;
            } else {
                $past[] = $formatted;
            }
        }

        return Response::success([
            'upcoming'  => $upcoming,
            'past'      => $past,
            'cancelled' => $cancelled,
        ]);
    }

    private function formatCustomerClassBooking(array $row, \DateTimeImmutable $now): array
    {
        $locationTimezone = $row['location_timezone'] ?? 'UTC';
        $startsAt         = $row['starts_at'] ?? null;
        $endsAt           = $row['ends_at']   ?? null;
        $status           = $row['status']    ?? '';

        $isActiveBooking = in_array($status, ['CONFIRMED', 'WAITLISTED'], true);
        $isFuture        = $startsAt !== null
            && new \DateTimeImmutable($startsAt, new \DateTimeZone('UTC')) > $now;

        $canCancel      = false;
        $canCancelUntil = null;

        if ($isActiveBooking && $isFuture) {
            $cutoffMinutes = (int) ($row['cancel_cutoff_minutes'] ?? 0);
            if ($cutoffMinutes > 0) {
                $startsAtDt       = new \DateTimeImmutable((string) $startsAt, new \DateTimeZone('UTC'));
                $canCancelUntilDt = $startsAtDt->modify("-{$cutoffMinutes} minutes");
                $canCancelUntil   = $canCancelUntilDt->format('Y-m-d\TH:i:s\Z');
                $canCancel        = $now < $canCancelUntilDt;
            } else {
                $canCancel = true;
            }
        }

        return [
            'id'                   => (int) $row['id'],
            'business_id'          => (int) $row['business_id'],
            'class_event_id'       => (int) $row['class_event_id'],
            'class_type_id'        => (int) $row['class_type_id'],
            'class_type_name'      => (string) ($row['class_type_name'] ?? ''),
            'class_type_color_hex' => $row['class_type_color_hex'] ?? null,
            'location_id'          => (int) $row['location_id'],
            'location_name'        => (string) ($row['location_name'] ?? ''),
            'location_address'     => $row['location_address'] ?? null,
            'location_city'        => $row['location_city']    ?? null,
            'starts_at'            => $startsAt,
            'starts_at_local'      => $startsAt !== null
                ? $this->formatUtcSqlToLocationLocal((string) $startsAt, $locationTimezone)
                : null,
            'ends_at'              => $endsAt,
            'ends_at_local'        => $endsAt !== null
                ? $this->formatUtcSqlToLocationLocal((string) $endsAt, $locationTimezone)
                : null,
            'status'               => strtolower($status),
            'waitlist_position'    => isset($row['waitlist_position']) ? (int) $row['waitlist_position'] : null,
            'price_cents'          => isset($row['price_cents']) ? (int) $row['price_cents'] : null,
            'currency'             => $row['currency'] ?? null,
            'can_cancel'           => $canCancel,
            'can_cancel_until'     => $canCancelUntil,
            'booked_at'            => $row['booked_at']    ?? null,
            'cancelled_at'         => $row['cancelled_at'] ?? null,
        ];
    }

    private function canRead(int $userId, int $businessId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    private function canManage(int $userId, int $businessId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_services', false);
    }

    private function canManageLocation(int $userId, int $businessId, int $locationId): bool
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasLocationAccess($userId, $businessId, $locationId);
    }

    private function resolveCustomerId(int $businessId, int $userId): ?int
    {
        return $this->classEventRepo->findClientIdByUser($businessId, $userId);
    }

    private function toSqlUtc(string $isoDateTime): string
    {
        $dt = new \DateTimeImmutable($isoDateTime);
        return $dt->setTimezone(new \DateTimeZone('UTC'))->format('Y-m-d H:i:s');
    }

    private function toSqlUtcForLocation(string $isoDateTime, int $locationId): string
    {
        $raw = trim($isoDateTime);
        if ($raw === '') {
            throw new \InvalidArgumentException('Invalid datetime');
        }

        $hasOffset = str_ends_with($raw, 'Z') || (bool) preg_match('/[+\-]\d{2}:\d{2}$/', $raw);
        if ($hasOffset) {
            return $this->toSqlUtc($raw);
        }

        $timezone = $this->locationRepo->getTimezone($locationId);
        if (!is_string($timezone) || trim($timezone) === '') {
            throw new \InvalidArgumentException('Missing location timezone');
        }
        $dt = new \DateTimeImmutable($raw, new \DateTimeZone($timezone));
        return $dt->setTimezone(new \DateTimeZone('UTC'))->format('Y-m-d H:i:s');
    }

    /**
     * Parse filter datetimes in a deterministic way:
     * - with explicit offset/Z: trust input instant
     * - without offset: location_id is required to resolve location timezone
     */
    private function toSqlUtcForFilter(string $isoDateTime, ?int $locationId): string
    {
        $raw = trim($isoDateTime);
        if ($raw === '') {
            throw new \InvalidArgumentException('Invalid datetime');
        }

        $hasOffset = str_ends_with($raw, 'Z') || (bool) preg_match('/[+\-]\d{2}:\d{2}$/', $raw);
        if ($hasOffset) {
            return $this->toSqlUtc($raw);
        }

        if ($locationId === null || $locationId <= 0) {
            throw new \InvalidArgumentException('location_id is required when from/to has no timezone offset');
        }

        $timezoneName = $this->locationRepo->getTimezone($locationId);
        if (!is_string($timezoneName) || trim($timezoneName) === '') {
            throw new \InvalidArgumentException('Missing location timezone');
        }

        $dt = new \DateTimeImmutable($raw, new \DateTimeZone($timezoneName));
        return $dt->setTimezone(new \DateTimeZone('UTC'))->format('Y-m-d H:i:s');
    }

    private function formatUtcSqlToLocationLocal(string $sqlUtcDateTime, string $timezone): string
    {
        $utc = new \DateTimeImmutable($sqlUtcDateTime, new \DateTimeZone('UTC'));
        return $utc->setTimezone(new \DateTimeZone($timezone))->format('Y-m-d H:i:s');
    }

    private function validatedOnlineVisibility(array $body, Request $request): string|Response|null
    {
        if (!array_key_exists('online_visibility', $body)) {
            return null;
        }

        $value = strtolower(trim((string) $body['online_visibility']));
        if (!in_array($value, ['public', 'direct_link', 'hidden'], true)) {
            return Response::error('Invalid online_visibility', 'validation_error', 400, $request->traceId);
        }

        return $value;
    }

    private function directLinkScopeFromQuery(Request $request, int $businessId, ?int $locationId = null): ?array
    {
        $link = trim((string) ($request->queryParam('link') ?? ''));
        if ($link === '' || $this->directLinkRepo === null) {
            return null;
        }

        $scope = $this->directLinkRepo->resolveAvailableScope($businessId, $link);
        if (
            $scope !== null
            && ($scope['target_type'] ?? null) === BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY
        ) {
            $scope['child_visibility_scope'] = $this->directLinkRepo->resolveCategoryChildVisibilityScope(
                $businessId,
                (int) ($scope['target_id'] ?? 0),
                $locationId
            );
        }

        return $scope;
    }

    private function validateCreateOrUpdate(array $body, bool $isCreate): ?string
    {
        $startsAt = $body['starts_at'] ?? $body['starts_at_utc'] ?? null;
        $endsAt = $body['ends_at'] ?? $body['ends_at_utc'] ?? null;

        if ($isCreate) {
            if (!array_key_exists('class_type_id', $body)) {
                return 'class_type_id is required';
            }
            if ($startsAt === null) {
                return 'starts_at is required';
            }
            if ($endsAt === null) {
                return 'ends_at is required';
            }
        }

        if ($startsAt !== null && $endsAt !== null) {
            try {
                $start = new \DateTimeImmutable((string) $startsAt);
                $end = new \DateTimeImmutable((string) $endsAt);
                if ($end <= $start) {
                    return 'ends_at must be greater than starts_at';
                }
            } catch (\Throwable) {
                return 'Invalid starts_at or ends_at';
            }
        }

        if (isset($body['capacity_total']) && (int) $body['capacity_total'] < 1) {
            return 'capacity_total must be >= 1';
        }

        if ($isCreate && !array_key_exists('location_id', $body)) {
            return 'location_id is required';
        }
        if (array_key_exists('location_id', $body)) {
            if ($body['location_id'] === null || (int) $body['location_id'] <= 0) {
                return 'location_id must be > 0';
            }
        }

        $staffId = $body['staff_id'] ?? $body['instructor_staff_id'] ?? null;
        if ($isCreate && $staffId === null) {
            return 'staff_id is required';
        }
        if ($staffId !== null && (int) $staffId <= 0) {
            return 'staff_id must be > 0';
        }

        if (array_key_exists('resource_requirements', $body)) {
            if (!is_array($body['resource_requirements'])) {
                return 'resource_requirements must be an array';
            }
            $seenResourceIds = [];
            foreach ($body['resource_requirements'] as $item) {
                if (!is_array($item) || !isset($item['resource_id'])) {
                    return 'resource_requirements item must include resource_id';
                }
                $resourceId = (int) $item['resource_id'];
                if ($resourceId <= 0) {
                    return 'resource_requirements.resource_id must be > 0';
                }
                if (isset($seenResourceIds[$resourceId])) {
                    return 'resource_requirements contains duplicated resource_id';
                }
                $seenResourceIds[$resourceId] = true;
                if (isset($item['quantity']) && (int) $item['quantity'] < 1) {
                    return 'resource_requirements.quantity must be >= 1';
                }
            }
        }

        return null;
    }

    private function formatClassEvent(array $row, array $resourceRequirements = []): array
    {
        $locationTimezone = $this->requireLocationTimezone($row);
        $spotsLeft = max(
            0,
            (int) ($row['capacity_total'] ?? 1) -
                (int) ($row['capacity_reserved'] ?? 0) -
                (int) ($row['confirmed_count'] ?? 0)
        );

        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'class_type_id' => (int) $row['class_type_id'],
            'class_type_name' => $row['class_type_name'] ?? null,
            'class_type_color_hex' => $row['class_type_color_hex'] ?? null,
            'starts_at' => $row['starts_at'],
            'starts_at_local' => $this->formatUtcSqlToLocationLocal(
                (string) $row['starts_at'],
                $locationTimezone
            ),
            'ends_at' => $row['ends_at'],
            'ends_at_local' => $this->formatUtcSqlToLocationLocal(
                (string) $row['ends_at'],
                $locationTimezone
            ),
            'location_id' => (int) $row['location_id'],
            'staff_id' => (int) $row['staff_id'],
            'instructor_staff_id' => (int) $row['staff_id'],
            'resource_requirements' => $resourceRequirements,
            'capacity_total' => (int) ($row['capacity_total'] ?? 1),
            'capacity_reserved' => (int) ($row['capacity_reserved'] ?? 0),
            'confirmed_count' => (int) ($row['confirmed_count'] ?? 0),
            'waitlist_count' => (int) ($row['waitlist_count'] ?? 0),
            'waitlist_enabled' => (int) ($row['waitlist_enabled'] ?? 0) === 1,
            'is_bookable_online' => (int) ($row['is_bookable_online'] ?? 1) === 1,
            'online_visibility' => (string) ($row['online_visibility'] ?? 'public'),
            'booking_open_at' => $row['booking_open_at'] ?? null,
            'booking_open_at_local' => isset($row['booking_open_at']) && $row['booking_open_at'] !== null
                ? $this->formatUtcSqlToLocationLocal(
                    (string) $row['booking_open_at'],
                    $locationTimezone
                )
                : null,
            'booking_close_at' => $row['booking_close_at'] ?? null,
            'booking_close_at_local' => isset($row['booking_close_at']) && $row['booking_close_at'] !== null
                ? $this->formatUtcSqlToLocationLocal(
                    (string) $row['booking_close_at'],
                    $locationTimezone
                )
                : null,
            'cancel_cutoff_minutes' => (int) ($row['cancel_cutoff_minutes'] ?? 0),
            'status' => $row['status'] ?? 'SCHEDULED',
            'visibility' => $row['visibility'] ?? 'PUBLIC',
            'price_cents' => isset($row['price_cents']) ? (int) $row['price_cents'] : null,
            'currency' => $row['currency'] ?? null,
            'spots_left' => $spotsLeft,
            'is_full' => $spotsLeft <= 0,
            'my_booking_status' => $row['my_booking_status'] ?? null,
        ];
    }

    /**
     * Like formatClassEvent but adds class_type metadata (color, category)
     * needed by the public booking portal.
     */
    private function formatClassEventPublic(array $row, array $resourceRequirements = []): array
    {
        $base = $this->formatClassEvent($row, $resourceRequirements);

        $base['class_type_color_hex']           = $row['class_type_color_hex'] ?? null;
        $base['class_type_service_category_id'] = isset($row['class_type_service_category_id'])
            ? (int) $row['class_type_service_category_id']
            : null;

        return $base;
    }

    private function normalizeResourceRequirements(array $body): array
    {
        if (array_key_exists('resource_requirements', $body) && is_array($body['resource_requirements'])) {
            $normalized = [];
            $seen = [];
            foreach ($body['resource_requirements'] as $item) {
                if (!is_array($item) || !isset($item['resource_id'])) {
                    continue;
                }
                $resourceId = (int) $item['resource_id'];
                if ($resourceId <= 0 || isset($seen[$resourceId])) {
                    continue;
                }
                $seen[$resourceId] = true;
                $normalized[] = [
                    'resource_id' => $resourceId,
                    'quantity' => isset($item['quantity']) ? max(1, (int) $item['quantity']) : 1,
                ];
            }
            return $normalized;
        }

        if (array_key_exists('resource_id', $body)) {
            $resourceId = (int) $body['resource_id'];
            if ($resourceId > 0) {
                return [[
                    'resource_id' => $resourceId,
                    'quantity' => 1,
                ]];
            }
        }

        return [];
    }

    private function extractResourceIds(array $resourceRequirements): array
    {
        $ids = [];
        foreach ($resourceRequirements as $item) {
            if (!is_array($item) || !isset($item['resource_id'])) {
                continue;
            }
            $resourceId = (int) $item['resource_id'];
            if ($resourceId > 0) {
                $ids[] = $resourceId;
            }
        }
        return array_values(array_unique($ids));
    }

    private function formatClassBooking(array $row): array
    {
        $locationTimezone = $this->requireLocationTimezone($row);
        $bookedAt = $row['booked_at'] ?? null;
        $cancelledAt = $row['cancelled_at'] ?? null;
        $checkedInAt = $row['checked_in_at'] ?? null;

        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'class_event_id' => (int) $row['class_event_id'],
            'customer_id' => (int) $row['customer_id'],
            'status' => strtolower((string) $row['status']),
            'waitlist_position' => isset($row['waitlist_position']) ? (int) $row['waitlist_position'] : null,
            'booked_at' => $bookedAt,
            'booked_at_local' => $bookedAt !== null
                ? $this->formatUtcSqlToLocationLocal((string) $bookedAt, $locationTimezone)
                : null,
            'cancelled_at' => $cancelledAt,
            'cancelled_at_local' => $cancelledAt !== null
                ? $this->formatUtcSqlToLocationLocal((string) $cancelledAt, $locationTimezone)
                : null,
            'checked_in_at' => $checkedInAt,
            'checked_in_at_local' => $checkedInAt !== null
                ? $this->formatUtcSqlToLocationLocal((string) $checkedInAt, $locationTimezone)
                : null,
            'payment_status' => $row['payment_status'] ?? null,
            'notes' => $row['notes'] ?? null,
            'customer_first_name' => $row['customer_first_name'] ?? null,
            'customer_last_name' => $row['customer_last_name'] ?? null,
            'location_timezone' => $locationTimezone,
        ];
    }

    private function requireLocationTimezone(array $row): string
    {
        $timezone = trim((string) ($row['location_timezone'] ?? ''));
        if ($timezone === '') {
            throw new \RuntimeException('Missing location timezone in class event payload');
        }

        // Validate timezone identifier.
        new \DateTimeZone($timezone);
        return $timezone;
    }

    private function formatClassType(array $row, array $locationIds = []): array
    {
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'name' => (string) ($row['name'] ?? ''),
            'description' => $row['description'] ?? null,
            'color_hex' => $row['color_hex'] ?? null,
            'service_category_id' => isset($row['service_category_id']) ? (int) $row['service_category_id'] : null,
            'sort_order' => (int) ($row['sort_order'] ?? 0),
            'is_active' => (int) ($row['is_active'] ?? 1) === 1,
            'location_ids' => array_values(array_map('intval', $locationIds)),
        ];
    }

    private function normalizeServiceCategoryId(int $businessId, mixed $raw, bool $required): array
    {
        if ($raw === null) {
            if ($required) {
                return ['error' => 'service_category_id is required'];
            }
            return ['value' => null];
        }
        if (is_string($raw) && trim($raw) === '') {
            if ($required) {
                return ['error' => 'service_category_id is required'];
            }
            return ['value' => null];
        }

        if (!is_int($raw) && !is_float($raw) && !(is_string($raw) && ctype_digit(trim($raw)))) {
            return ['error' => 'service_category_id must be an integer'];
        }

        $value = (int) $raw;
        if ($value <= 0) {
            return ['error' => 'service_category_id must be greater than 0'];
        }

        if (!$this->classEventRepo->serviceCategoryExistsInBusiness($businessId, $value)) {
            return ['error' => 'service_category_id does not belong to business'];
        }

        return ['value' => $value];
    }

    private function isDuplicateKeyError(\Throwable $e): bool
    {
        return $e instanceof \PDOException && (string) ($e->getCode() ?? '') === '23000';
    }

    private function isForeignKeyConstraintError(\Throwable $e): bool
    {
        if (!$e instanceof \PDOException) {
            return false;
        }
        $message = strtolower((string) $e->getMessage());
        return str_contains($message, 'foreign key constraint fails');
    }

    private function readBoolFromBody(array $body, string $key, bool $default): bool
    {
        if (!array_key_exists($key, $body)) {
            return $default;
        }

        $value = $body[$key];
        if (is_bool($value)) {
            return $value;
        }
        if (is_int($value) || is_float($value)) {
            return ((int) $value) !== 0;
        }
        if (is_string($value)) {
            $normalized = strtolower(trim($value));
            if (in_array($normalized, ['1', 'true', 'yes', 'on'], true)) {
                return true;
            }
            if (in_array($normalized, ['0', 'false', 'no', 'off'], true)) {
                return false;
            }
        }

        return $default;
    }

    /**
     * @return int[]|null
     */
    private function normalizeOptionalCustomerIds(mixed $raw): ?array
    {
        if ($raw === null) {
            return null;
        }
        if (!is_array($raw)) {
            return null;
        }
        $ids = array_values(array_unique(array_map(
            static fn ($id): int => (int) $id,
            $raw
        )));
        return array_values(array_filter($ids, static fn (int $id): bool => $id > 0));
    }

    /**
     * @param int[]|null $customerIds
     */
    private function queueClassEventNotifications(
        int $businessId,
        int $classEventId,
        string $channel,
        ?array $customerIds = null
    ): void {
        if ($this->queueClassBookingNotification === null) {
            return;
        }

        $customerSet = null;
        if ($customerIds !== null) {
            $customerSet = array_fill_keys($customerIds, true);
            if (empty($customerSet)) {
                return;
            }
        }

        $participants = $this->classEventRepo->findParticipants($businessId, $classEventId);
        foreach ($participants as $participant) {
            $status = strtoupper((string) ($participant['status'] ?? ''));
            if (!in_array($status, ['CONFIRMED', 'WAITLISTED'], true)) {
                continue;
            }
            $customerId = (int) ($participant['customer_id'] ?? 0);
            if ($customerSet !== null && !isset($customerSet[$customerId])) {
                continue;
            }
            $classBookingId = (int) ($participant['id'] ?? 0);
            if ($classBookingId <= 0) {
                continue;
            }
            try {
                $this->queueClassBookingNotification->execute(
                    $classBookingId,
                    $businessId,
                    $channel
                );
            } catch (\Throwable) {
                // notification failure must not block class event mutations
            }
        }
    }

    private function resolveClassTypeLocationIdsForMutation(
        Request $request,
        int $userId,
        int $businessId,
        array $body,
        bool $isCreate
    ): array {
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);
        $allowedLocationIds = $isSuperadmin
            ? null
            : $this->businessUserRepo->getAllowedLocationIds($userId, $businessId);

        $hasLocationIds = array_key_exists('location_ids', $body);
        if (!$hasLocationIds) {
            if ($isCreate && is_array($allowedLocationIds)) {
                return ['location_ids' => $allowedLocationIds];
            }
            return ['location_ids' => null];
        }

        if (!is_array($body['location_ids'])) {
            return ['error' => 'location_ids must be an array'];
        }

        $locationIds = array_values(array_unique(array_map(
            static fn ($id): int => (int) $id,
            $body['location_ids']
        )));
        $locationIds = array_values(array_filter($locationIds, static fn ($id): bool => $id > 0));

        if (is_array($allowedLocationIds)) {
            if (empty($locationIds)) {
                return ['error' => 'location_ids cannot be empty for location-scoped operators'];
            }
            $allowedSet = array_map('intval', $allowedLocationIds);
            foreach ($locationIds as $locationId) {
                if (!in_array($locationId, $allowedSet, true)) {
                    return ['error' => 'location_ids contains unauthorized locations'];
                }
            }
        }

        if (!$this->classEventRepo->locationsBelongToBusiness($businessId, $locationIds)) {
            return ['error' => 'location_ids must belong to the specified business'];
        }

        return ['location_ids' => $locationIds];
    }
}
