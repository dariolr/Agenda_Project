<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingDirectLinkRepository;
use Agenda\Infrastructure\Repositories\ServicePackageRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class ServicePackageRepositoryTest extends TestCase
{
    private PDO $pdo;
    private ServicePackageRepository $repository;

    protected function setUp(): void
    {
        $this->pdo = new PDO('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->createSchema();

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $this->pdo);

        $this->repository = new ServicePackageRepository($connection);
    }

    public function testPublicPackageWithPublicItemsIsValidAndListed(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'public',
            serviceVisibilities: ['public', 'public'],
        );

        $packages = $this->repository->findByLocationId(10);

        $this->assertCount(1, $packages);
        $this->assertSame(1, $packages[0]['id']);
        $this->assertFalse($packages[0]['is_broken']);
        $this->assertSame(75, $packages[0]['effective_duration_minutes']);
        $this->assertSame(75.0, $packages[0]['effective_price']);

        $expanded = $this->repository->getExpanded(1, 10);
        $this->assertNotNull($expanded);
        $this->assertFalse($expanded['is_broken']);
    }

    public function testPublicPackageWithDirectLinkItemIsValidAndListed(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'public',
            serviceVisibilities: ['public', 'direct_link'],
        );

        $packages = $this->repository->findByLocationId(10);

        $this->assertCount(1, $packages);
        $this->assertFalse($packages[0]['is_broken']);

        $expanded = $this->repository->getExpanded(1, 10);
        $this->assertNotNull($expanded);
        $this->assertFalse($expanded['is_broken']);
    }

    public function testPublicPackageWithHiddenItemIsValidAndListed(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'public',
            serviceVisibilities: ['public', 'hidden'],
        );

        $packages = $this->repository->findByLocationId(10);

        $this->assertCount(1, $packages);
        $this->assertFalse($packages[0]['is_broken']);

        $expanded = $this->repository->getExpanded(1, 10);
        $this->assertNotNull($expanded);
        $this->assertFalse($expanded['is_broken']);
    }

    public function testInactiveServiceMarksPackageBroken(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'public',
            serviceVisibilities: ['public', 'hidden'],
            inactiveServiceIds: [1002],
        );

        $packages = $this->repository->findByLocationId(10);

        $this->assertCount(1, $packages);
        $this->assertTrue($packages[0]['is_broken']);

        $expanded = $this->repository->getExpanded(1, 10);
        $this->assertNotNull($expanded);
        $this->assertTrue($expanded['is_broken']);
    }

    public function testInactiveVariantMarksPackageBroken(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'public',
            serviceVisibilities: ['public', 'hidden'],
            inactiveVariantServiceIds: [1002],
        );

        $packages = $this->repository->findByLocationId(10);

        $this->assertCount(1, $packages);
        $this->assertTrue($packages[0]['is_broken']);

        $expanded = $this->repository->getExpanded(1, 10);
        $this->assertNotNull($expanded);
        $this->assertTrue($expanded['is_broken']);
    }

    public function testMissingVariantMarksPackageBroken(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'public',
            serviceVisibilities: ['public', 'hidden'],
            missingVariantServiceIds: [1002],
        );

        $packages = $this->repository->findByLocationId(10);

        $this->assertCount(1, $packages);
        $this->assertTrue($packages[0]['is_broken']);

        $expanded = $this->repository->getExpanded(1, 10);
        $this->assertNotNull($expanded);
        $this->assertTrue($expanded['is_broken']);
    }

    public function testDirectLinkPackageIsHiddenFromNormalListingAndAvailableInDirectScope(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'direct_link',
            serviceVisibilities: ['public', 'hidden'],
        );

        $this->assertSame([], $this->repository->findByLocationId(10));

        $packages = $this->repository->findByLocationId(10, [
            'target_type' => BookingDirectLinkRepository::TARGET_SERVICE_PACKAGE,
            'target_id' => 1,
        ]);

        $this->assertCount(1, $packages);
        $this->assertSame(1, $packages[0]['id']);
        $this->assertFalse($packages[0]['is_broken']);

        $expanded = $this->repository->getExpanded(1, 10, true);
        $this->assertNotNull($expanded);
        $this->assertFalse($expanded['is_broken']);
    }

    public function testHiddenPackageIsHiddenFromNormalListing(): void
    {
        $this->seedPackageWithServices(
            packageId: 1,
            packageVisibility: 'hidden',
            serviceVisibilities: ['public', 'hidden'],
        );

        $this->assertSame([], $this->repository->findByLocationId(10));
        $this->assertNull($this->repository->getExpanded(1, 10));
    }

    private function createSchema(): void
    {
        $this->pdo->exec(
            'CREATE TABLE service_categories (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE service_packages (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                location_id INTEGER NOT NULL,
                category_id INTEGER NOT NULL,
                sort_order INTEGER NOT NULL DEFAULT 0,
                name TEXT NOT NULL,
                description TEXT,
                override_price REAL,
                override_duration_minutes INTEGER,
                is_active INTEGER NOT NULL DEFAULT 1,
                is_bookable_online INTEGER NOT NULL DEFAULT 1,
                online_visibility TEXT NOT NULL DEFAULT "public",
                is_broken INTEGER NOT NULL DEFAULT 0
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE services (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                online_visibility TEXT NOT NULL DEFAULT "public"
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE service_variants (
                id INTEGER PRIMARY KEY,
                service_id INTEGER NOT NULL,
                location_id INTEGER NOT NULL,
                duration_minutes INTEGER NOT NULL,
                processing_time INTEGER NOT NULL DEFAULT 0,
                blocked_time INTEGER NOT NULL DEFAULT 0,
                price REAL NOT NULL DEFAULT 0,
                is_active INTEGER NOT NULL DEFAULT 1,
                is_bookable_online INTEGER NOT NULL DEFAULT 1,
                online_visibility TEXT NOT NULL DEFAULT "public"
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE service_package_items (
                package_id INTEGER NOT NULL,
                service_id INTEGER NOT NULL,
                sort_order INTEGER NOT NULL DEFAULT 0
            )'
        );
    }

    /**
     * @param list<string> $serviceVisibilities
     * @param list<int> $inactiveServiceIds
     * @param list<int> $inactiveVariantServiceIds
     * @param list<int> $missingVariantServiceIds
     */
    private function seedPackageWithServices(
        int $packageId,
        string $packageVisibility,
        array $serviceVisibilities,
        array $inactiveServiceIds = [],
        array $inactiveVariantServiceIds = [],
        array $missingVariantServiceIds = [],
    ): void {
        $this->pdo->exec("INSERT INTO service_categories (id, name) VALUES (5, 'Categoria')");

        $stmt = $this->pdo->prepare(
            'INSERT INTO service_packages
             (id, business_id, location_id, category_id, sort_order, name, is_active, is_bookable_online, online_visibility, is_broken)
             VALUES (?, 20, 10, 5, 0, ?, 1, 1, ?, 0)'
        );
        $stmt->execute([$packageId, 'Pacchetto ' . $packageId, $packageVisibility]);

        foreach ($serviceVisibilities as $index => $visibility) {
            $serviceId = 1001 + $index;
            $isServiceActive = in_array($serviceId, $inactiveServiceIds, true) ? 0 : 1;
            $isVariantActive = in_array($serviceId, $inactiveVariantServiceIds, true) ? 0 : 1;

            $serviceStmt = $this->pdo->prepare(
                'INSERT INTO services (id, name, is_active, online_visibility)
                 VALUES (?, ?, ?, ?)'
            );
            $serviceStmt->execute([$serviceId, 'Servizio ' . $serviceId, $isServiceActive, $visibility]);

            if (!in_array($serviceId, $missingVariantServiceIds, true)) {
                $variantStmt = $this->pdo->prepare(
                    'INSERT INTO service_variants
                     (id, service_id, location_id, duration_minutes, processing_time, blocked_time, price, is_active, is_bookable_online, online_visibility)
                     VALUES (?, ?, 10, ?, ?, 0, ?, ?, 0, ?)'
                );
                $variantStmt->execute([
                    2001 + $index,
                    $serviceId,
                    30 + ($index * 15),
                    $index === 0 ? 0 : 0,
                    30.0 + ($index * 15.0),
                    $isVariantActive,
                    $visibility,
                ]);
            }

            $itemStmt = $this->pdo->prepare(
                'INSERT INTO service_package_items (package_id, service_id, sort_order)
                 VALUES (?, ?, ?)'
            );
            $itemStmt->execute([$packageId, $serviceId, $index]);
        }
    }
}
