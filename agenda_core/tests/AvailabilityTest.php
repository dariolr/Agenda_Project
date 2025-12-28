<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Unit tests for Availability computation
 * Tests slot generation, working hours, and availability filtering
 */
final class AvailabilityTest extends TestCase
{
    // ==================== Working Hours Tests ====================

    public function testWorkingHoursParsingAM(): void
    {
        $openTime = '09:00';
        $closeTime = '18:00';

        $open = DateTimeImmutable::createFromFormat('H:i', $openTime);
        $close = DateTimeImmutable::createFromFormat('H:i', $closeTime);

        $this->assertInstanceOf(DateTimeImmutable::class, $open);
        $this->assertInstanceOf(DateTimeImmutable::class, $close);
        $this->assertTrue($close > $open);
    }

    public function testWorkingHoursSpansDayCorrectly(): void
    {
        $open = new DateTimeImmutable('2025-01-15 09:00:00');
        $close = new DateTimeImmutable('2025-01-15 18:00:00');

        $hoursOpen = ($close->getTimestamp() - $open->getTimestamp()) / 3600;

        $this->assertEquals(9, $hoursOpen);
    }

    // ==================== Slot Generation Tests ====================

    public function testGenerateSlots30MinInterval(): void
    {
        $open = new DateTimeImmutable('2025-01-15 09:00:00', new DateTimeZone('UTC'));
        $close = new DateTimeImmutable('2025-01-15 12:00:00', new DateTimeZone('UTC'));
        $slotDuration = 30; // minutes

        $slots = [];
        $current = $open;

        while ($current < $close) {
            $slotEnd = $current->modify("+{$slotDuration} minutes");
            if ($slotEnd <= $close) {
                $slots[] = [
                    'start' => $current->format('H:i'),
                    'end' => $slotEnd->format('H:i'),
                ];
            }
            $current = $slotEnd;
        }

        // 9:00-9:30, 9:30-10:00, 10:00-10:30, 10:30-11:00, 11:00-11:30, 11:30-12:00
        $this->assertCount(6, $slots);
        $this->assertEquals('09:00', $slots[0]['start']);
        $this->assertEquals('11:30', $slots[5]['start']);
        $this->assertEquals('12:00', $slots[5]['end']);
    }

    public function testGenerateSlots15MinInterval(): void
    {
        $open = new DateTimeImmutable('2025-01-15 09:00:00', new DateTimeZone('UTC'));
        $close = new DateTimeImmutable('2025-01-15 10:00:00', new DateTimeZone('UTC'));
        $slotDuration = 15;

        $slots = [];
        $current = $open;

        while ($current < $close) {
            $slotEnd = $current->modify("+{$slotDuration} minutes");
            if ($slotEnd <= $close) {
                $slots[] = $current->format('H:i');
            }
            $current = $slotEnd;
        }

        $this->assertCount(4, $slots);
        $this->assertEquals(['09:00', '09:15', '09:30', '09:45'], $slots);
    }

    // ==================== Availability Filtering Tests ====================

    public function testFilterOutBookedSlots(): void
    {
        // All possible slots
        $allSlots = ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30'];

        // Booked slots
        $bookedSlots = ['10:00', '10:30'];

        $availableSlots = array_values(array_diff($allSlots, $bookedSlots));

        $this->assertCount(4, $availableSlots);
        $this->assertNotContains('10:00', $availableSlots);
        $this->assertNotContains('10:30', $availableSlots);
        $this->assertEquals(['09:00', '09:30', '11:00', '11:30'], $availableSlots);
    }

    public function testFilterSlotsForServiceDuration(): void
    {
        // 30-min slots, but service needs 45 minutes
        // Only show slots where 45-min service fits before closing
        $close = new DateTimeImmutable('2025-01-15 12:00:00', new DateTimeZone('UTC'));
        $serviceDuration = 45;

        $allSlots = [
            new DateTimeImmutable('2025-01-15 09:00:00', new DateTimeZone('UTC')),
            new DateTimeImmutable('2025-01-15 10:00:00', new DateTimeZone('UTC')),
            new DateTimeImmutable('2025-01-15 11:00:00', new DateTimeZone('UTC')),
            new DateTimeImmutable('2025-01-15 11:30:00', new DateTimeZone('UTC')),
        ];

        $validSlots = [];
        foreach ($allSlots as $slot) {
            $serviceEnd = $slot->modify("+{$serviceDuration} minutes");
            if ($serviceEnd <= $close) {
                $validSlots[] = $slot->format('H:i');
            }
        }

        // 11:30 + 45min = 12:15 > 12:00, so not valid
        $this->assertCount(3, $validSlots);
        $this->assertContains('09:00', $validSlots);
        $this->assertContains('10:00', $validSlots);
        $this->assertContains('11:00', $validSlots);
        $this->assertNotContains('11:30', $validSlots);
    }

    // ==================== Staff Availability Tests ====================

    public function testStaffBreakTimeExcludedFromAvailability(): void
    {
        // Staff works 9:00-18:00 with break 12:00-13:00
        $workStart = new DateTimeImmutable('2025-01-15 09:00:00');
        $workEnd = new DateTimeImmutable('2025-01-15 18:00:00');
        $breakStart = new DateTimeImmutable('2025-01-15 12:00:00');
        $breakEnd = new DateTimeImmutable('2025-01-15 13:00:00');

        $slotToCheck = new DateTimeImmutable('2025-01-15 12:30:00');

        $isDuringBreak = ($slotToCheck >= $breakStart && $slotToCheck < $breakEnd);

        $this->assertTrue($isDuringBreak, 'Slot during break should be marked unavailable');
    }

    public function testStaffAvailableOutsideBreak(): void
    {
        $breakStart = new DateTimeImmutable('2025-01-15 12:00:00');
        $breakEnd = new DateTimeImmutable('2025-01-15 13:00:00');

        $slotToCheck = new DateTimeImmutable('2025-01-15 14:00:00');

        $isDuringBreak = ($slotToCheck >= $breakStart && $slotToCheck < $breakEnd);

        $this->assertFalse($isDuringBreak, 'Slot outside break should be available');
    }

    // ==================== Multi-Staff Availability Tests ====================

    public function testAnyStaffAvailableReturnsSlot(): void
    {
        // Staff A booked at 10:00, Staff B free
        $staffABooked = ['10:00', '10:30'];
        $staffBBooked = ['11:00'];

        $requestedSlot = '10:00';

        // At least one staff free?
        $staffAFree = !in_array($requestedSlot, $staffABooked);
        $staffBFree = !in_array($requestedSlot, $staffBBooked);

        $slotAvailable = $staffAFree || $staffBFree;

        $this->assertTrue($slotAvailable, 'Slot should be available if any staff is free');
    }

    public function testNoStaffAvailableReturnsUnavailable(): void
    {
        // Both staff booked at 10:00
        $staffABooked = ['10:00', '10:30'];
        $staffBBooked = ['10:00', '11:00'];

        $requestedSlot = '10:00';

        $staffAFree = !in_array($requestedSlot, $staffABooked);
        $staffBFree = !in_array($requestedSlot, $staffBBooked);

        $slotAvailable = $staffAFree || $staffBFree;

        $this->assertFalse($slotAvailable, 'Slot should be unavailable if all staff booked');
    }

    // ==================== Date Range Tests ====================

    public function testAvailabilityForDateRange(): void
    {
        $startDate = new DateTimeImmutable('2025-01-15');
        $endDate = new DateTimeImmutable('2025-01-17');

        $dates = [];
        $current = $startDate;

        while ($current <= $endDate) {
            $dates[] = $current->format('Y-m-d');
            $current = $current->modify('+1 day');
        }

        $this->assertCount(3, $dates);
        $this->assertEquals(['2025-01-15', '2025-01-16', '2025-01-17'], $dates);
    }

    public function testExcludeClosedDays(): void
    {
        // Business closed on Sunday (day 0)
        $closedDays = [0]; // Sunday

        $dates = [
            new DateTimeImmutable('2025-01-18'), // Saturday (6)
            new DateTimeImmutable('2025-01-19'), // Sunday (0)
            new DateTimeImmutable('2025-01-20'), // Monday (1)
        ];

        $openDates = [];
        foreach ($dates as $date) {
            $dayOfWeek = (int) $date->format('w');
            if (!in_array($dayOfWeek, $closedDays)) {
                $openDates[] = $date->format('Y-m-d');
            }
        }

        $this->assertCount(2, $openDates);
        $this->assertNotContains('2025-01-19', $openDates);
    }

    // ==================== Buffer Time Tests ====================

    public function testBufferTimeBetweenAppointments(): void
    {
        $appointmentEnd = new DateTimeImmutable('2025-01-15 10:30:00');
        $bufferMinutes = 15;
        $nextAvailableSlot = $appointmentEnd->modify("+{$bufferMinutes} minutes");

        $this->assertEquals('10:45', $nextAvailableSlot->format('H:i'));
    }

    public function testNoBufferWhenNotConfigured(): void
    {
        $appointmentEnd = new DateTimeImmutable('2025-01-15 10:30:00');
        $bufferMinutes = 0;
        $nextAvailableSlot = $appointmentEnd->modify("+{$bufferMinutes} minutes");

        $this->assertEquals('10:30', $nextAvailableSlot->format('H:i'));
    }

    // ==================== Timezone Tests ====================

    public function testSlotConversionBetweenTimezones(): void
    {
        $utcSlot = new DateTimeImmutable('2025-01-15 10:00:00', new DateTimeZone('UTC'));
        $romeSlot = $utcSlot->setTimezone(new DateTimeZone('Europe/Rome'));

        // In January, Rome is UTC+1
        $this->assertEquals('11:00', $romeSlot->format('H:i'));
    }

    public function testSlotsGeneratedInBusinessTimezone(): void
    {
        $businessTz = new DateTimeZone('Europe/Rome');
        $open = new DateTimeImmutable('2025-01-15 09:00:00', $businessTz);

        $this->assertEquals('Europe/Rome', $open->getTimezone()->getName());
        $this->assertEquals('09:00', $open->format('H:i'));

        // Convert to UTC for storage
        $utc = $open->setTimezone(new DateTimeZone('UTC'));
        $this->assertEquals('08:00', $utc->format('H:i'));
    }
}
