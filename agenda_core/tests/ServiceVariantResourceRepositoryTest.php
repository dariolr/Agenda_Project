<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\ServiceVariantResourceRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class ServiceVariantResourceRepositoryTest extends TestCase
{
    public function testAggregatedRequirementsUsesPeakQuantityPerResource(): void
    {
        $pdo = new PDO('sqlite::memory:');
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->exec(
            'CREATE TABLE service_variant_resource_requirements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                service_variant_id INTEGER NOT NULL,
                resource_id INTEGER NOT NULL,
                quantity INTEGER NOT NULL
            )'
        );

        $stmt = $pdo->prepare(
            'INSERT INTO service_variant_resource_requirements (service_variant_id, resource_id, quantity)
             VALUES (?, ?, ?)'
        );

        // Two sequential services requiring the same resource should not be summed.
        $stmt->execute([1001, 5, 1]);
        $stmt->execute([1002, 5, 1]);

        // Mixed quantities for another shared resource -> peak is 2, not 3.
        $stmt->execute([1001, 6, 2]);
        $stmt->execute([1002, 6, 1]);

        // Resource present in only one variant.
        $stmt->execute([1001, 7, 3]);

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $pdo);

        $repository = new ServiceVariantResourceRepository($connection);
        $result = $repository->getAggregatedRequirements([1001, 1002]);

        $this->assertSame(1, $result[5]);
        $this->assertSame(2, $result[6]);
        $this->assertSame(3, $result[7]);
    }
}

