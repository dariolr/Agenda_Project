<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;

final class ServiceLocationRemovalTest extends TestCase
{
    public function testLocationScopedServiceDeleteRouteIsRegistered(): void
    {
        $kernel = (string) file_get_contents(__DIR__ . '/../src/Http/Kernel.php');

        $this->assertStringContainsString(
            "\$this->router->delete('/v1/locations/{location_id}/services/{service_id}', ServicesController::class, 'removeFromLocation'",
            $kernel
        );
        $this->assertStringContainsString("'location_path'", $kernel);
        $this->assertStringContainsString("'location_access'", $kernel);
    }

    public function testLocationScopedRemovalKeepsGlobalDeleteSeparate(): void
    {
        $repository = (string) file_get_contents(__DIR__ . '/../src/Infrastructure/Repositories/ServiceRepository.php');

        $this->assertStringContainsString('public function delete(int $serviceId): bool', $repository);
        $this->assertStringContainsString('public function removeFromLocation(int $serviceId, int $locationId): array', $repository);
        $this->assertStringContainsString('UPDATE service_variants SET is_active = 0, updated_at = NOW() WHERE service_id = ?', $repository);
    }

    public function testLocationScopedRemovalUsesTransactionAndOnlyDisablesOneVariant(): void
    {
        $repository = (string) file_get_contents(__DIR__ . '/../src/Infrastructure/Repositories/ServiceRepository.php');

        $this->assertStringContainsString('$pdo->beginTransaction();', $repository);
        $this->assertStringContainsString('WHERE service_id = ?', $repository);
        $this->assertStringContainsString('AND location_id = ?', $repository);
        $this->assertStringContainsString('AND is_active = 1', $repository);
        $this->assertStringContainsString('SELECT COUNT(*)', $repository);
        $this->assertStringContainsString("'removed_from_location' => \$removedFromLocation", $repository);
        $this->assertStringContainsString("'globally_deactivated' => \$globallyDeactivated", $repository);
    }

    public function testLocationScopedRemovalBlocksActivePackagesWithConflict(): void
    {
        $repository = (string) file_get_contents(__DIR__ . '/../src/Infrastructure/Repositories/ServiceRepository.php');
        $controller = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ServicesController.php');

        $this->assertStringContainsString('FROM service_packages sp', $repository);
        $this->assertStringContainsString('JOIN service_package_items spi ON spi.package_id = sp.id', $repository);
        $this->assertStringContainsString('sp.location_id = ?', $repository);
        $this->assertStringContainsString('sp.is_active = 1', $repository);
        $this->assertStringContainsString('spi.service_id = ?', $repository);
        $this->assertStringContainsString('impossibile rimuovere il servizio perché usato da pacchetti attivi nella sede', $repository);
        $this->assertStringContainsString("Response::conflict(\n                'service_used_by_active_packages'", $controller);
    }
}
