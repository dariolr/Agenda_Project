<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

final class ServicePackageRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findById(int $packageId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT *
             FROM service_packages
             WHERE id = ?'
        );
        $stmt->execute([$packageId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function findByLocationId(int $locationId, ?array $directLinkScope = null): array
    {
        $visibilitySql = "sp.online_visibility = 'public'";
        $params = [$locationId];

        if ($directLinkScope !== null) {
            $targetType = (string) ($directLinkScope['target_type'] ?? '');
            $targetId = (int) ($directLinkScope['target_id'] ?? 0);
            if ($targetType === BookingDirectLinkRepository::TARGET_SERVICE_PACKAGE) {
                $visibilitySql = "(sp.online_visibility = 'public' OR sp.id = ?)";
                $params[] = $targetId;
            } elseif ($targetType === BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY) {
                $scope = (string) ($directLinkScope['child_visibility_scope'] ?? 'empty');
                $allowed = match ($scope) {
                    'public_only' => "'public'",
                    'direct_link_only' => "'direct_link'",
                    default => null,
                };
                $visibilitySql = $allowed === null
                    ? '1 = 0'
                    : "sp.category_id = ? AND sp.online_visibility IN ({$allowed})";
                $params[] = $targetId;
            } elseif ($targetType === BookingDirectLinkRepository::TARGET_STAFF) {
                $visibilitySql = "sp.online_visibility = 'public'
                    AND NOT EXISTS (
                        SELECT 1
                        FROM service_package_items spi_staff
                        WHERE spi_staff.package_id = sp.id
                          AND EXISTS (SELECT 1 FROM staff_services ss_any WHERE ss_any.staff_id = ?)
                          AND NOT EXISTS (
                              SELECT 1
                              FROM staff_services ss
                              WHERE ss.staff_id = ?
                                AND ss.service_id = spi_staff.service_id
                          )
                    )";
                $params[] = $targetId;
                $params[] = $targetId;
            }
        }

        $stmt = $this->db->getPdo()->prepare(
            "SELECT sp.*, sc.name AS category_name
             FROM service_packages sp
             LEFT JOIN service_categories sc ON sc.id = sp.category_id
             WHERE sp.location_id = ?
               AND sp.is_active = 1
               AND sp.is_bookable_online = 1
               AND {$visibilitySql}
               AND sp.is_broken = 0
             ORDER BY sp.sort_order ASC, sp.name ASC, sp.id ASC"
        );
        $stmt->execute($params);
        $packages = $stmt->fetchAll();

        if (empty($packages)) {
            return [];
        }

        $packageIds = array_map(fn($p) => (int) $p['id'], $packages);
        $itemsByPackage = $this->getItemsForPackages($packageIds, $locationId);
        $totalsByPackage = $this->getTotalsForPackages($packageIds, $locationId);

        return array_map(
            fn(array $package) => $this->formatPackageRow(
                $package,
                $itemsByPackage,
                $totalsByPackage,
            ),
            $packages,
        );
    }

    public function findAdminByLocationId(int $locationId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            "SELECT sp.*, sc.name AS category_name
             FROM service_packages sp
             LEFT JOIN service_categories sc ON sc.id = sp.category_id
             WHERE sp.location_id = ?
               AND sp.is_active = 1
             ORDER BY sp.sort_order ASC, sp.name ASC, sp.id ASC"
        );
        $stmt->execute([$locationId]);
        $packages = $stmt->fetchAll();

        if (empty($packages)) {
            return [];
        }

        $packageIds = array_map(fn($p) => (int) $p['id'], $packages);
        $itemsByPackage = $this->getItemsForPackages($packageIds, $locationId);
        $totalsByPackage = $this->getTotalsForPackages($packageIds, $locationId, true);

        return array_map(
            fn(array $package) => $this->formatPackageRow(
                $package,
                $itemsByPackage,
                $totalsByPackage,
            ),
            $packages,
        );
    }

    public function getDetailedById(int $packageId, int $locationId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT sp.*, sc.name AS category_name
             FROM service_packages sp
             LEFT JOIN service_categories sc ON sc.id = sp.category_id
             WHERE sp.id = ? AND sp.location_id = ?'
        );
        $stmt->execute([$packageId, $locationId]);
        $package = $stmt->fetch();

        if (!$package) {
            return null;
        }

        $itemsByPackage = $this->getItemsForPackages([$packageId], $locationId);
        $totalsByPackage = $this->getTotalsForPackages([$packageId], $locationId);

        return $this->formatPackageRow($package, $itemsByPackage, $totalsByPackage);
    }

    public function create(array $data, array $serviceIds): int
    {
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();

        try {
            $sortOrder = $data['sort_order'] ?? $this->getNextSortOrder(
                (int) $data['category_id'],
                (int) $data['location_id'],
            );
            $stmt = $pdo->prepare(
                'INSERT INTO service_packages
                    (business_id, location_id, category_id, sort_order, name, description, override_price, override_duration_minutes, is_active, is_bookable_online, online_visibility, is_broken)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $onlineVisibility = $this->normalizeOnlineVisibility(
                $data['online_visibility'] ?? null,
                (int) ($data['is_bookable_online'] ?? 1) === 1
            );
            $stmt->execute([
                $data['business_id'],
                $data['location_id'],
                $data['category_id'],
                $sortOrder,
                $data['name'],
                $data['description'],
                $data['override_price'],
                $data['override_duration_minutes'],
                $data['is_active'],
                $onlineVisibility === 'hidden' ? 0 : 1,
                $onlineVisibility,
                $data['is_broken'],
            ]);

            $packageId = (int) $pdo->lastInsertId();
            $this->replaceItems($packageId, $serviceIds);

            $pdo->commit();

            return $packageId;
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function update(int $packageId, array $data, ?array $serviceIds): void
    {
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();

        try {
            if (array_key_exists('online_visibility', $data)) {
                $data['online_visibility'] = $this->normalizeOnlineVisibility(
                    $data['online_visibility'] !== null ? (string) $data['online_visibility'] : null,
                    (int) ($data['is_bookable_online'] ?? 1) === 1
                );
                $data['is_bookable_online'] = $data['online_visibility'] === 'hidden' ? 0 : 1;
            }

            if (!empty($data)) {
                $fields = [];
                $params = [];

                foreach ($data as $key => $value) {
                    $fields[] = "{$key} = ?";
                    $params[] = $value;
                }

                $params[] = $packageId;

                $stmt = $pdo->prepare(
                    'UPDATE service_packages SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE id = ?'
                );
                $stmt->execute($params);
            }

            if ($serviceIds !== null) {
                $this->replaceItems($packageId, $serviceIds);
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function delete(int $packageId): bool
    {
        $stmt = $this->db->getPdo()->prepare('DELETE FROM service_packages WHERE id = ?');
        return $stmt->execute([$packageId]);
    }

    public function validateServices(array $serviceIds, int $locationId, int $businessId): bool
    {
        if (empty($serviceIds)) {
            return false;
        }

        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $params = array_merge([$locationId], $serviceIds, [$businessId]);

        $stmt = $this->db->getPdo()->prepare(
            "SELECT COUNT(*) FROM services s
             JOIN service_variants sv ON s.id = sv.service_id AND sv.location_id = ?
             WHERE s.id IN ({$placeholders})
               AND s.business_id = ?
               AND s.is_active = 1
               AND sv.is_active = 1"
        );
        $stmt->execute($params);

        return (int) $stmt->fetchColumn() === count($serviceIds);
    }

    public function validateCategory(int $categoryId, int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM service_categories WHERE id = ? AND business_id = ?'
        );
        $stmt->execute([$categoryId, $businessId]);

        return (int) $stmt->fetchColumn() === 1;
    }

    public function allBelongToSameBusiness(array $packageIds, int $businessId): bool
    {
        if (empty($packageIds)) {
            return false;
        }

        $placeholders = implode(',', array_fill(0, count($packageIds), '?'));
        $params = array_merge($packageIds, [$businessId]);
        $stmt = $this->db->getPdo()->prepare(
            "SELECT COUNT(*) FROM service_packages WHERE id IN ({$placeholders}) AND business_id = ?"
        );
        $stmt->execute($params);

        return (int) $stmt->fetchColumn() === count($packageIds);
    }

    public function getExpanded(int $packageId, int $locationId, bool $allowDirectLink = false): ?array
    {
        $package = $this->findById($packageId);
        if (
            !$package
            || (int) $package['location_id'] !== $locationId
            || (int) ($package['is_bookable_online'] ?? 0) !== 1
            || (!$allowDirectLink && (string) ($package['online_visibility'] ?? 'public') !== 'public')
            || ($allowDirectLink && !in_array((string) ($package['online_visibility'] ?? 'public'), ['public', 'direct_link'], true))
        ) {
            return null;
        }

        $serviceIds = $this->getOrderedServiceIds($packageId);
        $totals = $this->getTotalsForPackages([$packageId], $locationId);
        $summary = $totals[$packageId] ?? [
            'total_duration' => 0,
            'total_price' => 0.0,
            'missing_count' => 0,
        ];

        $effectiveDuration = $package['override_duration_minutes'] !== null
            ? (int) $package['override_duration_minutes']
            : (int) $summary['total_duration'];
        $effectivePrice = $package['override_price'] !== null
            ? (float) $package['override_price']
            : (float) $summary['total_price'];

        return [
            'package_id' => (int) $package['id'],
            'location_id' => (int) $package['location_id'],
            'service_ids' => $serviceIds,
            'effective_price' => $effectivePrice,
            'effective_duration_minutes' => $effectiveDuration,
            'is_active' => (bool) $package['is_active'],
            'is_broken' => (bool) $package['is_broken'] || $summary['missing_count'] > 0,
        ];
    }

    public function getExpandedAdmin(int $packageId, int $locationId): ?array
    {
        $package = $this->findById($packageId);
        if (
            !$package
            || (int) $package['location_id'] !== $locationId
        ) {
            return null;
        }

        $serviceIds = $this->getOrderedServiceIds($packageId);
        $totals = $this->getTotalsForPackages([$packageId], $locationId, true);
        $summary = $totals[$packageId] ?? [
            'total_duration' => 0,
            'total_price' => 0.0,
            'missing_count' => 0,
        ];

        $effectiveDuration = $package['override_duration_minutes'] !== null
            ? (int) $package['override_duration_minutes']
            : (int) $summary['total_duration'];
        $effectivePrice = $package['override_price'] !== null
            ? (float) $package['override_price']
            : (float) $summary['total_price'];

        return [
            'package_id' => (int) $package['id'],
            'location_id' => (int) $package['location_id'],
            'service_ids' => $serviceIds,
            'effective_price' => $effectivePrice,
            'effective_duration_minutes' => $effectiveDuration,
            'is_active' => (bool) $package['is_active'],
            'is_broken' => (bool) $package['is_broken'] || $summary['missing_count'] > 0,
        ];
    }

    public function markBrokenByServiceId(int $serviceId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE service_packages sp
             JOIN service_package_items spi ON spi.package_id = sp.id
             SET sp.is_broken = 1, sp.updated_at = NOW()
             WHERE spi.service_id = ?'
        );
        $stmt->execute([$serviceId]);
    }

    public function updateSortOrder(int $packageId, ?int $categoryId, int $sortOrder): void
    {
        if ($categoryId !== null) {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE service_packages SET category_id = ?, sort_order = ?, updated_at = NOW() WHERE id = ?'
            );
            $stmt->execute([$categoryId, $sortOrder, $packageId]);
        } else {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE service_packages SET sort_order = ?, updated_at = NOW() WHERE id = ?'
            );
            $stmt->execute([$sortOrder, $packageId]);
        }
    }

    private function replaceItems(int $packageId, array $serviceIds): void
    {
        $pdo = $this->db->getPdo();

        $stmt = $pdo->prepare('DELETE FROM service_package_items WHERE package_id = ?');
        $stmt->execute([$packageId]);

        $insert = $pdo->prepare(
            'INSERT INTO service_package_items (package_id, service_id, sort_order)
             VALUES (?, ?, ?)'
        );

        foreach ($serviceIds as $index => $serviceId) {
            $insert->execute([$packageId, $serviceId, $index]);
        }
    }

    private function getOrderedServiceIds(int $packageId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT service_id
             FROM service_package_items
             WHERE package_id = ?
             ORDER BY sort_order ASC'
        );
        $stmt->execute([$packageId]);

        return array_map('intval', $stmt->fetchAll(\PDO::FETCH_COLUMN));
    }

    private function getItemsForPackages(array $packageIds, int $locationId): array
    {
        if (empty($packageIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($packageIds), '?'));
        $params = array_merge([$locationId], $packageIds);

        $stmt = $this->db->getPdo()->prepare(
            "SELECT spi.package_id, spi.service_id, spi.sort_order,
                    s.name AS service_name,
                    s.is_active AS service_is_active,
                    sv.duration_minutes,
                    sv.processing_time,
                    sv.blocked_time,
                    sv.price,
                    sv.is_active AS variant_is_active
             FROM service_package_items spi
             LEFT JOIN services s ON s.id = spi.service_id
             LEFT JOIN service_variants sv ON sv.service_id = spi.service_id AND sv.location_id = ?
             WHERE spi.package_id IN ({$placeholders})
             ORDER BY spi.package_id ASC, spi.sort_order ASC"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll();

        $itemsByPackage = [];
        foreach ($rows as $row) {
            $packageId = (int) $row['package_id'];
            $itemsByPackage[$packageId][] = [
                'service_id' => (int) $row['service_id'],
                'sort_order' => (int) $row['sort_order'],
                'name' => $row['service_name'],
                'duration_minutes' => $row['duration_minutes'] !== null ? (int) $row['duration_minutes'] : null,
                'processing_time' => $row['processing_time'] !== null ? (int) $row['processing_time'] : null,
                'blocked_time' => $row['blocked_time'] !== null ? (int) $row['blocked_time'] : null,
                'price' => $row['price'] !== null ? (float) $row['price'] : null,
                'service_is_active' => $row['service_is_active'] !== null ? (bool) $row['service_is_active'] : false,
                'variant_is_active' => $row['variant_is_active'] !== null ? (bool) $row['variant_is_active'] : false,
            ];
        }

        return $itemsByPackage;
    }

    private function getTotalsForPackages(array $packageIds, int $locationId, bool $includeHiddenForAdmin = false): array
    {
        if (empty($packageIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($packageIds), '?'));
        $params = array_merge([$locationId], $packageIds);

        $missingCondition = 's.id IS NULL OR s.is_active = 0 OR sv.id IS NULL OR sv.is_active = 0';
        $availableCondition = 's.id IS NOT NULL AND s.is_active = 1 AND sv.id IS NOT NULL AND sv.is_active = 1';

        $stmt = $this->db->getPdo()->prepare(
            "SELECT spi.package_id,
                    COUNT(*) AS total_items,
                    SUM(CASE
                        WHEN {$missingCondition}
                            THEN 1
                        ELSE 0
                    END) AS missing_count,
                    SUM(CASE
                        WHEN {$availableCondition}
                            THEN sv.duration_minutes + COALESCE(sv.processing_time, 0) + COALESCE(sv.blocked_time, 0)
                        ELSE 0
                    END) AS total_duration,
                    SUM(CASE
                        WHEN {$availableCondition}
                            THEN sv.price
                        ELSE 0
                    END) AS total_price
             FROM service_package_items spi
             LEFT JOIN services s ON s.id = spi.service_id
             LEFT JOIN service_variants sv ON sv.service_id = spi.service_id AND sv.location_id = ?
             WHERE spi.package_id IN ({$placeholders})
             GROUP BY spi.package_id"
        );
        $stmt->execute($params);
        $rows = $stmt->fetchAll();

        $totals = [];
        foreach ($rows as $row) {
            $packageId = (int) $row['package_id'];
            $totals[$packageId] = [
                'total_duration' => (int) ($row['total_duration'] ?? 0),
                'total_price' => (float) ($row['total_price'] ?? 0),
                'missing_count' => (int) ($row['missing_count'] ?? 0),
            ];
        }

        return $totals;
    }

    private function formatPackageRow(
        array $package,
        array $itemsByPackage,
        array $totalsByPackage,
    ): array {
        $packageId = (int) $package['id'];
        $totals = $totalsByPackage[$packageId] ?? [
            'total_duration' => 0,
            'total_price' => 0.0,
            'missing_count' => 0,
        ];

        $effectiveDuration = $package['override_duration_minutes'] !== null
            ? (int) $package['override_duration_minutes']
            : (int) $totals['total_duration'];
        $effectivePrice = $package['override_price'] !== null
            ? (float) $package['override_price']
            : (float) $totals['total_price'];

        return [
            'id' => $packageId,
            'business_id' => (int) $package['business_id'],
            'location_id' => (int) $package['location_id'],
            'category_id' => (int) $package['category_id'],
            'category_name' => $package['category_name'] ?? null,
            'sort_order' => (int) ($package['sort_order'] ?? 0),
            'name' => $package['name'],
            'description' => $package['description'],
            'override_price' => $package['override_price'] !== null ? (float) $package['override_price'] : null,
            'override_duration_minutes' => $package['override_duration_minutes'] !== null
                ? (int) $package['override_duration_minutes']
                : null,
            'is_active' => (bool) $package['is_active'],
            'is_bookable_online' => (bool) ($package['is_bookable_online'] ?? true),
            'online_visibility' => (string) ($package['online_visibility'] ?? 'public'),
            'is_broken' => $package['is_broken'] || $totals['missing_count'] > 0,
            'effective_price' => $effectivePrice,
            'effective_duration_minutes' => $effectiveDuration,
            'items' => $itemsByPackage[$packageId] ?? [],
        ];
    }

    private function getNextSortOrder(int $categoryId, int $locationId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_sort
             FROM (
                 SELECT sort_order FROM services WHERE category_id = ?
                 UNION ALL
                 SELECT sort_order FROM service_packages WHERE category_id = ? AND location_id = ?
             ) AS combined'
        );
        $stmt->execute([$categoryId, $categoryId, $locationId]);

        return (int) $stmt->fetchColumn();
    }

    private function normalizeOnlineVisibility(?string $onlineVisibility, bool $fallbackBookable): string
    {
        if ($onlineVisibility === null || trim($onlineVisibility) === '') {
            return $fallbackBookable ? 'public' : 'hidden';
        }

        $normalized = strtolower(trim($onlineVisibility));
        if (!in_array($normalized, ['public', 'direct_link', 'hidden'], true)) {
            throw new \InvalidArgumentException('Invalid online_visibility');
        }

        return $normalized;
    }
}
