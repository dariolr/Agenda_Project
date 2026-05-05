<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Authorization;

use Agenda\Http\Request;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use DomainException;

final class LocationAuthorizationService
{
    public const ERROR_CODE = 'forbidden_location_scope';

    public function __construct(
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly LocationRepository $locationRepo,
        private readonly UserRepository $userRepo,
    ) {}

    public function canAccessAllBusinessLocations(Request $request, int $businessId): bool
    {
        $userId = $request->userId();
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        $businessUser = $this->businessUserRepo->findByUserAndBusiness($userId, $businessId);
        return $businessUser !== null && ($businessUser['scope_type'] ?? 'business') === 'business';
    }

    /**
     * @return int[]
     */
    public function getAllowedLocationIdsForRequest(Request $request, int $businessId): array
    {
        $userId = $request->userId();
        if ($userId === null) {
            return [];
        }

        if ($this->canAccessAllBusinessLocations($request, $businessId)) {
            return array_map(
                static fn(array $location): int => (int) $location['id'],
                $this->locationRepo->findByBusinessId($businessId)
            );
        }

        $allowedLocationIds = $this->businessUserRepo->getAllowedLocationIds($userId, $businessId);
        if (!is_array($allowedLocationIds)) {
            return [];
        }

        return array_values(array_map('intval', $allowedLocationIds));
    }

    public function assertCanAccessLocation(Request $request, int $businessId, int $locationId): void
    {
        $this->assertCanAccessOnlyLocations($request, $businessId, [$locationId]);
    }

    /**
     * @param int[] $locationIds
     */
    public function assertCanAccessOnlyLocations(Request $request, int $businessId, array $locationIds): void
    {
        $locationIds = array_values(array_unique(array_map('intval', $locationIds)));
        $locationIds = array_values(array_filter($locationIds, static fn(int $id): bool => $id > 0));
        if (empty($locationIds) || $this->canAccessAllBusinessLocations($request, $businessId)) {
            return;
        }

        $allowed = array_flip($this->getAllowedLocationIdsForRequest($request, $businessId));
        foreach ($locationIds as $locationId) {
            if (!isset($allowed[$locationId])) {
                throw new DomainException(self::ERROR_CODE);
            }
        }
    }
}
