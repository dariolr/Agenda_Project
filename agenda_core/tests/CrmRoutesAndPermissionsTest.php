<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;

final class CrmRoutesAndPermissionsTest extends TestCase
{
    public function testKernelRegistersCrmRoutes(): void
    {
        $kernel = (string) file_get_contents(__DIR__ . '/../src/Http/Kernel.php');

        $this->assertStringContainsString('/v1/businesses/{business_id}/clients', $kernel);
        $this->assertStringContainsString('/clients/dedup/suggestions', $kernel);
        $this->assertStringContainsString('/clients/{source_client_id}/merge-into/{target_client_id}', $kernel);
        $this->assertStringContainsString('/clients/{client_id}/gdpr/export', $kernel);
        $this->assertStringContainsString('/clients/{client_id}/gdpr/delete', $kernel);
        $this->assertStringContainsString('/clients/import/csv', $kernel);
        $this->assertStringContainsString('/clients/export/csv', $kernel);
    }

    public function testCrmControllerUsesClientPermissionBoundary(): void
    {
        $controller = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/CrmClientsController.php');

        $this->assertStringContainsString("'can_manage_clients'", $controller);
        $this->assertStringContainsString('assertBusinessAccess', $controller);
        $this->assertStringContainsString('assertClientInBusiness', $controller);
    }
}
