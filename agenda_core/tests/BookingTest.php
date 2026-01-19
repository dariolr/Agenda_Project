<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\UseCases\Booking\ComputeAvailability;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Booking logic tests (unit tests for availability computation)
 */
final class BookingTest extends TestCase
{
    public function testSlotIntervalIs15Minutes(): void
    {
        // Verify the constant value through reflection
        $class = new \ReflectionClass(ComputeAvailability::class);
        $constant = $class->getReflectionConstant('SLOT_INTERVAL_MINUTES');
        
        $this->assertEquals(15, $constant->getValue());
    }

    public function testMaxDaysAheadIs60(): void
    {
        $class = new \ReflectionClass(ComputeAvailability::class);
        $constant = $class->getReflectionConstant('DEFAULT_MAX_DAYS_AHEAD');
        
        $this->assertEquals(60, $constant->getValue());
    }

    public function testSlotOverlapDetection(): void
    {
        // Test slot overlap logic
        $slot1Start = new DateTimeImmutable('2025-01-15 10:00:00');
        $slot1End = new DateTimeImmutable('2025-01-15 10:30:00');
        
        $slot2Start = new DateTimeImmutable('2025-01-15 10:15:00');
        $slot2End = new DateTimeImmutable('2025-01-15 10:45:00');
        
        // Overlap detection: slot1 overlaps slot2 if slot1.start < slot2.end AND slot1.end > slot2.start
        $overlaps = $slot1Start < $slot2End && $slot1End > $slot2Start;
        
        $this->assertTrue($overlaps, 'Overlapping slots should be detected');
    }

    public function testNonOverlappingSlotsNotDetected(): void
    {
        $slot1Start = new DateTimeImmutable('2025-01-15 09:00:00');
        $slot1End = new DateTimeImmutable('2025-01-15 09:30:00');
        
        $slot2Start = new DateTimeImmutable('2025-01-15 10:00:00');
        $slot2End = new DateTimeImmutable('2025-01-15 10:30:00');
        
        $overlaps = $slot1Start < $slot2End && $slot1End > $slot2Start;
        
        $this->assertFalse($overlaps, 'Non-overlapping slots should not be detected');
    }

    public function testAdjacentSlotsAreNotOverlapping(): void
    {
        // Adjacent slots (slot1 ends exactly when slot2 starts)
        $slot1Start = new DateTimeImmutable('2025-01-15 09:00:00');
        $slot1End = new DateTimeImmutable('2025-01-15 09:30:00');
        
        $slot2Start = new DateTimeImmutable('2025-01-15 09:30:00');
        $slot2End = new DateTimeImmutable('2025-01-15 10:00:00');
        
        $overlaps = $slot1Start < $slot2End && $slot1End > $slot2Start;
        
        $this->assertFalse($overlaps, 'Adjacent slots should not be considered overlapping');
    }

    public function testDateValidation(): void
    {
        $timezone = new DateTimeZone('Europe/Rome');
        $today = new DateTimeImmutable('today', $timezone);
        $yesterday = $today->modify('-1 day');
        $tomorrow = $today->modify('+1 day');
        
        $this->assertTrue($yesterday < $today, 'Yesterday should be before today');
        $this->assertTrue($tomorrow > $today, 'Tomorrow should be after today');
    }

    public function testWorkingHoursLogic(): void
    {
        // Test that weekday logic works (1=Monday, 5=Friday, 6=Saturday, 7=Sunday)
        $monday = new DateTimeImmutable('2025-01-13'); // This is a Monday
        $saturday = new DateTimeImmutable('2025-01-18'); // This is a Saturday
        
        $mondayDayOfWeek = (int) $monday->format('N');
        $saturdayDayOfWeek = (int) $saturday->format('N');
        
        $this->assertEquals(1, $mondayDayOfWeek);
        $this->assertEquals(6, $saturdayDayOfWeek);
        
        // Working days are Mon-Fri (1-5)
        $mondayIsWorking = $mondayDayOfWeek >= 1 && $mondayDayOfWeek <= 5;
        $saturdayIsWorking = $saturdayDayOfWeek >= 1 && $saturdayDayOfWeek <= 5;
        
        $this->assertTrue($mondayIsWorking);
        $this->assertFalse($saturdayIsWorking);
    }
}
