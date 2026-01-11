<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\StaffPlanningRepository;
use Agenda\Infrastructure\Repositories\TimeBlockRepository;
use Agenda\Infrastructure\Repositories\StaffAvailabilityExceptionRepository;
use DateTimeImmutable;
use DateTimeZone;
use DateInterval;

final class ComputeAvailability
{
    private const SLOT_INTERVAL_MINUTES = 15;
    private const DEFAULT_MAX_DAYS_AHEAD = 60;
    private const DEFAULT_MIN_NOTICE_HOURS = 1;

    public function __construct(
        private readonly BookingRepository $bookingRepository,
        private readonly StaffRepository $staffRepository,
        private readonly \Agenda\Infrastructure\Repositories\LocationRepository $locationRepository,
        private readonly StaffPlanningRepository $staffPlanningRepository,
        private readonly TimeBlockRepository $timeBlockRepository,
        private readonly StaffAvailabilityExceptionRepository $staffExceptionRepository,
    ) {}

    /**
     * Compute available time slots for a given date range.
     * 
     * @param int $businessId
     * @param int $locationId
     * @param int|null $staffId Filter by specific staff (optional)
     * @param int $durationMinutes Total duration needed
     * @param string $date Date in Y-m-d format
     * @param array<int> $serviceIds Services requested (used to filter eligible staff)
     * @return array Available slots
     */
    public function execute(
        int $businessId,
        int $locationId,
        ?int $staffId,
        int $durationMinutes,
        string $date,
        array $serviceIds
    ): array {
        // Get timezone and booking limits from location
        $location = $this->locationRepository->findById($locationId);
        if (!$location) {
            return ['error' => 'Location not found'];
        }
        
        $timezoneStr = $location['timezone'] ?? 'Europe/Rome';
        $timezone = new DateTimeZone($timezoneStr);
        
        // Get booking limits from location (with defaults)
        $maxDaysAhead = (int) ($location['max_booking_advance_days'] ?? self::DEFAULT_MAX_DAYS_AHEAD);
        $minNoticeHours = (int) ($location['min_booking_notice_hours'] ?? self::DEFAULT_MIN_NOTICE_HOURS);
        
        try {
            $targetDate = new DateTimeImmutable($date, $timezone);
        } catch (\Exception $e) {
            return ['error' => 'Invalid date format'];
        }

        // Validate date is not too far in the future (using location setting)
        $maxDate = (new DateTimeImmutable('now', $timezone))->modify('+' . $maxDaysAhead . ' days');
        if ($targetDate > $maxDate) {
            return ['slots' => []];
        }

        // Validate date is not in the past
        $today = new DateTimeImmutable('today', $timezone);
        if ($targetDate < $today) {
            return ['slots' => []];
        }

        // Calculate minimum booking time (now + min_booking_notice_hours)
        $minBookingTime = (new DateTimeImmutable('now', $timezone))->modify('+' . $minNoticeHours . ' hours');

        // Get staff members to check
        if ($staffId !== null) {
            $staffMembers = [['id' => $staffId]];
        } else {
            $staffMembers = $this->staffRepository->findByLocationId($locationId, $businessId);
        }

        // Filter by service capabilities (staff must be able to perform ALL requested services)
        $serviceIds = array_values(array_map('intval', $serviceIds));
        $staffMembers = array_filter(
            $staffMembers,
            fn ($s) => $this->staffRepository->canPerformServices((int) $s['id'], $serviceIds, $locationId, $businessId)
        );

        if (empty($staffMembers)) {
            return ['slots' => []];
        }

        $allSlots = [];

        foreach ($staffMembers as $staff) {
            $staffSlots = $this->computeStaffAvailability(
                (int) $staff['id'],
                $locationId,
                $targetDate,
                $durationMinutes,
                $timezone,
                $minBookingTime
            );

            foreach ($staffSlots as $slot) {
                $slot['staff_id'] = (int) $staff['id'];
                $slot['staff_name'] = $staff['display_name'] ?? null;
                $allSlots[] = $slot;
            }
        }

        // Sort by start time
        usort($allSlots, fn($a, $b) => $a['start_time'] <=> $b['start_time']);

        return ['slots' => $allSlots];
    }

    private function computeStaffAvailability(
        int $staffId,
        int $locationId,
        DateTimeImmutable $date,
        int $durationMinutes,
        DateTimeZone $timezone,
        DateTimeImmutable $minBookingTime
    ): array {
        $dateStr = $date->format('Y-m-d');
        
        // Usa StaffPlanningRepository per ottenere gli slot index disponibili
        $slotIndices = $this->staffPlanningRepository->getSlotsForDate($staffId, $dateStr);

        // Se nessun planning valido o nessuno slot, staff non disponibile
        if ($slotIndices === null || empty($slotIndices)) {
            return [];
        }

        // Converti slot index in intervalli di tempo
        // Slot index 0 = 00:00-00:15, slot index 1 = 00:15-00:30, ecc.
        $workingIntervals = $this->slotIndicesToIntervals($slotIndices, $date);

        if (empty($workingIntervals)) {
            return [];
        }

        // Get occupied slots for this day
        $dayStart = $date->setTime(0, 0, 0);
        $dayEnd = $date->setTime(23, 59, 59);
        
        $occupiedSlots = $this->bookingRepository->getOccupiedSlots(
            $staffId,
            $locationId,
            $dayStart,
            $dayEnd
        );

        // Get time blocks for this staff on this day
        $timeBlocks = $this->timeBlockRepository->findByStaffAndDate($staffId, $locationId, $dateStr);

        // Get availability exceptions for this staff on this day
        $exceptions = $this->staffExceptionRepository->getByStaffId($staffId, $dateStr, $dateStr);

        // Process exceptions - split into unavailable (to block) and available (to add)
        $unavailableExceptions = [];
        $availableExceptions = [];
        foreach ($exceptions as $exc) {
            if ($exc['type'] === 'unavailable') {
                $unavailableExceptions[] = $exc;
            } else {
                $availableExceptions[] = $exc;
            }
        }

        // Add available exceptions as extra working intervals
        foreach ($availableExceptions as $exc) {
            if ($exc['start_time'] !== null && $exc['end_time'] !== null) {
                $workingIntervals[] = [
                    'start' => new DateTimeImmutable($dateStr . ' ' . $exc['start_time'], $timezone),
                    'end' => new DateTimeImmutable($dateStr . ' ' . $exc['end_time'], $timezone),
                ];
            }
        }

        // Convert occupied slots to DateTimeImmutable
        $occupied = array_map(fn($slot) => [
            'start' => new DateTimeImmutable($slot['start_time'], $timezone),
            'end' => new DateTimeImmutable($slot['end_time'], $timezone),
        ], $occupiedSlots);

        // Convert time blocks to DateTimeImmutable and add to occupied
        foreach ($timeBlocks as $block) {
            $occupied[] = [
                'start' => new DateTimeImmutable($block['start_time'], $timezone),
                'end' => new DateTimeImmutable($block['end_time'], $timezone),
            ];
        }

        // Convert unavailable exceptions to occupied slots
        foreach ($unavailableExceptions as $exc) {
            if ($exc['start_time'] !== null && $exc['end_time'] !== null) {
                // Partial day unavailability
                $occupied[] = [
                    'start' => new DateTimeImmutable($dateStr . ' ' . $exc['start_time'], $timezone),
                    'end' => new DateTimeImmutable($dateStr . ' ' . $exc['end_time'], $timezone),
                ];
            } else {
                // Full day unavailability - block entire day
                $occupied[] = [
                    'start' => $date->setTime(0, 0, 0),
                    'end' => $date->setTime(23, 59, 59),
                ];
            }
        }

        // Generate available slots
        $availableSlots = [];

        foreach ($workingIntervals as $interval) {
            $current = $interval['start'];
            $intervalEnd = $interval['end'];

            while ($current->modify("+{$durationMinutes} minutes") <= $intervalEnd) {
                $slotEnd = $current->modify("+{$durationMinutes} minutes");

                // Skip if slot starts before minimum booking time (includes past + notice hours)
                if ($current <= $minBookingTime) {
                    $current = $current->modify('+' . self::SLOT_INTERVAL_MINUTES . ' minutes');
                    continue;
                }

                // Check if slot conflicts with any occupied slot
                $hasConflict = false;
                foreach ($occupied as $occ) {
                    if ($current < $occ['end'] && $slotEnd > $occ['start']) {
                        $hasConflict = true;
                        break;
                    }
                }

                if (!$hasConflict) {
                    $availableSlots[] = [
                        'start_time' => $current->format('c'),
                        'end_time' => $slotEnd->format('c'),
                    ];
                }

                $current = $current->modify('+' . self::SLOT_INTERVAL_MINUTES . ' minutes');
            }
        }

        return $availableSlots;
    }

    /**
     * Converte array di slot index in intervalli di tempo continui.
     * 
     * Esempio: [36, 37, 38, 48, 49] diventa:
     * - 09:00-09:45 (slot 36,37,38)
     * - 12:00-12:30 (slot 48,49)
     */
    private function slotIndicesToIntervals(array $slotIndices, DateTimeImmutable $date): array
    {
        if (empty($slotIndices)) {
            return [];
        }

        sort($slotIndices);
        
        $intervals = [];
        $currentStart = $slotIndices[0];
        $currentEnd = $slotIndices[0];

        for ($i = 1; $i < count($slotIndices); $i++) {
            if ($slotIndices[$i] === $currentEnd + 1) {
                // Slot consecutivo, estendi l'intervallo
                $currentEnd = $slotIndices[$i];
            } else {
                // Gap trovato, salva intervallo corrente e inizia nuovo
                $intervals[] = $this->slotRangeToTimeInterval($currentStart, $currentEnd, $date);
                $currentStart = $slotIndices[$i];
                $currentEnd = $slotIndices[$i];
            }
        }

        // Aggiungi ultimo intervallo
        $intervals[] = $this->slotRangeToTimeInterval($currentStart, $currentEnd, $date);

        return $intervals;
    }

    /**
     * Converte un range di slot index in un intervallo di DateTimeImmutable.
     * 
     * Lo slot index N corrisponde al range [N*15min, (N+1)*15min).
     * Es: slot 36 = 09:00-09:15
     */
    private function slotRangeToTimeInterval(int $startSlot, int $endSlot, DateTimeImmutable $date): array
    {
        $startMinutes = $startSlot * self::SLOT_INTERVAL_MINUTES;
        $startHour = intdiv($startMinutes, 60);
        $startMin = $startMinutes % 60;

        // L'end slot include lo slot stesso, quindi aggiungiamo 1 slot alla fine
        $endMinutes = ($endSlot + 1) * self::SLOT_INTERVAL_MINUTES;
        $endHour = intdiv($endMinutes, 60);
        $endMin = $endMinutes % 60;

        return [
            'start' => $date->setTime($startHour, $startMin),
            'end' => $date->setTime($endHour, $endMin),
        ];
    }
}
