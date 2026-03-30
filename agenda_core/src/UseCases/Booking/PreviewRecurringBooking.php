<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Domain\Booking\RecurrenceRule;
use Agenda\Domain\Exceptions\BookingException;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Preview a recurring booking series without creating it.
 * 
 * Calculates all dates and detects conflicts.
 * Returns the list of dates with conflict status so user can review before creation.
 */
final class PreviewRecurringBooking
{
    public function __construct(
        private readonly Connection $db,
        private readonly BookingRepository $bookingRepository,
        private readonly ServiceRepository $serviceRepository,
        private readonly StaffRepository $staffRepository,
        private readonly ClientRepository $clientRepository,
        private readonly LocationRepository $locationRepository,
    ) {}

    /**
     * Preview a recurring booking series.
     *
     * @param int $locationId The location ID
     * @param int $businessId The business ID
     * @param array $data {
     *   service_ids: int[],
     *   staff_id: int|null,
     *   start_time: string (ISO8601),
     *   client_id: int,
     *   recurrence: {
     *     frequency: 'daily'|'weekly'|'monthly'|'custom',
     *     interval_value?: int (default 1),
     *     max_occurrences?: int,
     *     end_date?: string (Y-m-d),
     *     days_of_week?: int[] (0=Sun, 6=Sat),
     *     day_of_month?: int
     *   }
     * }
     * @return array {
     *   total_dates: int,
     *   dates: array[] (each with recurrence_index, start_time, end_time, has_conflict)
     * }
     * @throws BookingException
     */
    public function execute(
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

        $itemTemplates = $this->buildItemTemplates(
            services: $services,
            data: $data,
            defaultStaffId: $staffId
        );
        if (empty($itemTemplates)) {
            throw BookingException::invalidService([]);
        }
        if ($staffId === null) {
            $staffId = $itemTemplates[0]['staff_id'] ?? null;
        }

        $totalDuration = 0;
        foreach ($itemTemplates as $template) {
            $candidateEnd = (int) $template['start_offset_minutes']
                + (int) $template['duration_minutes']
                + (int) $template['processing_extra_minutes']
                + (int) $template['blocked_extra_minutes'];
            if ($candidateEnd > $totalDuration) {
                $totalDuration = $candidateEnd;
            }
        }

        // Build RecurrenceRule (without ID, just for date calculation)
        $recurrenceRule = new RecurrenceRule(
            id: null,
            businessId: $businessId,
            frequency: $recurrenceData['frequency'],
            intervalValue: (int) ($recurrenceData['interval_value'] ?? 1),
            maxOccurrences: isset($recurrenceData['max_occurrences']) ? (int) $recurrenceData['max_occurrences'] : null,
            endDate: isset($recurrenceData['end_date']) ? new DateTimeImmutable($recurrenceData['end_date']) : null,
            conflictStrategy: RecurrenceRule::CONFLICT_SKIP, // Not used for preview, but required
            daysOfWeek: $recurrenceData['days_of_week'] ?? null,
            dayOfMonth: isset($recurrenceData['day_of_month']) ? (int) $recurrenceData['day_of_month'] : null,
        );

        // Calculate all dates in the series
        $dates = $recurrenceRule->calculateDates($startTime);

        // Build preview list with conflict detection
        $previewDates = [];
        foreach ($dates as $index => $date) {
            $occurrenceStart = $date->setTime(
                (int) $startTime->format('H'),
                (int) $startTime->format('i'),
                0
            );
            $occurrenceEnd = $occurrenceStart->modify("+{$totalDuration} minutes");

            $hasConflict = $this->checkConflict(
                $locationId,
                $staffId,
                $occurrenceStart,
                $occurrenceEnd
            );

            $previewDates[] = [
                'recurrence_index' => $index,
                'start_time' => $occurrenceStart->format('Y-m-d H:i:s'),
                'end_time' => $occurrenceEnd->format('Y-m-d H:i:s'),
                'has_conflict' => $hasConflict,
            ];
        }

        return [
            'total_dates' => count($previewDates),
            'dates' => $previewDates,
        ];
    }

    /**
     * Check for conflicts with existing bookings.
     */
    private function checkConflict(
        int $locationId,
        ?int $staffId,
        DateTimeImmutable $start,
        DateTimeImmutable $end
    ): bool {
        if ($staffId === null) {
            return false; // Cannot check conflicts without staff
        }

        $conflicts = $this->bookingRepository->checkConflicts(
            staffId: $staffId,
            locationId: $locationId,
            startTime: $start,
            endTime: $end,
            excludeBookingId: null
        );

        return !empty($conflicts);
    }

    /**
     * Build normalized recurring item templates used to compute occurrence span.
     *
     * @return array<int, array{
     *   staff_id:int,
     *   start_offset_minutes:int,
     *   duration_minutes:int,
     *   blocked_extra_minutes:int,
     *   processing_extra_minutes:int
     * }>
     */
    private function buildItemTemplates(array $services, array $data, ?int $defaultStaffId): array
    {
        $serviceById = [];
        foreach ($services as $service) {
            $serviceById[(int) $service['id']] = $service;
        }

        $rawItems = isset($data['items']) && is_array($data['items']) ? $data['items'] : null;
        $templates = [];

        if (is_array($rawItems) && !empty($rawItems)) {
            foreach ($rawItems as $item) {
                $serviceId = (int) ($item['service_id'] ?? 0);
                if ($serviceId <= 0 || !isset($serviceById[$serviceId])) {
                    throw BookingException::invalidService([$serviceId]);
                }
                $service = $serviceById[$serviceId];

                $itemStaffId = isset($item['staff_id']) ? (int) $item['staff_id'] : $defaultStaffId;
                if ($itemStaffId === null || $itemStaffId <= 0) {
                    throw BookingException::invalidStaff((int) $itemStaffId);
                }

                $templates[] = [
                    'staff_id' => $itemStaffId,
                    'start_offset_minutes' => isset($item['start_offset_minutes'])
                        ? max(0, (int) $item['start_offset_minutes'])
                        : null,
                    'duration_minutes' => isset($item['duration_minutes'])
                        ? max(1, (int) $item['duration_minutes'])
                        : (int) ($service['duration_minutes'] ?? $service['default_duration'] ?? 30),
                    'blocked_extra_minutes' => isset($item['blocked_extra_minutes'])
                        ? max(0, (int) $item['blocked_extra_minutes'])
                        : (int) ($service['blocked_time'] ?? 0),
                    'processing_extra_minutes' => isset($item['processing_extra_minutes'])
                        ? max(0, (int) $item['processing_extra_minutes'])
                        : (int) ($service['processing_time'] ?? 0),
                ];
            }
        } else {
            $cursor = 0;
            foreach ($services as $service) {
                $duration = (int) ($service['duration_minutes'] ?? $service['default_duration'] ?? 30);
                $processing = (int) ($service['processing_time'] ?? 0);
                $blocked = (int) ($service['blocked_time'] ?? 0);
                $templates[] = [
                    'staff_id' => (int) ($defaultStaffId ?? 0),
                    'start_offset_minutes' => $cursor,
                    'duration_minutes' => $duration,
                    'blocked_extra_minutes' => $blocked,
                    'processing_extra_minutes' => $processing,
                ];
                $cursor += $duration + $processing + $blocked;
            }
        }

        $cursor = 0;
        foreach ($templates as $index => $template) {
            $offset = $template['start_offset_minutes'];
            if ($offset === null) {
                $offset = $cursor;
            }
            $offset = max(0, (int) $offset);
            $templates[$index]['start_offset_minutes'] = $offset;
            $candidateEnd = $offset
                + (int) $template['duration_minutes']
                + (int) $template['processing_extra_minutes']
                + (int) $template['blocked_extra_minutes'];
            if ($candidateEnd > $cursor) {
                $cursor = $candidateEnd;
            }
        }

        return $templates;
    }
}
