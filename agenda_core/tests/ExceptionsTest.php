<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\BookingException;

final class ExceptionsTest extends TestCase
{
    public function testAuthExceptionInvalidCredentials(): void
    {
        $exception = AuthException::invalidCredentials();

        $this->assertEquals(401, $exception->getHttpStatus());
        $this->assertEquals('invalid_credentials', $exception->getErrorCode());
        $this->assertStringContainsString('Invalid', $exception->getMessage());
    }

    public function testAuthExceptionAccountDisabled(): void
    {
        $exception = AuthException::accountDisabled();

        $this->assertEquals(401, $exception->getHttpStatus());
        $this->assertEquals('account_disabled', $exception->getErrorCode());
    }

    public function testAuthExceptionTokenExpired(): void
    {
        $exception = AuthException::tokenExpired();

        $this->assertEquals(401, $exception->getHttpStatus());
        $this->assertEquals('token_expired', $exception->getErrorCode());
    }

    public function testBookingExceptionSlotConflict(): void
    {
        $conflicts = [['id' => 1, 'start_time' => '2024-01-01 10:00:00']];
        $exception = BookingException::slotConflict($conflicts);

        $this->assertEquals(409, $exception->getHttpStatus());
        $this->assertEquals('slot_conflict', $exception->getErrorCode());
        $this->assertEquals(['conflicts' => $conflicts], $exception->getDetails());
    }

    public function testBookingExceptionInvalidService(): void
    {
        $exception = BookingException::invalidService([1, 2, 3]);

        $this->assertEquals(400, $exception->getHttpStatus());
        $this->assertEquals('invalid_service', $exception->getErrorCode());
        $this->assertEquals(['service_ids' => [1, 2, 3]], $exception->getDetails());
    }

    public function testBookingExceptionInvalidStaff(): void
    {
        $exception = BookingException::invalidStaff(42);

        $this->assertEquals(400, $exception->getHttpStatus());
        $this->assertEquals('invalid_staff', $exception->getErrorCode());
        $this->assertEquals(['staff_id' => 42], $exception->getDetails());
    }

    public function testBookingExceptionInvalidTime(): void
    {
        $exception = BookingException::invalidTime('must be in the future');

        $this->assertEquals(400, $exception->getHttpStatus());
        $this->assertEquals('invalid_time', $exception->getErrorCode());
        $this->assertStringContainsString('must be in the future', $exception->getMessage());
    }
}
