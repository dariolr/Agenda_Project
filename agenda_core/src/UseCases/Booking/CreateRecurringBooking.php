<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\RecurrenceRuleRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\UseCases\Notifications\QueueBookingConfirmation;
use Agenda\UseCases\Notifications\QueueBookingReminder;
use Agenda\Domain\Booking\RecurrenceRule;
use Agenda\Domain\Exceptions\BookingException;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Create a recurring booking series.
 * 
 * Creates a RecurrenceRule and multiple bookings based on the rule.
 * Conflict handling: skip (default) or force.
 */
final class CreateRecurringBooking
{
    public function __construct(
        private readonly Connection $db,
        private readonly BookingRepository $bookingRepository,
        private readonly RecurrenceRuleRepository $recurrenceRuleRepository,
        private readonly ServiceRepository $serviceRepository,
        private readonly StaffRepository $staffRepository,
        private readonly ClientRepository $clientRepository,
        private readonly LocationRepository $locationRepository,
        private readonly UserRepository $userRepository,
        private readonly ?ComputeAvailability $computeAvailability = null,
        private readonly ?NotificationRepository $notificationRepo = null,
        private readonly ?BookingAuditRepository $auditRepository = null,
    ) {}

    /**
     * Create a recurring booking series.
     *
     * @param int $userId The authenticated user ID (operator)
     * @param int $locationId The location ID
     * @param int $businessId The business ID
     * @param array $data {
     *   service_ids: int[],
     *   staff_id: int|null,
     *   start_time: string (ISO8601),
     *   notes?: string,
     *   client_id: int,
     *   excluded_indices?: int[] (indices to skip, from preview),
     *   recurrence: {
     *     frequency: 'daily'|'weekly'|'monthly'|'custom',
     *     interval_value?: int (default 1),
     *     max_occurrences?: int,
     *     end_date?: string (Y-m-d),
     *     conflict_strategy?: 'skip'|'force' (default 'skip'),
     *     days_of_week?: int[] (0=Sun, 6=Sat),
     *     day_of_month?: int
     *   }
     * }
     * @return array {
     *   recurrence_rule_id: int,
     *   total_requested: int,
     *   created_count: int,
     *   skipped_count: int,
     *   bookings: array[],
     *   skipped_dates: array[]
     * }
     * @throws BookingException
     */
    public function execute(
        int $userId,
        int $locationId,
        int $businessId,
        array $data
    ): array {
        // Validate required fields
        $serviceIds = $data['service_ids'] ?? [];
        $staffId = $data['staff_id'] ?? null;
        $startTimeString = $data['start_time'] ?? null;
        $clientId = $data['client_id'] ?? null;
        $recurrenceData = $data['recurrence'] ?? null;
        $notes = $data['notes'] ?? null;
        $excludedIndices = $data['excluded_indices'] ?? [];

        if (empty($serviceIds)) {
            throw BookingException::invalidService([]);
        }

        if ($startTimeString === null) {
            throw BookingException::invalidTime('start_time is required');
        }

        if ($clientId === null) {
            throw BookingException::invalidClient('client_id is required for recurring bookings');
        }

        if ($recurrenceData === null || !isset($recurrenceData['frequency'])) {
            throw new \InvalidArgumentException('recurrence.frequency is required');
        }

        // Parse start time
        try {
            $startTime = new DateTimeImmutable($startTimeString, new DateTimeZone('UTC'));
        } catch (\Exception $e) {
            throw BookingException::invalidTime('Invalid start_time format');
        }

        // Get location timezone
        $location = $this->locationRepository->findById($locationId);
        if (!$location) {
            throw BookingException::invalidLocation($locationId);
        }
        $timezone = new DateTimeZone($location['timezone'] ?? 'Europe/Rome');

        // Validate services
        $services = $this->serviceRepository->findByIds($serviceIds, $locationId, $businessId);
        if (count($services) !== count($serviceIds)) {
            throw BookingException::invalidService($serviceIds);
        }

        // Validate staff if provided
        if ($staffId !== null) {
            $staff = $this->staffRepository->findById($staffId);
            if (!$staff) {
                throw BookingException::invalidStaff($staffId);
            }
        }

        // Validate client
        $client = $this->clientRepository->findById($clientId);
        if (!$client) {
            throw BookingException::invalidClient("Client with ID {$clientId} not found");
        }

        // Calculate total duration (including processing_time and blocked_time, as in CreateBooking)
        $totalDuration = 0;
        foreach ($services as $service) {
            $totalDuration += (int) ($service['duration_minutes'] ?? $service['default_duration'] ?? 30)
                + (int) ($service['processing_time'] ?? 0)
                + (int) ($service['blocked_time'] ?? 0);
        }

        // Build RecurrenceRule
        $recurrenceRule = new RecurrenceRule(
            id: null,
            businessId: $businessId,
            frequency: $recurrenceData['frequency'],
            intervalValue: (int) ($recurrenceData['interval_value'] ?? 1),
            maxOccurrences: isset($recurrenceData['max_occurrences']) ? (int) $recurrenceData['max_occurrences'] : null,
            endDate: isset($recurrenceData['end_date']) ? new DateTimeImmutable($recurrenceData['end_date']) : null,
            conflictStrategy: $recurrenceData['conflict_strategy'] ?? RecurrenceRule::CONFLICT_SKIP,
            daysOfWeek: $recurrenceData['days_of_week'] ?? null,
            dayOfMonth: isset($recurrenceData['day_of_month']) ? (int) $recurrenceData['day_of_month'] : null,
        );

        // Calculate all dates in the series
        $dates = $recurrenceRule->calculateDates($startTime);
        $totalRequested = count($dates);

        // Start transaction
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();

        try {
            // Create recurrence rule
            $ruleId = $this->recurrenceRuleRepository->create($recurrenceRule);

            $createdBookings = [];
            $skippedDates = [];
            $skippedCount = 0;

            foreach ($dates as $index => $date) {
                // Skip if user excluded this index in preview
                if (in_array($index, $excludedIndices, true)) {
                    $occurrenceStart = $date->setTime(
                        (int) $startTime->format('H'),
                        (int) $startTime->format('i'),
                        0
                    );
                    $occurrenceEnd = $occurrenceStart->modify("+{$totalDuration} minutes");
                    $skippedDates[] = [
                        'recurrence_index' => $index,
                        'start_time' => $occurrenceStart->format('Y-m-d H:i:s'),
                        'end_time' => $occurrenceEnd->format('Y-m-d H:i:s'),
                        'reason' => 'excluded',
                    ];
                    $skippedCount++;
                    continue;
                }

                $isParent = (count($createdBookings) === 0); // First created is parent

                // Calculate start and end time for this occurrence
                $occurrenceStart = $date->setTime(
                    (int) $startTime->format('H'),
                    (int) $startTime->format('i'),
                    0
                );
                $occurrenceEnd = $occurrenceStart->modify("+{$totalDuration} minutes");

                // Check for conflicts (only if not forcing)
                $hasConflict = false;
                if ($recurrenceRule->shouldSkipConflicts()) {
                    $hasConflict = $this->checkConflict(
                        $locationId,
                        $staffId,
                        $occurrenceStart,
                        $occurrenceEnd
                    );

                    if ($hasConflict) {
                        $skippedDates[] = [
                            'recurrence_index' => $index,
                            'start_time' => $occurrenceStart->format('Y-m-d H:i:s'),
                            'end_time' => $occurrenceEnd->format('Y-m-d H:i:s'),
                            'reason' => 'conflict',
                        ];
                        $skippedCount++;
                        continue; // Skip this occurrence
                    }
                } elseif ($recurrenceRule->shouldForceCreation()) {
                    // Check conflict for flagging but don't skip
                    $hasConflict = $this->checkConflict(
                        $locationId,
                        $staffId,
                        $occurrenceStart,
                        $occurrenceEnd
                    );
                }

                // Create booking
                $bookingId = $this->bookingRepository->create([
                    'business_id' => $businessId,
                    'location_id' => $locationId,
                    'client_id' => $clientId,
                    'user_id' => $userId,
                    'client_name' => trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? '')),
                    'notes' => $notes,
                    'status' => 'confirmed',
                    'source' => 'manual',
                    'recurrence_rule_id' => $ruleId,
                    'recurrence_index' => $index,
                    'is_recurrence_parent' => $isParent,
                    'has_conflict' => $hasConflict,
                ]);

                // Create booking items
                $currentStart = $occurrenceStart;
                foreach ($services as $service) {
                    $serviceDuration    = (int) ($service['duration_minutes'] ?? $service['default_duration'] ?? 30);
                    $processingMinutes  = (int) ($service['processing_time'] ?? 0);
                    $blockedMinutes     = (int) ($service['blocked_time'] ?? 0);

                    // end_time = durata visibile del servizio (senza extra), come in CreateBooking
                    $serviceEnd  = $currentStart->modify("+{$serviceDuration} minutes");
                    // Il prossimo servizio inizia dopo tutto il tempo bloccato
                    $blockedEnd  = $currentStart->modify("+" . ($serviceDuration + $processingMinutes + $blockedMinutes) . " minutes");

                    $this->bookingRepository->addBookingItem($bookingId, [
                        'location_id' => $locationId,
                        'service_id' => $service['id'],
                        'service_variant_id' => $service['service_variant_id'] ?? $service['variant_id'] ?? $service['id'],
                        'staff_id' => $staffId,
                        'start_time' => $currentStart->format('Y-m-d H:i:s'),
                        'end_time' => $serviceEnd->format('Y-m-d H:i:s'),
                        'price' => $service['price'] ?? 0,
                        'extra_blocked_minutes' => $blockedMinutes,
                        'extra_processing_minutes' => $processingMinutes,
                        'service_name_snapshot' => $service['name'],
                        'client_name_snapshot' => trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? '')),
                    ]);

                    $currentStart = $blockedEnd;
                }

                $createdBookings[] = [
                    'id' => $bookingId,
                    'recurrence_index' => $index,
                    'start_time' => $occurrenceStart->format('Y-m-d H:i:s'),
                    'end_time' => $occurrenceEnd->format('Y-m-d H:i:s'),
                    'has_conflict' => $hasConflict,
                    'is_recurrence_parent' => $isParent,
                ];

                // NOTE: Notifications for recurring bookings will be implemented in Phase 2
                // For now, only the parent booking confirmation is logged

                // Log audit event
                if ($this->auditRepository !== null) {
                    try {
                        $booking = $this->bookingRepository->findById($bookingId);
                        $this->auditRepository->createEvent(
                            bookingId: $bookingId,
                            eventType: 'booking_created',
                            actorType: 'staff',
                            actorId: $userId,
                            payload: $this->buildAuditPayload($booking),
                            correlationId: "recurring_{$ruleId}"
                        );
                    } catch (\Exception $e) {
                        error_log("Failed to log recurring booking audit: " . $e->getMessage());
                    }
                }
            }

            $pdo->commit();

            return [
                'recurrence_rule_id' => $ruleId,
                'total_requested' => $totalRequested,
                'created_count' => count($createdBookings),
                'skipped_count' => $skippedCount,
                'conflict_strategy' => $recurrenceRule->conflictStrategy,
                'bookings' => $createdBookings,
                'skipped_dates' => $skippedDates,
            ];

        } catch (\Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Check for conflicts with existing bookings.
     */
    private function checkConflict(
        int $locationId,
        ?int $staffId,
        DateTimeImmutable $startTime,
        DateTimeImmutable $endTime
    ): bool {
        if ($staffId === null) {
            // If no staff specified, we can't properly check conflicts
            return false;
        }

        // Use existing conflict detection from BookingRepository
        $existingBookings = $this->bookingRepository->findConflictingBookings(
            locationId: $locationId,
            staffId: $staffId,
            startTime: $startTime->format('Y-m-d H:i:s'),
            endTime: $endTime->format('Y-m-d H:i:s')
        );

        return !empty($existingBookings);
    }

    /**
     * Build audit payload for a booking.
     */
    private function buildAuditPayload(array $booking): array
    {
        return [
            'booking_id' => $booking['id'],
            'status' => $booking['status'],
            'location_id' => $booking['location_id'],
            'client_id' => $booking['client_id'],
            'notes' => $booking['notes'],
            'source' => $booking['source'],
            'recurrence_rule_id' => $booking['recurrence_rule_id'],
            'recurrence_index' => $booking['recurrence_index'],
            'is_recurrence_parent' => $booking['is_recurrence_parent'],
            'items' => array_map(fn($item) => [
                'service_id' => $item['service_id'],
                'staff_id' => $item['staff_id'],
                'start_time' => $item['start_time'],
                'end_time' => $item['end_time'],
                'price' => $item['price'],
            ], $booking['items'] ?? []),
            'total_price' => $booking['total_price'] ?? 0,
            'first_start_time' => $booking['items'][0]['start_time'] ?? null,
            'last_end_time' => end($booking['items'])['end_time'] ?? null,
        ];
    }
}
