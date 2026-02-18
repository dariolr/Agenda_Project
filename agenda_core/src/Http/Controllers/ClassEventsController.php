<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\ClassEventRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class ClassEventsController
{
    public function __construct(
        private readonly ClassEventRepository $classEventRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly LocationRepository $locationRepo,
        private readonly UserRepository $userRepo,
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

        try {
            $id = $this->classEventRepo->createClassType($businessId, [
                'name' => $name,
                'description' => array_key_exists('description', $body) ? $body['description'] : null,
                'is_active' => array_key_exists('is_active', $body) ? (bool) $body['is_active'] : true,
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
        if ($this->classEventRepo->hasClassEventsForType($businessId, $classTypeId)) {
            return Response::conflict(
                'class_type_in_use',
                'Cannot delete class type with existing scheduled classes',
                $request->traceId
            );
        }

        try {
            $deleted = $this->classEventRepo->deleteClassType($businessId, $classTypeId);
        } catch (\Throwable $e) {
            if ($this->isForeignKeyConstraintError($e)) {
                return Response::conflict(
                    'class_type_in_use',
                    'Cannot delete class type with existing scheduled classes',
                    $request->traceId
                );
            }
            return Response::serverError('Unable to delete class type', $request->traceId);
        }

        if (!$deleted) {
            return Response::notFound('Class type not found', $request->traceId);
        }
        return Response::success(['deleted' => true]);
    }

    public function index(Request $request): Response
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

        try {
            $from = new \DateTimeImmutable($fromRaw);
            $to = new \DateTimeImmutable($toRaw);
        } catch (\Throwable) {
            return Response::error('Invalid from/to datetime format', 'validation_error', 400, $request->traceId);
        }

        $locationId = $request->queryParam('location_id');
        $classTypeId = $request->queryParam('class_type_id');

        $items = $this->classEventRepo->findByBusinessAndRange(
            $businessId,
            $from->format('Y-m-d H:i:s'),
            $to->format('Y-m-d H:i:s'),
            $locationId !== null && $locationId !== '' ? (int) $locationId : null,
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
        if ($customerId === null || $customerId <= 0) {
            return Response::error('customer_id is required', 'validation_error', 400, $request->traceId);
        }

        try {
            $booking = $this->classEventRepo->book($businessId, $classEventId, $customerId);
        } catch (\RuntimeException $e) {
            return match ($e->getMessage()) {
                'class_event_not_found' => Response::notFound('Class event not found', $request->traceId),
                'class_event_not_bookable' => Response::conflict('class_event_not_bookable', 'Class event is not bookable', $request->traceId),
                'class_event_full' => Response::conflict('class_event_full', 'Class is full', $request->traceId),
                default => Response::serverError('Unable to create class booking', $request->traceId),
            };
        } catch (\Throwable) {
            return Response::serverError('Unable to create class booking', $request->traceId);
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
        if ($customerId === null || $customerId <= 0) {
            return Response::error('customer_id is required', 'validation_error', 400, $request->traceId);
        }

        try {
            $ok = $this->classEventRepo->cancelBooking($businessId, $classEventId, $customerId);
        } catch (\Throwable) {
            return Response::serverError('Unable to cancel class booking', $request->traceId);
        }

        if (!$ok) {
            return Response::notFound('Class booking not found', $request->traceId);
        }
        return Response::success(['cancelled' => true]);
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

        $timezone = $this->locationRepo->getTimezone($locationId) ?? 'Europe/Rome';
        $dt = new \DateTimeImmutable($raw, new \DateTimeZone($timezone));
        return $dt->setTimezone(new \DateTimeZone('UTC'))->format('Y-m-d H:i:s');
    }

    private function formatUtcSqlToLocationLocal(string $sqlUtcDateTime, string $timezone): string
    {
        $utc = new \DateTimeImmutable($sqlUtcDateTime, new \DateTimeZone('UTC'));
        return $utc->setTimezone(new \DateTimeZone($timezone))->format('Y-m-d H:i:s');
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
            'starts_at' => $row['starts_at'],
            'starts_at_local' => $this->formatUtcSqlToLocationLocal(
                (string) $row['starts_at'],
                (string) ($row['location_timezone'] ?? 'Europe/Rome')
            ),
            'ends_at' => $row['ends_at'],
            'ends_at_local' => $this->formatUtcSqlToLocationLocal(
                (string) $row['ends_at'],
                (string) ($row['location_timezone'] ?? 'Europe/Rome')
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
            'booking_open_at' => $row['booking_open_at'] ?? null,
            'booking_open_at_local' => isset($row['booking_open_at']) && $row['booking_open_at'] !== null
                ? $this->formatUtcSqlToLocationLocal(
                    (string) $row['booking_open_at'],
                    (string) ($row['location_timezone'] ?? 'Europe/Rome')
                )
                : null,
            'booking_close_at' => $row['booking_close_at'] ?? null,
            'booking_close_at_local' => isset($row['booking_close_at']) && $row['booking_close_at'] !== null
                ? $this->formatUtcSqlToLocationLocal(
                    (string) $row['booking_close_at'],
                    (string) ($row['location_timezone'] ?? 'Europe/Rome')
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
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'class_event_id' => (int) $row['class_event_id'],
            'customer_id' => (int) $row['customer_id'],
            'status' => (string) $row['status'],
            'waitlist_position' => isset($row['waitlist_position']) ? (int) $row['waitlist_position'] : null,
            'booked_at' => $row['booked_at'],
            'cancelled_at' => $row['cancelled_at'] ?? null,
            'checked_in_at' => $row['checked_in_at'] ?? null,
            'payment_status' => $row['payment_status'] ?? null,
            'notes' => $row['notes'] ?? null,
            'customer_first_name' => $row['customer_first_name'] ?? null,
            'customer_last_name' => $row['customer_last_name'] ?? null,
        ];
    }

    private function formatClassType(array $row, array $locationIds = []): array
    {
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'name' => (string) ($row['name'] ?? ''),
            'description' => $row['description'] ?? null,
            'is_active' => (int) ($row['is_active'] ?? 1) === 1,
            'location_ids' => array_values(array_map('intval', $locationIds)),
        ];
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
