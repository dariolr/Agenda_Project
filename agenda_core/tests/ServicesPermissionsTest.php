<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Http\Controllers\ServicesController;
use Agenda\Infrastructure\Repositories\StaffRepository;
use PHPUnit\Framework\TestCase;

/**
 * Regression tests for permissions on staff popular services endpoint.
 */
final class ServicesPermissionsTest extends TestCase
{
    public function testServicesControllerNowDependsOnStaffRepository(): void
    {
        $reflection = new \ReflectionClass(ServicesController::class);
        $constructor = $reflection->getConstructor();

        $this->assertNotNull($constructor);

        $hasStaffRepo = false;
        foreach ($constructor->getParameters() as $parameter) {
            $type = $parameter->getType();
            if ($type instanceof \ReflectionNamedType && $type->getName() === StaffRepository::class) {
                $hasStaffRepo = true;
                break;
            }
        }

        $this->assertTrue(
            $hasStaffRepo,
            'ServicesController must receive StaffRepository to resolve business_id from staff_id'
        );
    }

    public function testPopularEndpointAuthorizationUsesStaffBusinessAndNotFoundOnDeny(): void
    {
        $source = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ServicesController.php');

        // Must resolve staff first, then derive business_id from staff.
        $this->assertStringContainsString("\$staff = \$this->staffRepo->findById(\$staffId);", $source);
        $this->assertStringContainsString("\$businessId = (int) \$staff['business_id'];", $source);

        // Must always enforce hasBusinessAccess on that derived business id.
        $this->assertStringContainsString("if (!\$this->hasBusinessAccess(\$request, \$businessId)) {", $source);

        // Must not leak existence across businesses.
        $this->assertStringContainsString("return Response::notFound('Staff not found'", $source);
    }
}

