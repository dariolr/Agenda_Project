<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\StaffPlanningRepository;
use Agenda\Infrastructure\Repositories\TimeBlockRepository;
use Agenda\Infrastructure\Repositories\StaffAvailabilityExceptionRepository;
use Agenda\Infrastructure\Repositories\ServiceVariantResourceRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\LocationClosureRepository;
use DateTimeImmutable;
use DateTimeZone;
use DateInterval;

final class ComputeAvailability
{
    /**
     * Fallback for planning slot duration when a planning row has no explicit value.
     */
    private const PLANNING_SLOT_MINUTES = 15;

    /**
     * Fallback interval used only for online slot proposal cadence.
     */
    private const DEFAULT_DISPLAY_SLOT_INTERVAL_MINUTES = 15;
    private const DEFAULT_MAX_DAYS_AHEAD = 60;
    private const DEFAULT_MIN_NOTICE_HOURS = 1;
    
    /** @var int|null Booking ID to exclude from conflicts (for edit mode) */
    private ?int $currentExcludeBookingId = null;
    
    /** @var array|null Location slot settings for current request */
    private ?array $currentLocationSlotSettings = null;

    public function __construct(
        private readonly BookingRepository $bookingRepository,
        private readonly StaffRepository $staffRepository,
        private readonly \Agenda\Infrastructure\Repositories\LocationRepository $locationRepository,
        private readonly StaffPlanningRepository $staffPlanningRepository,
        private readonly TimeBlockRepository $timeBlockRepository,
        private readonly StaffAvailabilityExceptionRepository $staffExceptionRepository,
        private readonly ?ServiceVariantResourceRepository $resourceRequirementRepository = null,
        private readonly ?ServiceRepository $serviceRepository = null,
        private readonly ?LocationClosureRepository $locationClosureRepository = null,
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
     * @param bool $keepStaffInfo If true, keep staff_id even when deduplicating (for internal use)
     * @param int|null $excludeBookingId Exclude this booking from conflicts (for edit mode)
     * @param bool $isPublic If true, apply slot_display_mode filtering (for frontend booking)
     * @return array Available slots
     */
    public function execute(
        int $businessId,
        int $locationId,
        ?int $staffId,
        int $durationMinutes,
        string $date,
        array $serviceIds,
        bool $keepStaffInfo = false,
        ?int $excludeBookingId = null,
        bool $isPublic = false
    ): array {
        // Store excludeBookingId for use in computeStaffAvailability
        $this->currentExcludeBookingId = $excludeBookingId;
        
        // Get timezone and booking limits from location
        $location = $this->locationRepository->findById($locationId);
        if (!$location) {
            return ['error' => 'Location not found'];
        }
        
        // Store slot settings for filtering
        $this->currentLocationSlotSettings = [
            // Controls only the cadence of proposed customer slots.
            'online_booking_slot_interval_minutes' => (int) ($location['online_booking_slot_interval_minutes'] ?? self::DEFAULT_DISPLAY_SLOT_INTERVAL_MINUTES),
            'slot_display_mode' => $location['slot_display_mode'] ?? 'all',
            'min_gap_minutes' => (int) ($location['min_gap_minutes'] ?? 30),
        ];
        
        $timezoneStr = $location['timezone'] ?? 'Europe/Rome';
        $timezone = new DateTimeZone($timezoneStr);
        
        // Get booking limits from location (with defaults)
        $maxDaysAhead = (int) ($location['max_booking_advance_days'] ?? self::DEFAULT_MAX_DAYS_AHEAD);
        $minNoticeHours = (int) ($location['min_booking_notice_hours'] ?? self::DEFAULT_MIN_NOTICE_HOURS);
        
        // Get resource requirements for requested services (if repository is available)
        $resourceRequirements = [];
        $resourceCapacities = [];
        if ($this->resourceRequirementRepository !== null && $this->serviceRepository !== null) {
            $variantIds = $this->serviceRepository->getVariantIdsByServiceIds($serviceIds, $locationId);
            if (!empty($variantIds)) {
                $resourceRequirements = $this->resourceRequirementRepository->getAggregatedRequirements($variantIds);
                if (!empty($resourceRequirements)) {
                    $resourceCapacities = $this->resourceRequirementRepository->getResourceCapacities($locationId);
                }
            }
        }
        
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

        // Check if location is closed on this date
        if ($this->locationClosureRepository !== null) {
            if ($this->locationClosureRepository->isDateClosed($locationId, $date)) {
                return ['slots' => []];
            }
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

        // Filter slots by resource availability
        if (!empty($resourceRequirements) && !empty($resourceCapacities)) {
            $allSlots = $this->filterByResourceAvailability(
                $allSlots,
                $resourceRequirements,
                $resourceCapacities,
                $locationId,
                $timezone,
                $durationMinutes
            );
        }

        // Se staffId non è specificato ("qualsiasi operatore"), deduplica per orario
        // Mostra ogni orario una sola volta (con il primo staff disponibile)
        if ($staffId === null) {
            $uniqueSlots = [];
            $seenStartTimes = [];
            foreach ($allSlots as $slot) {
                if (!isset($seenStartTimes[$slot['start_time']])) {
                    $seenStartTimes[$slot['start_time']] = true;
                    // Mantieni staff_id se richiesto (per CreateBooking), altrimenti rimuovi (per API pubblica)
                    if (!$keepStaffInfo) {
                        unset($slot['staff_id'], $slot['staff_name']);
                    }
                    $uniqueSlots[] = $slot;
                }
            }
            
            // Apply min_gap filtering for public requests
            if ($isPublic) {
                $uniqueSlots = $this->applyMinGapFilter($uniqueSlots, $durationMinutes, $timezone, $locationId);
            }
            
            return ['slots' => $uniqueSlots];
        }

        $finalSlots = $allSlots;
        
        // Apply min_gap filtering for public requests
        if ($isPublic) {
            $finalSlots = $this->applyMinGapFilter($finalSlots, $durationMinutes, $timezone, $locationId);
        }
        
        return ['slots' => $finalSlots];
    }
    
    /**
     * Apply min_gap filter to slots based on location settings.
     * Removes slots that would create gaps smaller than min_gap_minutes.
     * 
     * @param array $slots Available slots
     * @param int $durationMinutes Duration of the service
     * @param DateTimeZone $timezone Location timezone
     * @param int $locationId Location ID for fetching existing bookings
     * @return array Filtered slots
     */
    private function applyMinGapFilter(array $slots, int $durationMinutes, DateTimeZone $timezone, int $locationId): array
    {
        // Check if min_gap mode is enabled
        if ($this->currentLocationSlotSettings === null) {
            return $slots;
        }
        
        $displayMode = $this->currentLocationSlotSettings['slot_display_mode'];
        if ($displayMode !== 'min_gap') {
            return $slots;
        }
        
        $minGapMinutes = $this->currentLocationSlotSettings['min_gap_minutes'];
        
        if (empty($slots) || $minGapMinutes <= 0) {
            return $slots;
        }
        
        // Get the date from first slot
        $firstSlot = $slots[0];
        $firstSlotTime = new DateTimeImmutable($firstSlot['start_time'], $timezone);
        $dateStr = $firstSlotTime->format('Y-m-d');
        $dayStart = $firstSlotTime->setTime(0, 0, 0);
        $dayEnd = $firstSlotTime->setTime(23, 59, 59);
        
        // Get all occupied slots for this location on this date (all staff)
        $occupiedSlots = $this->bookingRepository->getOccupiedSlotsForLocation(
            $locationId,
            $dayStart,
            $dayEnd,
            $this->currentExcludeBookingId
        );
        
        // Convert occupied slots to DateTimeImmutable
        $occupiedIntervals = array_map(fn($slot) => [
            'start' => new DateTimeImmutable($slot['start_time'], $timezone),
            'end' => new DateTimeImmutable($slot['end_time'], $timezone),
        ], $occupiedSlots);
        
        // Filter slots
        $filteredSlots = [];
        
        foreach ($slots as $slot) {
            $slotStart = new DateTimeImmutable($slot['start_time'], $timezone);
            $slotEnd = new DateTimeImmutable($slot['end_time'], $timezone);
            
            // Check if this slot creates a problematic gap
            $createsSmallGap = false;
            
            foreach ($occupiedIntervals as $occupied) {
                // Gap PRIMA dello slot: distanza tra fine occupied e inizio slot
                // Se occupied finisce prima del nostro slot
                if ($occupied['end'] <= $slotStart) {
                    $gapMinutes = ($slotStart->getTimestamp() - $occupied['end']->getTimestamp()) / 60;
                    // Gap piccolo ma non zero (gap zero = adiacente = ok)
                    if ($gapMinutes > 0 && $gapMinutes < $minGapMinutes) {
                        $createsSmallGap = true;
                        break;
                    }
                }
                
                // Gap DOPO lo slot: distanza tra fine slot e inizio occupied
                // Se occupied inizia dopo il nostro slot
                if ($slotEnd <= $occupied['start']) {
                    $gapMinutes = ($occupied['start']->getTimestamp() - $slotEnd->getTimestamp()) / 60;
                    // Gap piccolo ma non zero (gap zero = adiacente = ok)
                    if ($gapMinutes > 0 && $gapMinutes < $minGapMinutes) {
                        $createsSmallGap = true;
                        break;
                    }
                }
            }
            
            if (!$createsSmallGap) {
                $filteredSlots[] = $slot;
            }
        }
        
        return $filteredSlots;
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
        $slotIntervalMinutes = $this->getSlotIntervalMinutes();
        
        $planning = $this->staffPlanningRepository->findValidForDate($staffId, $dateStr);

        if ($planning === null) {
            return [];
        }

        $planningSlotMinutes = (int) ($planning['planning_slot_minutes'] ?? self::PLANNING_SLOT_MINUTES);
        if ($planningSlotMinutes <= 0) {
            $planningSlotMinutes = self::PLANNING_SLOT_MINUTES;
        }

        $slotIndices = $this->extractSlotIndicesForPlanningDate($planning, $dateStr);

        // Se nessuno slot, staff non disponibile
        if (empty($slotIndices)) {
            return [];
        }

        // Converti slot index in intervalli di tempo
        $workingIntervals = $this->slotIndicesToIntervals($slotIndices, $date, $planningSlotMinutes);

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
            $dayEnd,
            $this->currentExcludeBookingId
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
        $addedStartTimes = []; // Track start times to avoid duplicates

        foreach ($workingIntervals as $interval) {
            $current = $interval['start'];
            $intervalEnd = $interval['end'];

            while ($current->modify("+{$durationMinutes} minutes") <= $intervalEnd) {
                $slotEnd = $current->modify("+{$durationMinutes} minutes");

                // Skip if slot starts before minimum booking time (includes past + notice hours)
                if ($current <= $minBookingTime) {
                    $current = $current->modify('+' . $slotIntervalMinutes . ' minutes');
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
                    $startTimeKey = $current->format('c');
                    if (!isset($addedStartTimes[$startTimeKey])) {
                        $availableSlots[] = [
                            'start_time' => $startTimeKey,
                            'end_time' => $slotEnd->format('c'),
                        ];
                        $addedStartTimes[$startTimeKey] = true;
                    }
                }

                $current = $current->modify('+' . $slotIntervalMinutes . ' minutes');
            }
        }

        // === SLOT OPPORTUNISTICI ===
        // 1) Slot che PARTONO dalla fine di appuntamenti esistenti
        // Es: appuntamento finisce alle 12:50 → aggiungi slot 12:50
        foreach ($occupied as $occ) {
            $opportunisticStart = $occ['end'];
            
            // Skip se è già allineato all'intervallo slot configurato
            if ($this->isAlignedToSlotInterval($opportunisticStart, $slotIntervalMinutes)) {
                continue;
            }
            
            // Skip se è prima del minimo tempo di prenotazione
            if ($opportunisticStart <= $minBookingTime) {
                continue;
            }
            
            $opportunisticEnd = $opportunisticStart->modify("+{$durationMinutes} minutes");
            
            // Verifica che lo slot sia dentro un intervallo di lavoro
            $inWorkingInterval = false;
            foreach ($workingIntervals as $interval) {
                if ($opportunisticStart >= $interval['start'] && $opportunisticEnd <= $interval['end']) {
                    $inWorkingInterval = true;
                    break;
                }
            }
            
            if (!$inWorkingInterval) {
                continue;
            }
            
            // Verifica che non ci siano conflitti con altri slot occupati
            $hasConflict = false;
            foreach ($occupied as $otherOcc) {
                if ($opportunisticStart < $otherOcc['end'] && $opportunisticEnd > $otherOcc['start']) {
                    $hasConflict = true;
                    break;
                }
            }
            
            if (!$hasConflict) {
                $startTimeKey = $opportunisticStart->format('c');
                if (!isset($addedStartTimes[$startTimeKey])) {
                    $availableSlots[] = [
                        'start_time' => $startTimeKey,
                        'end_time' => $opportunisticEnd->format('c'),
                    ];
                    $addedStartTimes[$startTimeKey] = true;
                }
            }
        }
        
        // 2) Slot che FINISCONO all'inizio di appuntamenti esistenti
        // Es: appuntamento inizia alle 12:40, servizio 35 min → aggiungi slot 12:05
        foreach ($occupied as $occ) {
            $opportunisticEnd = $occ['start'];
            $opportunisticStart = $opportunisticEnd->modify("-{$durationMinutes} minutes");
            
            // Skip se è già allineato all'intervallo slot configurato
            if ($this->isAlignedToSlotInterval($opportunisticStart, $slotIntervalMinutes)) {
                continue;
            }
            
            // Skip se è prima del minimo tempo di prenotazione
            if ($opportunisticStart <= $minBookingTime) {
                continue;
            }
            
            // Verifica che lo slot sia dentro un intervallo di lavoro
            $inWorkingInterval = false;
            foreach ($workingIntervals as $interval) {
                if ($opportunisticStart >= $interval['start'] && $opportunisticEnd <= $interval['end']) {
                    $inWorkingInterval = true;
                    break;
                }
            }
            
            if (!$inWorkingInterval) {
                continue;
            }
            
            // Verifica che non ci siano conflitti con altri slot occupati
            $hasConflict = false;
            foreach ($occupied as $otherOcc) {
                if ($opportunisticStart < $otherOcc['end'] && $opportunisticEnd > $otherOcc['start']) {
                    $hasConflict = true;
                    break;
                }
            }
            
            if (!$hasConflict) {
                $startTimeKey = $opportunisticStart->format('c');
                if (!isset($addedStartTimes[$startTimeKey])) {
                    $availableSlots[] = [
                        'start_time' => $startTimeKey,
                        'end_time' => $opportunisticEnd->format('c'),
                    ];
                    $addedStartTimes[$startTimeKey] = true;
                }
            }
        }

        // Sort by start time
        usort($availableSlots, fn($a, $b) => $a['start_time'] <=> $b['start_time']);

        return $availableSlots;
    }

    /**
     * Converte array di slot index in intervalli di tempo continui.
     * 
     * Esempio: [36, 37, 38, 48, 49] diventa:
     * - 09:00-09:45 (slot 36,37,38)
     * - 12:00-12:30 (slot 48,49)
     */
    private function slotIndicesToIntervals(array $slotIndices, DateTimeImmutable $date, int $planningSlotMinutes): array
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
                $intervals[] = $this->slotRangeToTimeInterval($currentStart, $currentEnd, $date, $planningSlotMinutes);
                $currentStart = $slotIndices[$i];
                $currentEnd = $slotIndices[$i];
            }
        }

        // Aggiungi ultimo intervallo
        $intervals[] = $this->slotRangeToTimeInterval($currentStart, $currentEnd, $date, $planningSlotMinutes);

        return $intervals;
    }

    /**
     * Converte un range di slot index in un intervallo di DateTimeImmutable.
     * 
     * Lo slot index N corrisponde al range [N*planningSlotMinutes, (N+1)*planningSlotMinutes).
     */
    private function slotRangeToTimeInterval(
        int $startSlot,
        int $endSlot,
        DateTimeImmutable $date,
        int $planningSlotMinutes
    ): array
    {
        $startMinutes = $startSlot * $planningSlotMinutes;
        $startHour = intdiv($startMinutes, 60);
        $startMin = $startMinutes % 60;

        // L'end slot include lo slot stesso, quindi aggiungiamo 1 slot alla fine
        $endMinutes = ($endSlot + 1) * $planningSlotMinutes;
        $endHour = intdiv($endMinutes, 60);
        $endMin = $endMinutes % 60;

        return [
            'start' => $date->setTime($startHour, $startMin),
            'end' => $date->setTime($endHour, $endMin),
        ];
    }

    private function getSlotIntervalMinutes(): int
    {
        $interval = (int) ($this->currentLocationSlotSettings['online_booking_slot_interval_minutes'] ?? self::DEFAULT_DISPLAY_SLOT_INTERVAL_MINUTES);
        return $interval > 0 ? $interval : self::DEFAULT_DISPLAY_SLOT_INTERVAL_MINUTES;
    }

    /**
     * Estrae gli slot index del planning valido per la data.
     *
     * @param array<string, mixed> $planning
     * @return array<int>
     */
    private function extractSlotIndicesForPlanningDate(array $planning, string $dateStr): array
    {
        $dayOfWeek = (int) (new DateTimeImmutable($dateStr))->format('N');
        $weekLabel = 'a';

        if (($planning['type'] ?? 'weekly') === 'biweekly') {
            $weekLabel = $this->staffPlanningRepository->computeWeekLabel(
                (string) $planning['valid_from'],
                $dateStr
            );
        }

        $templates = $planning['templates'] ?? [];
        if (!is_array($templates)) {
            return [];
        }

        foreach ($templates as $template) {
            if (!is_array($template)) {
                continue;
            }
            if (($template['week_label'] ?? null) !== $weekLabel) {
                continue;
            }

            $daySlots = $template['day_slots'] ?? [];
            if (!is_array($daySlots)) {
                return [];
            }

            $slots = $daySlots[$dayOfWeek] ?? [];
            if (!is_array($slots)) {
                return [];
            }

            return array_map('intval', $slots);
        }

        return [];
    }

    private function isAlignedToSlotInterval(DateTimeImmutable $time, int $slotIntervalMinutes): bool
    {
        if ($slotIntervalMinutes <= 1) {
            return true;
        }

        $minutesFromMidnight = ((int) $time->format('H')) * 60 + ((int) $time->format('i'));
        return $minutesFromMidnight % $slotIntervalMinutes === 0;
    }

    /**
     * Filter slots by resource availability.
     * Removes slots where required resources are not available.
     * 
     * @param array $slots Available slots to filter
     * @param array $resourceRequirements Resources needed (resource_id => quantity)
     * @param array $resourceCapacities Total capacity per resource (resource_id => total)
     * @param int $locationId Location ID
     * @param DateTimeZone $timezone Timezone for the location
     * @param int $durationMinutes Duration of the booking
     * @return array Filtered slots
     */
    private function filterByResourceAvailability(
        array $slots,
        array $resourceRequirements,
        array $resourceCapacities,
        int $locationId,
        DateTimeZone $timezone,
        int $durationMinutes
    ): array {
        if (empty($slots) || empty($resourceRequirements) || $this->resourceRequirementRepository === null) {
            return $slots;
        }

        // Get date range from slots
        $firstSlotTime = new DateTimeImmutable($slots[0]['start_time'], $timezone);
        $lastSlotTime = new DateTimeImmutable($slots[count($slots) - 1]['end_time'], $timezone);
        
        // Get all resource usage for the date range
        $resourceUsage = $this->resourceRequirementRepository->getResourceUsageInRange(
            $locationId,
            $firstSlotTime->modify('-1 hour'), // Buffer for overlapping bookings
            $lastSlotTime->modify('+1 hour'),
            $this->currentExcludeBookingId
        );

        $filteredSlots = [];

        foreach ($slots as $slot) {
            $slotStart = new DateTimeImmutable($slot['start_time'], $timezone);
            $slotEnd = new DateTimeImmutable($slot['end_time'], $timezone);

            // Calculate resource usage during this slot
            $usageDuringSlot = [];
            foreach ($resourceUsage as $usage) {
                $usageStart = new DateTimeImmutable($usage['start_time'], $timezone);
                $usageEnd = new DateTimeImmutable($usage['end_time'], $timezone);

                // Check if usage overlaps with slot
                if ($usageStart < $slotEnd && $usageEnd > $slotStart) {
                    $resourceId = (int) $usage['resource_id'];
                    $usageDuringSlot[$resourceId] = ($usageDuringSlot[$resourceId] ?? 0) + (int) $usage['quantity_used'];
                }
            }

            // Check if all required resources are available
            $resourcesAvailable = true;
            foreach ($resourceRequirements as $resourceId => $requiredQty) {
                $totalCapacity = $resourceCapacities[$resourceId] ?? 0;
                $currentUsage = $usageDuringSlot[$resourceId] ?? 0;
                $available = $totalCapacity - $currentUsage;

                if ($available < $requiredQty) {
                    $resourcesAvailable = false;
                    break;
                }
            }

            if ($resourcesAvailable) {
                $filteredSlots[] = $slot;
            }
        }

        return $filteredSlots;
    }
}
