<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Domain\Exceptions\BookingException;
use Agenda\UseCases\Booking\CreateBooking;
use PHPUnit\Framework\TestCase;

final class CreateBookingPackageVisibilityTest extends TestCase
{
    public function testPackageCoveredServicesBypassOnlineVisibilityOnly(): void
    {
        $method = $this->assertCustomerServicesMethod();
        $useCase = (new \ReflectionClass(CreateBooking::class))->newInstanceWithoutConstructor();

        $method->invoke(
            $useCase,
            20,
            10,
            [
                [
                    'id' => 1001,
                    'variant_is_active' => 1,
                    'is_bookable_online' => 0,
                    'online_visibility' => 'hidden',
                ],
                [
                    'id' => 1002,
                    'variant_is_active' => 1,
                    'is_bookable_online' => 1,
                    'online_visibility' => 'direct_link',
                ],
            ],
            [1001, 1002],
            null,
            [1001, 1002],
        );

        $this->addToAssertionCount(1);
    }

    public function testUncoveredHiddenServiceStillFails(): void
    {
        $method = $this->assertCustomerServicesMethod();
        $useCase = (new \ReflectionClass(CreateBooking::class))->newInstanceWithoutConstructor();

        $this->expectException(BookingException::class);
        $this->expectExceptionMessage('One or more services are invalid or not available');

        $method->invoke(
            $useCase,
            20,
            10,
            [
                [
                    'id' => 1001,
                    'variant_is_active' => 1,
                    'is_bookable_online' => 0,
                    'online_visibility' => 'hidden',
                ],
            ],
            [1001],
            null,
            [],
        );
    }

    public function testPackageCoveredInactiveVariantStillFails(): void
    {
        $method = $this->assertCustomerServicesMethod();
        $useCase = (new \ReflectionClass(CreateBooking::class))->newInstanceWithoutConstructor();

        $this->expectException(BookingException::class);

        $method->invoke(
            $useCase,
            20,
            10,
            [
                [
                    'id' => 1001,
                    'variant_is_active' => 0,
                    'is_bookable_online' => 0,
                    'online_visibility' => 'hidden',
                ],
            ],
            [1001],
            null,
            [1001],
        );
    }

    private function assertCustomerServicesMethod(): \ReflectionMethod
    {
        $method = new \ReflectionMethod(CreateBooking::class, 'assertCustomerServicesAreBookableOnline');
        $method->setAccessible(true);
        return $method;
    }
}
