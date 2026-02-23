<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;

/**
 * Regression tests to ensure role permissions are enforced on critical modules.
 */
final class RolePermissionsEnforcementTest extends TestCase
{
    public function testServicesModulesUseManageServicesPermission(): void
    {
        $servicesController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ServicesController.php');
        $packagesController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ServicePackagesController.php');
        $variantResourcesController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ServiceVariantResourceController.php');
        $resourcesController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ResourcesController.php');

        $this->assertStringContainsString("'can_manage_services'", $servicesController);
        $this->assertStringContainsString("'can_manage_services'", $packagesController);
        $this->assertStringContainsString("'can_manage_services'", $variantResourcesController);
        $this->assertStringContainsString("'can_manage_services'", $resourcesController);
    }

    public function testStaffModulesUseManageStaffPermission(): void
    {
        $staffController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/StaffController.php');
        $staffExceptionsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/StaffAvailabilityExceptionController.php');
        $staffPlanningController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/StaffPlanningController.php');
        $timeBlocksController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/TimeBlocksController.php');
        $closuresController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/LocationClosuresController.php');

        $this->assertStringContainsString("'can_manage_staff'", $staffController);
        $this->assertStringContainsString("'can_manage_staff'", $staffExceptionsController);
        $this->assertStringContainsString("'can_manage_staff'", $staffPlanningController);
        $this->assertStringContainsString("'can_manage_staff'", $timeBlocksController);
        $this->assertStringContainsString("'can_manage_staff'", $closuresController);
    }

    public function testBookingClientsAndReportsUseSpecificPermissions(): void
    {
        $bookingsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/BookingsController.php');
        $appointmentsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/AppointmentsController.php');
        $clientsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ClientsController.php');
        $crmClientsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/CrmClientsController.php');
        $reportsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ReportsController.php');

        $this->assertStringContainsString("'can_manage_bookings'", $bookingsController);
        $this->assertStringContainsString("'can_manage_bookings'", $appointmentsController);
        $this->assertStringContainsString("'can_manage_clients'", $clientsController);
        $this->assertStringContainsString("'can_manage_clients'", $crmClientsController);
        $this->assertStringContainsString("'can_view_reports'", $reportsController);
    }

    public function testViewerRoleIsAcceptedAndUsedForReadOnlyBookings(): void
    {
        $businessUsersController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/BusinessUsersController.php');
        $invitationsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/BusinessInvitationsController.php');
        $bookingsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/BookingsController.php');
        $appointmentsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/AppointmentsController.php');

        $this->assertStringContainsString("'viewer'", $businessUsersController);
        $this->assertStringContainsString("'viewer'", $invitationsController);
        $this->assertStringContainsString('allowReadOnly', $bookingsController);
        $this->assertStringContainsString("if (\$role === 'viewer')", $bookingsController);
        $this->assertStringContainsString('allowReadOnly', $appointmentsController);
        $this->assertStringContainsString("if (\$role === 'viewer')", $appointmentsController);
    }
}
