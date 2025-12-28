<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use DateTimeImmutable;
use DateTimeZone;
use DateInterval;

final class ComputeAvailability
{
    private const SLOT_INTERVAL_MINUTES = 15;
    private const MAX_DAYS_AHEAD = 60;

    public function __construct(
        private readonly BookingRepository $bookingRepository,
        private readonly StaffRepository $staffRepository,
        private readonly \Agenda\Infrastructure\Repositories\LocationRepository $locationRepository,
    ) {}

    /**
     * Compute available time slots for a given date range.
     * 
     * @param int $businessId
     * @param int $locationId
     * @param int|null $staffId Filter by specific staff (optional)
     * @param int $durationMinutes Total duration needed
     * @param string $date Date in Y-m-d format
     * @return array Available slots
     */
    public function execute(
        int $businessId,
        int $locationId,
        ?int $staffId,
        int $durationMinutes,
        string $date
    ): array {
        // Get timezone from location
        $location = $this->locationRepository->findById($locationId);
        if (!$location) {
            return ['error' => 'Location not found'];
        }
        
        $timezoneStr = $location['timezone'] ?? 'Europe/Rome';
        $timezone = new DateTimeZone($timezoneStr);
        
        try {
            $targetDate = new DateTimeImmutable($date, $timezone);
        } catch (\Exception $e) {
            return ['error' => 'Invalid date format'];
        }

        // Validate date is not too far in the future
        $maxDate = (new DateTimeImmutable('now', $timezone))->modify('+' . self::MAX_DAYS_AHEAD . ' days');
        if ($targetDate > $maxDate) {
            return ['slots' => []];
        }

        // Validate date is not in the past
        $today = new DateTimeImmutable('today', $timezone);
        if ($targetDate < $today) {
            return ['slots' => []];
        }

        // Get staff members to check
        if ($staffId !== null) {
            $staffMembers = [['id' => $staffId]];
        } else {
            $staffMembers = $this->staffRepository->findByLocationId($locationId, $businessId);
        }

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
                $timezone
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
        DateTimeZone $timezone
    ): array {
        // Get day of week (0 = Sunday, 6 = Saturday in MySQL, PHP uses 0-6 starting Monday)
        $dayOfWeek = (int) $date->format('N'); // 1 = Monday, 7 = Sunday
        
        // Get working hours for this day
        $workingHours = $this->staffRepository->getWorkingHours($staffId, $dayOfWeek);

        // If no working hours defined or not working, return empty
        if ($workingHours === null || !$workingHours['is_working']) {
            return [];
        }

        // Parse working hours
        $startOfDay = $date->setTime(
            (int) substr($workingHours['start_time'], 0, 2),
            (int) substr($workingHours['start_time'], 3, 2)
        );
        $endOfDay = $date->setTime(
            (int) substr($workingHours['end_time'], 0, 2),
            (int) substr($workingHours['end_time'], 3, 2)
        );

        // Get occupied slots for this day
        $dayStart = $date->setTime(0, 0, 0);
        $dayEnd = $date->setTime(23, 59, 59);
        
        $occupiedSlots = $this->bookingRepository->getOccupiedSlots(
            $staffId,
            $locationId,
            $dayStart,
            $dayEnd
        );

        // Convert occupied slots to DateTimeImmutable
        $occupied = array_map(fn($slot) => [
            'start' => new DateTimeImmutable($slot['start_time'], $timezone),
            'end' => new DateTimeImmutable($slot['end_time'], $timezone),
        ], $occupiedSlots);

        // Generate available slots
        $availableSlots = [];
        $current = $startOfDay;
        $now = new DateTimeImmutable('now', $timezone);

        while ($current->modify("+{$durationMinutes} minutes") <= $endOfDay) {
            $slotEnd = $current->modify("+{$durationMinutes} minutes");

            // Skip if slot starts in the past
            if ($current <= $now) {
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

        return $availableSlots;
    }
}
