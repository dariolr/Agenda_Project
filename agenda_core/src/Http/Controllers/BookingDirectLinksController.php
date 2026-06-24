<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Environment\EnvironmentConfig;
use Agenda\Infrastructure\Repositories\BookingDirectLinkRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use DateTimeImmutable;
use DateTimeZone;
use InvalidArgumentException;

final class BookingDirectLinksController
{
    public function __construct(
        private readonly BookingDirectLinkRepository $directLinkRepo,
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly LocationRepository $locationRepo,
        private readonly UserRepository $userRepo,
    ) {}

    public function resolve(Request $request): Response
    {
        $businessSlug = trim((string) ($request->queryParam('business_slug') ?? ''));
        $linkSlug = trim((string) ($request->queryParam('link') ?? ''));

        if ($businessSlug === '' || !$this->directLinkRepo->isValidSlug($linkSlug)) {
            return Response::error('Invalid booking direct link parameters', 'validation_error', 400, $request->traceId);
        }

        $business = $this->businessRepo->findBySlug($businessSlug);
        if (!$business || (int) ($business['is_active'] ?? 0) !== 1 || (int) ($business['is_suspended'] ?? 0) === 1) {
            return $this->notAvailable(404, $request);
        }

        $businessId = (int) $business['id'];
        $link = $this->directLinkRepo->findByBusinessAndSlug($businessId, $linkSlug);
        if ($link === null) {
            return $this->notAvailable(404, $request);
        }

        $targetType = (string) $link['target_type'];
        $targetId = (int) $link['target_id'];
        $urlLocationId = (int) ($request->queryParam('location_id') ?? 0);
        $scope = $this->directLinkRepo->resolveAvailableScope($businessId, $linkSlug, $urlLocationId > 0 ? $urlLocationId : null);
        if ($scope === null) {
            return $this->notAvailable(409, $request);
        }

        $target = $scope['target'];
        $scopeType = (string) ($scope['scope_type'] ?? BookingDirectLinkRepository::SCOPE_LOCATION);
        $locationId = $scopeType === BookingDirectLinkRepository::SCOPE_LOCATION
            ? (int) ($link['location_id'] ?? 0)
            : ($urlLocationId > 0 ? $urlLocationId : 0);
        $compatibleLocationIds = array_map('intval', $scope['compatible_location_ids'] ?? []);

        $payload = [
            'business_id' => $businessId,
            'business_slug' => (string) $business['slug'],
            'link_slug' => (string) $link['slug'],
            'scope_type' => $scopeType,
            'location_id' => $locationId,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'compatible_location_ids' => $compatibleLocationIds,
            'requires_location_selection' => $scopeType === BookingDirectLinkRepository::SCOPE_BUSINESS
                && $locationId <= 0
                && count($compatibleLocationIds) !== 1,
            'target' => $this->formatTarget($targetType, $target),
        ];

        if ($targetType === BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY) {
            $payload['child_visibility_scope'] = $this->directLinkRepo->resolveCategoryChildVisibilityScope(
                $businessId,
                $targetId,
                $locationId > 0 ? $locationId : null
            );
        }

        return Response::success($payload);
    }

    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $targetType = trim((string) ($request->queryParam('target_type') ?? ''));
        $targetId = (int) ($request->queryParam('target_id') ?? 0);
        $scopeType = trim((string) ($request->queryParam('scope_type') ?? BookingDirectLinkRepository::SCOPE_LOCATION));
        $locationId = (int) ($request->queryParam('location_id') ?? 0);

        if ($targetType === '' || $targetId <= 0) {
            return Response::error('target_type and target_id are required', 'validation_error', 400, $request->traceId);
        }

        if (!$this->hasBusinessAccessForTarget($request, $businessId, $targetType)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        try {
            $link = $this->directLinkRepo->findByTarget(
                $businessId,
                $targetType,
                $targetId,
                $scopeType === BookingDirectLinkRepository::SCOPE_LOCATION && $locationId > 0 ? $locationId : null,
                $scopeType
            );
            $compatibleLocationIds = in_array($targetType, [BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY, BookingDirectLinkRepository::TARGET_STAFF], true)
                ? $this->directLinkRepo->compatibleLocationIdsForLink($businessId, $targetType, $targetId)
                : ($locationId > 0 ? [$locationId] : []);
        } catch (InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400, $request->traceId);
        }

        return Response::success([
            'link' => $link !== null ? $this->formatAdminLink($request, $businessId, $link) : null,
            'compatible_location_ids' => $compatibleLocationIds,
            'requires_location_selection' => count($compatibleLocationIds) > 1,
        ]);
    }

    public function createOrGet(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $body = $request->getBody() ?? [];
        $targetType = trim((string) ($body['target_type'] ?? ''));
        $targetId = (int) ($body['target_id'] ?? 0);
        $scopeType = trim((string) ($body['scope_type'] ?? BookingDirectLinkRepository::SCOPE_LOCATION));
        $locationId = array_key_exists('location_id', $body) && $body['location_id'] !== null
            ? (int) $body['location_id']
            : null;

        if ($targetType === '' || $targetId <= 0) {
            return Response::error('target_type and target_id are required', 'validation_error', 400, $request->traceId);
        }

        if (!$this->hasBusinessAccessForTarget($request, $businessId, $targetType)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        try {
            $this->directLinkRepo->assertTargetType($targetType);
            if (!in_array($scopeType, [BookingDirectLinkRepository::SCOPE_LOCATION, BookingDirectLinkRepository::SCOPE_BUSINESS], true)) {
                return Response::error('Invalid scope_type', 'validation_error', 400, $request->traceId);
            }
            if ($scopeType === BookingDirectLinkRepository::SCOPE_LOCATION && (!$locationId || !$this->locationBelongsToBusiness($businessId, $locationId))) {
                return Response::error('Invalid location for this business', 'validation_error', 400, $request->traceId);
            }
            if ($scopeType === BookingDirectLinkRepository::SCOPE_BUSINESS && !in_array($targetType, [BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY, BookingDirectLinkRepository::TARGET_STAFF], true)) {
                return Response::error('Business-scoped direct links are allowed only for service_category and staff', 'validation_error', 400, $request->traceId);
            }

            $baseName = $this->directLinkRepo->targetBaseName($businessId, $targetType, $targetId);
            if ($baseName === null || $baseName === '') {
                return Response::notFound('Target not found', $request->traceId);
            }

            if ($scopeType === BookingDirectLinkRepository::SCOPE_LOCATION && !$this->targetMatchesLocation($businessId, $targetType, $targetId, (int) $locationId)) {
                return Response::error('Target does not belong to location_id', 'validation_error', 400, $request->traceId);
            }
            if ($scopeType === BookingDirectLinkRepository::SCOPE_BUSINESS && empty($this->directLinkRepo->compatibleLocationIdsForLink($businessId, $targetType, $targetId))) {
                return Response::error('Target is not available for online booking', 'validation_error', 400, $request->traceId);
            }

            $link = $this->directLinkRepo->createOrUpdateForTarget(
                $businessId,
                $targetType,
                $targetId,
                $locationId,
                $baseName,
                $scopeType
            );
        } catch (InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400, $request->traceId);
        }

        return Response::success($this->formatAdminLink($request, $businessId, $link), 201);
    }

    public function update(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        return Response::error('Updating booking direct links is not implemented yet', 'not_implemented', 501, $request->traceId);
    }

    private function targetIsAvailable(string $targetType, array $target): bool
    {
        return match ($targetType) {
            BookingDirectLinkRepository::TARGET_SERVICE_VARIANT =>
                in_array((string) ($target['online_visibility'] ?? 'public'), ['public', 'direct_link'], true)
                &&
                (int) ($target['is_active'] ?? 0) === 1
                && (int) ($target['service_is_active'] ?? 0) === 1
                && (int) ($target['location_is_active'] ?? 0) === 1
                && (int) ($target['location_online_booking_enabled'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1,
            BookingDirectLinkRepository::TARGET_SERVICE_PACKAGE =>
                in_array((string) ($target['online_visibility'] ?? 'public'), ['public', 'direct_link'], true)
                &&
                (int) ($target['is_active'] ?? 0) === 1
                && (int) ($target['is_broken'] ?? 0) === 0
                && (int) ($target['location_is_active'] ?? 0) === 1
                && (int) ($target['location_online_booking_enabled'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1,
            BookingDirectLinkRepository::TARGET_CLASS_EVENT =>
                in_array((string) ($target['online_visibility'] ?? 'public'), ['public', 'direct_link'], true)
                &&
                (string) ($target['status'] ?? '') === 'SCHEDULED'
                && (string) ($target['visibility'] ?? '') === 'PUBLIC'
                && (int) ($target['location_is_active'] ?? 0) === 1
                && (int) ($target['location_online_booking_enabled'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1
                && $this->classEventWindowIsOpen($target),
            BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY => true,
            BookingDirectLinkRepository::TARGET_STAFF =>
                (int) ($target['is_active'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1,
            default => false,
        };
    }

    private function locationBelongsToBusiness(int $businessId, int $locationId): bool
    {
        $location = $this->locationRepo->findById($locationId);
        return $location !== null && (int) ($location['business_id'] ?? 0) === $businessId;
    }

    private function targetMatchesLocation(
        int $businessId,
        string $targetType,
        int $targetId,
        int $locationId
    ): bool {
        $target = $this->directLinkRepo->loadTarget($businessId, $targetType, $targetId);
        if ($target === null) {
            return false;
        }

        return match ($targetType) {
            BookingDirectLinkRepository::TARGET_SERVICE_VARIANT,
            BookingDirectLinkRepository::TARGET_SERVICE_PACKAGE,
            BookingDirectLinkRepository::TARGET_CLASS_EVENT => (int) ($target['location_id'] ?? 0) === $locationId,
            BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY => true,
            BookingDirectLinkRepository::TARGET_STAFF => in_array($locationId, $this->directLinkRepo->compatibleLocationIdsForLink($businessId, $targetType, $targetId), true),
            default => false,
        };
    }

    private function classEventWindowIsOpen(array $target): bool
    {
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        $startsAt = new DateTimeImmutable((string) $target['starts_at'], new DateTimeZone('UTC'));
        if ($startsAt <= $now) {
            return false;
        }

        if (!empty($target['booking_open_at'])) {
            $openAt = new DateTimeImmutable((string) $target['booking_open_at'], new DateTimeZone('UTC'));
            if ($openAt > $now) {
                return false;
            }
        }

        if (!empty($target['booking_close_at'])) {
            $closeAt = new DateTimeImmutable((string) $target['booking_close_at'], new DateTimeZone('UTC'));
            if ($closeAt <= $now) {
                return false;
            }
        }

        return true;
    }

    private function formatTarget(string $targetType, array $target): array
    {
        $payload = ['id' => (int) $target['id']];
        if ($targetType !== BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY && array_key_exists('online_visibility', $target)) {
            $payload['online_visibility'] = (string) $target['online_visibility'];
        }

        foreach (['name', 'surname', 'display_name', 'avatar_url', 'color_hex', 'service_id', 'location_id', 'category_id', 'class_type_id', 'starts_at', 'ends_at'] as $key) {
            if (array_key_exists($key, $target)) {
                $payload[$key] = is_numeric($target[$key]) ? (int) $target[$key] : $target[$key];
            }
        }

        $payload['target_type'] = $targetType;
        return $payload;
    }

    private function formatAdminLink(Request $request, int $businessId, array $link): array
    {
        $business = $this->businessRepo->findById($businessId);
        $slug = (string) ($business['slug'] ?? '');
        $linkSlug = (string) $link['slug'];
        $scopeType = (string) ($link['scope_type'] ?? BookingDirectLinkRepository::SCOPE_LOCATION);
        $locationId = isset($link['location_id']) ? (int) $link['location_id'] : 0;
        $compatibleLocationIds = $scopeType === BookingDirectLinkRepository::SCOPE_BUSINESS
            ? $this->directLinkRepo->compatibleLocationIdsForLink($businessId, (string) $link['target_type'], (int) $link['target_id'])
            : [];
        $query = $scopeType === BookingDirectLinkRepository::SCOPE_BUSINESS
            ? '?link=' . rawurlencode($linkSlug)
            : '?location=' . $locationId . '&link=' . rawurlencode($linkSlug);

        return [
            'id' => (int) $link['id'],
            'scope_type' => $scopeType,
            'location_id' => $locationId,
            'compatible_location_ids' => $compatibleLocationIds,
            'slug' => $linkSlug,
            'target_type' => (string) $link['target_type'],
            'target_id' => (int) $link['target_id'],
            'is_active' => (bool) ($link['is_active'] ?? true),
            'url' => rtrim(EnvironmentConfig::current()->webBaseUrl, '/') . '/' . $slug . '/booking' . $query,
        ];
    }

    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        return $this->hasBusinessAccessForTarget($request, $businessId, null);
    }

    private function hasBusinessAccessForTarget(Request $request, int $businessId, ?string $targetType): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        if ($targetType === BookingDirectLinkRepository::TARGET_STAFF) {
            return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_staff', false)
                || $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_services', false);
        }

        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_services', false);
    }

    private function notAvailable(int $status, Request $request): Response
    {
        return Response::error(
            'Booking direct link is not available',
            'booking_direct_link_not_available',
            $status,
            $request->traceId
        );
    }
}
