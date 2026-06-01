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
        $target = $this->directLinkRepo->loadTarget(
            $businessId,
            $targetType,
            $targetId
        );
        $urlLocationId = (int) ($request->queryParam('location_id') ?? 0);
        $linkLocationId = (int) ($link['location_id'] ?? 0);
        if (
            $target === null
            || !$this->targetIsAvailable((string) $link['target_type'], $target)
            || !$this->locationBelongsToBusiness($businessId, $linkLocationId)
            || ($linkLocationId > 0 && ($urlLocationId <= 0 || $urlLocationId !== $linkLocationId))
        ) {
            return $this->notAvailable(409, $request);
        }

        $payload = [
            'business_id' => $businessId,
            'business_slug' => (string) $business['slug'],
            'link_slug' => (string) $link['slug'],
            'location_id' => $linkLocationId,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'target' => $this->formatTarget($targetType, $target),
        ];

        if ($targetType === BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY) {
            $payload['child_visibility_scope'] = $this->directLinkRepo->resolveCategoryChildVisibilityScope(
                $businessId,
                $targetId,
                $linkLocationId > 0 ? $linkLocationId : null
            );
        }

        return Response::success($payload);
    }

    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $targetType = trim((string) ($request->queryParam('target_type') ?? ''));
        $targetId = (int) ($request->queryParam('target_id') ?? 0);
        $locationId = (int) ($request->queryParam('location_id') ?? 0);

        if ($targetType === '' || $targetId <= 0) {
            return Response::error('target_type and target_id are required', 'validation_error', 400, $request->traceId);
        }

        try {
            $link = $this->directLinkRepo->findByTarget(
                $businessId,
                $targetType,
                $targetId,
                $locationId > 0 ? $locationId : null
            );
        } catch (InvalidArgumentException) {
            return Response::error('Invalid target_type', 'validation_error', 400, $request->traceId);
        }

        return Response::success([
            'link' => $link !== null ? $this->formatAdminLink($request, $businessId, $link) : null,
        ]);
    }

    public function createOrGet(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $targetType = trim((string) ($body['target_type'] ?? ''));
        $targetId = (int) ($body['target_id'] ?? 0);
        $locationId = (int) ($body['location_id'] ?? 0);

        if ($targetType === '' || $targetId <= 0 || $locationId <= 0) {
            return Response::error('target_type, target_id and location_id are required', 'validation_error', 400, $request->traceId);
        }

        try {
            if (!$this->locationBelongsToBusiness($businessId, $locationId)) {
                return Response::error('Invalid location for this business', 'validation_error', 400, $request->traceId);
            }

            $baseName = $this->directLinkRepo->targetBaseName($businessId, $targetType, $targetId);
            if ($baseName === null || $baseName === '') {
                return Response::notFound('Target not found', $request->traceId);
            }

            if (!$this->targetMatchesLocation($businessId, $targetType, $targetId, $locationId)) {
                return Response::error('Target does not belong to location_id', 'validation_error', 400, $request->traceId);
            }

            $link = $this->directLinkRepo->createOrUpdateForTarget(
                $businessId,
                $targetType,
                $targetId,
                $locationId,
                $baseName
            );
        } catch (InvalidArgumentException) {
            return Response::error('Invalid target_type', 'validation_error', 400, $request->traceId);
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

        foreach (['name', 'service_id', 'location_id', 'category_id', 'class_type_id', 'starts_at', 'ends_at'] as $key) {
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

        return [
            'id' => (int) $link['id'],
            'location_id' => (int) ($link['location_id'] ?? 0),
            'slug' => $linkSlug,
            'target_type' => (string) $link['target_type'],
            'target_id' => (int) $link['target_id'],
            'is_active' => (bool) ($link['is_active'] ?? true),
            'url' => rtrim(EnvironmentConfig::current()->webBaseUrl, '/') . '/' . $slug . '/booking?location=' . (int) ($link['location_id'] ?? 0) . '&link=' . rawurlencode($linkSlug),
        ];
    }

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
