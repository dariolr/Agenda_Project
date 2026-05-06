<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;

final class LocationScopedAuthorizationSourceTest extends TestCase
{
    public function testServicesControllerProtectsLocationScopedServiceMutations(): void
    {
        $source = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ServicesController.php');

        $this->assertStringContainsString('LocationAuthorizationService::ERROR_CODE', $source);
        $this->assertStringContainsString('$changedLocationIds = array_values(array_unique(array_merge($addedLocationIds, $removedLocationIds)));', $source);
        $this->assertStringContainsString('$locationScopeError = $this->requireLocationScope($request, $businessId, $changedLocationIds);', $source);
        $this->assertStringContainsString('$onlyLocationId = $this->serviceRepository->getSingleActiveVariantLocationId($serviceId);', $source);
        $this->assertStringContainsString('$businessWideError = $this->requireBusinessWideLocationScope($request, $businessId);', $source);
    }

    public function testClassEventsAndBookingsUseForbiddenLocationScope(): void
    {
        $classEventsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ClassEventsController.php');
        $bookingsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/BookingsController.php');
        $bookingPaymentsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/BookingPaymentsController.php');

        $this->assertStringContainsString('LocationAuthorizationService::ERROR_CODE', $classEventsController);
        $this->assertStringContainsString('[(int) $currentEvent[\'location_id\'], $effectiveLocationId]', $classEventsController);
        $this->assertStringContainsString('LocationAuthorizationService::ERROR_CODE', $bookingsController);
        $this->assertStringContainsString('requireLocationScopeForBookings', $bookingsController);
        $this->assertStringContainsString('LocationAuthorizationService::ERROR_CODE', $bookingPaymentsController);
    }

    public function testLocationsControllerBlocksGlobalLocationMutationsForLocationScopedUsers(): void
    {
        $source = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/LocationsController.php');

        $this->assertStringContainsString('LocationAuthorizationService::ERROR_CODE', $source);
        $this->assertStringContainsString('requireBusinessWideLocationScope', $source);
        $this->assertStringContainsString('requireLocationScope', $source);
        $this->assertMatchesRegularExpression(
            '/public function destroy\\(Request \\$request\\): Response.*?\\$businessWideError = \\$this->requireBusinessWideLocationScope\\(\\$request, \\$businessId\\);/s',
            $source
        );
    }
}
