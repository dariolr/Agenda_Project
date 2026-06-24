<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Domain\Helpers\Unicode;
use Agenda\Infrastructure\Database\Connection;
use InvalidArgumentException;

final class BookingDirectLinkRepository
{
    public const TARGET_SERVICE_VARIANT = 'service_variant';
    public const TARGET_SERVICE_PACKAGE = 'service_package';
    public const TARGET_CLASS_EVENT = 'class_event';
    public const TARGET_SERVICE_CATEGORY = 'service_category';
    public const TARGET_STAFF = 'staff';

    public const SCOPE_LOCATION = 'location';
    public const SCOPE_BUSINESS = 'business';

    private const TARGET_TYPES = [
        self::TARGET_SERVICE_VARIANT,
        self::TARGET_SERVICE_PACKAGE,
        self::TARGET_CLASS_EVENT,
        self::TARGET_SERVICE_CATEGORY,
        self::TARGET_STAFF,
    ];

    private const SCOPE_TYPES = [
        self::SCOPE_LOCATION,
        self::SCOPE_BUSINESS,
    ];

    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findByBusinessAndSlug(int $businessId, string $slug): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT *
             FROM booking_direct_links
             WHERE business_id = ?
               AND slug = ?
               AND is_active = 1
             LIMIT 1'
        );
        $stmt->execute([$businessId, $slug]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public function findByTarget(
        int $businessId,
        string $targetType,
        int $targetId,
        ?int $locationId = null,
        string $scopeType = self::SCOPE_LOCATION
    ): ?array
    {
        $this->assertTargetType($targetType);
        $this->assertScopeType($scopeType);

        $sql = 'SELECT *
             FROM booking_direct_links
             WHERE business_id = ?
               AND target_type = ?
               AND target_id = ?
               AND COALESCE(scope_type, ?) = ?';
        $params = [$businessId, $targetType, $targetId, self::SCOPE_LOCATION, $scopeType];
        if ($scopeType === self::SCOPE_LOCATION) {
            $sql .= ' AND location_id = ?';
            $params[] = (int) $locationId;
        } else {
            $sql .= ' AND location_id IS NULL';
        }
        $sql .= ' ORDER BY is_active DESC, id ASC
             LIMIT 1';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public function createOrUpdateForTarget(
        int $businessId,
        string $targetType,
        int $targetId,
        ?int $locationId,
        string $baseName,
        string $scopeType = self::SCOPE_LOCATION
    ): array {
        $this->assertTargetType($targetType);
        $this->assertValidScopeForTarget($targetType, $scopeType, $locationId);

        $existing = $this->findByTarget($businessId, $targetType, $targetId, $locationId, $scopeType);
        if ($existing !== null) {
            if ((int) $existing['is_active'] !== 1) {
                $stmt = $this->db->getPdo()->prepare(
                    'UPDATE booking_direct_links SET is_active = 1, updated_at = NOW() WHERE id = ?'
                );
                $stmt->execute([(int) $existing['id']]);
                $existing['is_active'] = 1;
            }
            return $existing;
        }

        $slug = $this->generateUniqueSlug($businessId, $baseName);
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO booking_direct_links (business_id, location_id, scope_type, slug, target_type, target_id, is_active)
             VALUES (?, ?, ?, ?, ?, ?, 1)'
        );
        $stmt->execute([
            $businessId,
            $scopeType === self::SCOPE_LOCATION ? (int) $locationId : null,
            $scopeType,
            $slug,
            $targetType,
            $targetId,
        ]);

        return [
            'id' => (int) $this->db->getPdo()->lastInsertId(),
            'business_id' => $businessId,
            'location_id' => $scopeType === self::SCOPE_LOCATION ? (int) $locationId : null,
            'scope_type' => $scopeType,
            'slug' => $slug,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'is_active' => 1,
        ];
    }

    public function deactivateForTarget(
        int $businessId,
        string $targetType,
        int $targetId,
        ?int $locationId = null
    ): void
    {
        $this->assertTargetType($targetType);

        $sql = 'UPDATE booking_direct_links
             SET is_active = 0, updated_at = NOW()
             WHERE business_id = ?
               AND target_type = ?
               AND target_id = ?';
        $params = [$businessId, $targetType, $targetId];
        if ($locationId !== null) {
            $sql .= ' AND location_id = ?';
            $params[] = $locationId;
        }
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
    }

    public function generateUniqueSlug(int $businessId, string $baseName): string
    {
        $baseSlug = $this->slugify($baseName);
        $slug = $baseSlug;
        $suffix = 2;

        while ($this->slugExists($businessId, $slug)) {
            $candidateSuffix = '-' . $suffix;
            $slug = substr($baseSlug, 0, 160 - strlen($candidateSuffix)) . $candidateSuffix;
            $suffix++;
        }

        return $slug;
    }

    public function loadTarget(int $businessId, string $targetType, int $targetId): ?array
    {
        $this->assertTargetType($targetType);

        return match ($targetType) {
            self::TARGET_SERVICE_VARIANT => $this->loadServiceVariant($businessId, $targetId),
            self::TARGET_SERVICE_PACKAGE => $this->loadServicePackage($businessId, $targetId),
            self::TARGET_CLASS_EVENT => $this->loadClassEvent($businessId, $targetId),
            self::TARGET_SERVICE_CATEGORY => $this->loadServiceCategory($businessId, $targetId),
            self::TARGET_STAFF => $this->loadStaff($businessId, $targetId),
        };
    }

    public function resolveAvailableScope(int $businessId, string $slug, ?int $enforceLocationId = null): ?array
    {
        if (!$this->isValidSlug($slug)) {
            return null;
        }

        $link = $this->findByBusinessAndSlug($businessId, $slug);
        if ($link === null) {
            return null;
        }

        $scopeType = (string) ($link['scope_type'] ?? self::SCOPE_LOCATION);
        $linkLocationId = (int) ($link['location_id'] ?? 0);
        if ($scopeType === self::SCOPE_LOCATION && ($linkLocationId <= 0 || $enforceLocationId === null || $enforceLocationId <= 0 || $enforceLocationId !== $linkLocationId)) {
            return null;
        }

        $targetType = (string) $link['target_type'];
        $targetId = (int) $link['target_id'];
        $target = $this->loadTarget($businessId, $targetType, $targetId);
        if ($target === null || !$this->targetIsOnlineAvailable($targetType, $target)) {
            return null;
        }

        $compatibleLocationIds = [];
        if ($scopeType === self::SCOPE_BUSINESS) {
            $compatibleLocationIds = $this->compatibleLocationIdsForLink($businessId, $targetType, $targetId);
            if (empty($compatibleLocationIds)) {
                return null;
            }
            if ($enforceLocationId !== null && $enforceLocationId > 0 && !in_array($enforceLocationId, $compatibleLocationIds, true)) {
                return null;
            }
        }

        $scope = [
            'scope_type' => $scopeType,
            'location_id' => $scopeType === self::SCOPE_LOCATION ? $linkLocationId : ($enforceLocationId ?? null),
            'compatible_location_ids' => $compatibleLocationIds,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'target' => $target,
        ];

        if ($targetType === self::TARGET_SERVICE_CATEGORY) {
            $scope['child_visibility_scope'] = $this->resolveCategoryChildVisibilityScope($businessId, $targetId, $enforceLocationId);
        }

        if ($targetType === self::TARGET_STAFF) {
            $scope['staff_id'] = $targetId;
        }

        return $scope;
    }

    public function targetBaseName(int $businessId, string $targetType, int $targetId): ?string
    {
        $target = $this->loadTarget($businessId, $targetType, $targetId);
        if (!is_array($target)) {
            return null;
        }

        if ($targetType === self::TARGET_CLASS_EVENT) {
            return $this->buildClassEventBaseName($target);
        }

        return (string) ($target['name'] ?? '');
    }

    public function authorizesDirectServiceIds(
        int $businessId,
        int $locationId,
        string $slug,
        array $directServiceIds,
        array $allRequestedServiceIds
    ): bool {
        $directServiceIds = $this->normalizePositiveIds($directServiceIds);
        $allRequestedServiceIds = $this->normalizePositiveIds($allRequestedServiceIds);
        if (empty($directServiceIds)) {
            return true;
        }

        $scope = $this->resolveAvailableScope($businessId, $slug, $locationId);
        if ($scope === null) {
            return false;
        }

        $targetType = (string) $scope['target_type'];
        $targetId = (int) $scope['target_id'];
        $target = $scope['target'];

        if ($targetType === self::TARGET_SERVICE_VARIANT) {
            return (int) ($target['location_id'] ?? 0) === $locationId
                && $directServiceIds === [(int) ($target['service_id'] ?? 0)];
        }

        if ($targetType === self::TARGET_SERVICE_CATEGORY) {
            if ($this->resolveCategoryChildVisibilityScope($businessId, $targetId, $locationId) !== 'direct_link_only') {
                return false;
            }
            return $this->directServicesBelongToCategory(
                $businessId,
                $locationId,
                $targetId,
                $directServiceIds
            );
        }

        if ($targetType === self::TARGET_SERVICE_PACKAGE) {
            if ((int) ($target['location_id'] ?? 0) !== $locationId) {
                return false;
            }
            $packageServiceIds = $this->loadPackageServiceIds($businessId, $targetId);
            sort($packageServiceIds);
            sort($allRequestedServiceIds);
            return $packageServiceIds === $allRequestedServiceIds;
        }

        return false;
    }

    public function authorizesRequestedServiceIds(
        int $businessId,
        int $locationId,
        string $slug,
        array $requestedServiceIds
    ): bool {
        $requestedServiceIds = $this->normalizePositiveIds($requestedServiceIds);
        if (empty($requestedServiceIds)) {
            return false;
        }

        $scope = $this->resolveAvailableScope($businessId, $slug, $locationId);
        if ($scope === null) {
            return false;
        }

        $targetType = (string) $scope['target_type'];
        $targetId = (int) $scope['target_id'];
        $target = $scope['target'];

        return match ($targetType) {
            self::TARGET_SERVICE_VARIANT =>
                (int) ($target['location_id'] ?? 0) === $locationId
                && $requestedServiceIds === [(int) ($target['service_id'] ?? 0)],
            self::TARGET_SERVICE_PACKAGE =>
                (int) ($target['location_id'] ?? 0) === $locationId
                && $this->loadPackageServiceIds($businessId, $targetId) === $requestedServiceIds,
            self::TARGET_SERVICE_CATEGORY => $this->authorizesCategoryServicesForScope(
                $businessId,
                $locationId,
                $targetId,
                $requestedServiceIds
            ),
            self::TARGET_STAFF => $this->staffCanPerformServices(
                $businessId,
                $locationId,
                $targetId,
                $requestedServiceIds
            ),
            default => false,
        };
    }

    public function authorizesStaff(int $businessId, string $slug, int $staffId, ?int $locationId): bool
    {
        if ($staffId <= 0 || $locationId === null || $locationId <= 0) {
            return false;
        }

        $scope = $this->resolveAvailableScope($businessId, $slug, $locationId);
        return $scope !== null
            && ($scope['target_type'] ?? null) === self::TARGET_STAFF
            && (int) ($scope['target_id'] ?? 0) === $staffId;
    }

    public function authorizesRequestedServiceIdsForStaffLink(
        int $businessId,
        int $locationId,
        string $slug,
        int $staffId,
        array $requestedServiceIds
    ): bool {
        if (!$this->authorizesStaff($businessId, $slug, $staffId, $locationId)) {
            return false;
        }

        return $this->staffCanPerformServices($businessId, $locationId, $staffId, $requestedServiceIds);
    }

    public function compatibleLocationIdsForLink(int $businessId, string $targetType, int $targetId): array
    {
        $this->assertTargetType($targetType);

        if ($targetType === self::TARGET_SERVICE_CATEGORY) {
            $ids = [];
            foreach ($this->onlineLocationIdsForBusiness($businessId) as $locationId) {
                if ($this->categoryHasVisibleChildren($businessId, $targetId, 'public', $locationId)
                    || $this->categoryHasVisibleChildren($businessId, $targetId, 'direct_link', $locationId)
                ) {
                    $ids[] = $locationId;
                }
            }
            return $ids;
        }

        if ($targetType === self::TARGET_STAFF) {
            $stmt = $this->db->getPdo()->prepare(
                'SELECT DISTINCT l.id
                 FROM staff s
                 INNER JOIN staff_locations sl ON sl.staff_id = s.id
                 INNER JOIN locations l ON l.id = sl.location_id
                 WHERE s.id = ?
                   AND s.business_id = ?
                   AND s.is_active = 1
                   AND s.is_bookable_online = 1
                   AND l.business_id = ?
                   AND l.is_active = 1
                   AND l.online_booking_enabled = 1
                 ORDER BY l.sort_order ASC, l.name ASC, l.id ASC'
            );
            $stmt->execute([$targetId, $businessId, $businessId]);
            return array_map('intval', $stmt->fetchAll(\PDO::FETCH_COLUMN));
        }

        return [];
    }

    public function authorizesClassEvent(int $businessId, string $slug, int $classEventId): bool
    {
        $eventLocationId = $this->loadClassEventLocationId($businessId, $classEventId);
        if ($eventLocationId === null) {
            return false;
        }

        $scope = $this->resolveAvailableScope($businessId, $slug, $eventLocationId);
        if ($scope === null) {
            return false;
        }

        $targetType = (string) $scope['target_type'];
        $targetId = (int) $scope['target_id'];
        if ($targetType === self::TARGET_CLASS_EVENT) {
            return (int) $scope['target_id'] === $classEventId;
        }

        if ($targetType === self::TARGET_SERVICE_CATEGORY) {
            $visibilityScope = $this->resolveCategoryChildVisibilityScope($businessId, $targetId, $eventLocationId);
            if ($visibilityScope === 'empty') {
                return false;
            }
            $requiredVisibility = $visibilityScope === 'public_only' ? 'public' : 'direct_link';
            $stmt = $this->db->getPdo()->prepare(
                "SELECT 1
                 FROM class_events ce
                 INNER JOIN class_types ct ON ct.id = ce.class_type_id AND ct.business_id = ce.business_id
                 WHERE ce.id = ?
                   AND ce.business_id = ?
                   AND ct.service_category_id = ?
                   AND ce.online_visibility = ?
                   AND ce.visibility = 'PUBLIC'
                   AND ce.status = 'SCHEDULED'
                   AND ce.is_bookable_online = 1
                 LIMIT 1"
            );
            $stmt->execute([$classEventId, $businessId, $targetId, $requiredVisibility]);
            return $stmt->fetchColumn() !== false;
        }

        if ($targetType === self::TARGET_STAFF) {
            $stmt = $this->db->getPdo()->prepare(
                "SELECT 1
                 FROM class_events
                 WHERE id = ?
                   AND business_id = ?
                   AND location_id = ?
                   AND staff_id = ?
                   AND online_visibility = 'public'
                   AND visibility = 'PUBLIC'
                   AND status = 'SCHEDULED'
                   AND is_bookable_online = 1
                 LIMIT 1"
            );
            $stmt->execute([$classEventId, $businessId, $eventLocationId, $targetId]);
            return $stmt->fetchColumn() !== false;
        }

        return false;
    }

    public function resolveCategoryChildVisibilityScope(
        int $businessId,
        int $categoryId,
        ?int $locationId = null
    ): string {
        if ($this->categoryHasVisibleChildren($businessId, $categoryId, 'public', $locationId)) {
            return 'public_only';
        }

        if ($this->categoryHasVisibleChildren($businessId, $categoryId, 'direct_link', $locationId)) {
            return 'direct_link_only';
        }

        return 'empty';
    }

    public function assertTargetType(string $targetType): void
    {
        if (!in_array($targetType, self::TARGET_TYPES, true)) {
            throw new InvalidArgumentException('Invalid booking direct link target_type');
        }
    }

    private function assertScopeType(string $scopeType): void
    {
        if (!in_array($scopeType, self::SCOPE_TYPES, true)) {
            throw new InvalidArgumentException('Invalid booking direct link scope_type');
        }
    }

    private function assertValidScopeForTarget(string $targetType, string $scopeType, ?int $locationId): void
    {
        $this->assertScopeType($scopeType);

        if ($scopeType === self::SCOPE_LOCATION) {
            if ($locationId === null || $locationId <= 0) {
                throw new InvalidArgumentException('location_id is required for location-scoped booking direct links');
            }
            return;
        }

        if (!in_array($targetType, [self::TARGET_SERVICE_CATEGORY, self::TARGET_STAFF], true)) {
            throw new InvalidArgumentException('Business-scoped booking direct links are allowed only for service_category and staff');
        }

        if ($locationId !== null && $locationId > 0) {
            throw new InvalidArgumentException('location_id must be empty for business-scoped booking direct links');
        }
    }

    public function isValidSlug(string $slug): bool
    {
        return (bool) preg_match('/^[a-z0-9-]{1,160}$/', $slug);
    }

    private function slugExists(int $businessId, string $slug): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM booking_direct_links WHERE business_id = ? AND slug = ? LIMIT 1'
        );
        $stmt->execute([$businessId, $slug]);
        return $stmt->fetchColumn() !== false;
    }

    private function normalizePositiveIds(array $ids): array
    {
        $normalized = array_values(array_unique(array_filter(
            array_map(static fn ($id): int => (int) $id, $ids),
            static fn (int $id): bool => $id > 0
        )));
        sort($normalized);
        return $normalized;
    }

    private function directServicesBelongToCategory(
        int $businessId,
        int $locationId,
        int $categoryId,
        array $serviceIds
    ): bool {
        return $this->servicesBelongToCategoryWithVisibility(
            $businessId,
            $locationId,
            $categoryId,
            $serviceIds,
            'direct_link'
        );
    }

    private function servicesBelongToCategoryWithVisibility(
        int $businessId,
        int $locationId,
        int $categoryId,
        array $serviceIds,
        string $visibility
    ): bool {
        if (empty($serviceIds)) {
            return true;
        }

        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT COUNT(DISTINCT s.id)
             FROM services s
             INNER JOIN service_variants sv ON sv.service_id = s.id AND sv.location_id = ?
             WHERE s.id IN ({$placeholders})
               AND s.business_id = ?
               AND s.category_id = ?
               AND s.is_active = 1
               AND sv.is_active = 1
               AND sv.is_bookable_online = 1
               AND sv.online_visibility = ?"
        );
        $stmt->execute(array_merge([$locationId], $serviceIds, [$businessId, $categoryId, $visibility]));
        return (int) $stmt->fetchColumn() === count($serviceIds);
    }

    private function authorizesCategoryServicesForScope(
        int $businessId,
        int $locationId,
        int $categoryId,
        array $requestedServiceIds
    ): bool {
        $scope = $this->resolveCategoryChildVisibilityScope($businessId, $categoryId, $locationId);
        return match ($scope) {
            'public_only' => $this->servicesBelongToCategoryWithVisibility(
                $businessId,
                $locationId,
                $categoryId,
                $requestedServiceIds,
                'public'
            ),
            'direct_link_only' => $this->servicesBelongToCategoryWithVisibility(
                $businessId,
                $locationId,
                $categoryId,
                $requestedServiceIds,
                'direct_link'
            ),
            default => false,
        };
    }

    private function categoryHasVisibleChildren(
        int $businessId,
        int $categoryId,
        string $visibility,
        ?int $locationId = null
    ): bool {
        $pdo = $this->db->getPdo();

        $serviceSql = "SELECT 1
            FROM services s
            INNER JOIN service_variants sv
                ON sv.service_id = s.id
            INNER JOIN locations l
                ON l.id = sv.location_id
            WHERE s.business_id = ?
            AND s.category_id = ?
            AND s.is_active = 1
            AND sv.is_active = 1
            AND l.is_active = 1
            AND l.online_booking_enabled = 1
            AND sv.is_bookable_online = 1
            AND sv.online_visibility = ?";

        $serviceParams = [$businessId, $categoryId, $visibility];

        if ($locationId !== null) {
            $serviceSql .= " AND sv.location_id = ?";
            $serviceParams[] = $locationId;
        }

        $serviceSql .= " LIMIT 1";

        $stmt = $pdo->prepare($serviceSql);
        $stmt->execute($serviceParams);

        if ($stmt->fetchColumn() !== false) {
            return true;
        }

        $packageSql = "SELECT 1
            FROM service_packages sp
            INNER JOIN locations l
                ON l.id = sp.location_id
            WHERE sp.business_id = ?
            AND sp.category_id = ?
            AND sp.is_active = 1
            AND sp.is_broken = 0
            AND l.is_active = 1
            AND l.online_booking_enabled = 1
            AND sp.is_bookable_online = 1
            AND sp.online_visibility = ?";

        $packageParams = [$businessId, $categoryId, $visibility];

        if ($locationId !== null) {
            $packageSql .= " AND sp.location_id = ?";
            $packageParams[] = $locationId;
        }

        $packageSql .= " LIMIT 1";

        $stmt = $pdo->prepare($packageSql);
        $stmt->execute($packageParams);

        if ($stmt->fetchColumn() !== false) {
            return true;
        }

        $now = (new \DateTimeImmutable('now', new \DateTimeZone('UTC')))
            ->format('Y-m-d H:i:s');

        $eventSql = "SELECT 1
            FROM class_events ce
            INNER JOIN class_types ct
                ON ct.id = ce.class_type_id
            AND ct.business_id = ce.business_id
            INNER JOIN locations l
                ON l.id = ce.location_id
            WHERE ce.business_id = ?
            AND ct.service_category_id = ?
            AND ce.status = 'SCHEDULED'
            AND ce.visibility = 'PUBLIC'
            AND ce.is_bookable_online = 1
            AND ce.online_visibility = ?
            AND l.is_active = 1
            AND l.online_booking_enabled = 1
            AND ce.starts_at > ?
            AND (ce.booking_open_at IS NULL OR ce.booking_open_at <= ?)
            AND (ce.booking_close_at IS NULL OR ce.booking_close_at > ?)";

        $eventParams = [$businessId, $categoryId, $visibility, $now, $now, $now];

        if ($locationId !== null) {
            $eventSql .= " AND ce.location_id = ?";
            $eventParams[] = $locationId;
        }

        $eventSql .= " LIMIT 1";

        $stmt = $pdo->prepare($eventSql);
        $stmt->execute($eventParams);

        return $stmt->fetchColumn() !== false;
    }

    private function loadClassEventLocationId(int $businessId, int $classEventId): ?int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT location_id
             FROM class_events
             WHERE id = ?
               AND business_id = ?
             LIMIT 1'
        );
        $stmt->execute([$classEventId, $businessId]);
        $value = $stmt->fetchColumn();
        return $value === false ? null : (int) $value;
    }

    private function loadPackageServiceIds(int $businessId, int $packageId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT spi.service_id
             FROM service_package_items spi
             INNER JOIN service_packages sp ON sp.id = spi.package_id
             WHERE spi.package_id = ?
               AND sp.business_id = ?
             ORDER BY spi.sort_order ASC, spi.service_id ASC'
        );
        $stmt->execute([$packageId, $businessId]);
        return $this->normalizePositiveIds($stmt->fetchAll(\PDO::FETCH_COLUMN));
    }

    private function slugify(string $value): string
    {
        $value = trim(mb_strtolower($value));
        $value = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $value) ?: $value;
        $value = strtolower($value);
        $value = preg_replace('/[^a-z0-9]+/', '-', $value) ?? '';
        $value = trim($value, '-');

        if ($value === '') {
            $value = 'booking-link';
        }

        return substr($value, 0, 160);
    }

    private function targetIsOnlineAvailable(string $targetType, array $target): bool
    {
        return match ($targetType) {
            self::TARGET_SERVICE_VARIANT =>
                in_array((string) ($target['online_visibility'] ?? 'public'), ['public', 'direct_link'], true)
                &&
                (int) ($target['is_active'] ?? 0) === 1
                && (int) ($target['service_is_active'] ?? 0) === 1
                && (int) ($target['location_is_active'] ?? 0) === 1
                && (int) ($target['location_online_booking_enabled'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1,
            self::TARGET_SERVICE_PACKAGE =>
                in_array((string) ($target['online_visibility'] ?? 'public'), ['public', 'direct_link'], true)
                &&
                (int) ($target['is_active'] ?? 0) === 1
                && (int) ($target['is_broken'] ?? 0) === 0
                && (int) ($target['location_is_active'] ?? 0) === 1
                && (int) ($target['location_online_booking_enabled'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1,
            self::TARGET_CLASS_EVENT =>
                in_array((string) ($target['online_visibility'] ?? 'public'), ['public', 'direct_link'], true)
                &&
                (string) ($target['status'] ?? '') === 'SCHEDULED'
                && (string) ($target['visibility'] ?? '') === 'PUBLIC'
                && (int) ($target['location_is_active'] ?? 0) === 1
                && (int) ($target['location_online_booking_enabled'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1,
            self::TARGET_SERVICE_CATEGORY => true,
            self::TARGET_STAFF =>
                (int) ($target['is_active'] ?? 0) === 1
                && (int) ($target['is_bookable_online'] ?? 0) === 1,
            default => false,
        };
    }

    private function loadServiceVariant(int $businessId, int $targetId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT sv.*, s.business_id, s.name, s.description, s.category_id,
                    s.is_active AS service_is_active,
                    l.is_active AS location_is_active,
                    l.online_booking_enabled AS location_online_booking_enabled
             FROM service_variants sv
             INNER JOIN services s ON s.id = sv.service_id
             INNER JOIN locations l ON l.id = sv.location_id
             WHERE sv.id = ?
               AND s.business_id = ?
             LIMIT 1'
        );
        $stmt->execute([$targetId, $businessId]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    private function loadServicePackage(int $businessId, int $targetId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT sp.*, l.is_active AS location_is_active, l.online_booking_enabled AS location_online_booking_enabled
             FROM service_packages sp
             INNER JOIN locations l ON l.id = sp.location_id
             WHERE sp.id = ?
               AND sp.business_id = ?
             LIMIT 1'
        );
        $stmt->execute([$targetId, $businessId]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    private function loadClassEvent(int $businessId, int $targetId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT ce.*, ct.name AS name, l.is_active AS location_is_active, l.online_booking_enabled AS location_online_booking_enabled, l.timezone AS location_timezone
             FROM class_events ce
             LEFT JOIN class_types ct ON ct.id = ce.class_type_id AND ct.business_id = ce.business_id
             INNER JOIN locations l ON l.id = ce.location_id
             WHERE ce.id = ?
               AND ce.business_id = ?
             LIMIT 1'
        );
        $stmt->execute([$targetId, $businessId]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    private function buildClassEventBaseName(array $target): string
    {
        $name = trim((string) ($target['name'] ?? 'class-event'));
        $startsAt = trim((string) ($target['starts_at'] ?? ''));
        if ($startsAt === '') {
            return $name;
        }

        try {
            $startsAtUtc = new \DateTimeImmutable($startsAt, new \DateTimeZone('UTC'));
            $timezoneName = trim((string) ($target['location_timezone'] ?? ''));
            if ($timezoneName !== '') {
                $startsAtUtc = $startsAtUtc->setTimezone(new \DateTimeZone($timezoneName));
            }

            return sprintf(
                '%s-%s',
                $name,
                $startsAtUtc->format('Ymd-Hi')
            );
        } catch (\Throwable) {
            return $name;
        }
    }

    private function loadServiceCategory(int $businessId, int $targetId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT *
             FROM service_categories
             WHERE id = ?
               AND business_id = ?
             LIMIT 1'
        );
        $stmt->execute([$targetId, $businessId]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    private function loadStaff(int $businessId, int $targetId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, surname, avatar_url, color_hex, is_active, is_bookable_online, sort_order
             FROM staff
             WHERE id = ?
               AND business_id = ?
             LIMIT 1'
        );
        $stmt->execute([$targetId, $businessId]);
        $row = $stmt->fetch();
        if (!$row) {
            return null;
        }

        if (empty($row['display_name'])) {
            $row['display_name'] = trim((string) $row['name'] . ' ' . Unicode::firstCharacter((string) ($row['surname'] ?? '')) . '.');
        }

        return $row;
    }

    private function onlineLocationIdsForBusiness(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id
             FROM locations
             WHERE business_id = ?
               AND is_active = 1
               AND online_booking_enabled = 1
             ORDER BY sort_order ASC, name ASC, id ASC'
        );
        $stmt->execute([$businessId]);
        return array_map('intval', $stmt->fetchAll(\PDO::FETCH_COLUMN));
    }

    private function staffCanPerformServices(int $businessId, int $locationId, int $staffId, array $serviceIds): bool
    {
        $serviceIds = $this->normalizePositiveIds($serviceIds);
        if (empty($serviceIds)) {
            return false;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM staff s
             INNER JOIN staff_locations sl ON sl.staff_id = s.id AND sl.location_id = ?
             INNER JOIN locations l ON l.id = sl.location_id
             WHERE s.id = ?
               AND s.business_id = ?
               AND s.is_active = 1
               AND s.is_bookable_online = 1
               AND l.business_id = ?
               AND l.is_active = 1
               AND l.online_booking_enabled = 1
             LIMIT 1'
        );
        $stmt->execute([$locationId, $staffId, $businessId, $businessId]);
        if ($stmt->fetchColumn() === false) {
            return false;
        }

        $restrictionStmt = $this->db->getPdo()->prepare('SELECT COUNT(*) FROM staff_services WHERE staff_id = ?');
        $restrictionStmt->execute([$staffId]);
        if ((int) $restrictionStmt->fetchColumn() === 0) {
            return true;
        }

        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT COUNT(DISTINCT service_id)
             FROM staff_services
             WHERE staff_id = ? AND service_id IN ({$placeholders})"
        );
        $stmt->execute(array_merge([$staffId], $serviceIds));
        return (int) $stmt->fetchColumn() === count($serviceIds);
    }
}
