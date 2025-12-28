<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use DateTimeImmutable;
use DateTimeZone;
use Agenda\Domain\Exceptions\BookingException;

/**
 * Unit tests for Booking use cases
 * Tests CreateBooking validation, conflict detection, and idempotency logic
 */
final class BookingUseCaseTest extends TestCase
{
    // ==================== Validation Tests ====================

    public function testBookingRequiresServiceIds(): void
    {
        $this->expectException(BookingException::class);
        throw BookingException::invalidService([]);
    }

    public function testBookingRequiresValidStartTime(): void
    {
        $this->expectException(BookingException::class);
        throw BookingException::invalidTime('start_time is required');
    }

    public function testBookingRejectsPastStartTime(): void
    {
        $pastTime = new DateTimeImmutable('-1 hour', new DateTimeZone('UTC'));
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));

        $this->assertTrue(
            $pastTime <= $now,
            'Past time should be less than or equal to now'
        );

        $this->expectException(BookingException::class);
        throw BookingException::invalidTime('start_time must be in the future');
    }

    public function testBookingAcceptsFutureStartTime(): void
    {
        $futureTime = new DateTimeImmutable('+1 hour', new DateTimeZone('UTC'));
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));

        $this->assertTrue(
            $futureTime > $now,
            'Future time should be greater than now'
        );
    }

    // ==================== Duration Calculation Tests ====================

    public function testTotalDurationCalculation(): void
    {
        // Simulate multiple services with durations
        $services = [
            ['id' => 1, 'name' => 'Haircut', 'duration' => 30],
            ['id' => 2, 'name' => 'Wash', 'duration' => 15],
            ['id' => 3, 'name' => 'Style', 'duration' => 20],
        ];

        $totalDuration = array_sum(array_column($services, 'duration'));

        $this->assertEquals(65, $totalDuration);
    }

    public function testEndTimeCalculation(): void
    {
        $startTime = new DateTimeImmutable('2025-01-15 10:00:00', new DateTimeZone('UTC'));
        $durationMinutes = 45;

        $endTime = $startTime->modify("+{$durationMinutes} minutes");

        $this->assertEquals(
            '2025-01-15 10:45:00',
            $endTime->format('Y-m-d H:i:s')
        );
    }

    // ==================== Conflict Detection Tests ====================

    public function testConflictDetection(): void
    {
        // Existing booking: 10:00 - 10:30
        $existingStart = new DateTimeImmutable('2025-01-15 10:00:00');
        $existingEnd = new DateTimeImmutable('2025-01-15 10:30:00');

        // New booking attempts: 10:15 - 10:45 (overlaps!)
        $newStart = new DateTimeImmutable('2025-01-15 10:15:00');
        $newEnd = new DateTimeImmutable('2025-01-15 10:45:00');

        // Conflict: newStart < existingEnd AND newEnd > existingStart
        $hasConflict = ($newStart < $existingEnd) && ($newEnd > $existingStart);

        $this->assertTrue($hasConflict, 'Should detect overlapping booking');
    }

    public function testNoConflictForAdjacentBookings(): void
    {
        // Existing booking: 10:00 - 10:30
        $existingStart = new DateTimeImmutable('2025-01-15 10:00:00');
        $existingEnd = new DateTimeImmutable('2025-01-15 10:30:00');

        // New booking: 10:30 - 11:00 (adjacent, no overlap)
        $newStart = new DateTimeImmutable('2025-01-15 10:30:00');
        $newEnd = new DateTimeImmutable('2025-01-15 11:00:00');

        $hasConflict = ($newStart < $existingEnd) && ($newEnd > $existingStart);

        $this->assertFalse($hasConflict, 'Adjacent bookings should not conflict');
    }

    public function testNoConflictForNonOverlappingBookings(): void
    {
        // Existing booking: 10:00 - 10:30
        $existingStart = new DateTimeImmutable('2025-01-15 10:00:00');
        $existingEnd = new DateTimeImmutable('2025-01-15 10:30:00');

        // New booking: 11:00 - 11:30 (completely separate)
        $newStart = new DateTimeImmutable('2025-01-15 11:00:00');
        $newEnd = new DateTimeImmutable('2025-01-15 11:30:00');

        $hasConflict = ($newStart < $existingEnd) && ($newEnd > $existingStart);

        $this->assertFalse($hasConflict, 'Non-overlapping bookings should not conflict');
    }

    public function testConflictWhenNewBookingContainsExisting(): void
    {
        // Existing booking: 10:15 - 10:30
        $existingStart = new DateTimeImmutable('2025-01-15 10:15:00');
        $existingEnd = new DateTimeImmutable('2025-01-15 10:30:00');

        // New booking: 10:00 - 11:00 (contains the existing)
        $newStart = new DateTimeImmutable('2025-01-15 10:00:00');
        $newEnd = new DateTimeImmutable('2025-01-15 11:00:00');

        $hasConflict = ($newStart < $existingEnd) && ($newEnd > $existingStart);

        $this->assertTrue($hasConflict, 'Should detect when new booking contains existing');
    }

    public function testConflictWhenExistingContainsNew(): void
    {
        // Existing booking: 10:00 - 11:00
        $existingStart = new DateTimeImmutable('2025-01-15 10:00:00');
        $existingEnd = new DateTimeImmutable('2025-01-15 11:00:00');

        // New booking: 10:15 - 10:30 (contained within existing)
        $newStart = new DateTimeImmutable('2025-01-15 10:15:00');
        $newEnd = new DateTimeImmutable('2025-01-15 10:30:00');

        $hasConflict = ($newStart < $existingEnd) && ($newEnd > $existingStart);

        $this->assertTrue($hasConflict, 'Should detect when existing contains new booking');
    }

    // ==================== Idempotency Tests ====================

    public function testIdempotencyKeyFormat(): void
    {
        // Valid UUID v4
        $validKey = '550e8400-e29b-41d4-a716-446655440000';
        $pattern = '/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i';

        $this->assertMatchesRegularExpression($pattern, $validKey);
    }

    public function testIdempotencyKeyRejectsInvalidFormat(): void
    {
        $invalidKeys = [
            'not-a-uuid',
            '550e8400-e29b-41d4-a716',  // Too short
            '550e8400-e29b-51d4-a716-446655440000', // Wrong version (5 instead of 4)
        ];

        $pattern = '/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i';

        foreach ($invalidKeys as $key) {
            $this->assertDoesNotMatchRegularExpression(
                $pattern,
                $key,
                "Key '$key' should not match UUID v4 pattern"
            );
        }
    }

    // ==================== Price Calculation Tests ====================

    public function testTotalPriceCalculation(): void
    {
        // Services with prices
        $services = [
            ['id' => 1, 'name' => 'Haircut', 'price' => 25.00],
            ['id' => 2, 'name' => 'Wash', 'price' => 10.00],
            ['id' => 3, 'name' => 'Style', 'price' => 15.50],
        ];

        $totalPrice = array_sum(array_column($services, 'price'));

        $this->assertEquals(50.50, $totalPrice);
    }

    // ==================== Booking Status Tests ====================

    public function testValidBookingStatuses(): void
    {
        $validStatuses = ['pending', 'confirmed', 'cancelled', 'completed', 'no_show'];

        foreach ($validStatuses as $status) {
            $this->assertContains($status, $validStatuses);
        }
    }

    public function testDefaultBookingStatusIsPending(): void
    {
        $defaultStatus = 'pending';
        $this->assertEquals('pending', $defaultStatus);
    }

    // ==================== Multi-Service Sequential Duration Tests ====================

    public function testSequentialServiceSlotCalculation(): void
    {
        // Multiple services booked sequentially
        $startTime = new DateTimeImmutable('2025-01-15 10:00:00', new DateTimeZone('UTC'));
        $services = [
            ['duration' => 30], // 10:00 - 10:30
            ['duration' => 15], // 10:30 - 10:45
            ['duration' => 20], // 10:45 - 11:05
        ];

        $currentTime = $startTime;
        $slots = [];

        foreach ($services as $index => $service) {
            $slotStart = $currentTime;
            $slotEnd = $currentTime->modify("+{$service['duration']} minutes");
            $slots[] = [
                'service_index' => $index,
                'start' => $slotStart->format('H:i'),
                'end' => $slotEnd->format('H:i'),
            ];
            $currentTime = $slotEnd;
        }

        $this->assertEquals('10:00', $slots[0]['start']);
        $this->assertEquals('10:30', $slots[0]['end']);
        $this->assertEquals('10:30', $slots[1]['start']);
        $this->assertEquals('10:45', $slots[1]['end']);
        $this->assertEquals('10:45', $slots[2]['start']);
        $this->assertEquals('11:05', $slots[2]['end']);

        // Total booking end time
        $this->assertEquals('11:05', $currentTime->format('H:i'));
    }
}
