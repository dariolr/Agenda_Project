<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\LocationClosureRepository;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\UseCases\Notifications\QueueBookingConfirmation;
use Agenda\UseCases\Notifications\QueueBookingReminder;
use Agenda\Domain\Exceptions\BookingException;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Create a new booking with conflict detection.
 * 
 * SCHEMA:
 * - bookings: container (no staff_id, no totals - calculated from items)
 * - booking_items: staff_id, service_variant_id, start_time, end_time, price
 */
final class CreateBooking
{
    public function __construct(
        private readonly Connection $db,
        private readonly BookingRepository $bookingRepository,
        private readonly ServiceRepository $serviceRepository,
        private readonly StaffRepository $staffRepository,
        private readonly ClientRepository $clientRepository,
        private readonly LocationRepository $locationRepository,
        private readonly UserRepository $userRepository,
        private readonly ?NotificationRepository $notificationRepo = null,
        private readonly ?ComputeAvailability $computeAvailability = null,
        private readonly ?BookingAuditRepository $auditRepository = null,
        private readonly ?LocationClosureRepository $locationClosureRepository = null,
    ) {}

    /**
     * Create a new booking with conflict detection.
     * Idempotent: returns existing booking if idempotency_key matches.
     * 
     * @param int $userId The authenticated user ID
     * @param int $locationId The location ID (from path/query)
     * @param int $businessId The business ID (derived from location)
     * @param array $data Booking payload {service_ids, staff_id?, start_time, notes?}
     * @param string|null $idempotencyKey Idempotency key from header
     * @return array Created booking data
     * @throws BookingException
     */
    public function execute(
        int $userId,
        int $locationId,
        int $businessId,
        array $data,
        ?string $idempotencyKey = null
    ): array {
        // Check idempotency first (outside transaction)
        if ($idempotencyKey !== null) {
            $existingBooking = $this->bookingRepository->findByIdempotencyKey($businessId, $idempotencyKey);
            if ($existingBooking !== null) {
                return $this->formatBookingResponse($existingBooking);
            }
        }

        $notes = $data['notes'] ?? null;
        $allowPast = $data['allow_past'] ?? false;
        $skipConflictCheck = $data['skip_conflict_check'] ?? false;
        $requestedClientId = $data['client_id'] ?? null;

        // Check if using new "items" format or legacy "service_ids" format
        if (isset($data['items']) && is_array($data['items']) && !empty($data['items'])) {
            return $this->executeWithItems(
                $userId, $locationId, $businessId, $data['items'],
                $notes, $allowPast, $skipConflictCheck, $requestedClientId, $idempotencyKey
            );
        }

        // Legacy format: service_ids with single staff_id
        $serviceIds = $data['service_ids'] ?? [];
        $staffId = $data['staff_id'] ?? null;
        $startTimeString = $data['start_time'] ?? null;

        if (empty($serviceIds)) {
            throw BookingException::invalidService([]);
        }

        if ($startTimeString === null) {
            throw BookingException::invalidTime('start_time is required');
        }

        // Parse start time
        try {
            $startTime = new DateTimeImmutable($startTimeString, new DateTimeZone('UTC'));
        } catch (\Exception $e) {
            throw BookingException::invalidTime('Invalid ISO8601 format');
        }

        // Validate start time is in the future (skip for operators creating past appointments)
        if (!$allowPast) {
            $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
            if ($startTime <= $now) {
                throw BookingException::invalidTime('start_time must be in the future');
            }
        }

        // Validate location
        $location = $this->locationRepository->findById($locationId);
        if ($location === null || (int) $location['business_id'] !== $businessId) {
            throw BookingException::invalidLocation($locationId);
        }

        // Check if location is closed on this date
        if ($this->locationClosureRepository !== null) {
            $dateStr = $startTime->format('Y-m-d');
            $closure = $this->locationClosureRepository->findClosureForDate($locationId, $dateStr);
            if ($closure !== null) {
                throw BookingException::businessClosed($dateStr, $closure['reason'] ?? null);
            }
        }

        // Validate services belong to business at this location
        if (!$this->serviceRepository->allBelongToBusiness($serviceIds, $locationId, $businessId)) {
            throw BookingException::invalidService($serviceIds);
        }

        // Get services with variants (duration/price/variant_id from service_variants)
        $services = $this->serviceRepository->findByIds($serviceIds, $locationId, $businessId);
        
        if (count($services) !== count($serviceIds)) {
            throw BookingException::invalidService($serviceIds);
        }

        // Calculate total duration needed (including processing_time and blocked_time)
        $totalDuration = 0;
        foreach ($services as $service) {
            $totalDuration += (int) $service['duration_minutes']
                + (int) ($service['processing_time'] ?? 0)
                + (int) ($service['blocked_time'] ?? 0);
        }

        // If no staff specified, find first available staff for this slot
        if ($staffId === null) {
            // Use ComputeAvailability to find staff with real availability
            // (includes planning, exceptions, time blocks, and existing bookings)
            if ($this->computeAvailability !== null) {
                $dateStr = $startTime->format('Y-m-d');
                $availabilityResult = $this->computeAvailability->execute(
                    $businessId,
                    $locationId,
                    null, // any staff
                    $totalDuration,
                    $dateStr,
                    $serviceIds,
                    true // keepStaffInfo = true per ottenere staff_id
                );
                
                $slots = $availabilityResult['slots'] ?? [];
                $requestedStartFormatted = $startTime->format('Y-m-d H:i');
                
                // DEBUG: Log to file
                $debugLog = __DIR__ . '/../../../logs/debug.log';
                file_put_contents($debugLog, date('Y-m-d H:i:s') . " [CreateBooking] Looking for slot at: {$requestedStartFormatted}\n", FILE_APPEND);
                file_put_contents($debugLog, date('Y-m-d H:i:s') . " [CreateBooking] Available slots count: " . count($slots) . "\n", FILE_APPEND);
                foreach ($slots as $idx => $slot) {
                    $slotStart = new DateTimeImmutable($slot['start_time']);
                    $staffIdInSlot = $slot['staff_id'] ?? 'N/A';
                    file_put_contents($debugLog, date('Y-m-d H:i:s') . " [CreateBooking] Slot {$idx}: {$slotStart->format('Y-m-d H:i')} staff_id={$staffIdInSlot}\n", FILE_APPEND);
                }
                
                // Find a staff that has this exact slot available
                $foundStaff = null;
                foreach ($slots as $slot) {
                    // Compare start times (normalize to same format)
                    $slotStart = new DateTimeImmutable($slot['start_time']);
                    if ($slotStart->format('Y-m-d H:i') === $requestedStartFormatted) {
                        if (isset($slot['staff_id'])) {
                            $foundStaff = ['id' => $slot['staff_id']];
                            file_put_contents($debugLog, date('Y-m-d H:i:s') . " [CreateBooking] Found matching slot with staff_id: {$slot['staff_id']}\n", FILE_APPEND);
                            break;
                        }
                    }
                }
                
                if ($foundStaff === null) {
                    file_put_contents($debugLog, date('Y-m-d H:i:s') . " [CreateBooking] No staff found for slot {$requestedStartFormatted}\n", FILE_APPEND);
                    throw BookingException::slotConflict(['message' => 'No staff available for this time slot']);
                }
                
                $staffId = (int) $foundStaff['id'];
            } else {
                // Fallback: use basic check (legacy behavior)
                $availableStaff = $this->staffRepository->findByLocationId($locationId, $businessId);
                if (empty($availableStaff)) {
                    throw BookingException::invalidStaff(0);
                }
                
                // Filter staff that can perform ALL requested services
                $eligibleStaff = array_filter($availableStaff, function($staff) use ($serviceIds, $locationId, $businessId) {
                    return $this->staffRepository->canPerformServices((int) $staff['id'], $serviceIds, $locationId, $businessId);
                });
                
                if (empty($eligibleStaff)) {
                    throw BookingException::invalidStaff(0);
                }
                
                // Find first staff without conflicts for this time slot
                $slotEndTime = $startTime->modify("+{$totalDuration} minutes");
                $foundStaff = null;
                
                foreach ($eligibleStaff as $staff) {
                    $conflicts = $this->bookingRepository->checkConflicts(
                        (int) $staff['id'],
                        $locationId,
                        $startTime,
                        $slotEndTime
                    );
                    
                    if (empty($conflicts)) {
                        $foundStaff = $staff;
                        break;
                    }
                }
                
                if ($foundStaff === null) {
                    throw BookingException::slotConflict(['message' => 'No staff available for this time slot']);
                }
                
                $staffId = (int) $foundStaff['id'];
            }
        }

        // Validate staff belongs to location
        if (!$this->staffRepository->belongsToLocation($staffId, $locationId)) {
            throw BookingException::invalidStaff($staffId);
        }

        // Validate staff can perform ALL requested services
        if (!$this->staffRepository->canPerformServices($staffId, $serviceIds, $locationId, $businessId)) {
            throw BookingException::invalidStaff($staffId);
        }

        // Determine client for this booking
        $clientId = null;
        $clientName = null;
        $isOperatorBooking = $allowPast || $skipConflictCheck;

        if ($requestedClientId !== null) {
            // Specific client_id was passed - validate it belongs to the business
            $client = $this->clientRepository->findById((int) $requestedClientId);
            if ($client !== null && (int) $client['business_id'] === $businessId) {
                $clientId = (int) $client['id'];
                $clientName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));
            }
        } elseif (!$isOperatorBooking) {
            // No client_id and NOT an operator booking (i.e., customer booking online)
            // Auto-create/find client for the authenticated user
            $client = $this->clientRepository->findOrCreateForUser($userId, $businessId);
            $clientId = (int) $client['id'];
            $user = $this->userRepository->findById($userId);
            $clientName = $user ? trim($user['first_name'] . ' ' . $user['last_name']) : null;
        }
        // else: operator booking without client_id = walk-in (client_id stays null)

        // Start transaction for conflict detection
        $this->db->beginTransaction();

        try {
            // Calculate total duration and check conflicts for each item
            $currentTime = $startTime;
            $itemsToCreate = [];

            foreach ($services as $service) {
                // Display duration (what appears in gestionale) - only service time
                $displayDuration = (int) $service['duration_minutes'];
                // Blocked duration (for conflict check and next service start) - includes processing/blocked time
                $blockedDuration = $displayDuration
                    + (int) ($service['processing_time'] ?? 0)
                    + (int) ($service['blocked_time'] ?? 0);
                
                $displayEndTime = $currentTime->modify("+{$displayDuration} minutes");
                $blockedEndTime = $currentTime->modify("+{$blockedDuration} minutes");

                // Check for conflicts using SELECT FOR UPDATE (skip for operators)
                // Use blockedEndTime to ensure processing/blocked time is reserved
                if (!$skipConflictCheck) {
                    $conflicts = $this->bookingRepository->checkConflicts(
                        $staffId,
                        $locationId,
                        $currentTime,
                        $blockedEndTime
                    );

                    if (!empty($conflicts)) {
                        $this->db->rollBack();
                        throw BookingException::slotConflict($conflicts);
                    }
                }

                $itemsToCreate[] = [
                    'service_id' => (int) $service['id'],
                    'service_variant_id' => (int) $service['service_variant_id'],
                    'staff_id' => $staffId,
                    'start_time' => $currentTime->format('Y-m-d H:i:s'),
                    'end_time' => $displayEndTime->format('Y-m-d H:i:s'), // Display duration only
                    'price' => (float) $service['price'],
                    'service_name_snapshot' => $service['name'],
                    'client_name_snapshot' => $clientName,
                ];

                // Next service starts after blocked time (not display time)
                $currentTime = $blockedEndTime;
            }

            // Create booking (container)
            $bookingId = $this->bookingRepository->create([
                'business_id' => $businessId,
                'location_id' => $locationId,
                'client_id' => $clientId,
                'client_name' => $clientName,
                'user_id' => $userId,
                'notes' => $notes,
                'status' => 'confirmed',
                'source' => 'manual',
                'idempotency_key' => $idempotencyKey,
            ]);

            // Create booking items
            foreach ($itemsToCreate as $item) {
                $item['location_id'] = $locationId;
                $this->bookingRepository->addBookingItem($bookingId, $item);
            }

            $this->db->commit();

            // Fetch and return created booking
            $booking = $this->bookingRepository->findById($bookingId);
            
            // Create audit event for booking_created
            $this->createBookingCreatedEvent($bookingId, 'staff', $userId, $booking);
            
            // Queue notifications (async, non-blocking)
            $this->queueNotifications($booking, $location, $userId);
            
            return $this->formatBookingResponse($booking);

        } catch (BookingException $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        } catch (\Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }

    /**
     * Execute booking creation with new "items" format (each item has its own staff_id and start_time).
     */
    private function executeWithItems(
        int $userId,
        int $locationId,
        int $businessId,
        array $items,
        ?string $notes,
        bool $allowPast,
        bool $skipConflictCheck,
        ?int $requestedClientId,
        ?string $idempotencyKey
    ): array {
        // Validate location
        $location = $this->locationRepository->findById($locationId);
        if ($location === null || (int) $location['business_id'] !== $businessId) {
            throw BookingException::invalidLocation($locationId);
        }

        // Collect all service IDs for validation
        $serviceIds = array_map(fn($item) => (int) $item['service_id'], $items);

        // Check if location is closed on booking date(s)
        if ($this->locationClosureRepository !== null && !empty($items)) {
            // Check first item's start_time date
            $firstItemTime = $items[0]['start_time'] ?? null;
            if ($firstItemTime !== null) {
                try {
                    $firstDate = (new DateTimeImmutable($firstItemTime))->format('Y-m-d');
                    $closure = $this->locationClosureRepository->findClosureForDate($locationId, $firstDate);
                    if ($closure !== null) {
                        throw BookingException::businessClosed($firstDate, $closure['reason'] ?? null);
                    }
                } catch (\Exception $e) {
                    if ($e instanceof BookingException) {
                        throw $e;
                    }
                    // Ignore date parsing errors, let other validations handle it
                }
            }
        }

        // Validate all services belong to location
        if (!$this->serviceRepository->allBelongToBusiness($serviceIds, $locationId, $businessId)) {
            throw BookingException::invalidService($serviceIds);
        }

        // Get all services
        $services = $this->serviceRepository->findByIds($serviceIds, $locationId, $businessId);
        $servicesById = [];
        foreach ($services as $svc) {
            $servicesById[(int) $svc['id']] = $svc;
        }

        // Determine client
        $clientId = null;
        $clientName = null;
        $isOperatorBooking = $allowPast || $skipConflictCheck;

        if ($requestedClientId !== null) {
            $client = $this->clientRepository->findById($requestedClientId);
            if ($client !== null && (int) $client['business_id'] === $businessId) {
                $clientId = (int) $client['id'];
                $clientName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));
            }
        } elseif (!$isOperatorBooking) {
            $client = $this->clientRepository->findOrCreateForUser($userId, $businessId);
            $clientId = (int) $client['id'];
            $user = $this->userRepository->findById($userId);
            $clientName = $user ? trim($user['first_name'] . ' ' . $user['last_name']) : null;
        }

        // Start transaction
        $this->db->beginTransaction();

        try {
            $itemsToCreate = [];

            foreach ($items as $item) {
                $serviceId = (int) $item['service_id'];
                $staffId = (int) $item['staff_id'];
                $startTimeString = $item['start_time'];

                // Parse start time
                try {
                    $startTime = new DateTimeImmutable($startTimeString, new DateTimeZone('UTC'));
                } catch (\Exception $e) {
                    throw BookingException::invalidTime("Invalid ISO8601 format for service $serviceId");
                }

                // Validate start time in the future
                if (!$allowPast) {
                    $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
                    if ($startTime <= $now) {
                        throw BookingException::invalidTime('start_time must be in the future');
                    }
                }

                // Validate staff belongs to location
                if (!$this->staffRepository->belongsToLocation($staffId, $locationId)) {
                    throw BookingException::invalidStaff($staffId);
                }

                // Validate staff can perform this service
                if (!$this->staffRepository->canPerformServices($staffId, [$serviceId], $locationId, $businessId)) {
                    throw BookingException::invalidStaff($staffId);
                }

                // Get service data
                if (!isset($servicesById[$serviceId])) {
                    throw BookingException::invalidService([$serviceId]);
                }
                $service = $servicesById[$serviceId];

                // Use override values if provided, otherwise use service defaults
                $duration = isset($item['duration_minutes']) ? (int) $item['duration_minutes'] : (int) $service['duration_minutes'];
                $variantId = isset($item['service_variant_id']) ? (int) $item['service_variant_id'] : (int) $service['service_variant_id'];
                $price = isset($item['price']) ? (float) $item['price'] : (float) $service['price'];
                $blockedExtra = isset($item['blocked_extra_minutes']) ? (int) $item['blocked_extra_minutes'] : 0;
                $processingExtra = isset($item['processing_extra_minutes']) ? (int) $item['processing_extra_minutes'] : 0;

                $endTime = $startTime->modify("+{$duration} minutes");

                // Conflict check
                if (!$skipConflictCheck) {
                    $conflicts = $this->bookingRepository->checkConflicts($staffId, $locationId, $startTime, $endTime);
                    if (!empty($conflicts)) {
                        $this->db->rollBack();
                        throw BookingException::slotConflict($conflicts);
                    }
                }

                $itemsToCreate[] = [
                    'service_id' => $serviceId,
                    'service_variant_id' => $variantId,
                    'staff_id' => $staffId,
                    'start_time' => $startTime->format('Y-m-d H:i:s'),
                    'end_time' => $endTime->format('Y-m-d H:i:s'),
                    'price' => $price,
                    'extra_blocked_minutes' => $blockedExtra,
                    'extra_processing_minutes' => $processingExtra,
                    'service_name_snapshot' => $service['name'],
                    'client_name_snapshot' => $clientName,
                ];
            }

            // Create booking (container)
            $bookingId = $this->bookingRepository->create([
                'business_id' => $businessId,
                'location_id' => $locationId,
                'client_id' => $clientId,
                'client_name' => $clientName,
                'user_id' => $userId,
                'notes' => $notes,
                'status' => 'confirmed',
                'source' => 'manual',
                'idempotency_key' => $idempotencyKey,
            ]);

            // Create booking items
            foreach ($itemsToCreate as $itemData) {
                $itemData['location_id'] = $locationId;
                $this->bookingRepository->addBookingItem($bookingId, $itemData);
            }

            $this->db->commit();

            $booking = $this->bookingRepository->findById($bookingId);
            
            // Create audit event for booking_created
            $this->createBookingCreatedEvent($bookingId, 'staff', $userId, $booking);
            
            $this->queueNotifications($booking, $location, $userId);

            return $this->formatBookingResponse($booking);

        } catch (BookingException $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        } catch (\Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }

    private function formatBookingResponse(array $booking): array
    {
        return [
            'id' => (int) $booking['id'],
            'business_id' => (int) $booking['business_id'],
            'location_id' => (int) $booking['location_id'],
            'client_id' => $booking['client_id'] !== null ? (int) $booking['client_id'] : null,
            'user_id' => $booking['user_id'] !== null ? (int) $booking['user_id'] : null,
            'client_name' => $booking['client_name'] ?? null,
            'status' => $booking['status'],
            'source' => $booking['source'] ?? 'online',
            'notes' => $booking['notes'],
            'total_price' => (float) ($booking['total_price'] ?? 0),
            'total_duration_minutes' => (int) ($booking['total_duration_minutes'] ?? 0),
            'created_at' => $booking['created_at'],
            'updated_at' => $booking['updated_at'] ?? $booking['created_at'],
            'items' => array_map(fn($item) => [
                'id' => (int) $item['id'],
                'booking_id' => (int) $booking['id'],
                'service_id' => (int) $item['service_id'],
                'service_variant_id' => isset($item['service_variant_id']) ? (int) $item['service_variant_id'] : null,
                'service_name' => $item['service_name'] ?? $item['service_name_snapshot'],
                'staff_id' => (int) $item['staff_id'],
                'staff_display_name' => $item['staff_display_name'] ?? null,
                'location_id' => (int) $item['location_id'],
                'start_time' => $item['start_time'],
                'end_time' => $item['end_time'],
                'price' => (float) ($item['price'] ?? 0),
                'duration_minutes' => (int) ($item['duration_minutes'] ?? 0),
            ], $booking['items'] ?? []),
        ];
    }

    /**
     * Queue email notifications for the booking (non-blocking).
     */
    /**
     * Queue notifications for booking - sends to CLIENT (not operator).
     * Used when operator creates booking from gestionale.
     */
    private function queueNotifications(array $booking, array $location, int $userId): void
    {
        // Get client_id from booking - notifications go to CLIENT, not operator
        $clientId = $booking['client_id'] ?? null;
        if ($clientId === null) {
            error_log("Cannot queue notifications for booking {$booking['id']}: no client_id");
            return;
        }
        
        // Use the same method as customer bookings
        $this->queueNotificationsForClient($booking, $location, (int) $clientId);
    }

    /**
     * Create a new booking from a customer (client) authentication.
     * This method uses client_id directly instead of finding/creating from user_id.
     * 
     * @param int $clientId The authenticated client ID (from client JWT)
     * @param int $locationId The location ID
     * @param int $businessId The business ID
     * @param array $data Booking payload {service_ids, staff_id?, start_time, notes?}
     * @param string|null $idempotencyKey Idempotency key from header
     * @return array Created booking data
     * @throws BookingException
     */
    public function executeForCustomer(
        int $clientId,
        int $locationId,
        int $businessId,
        array $data,
        ?string $idempotencyKey = null
    ): array {
        // Check idempotency first (outside transaction)
        if ($idempotencyKey !== null) {
            $existingBooking = $this->bookingRepository->findByIdempotencyKey($businessId, $idempotencyKey);
            if ($existingBooking !== null) {
                return $this->formatBookingResponse($existingBooking);
            }
        }

        $notes = $data['notes'] ?? null;

        // Check if using new "items" format or legacy "service_ids" format
        if (isset($data['items']) && is_array($data['items']) && !empty($data['items'])) {
            return $this->executeForCustomerWithItems(
                $clientId, $locationId, $businessId, $data['items'],
                $notes, $idempotencyKey
            );
        }

        // Legacy format: service_ids with single staff_id
        $serviceIds = $data['service_ids'] ?? [];
        $staffId = $data['staff_id'] ?? null;
        $startTimeString = $data['start_time'] ?? null;

        if (empty($serviceIds)) {
            throw BookingException::invalidService([]);
        }

        if ($startTimeString === null) {
            throw BookingException::invalidTime('start_time is required');
        }

        // Validate location FIRST (need timezone for time validation)
        $location = $this->locationRepository->findById($locationId);
        if ($location === null || (int) $location['business_id'] !== $businessId) {
            throw BookingException::invalidLocation($locationId);
        }

        $locationTimezone = new DateTimeZone($location['timezone'] ?? 'Europe/Rome');

        // Parse start time in location timezone (frontend sends naive ISO local time)
        try {
            $startTimeLocal = new DateTimeImmutable($startTimeString, $locationTimezone);
        } catch (\Exception $e) {
            throw BookingException::invalidTime('Invalid ISO8601 format');
        }

        // Check if location is closed on this date
        if ($this->locationClosureRepository !== null) {
            $dateStr = $startTimeLocal->format('Y-m-d');
            $closure = $this->locationClosureRepository->findClosureForDate($locationId, $dateStr);
            if ($closure !== null) {
                throw BookingException::businessClosed($dateStr, $closure['reason'] ?? null);
            }
        }

        // Use local time for storage (database stores location time, not UTC)
        $startTime = $startTimeLocal;

        // DEBUG LOG
        $now = new DateTimeImmutable('now', $locationTimezone);
        file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " executeForCustomer: now_local={$now->format('Y-m-d H:i:s')} start_time_raw={$startTimeString} start_time_local={$startTimeLocal->format('Y-m-d H:i:s')} tz={$location['timezone']}\n", FILE_APPEND);

        // Validate start time is in the future (customers cannot book in the past)
        if ($startTimeLocal <= $now) {
            throw BookingException::invalidTime('start_time must be in the future');
        }

        // Validate client belongs to business
        $client = $this->clientRepository->findById($clientId);
        if ($client === null || (int) $client['business_id'] !== $businessId) {
            throw BookingException::invalidClient($clientId);
        }
        $clientName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));

        // Validate services belong to business at this location
        if (!$this->serviceRepository->allBelongToBusiness($serviceIds, $locationId, $businessId)) {
            throw BookingException::invalidService($serviceIds);
        }

        // Get services with variants
        $services = $this->serviceRepository->findByIds($serviceIds, $locationId, $businessId);
        
        if (count($services) !== count($serviceIds)) {
            throw BookingException::invalidService($serviceIds);
        }

        // Calculate total duration (including processing_time and blocked_time)
        $totalDuration = 0;
        foreach ($services as $service) {
            $totalDuration += (int) $service['duration_minutes']
                + (int) ($service['processing_time'] ?? 0)
                + (int) ($service['blocked_time'] ?? 0);
        }

        // If no staff specified, find available staff using ComputeAvailability
        if ($staffId === null) {
            $debugLog = __DIR__ . '/../../../logs/debug.log';
            
            if ($this->computeAvailability !== null) {
                $dateStr = $startTimeLocal->format('Y-m-d');
                $availabilityResult = $this->computeAvailability->execute(
                    $businessId,
                    $locationId,
                    null, // any staff
                    $totalDuration,
                    $dateStr,
                    $serviceIds,
                    true // keepStaffInfo = true per ottenere staff_id
                );
                
                $slots = $availabilityResult['slots'] ?? [];
                $requestedStartFormatted = $startTimeLocal->format('Y-m-d H:i');
                
                // DEBUG
                file_put_contents($debugLog, date('Y-m-d H:i:s') . " [executeForCustomer] Looking for slot at: {$requestedStartFormatted}\n", FILE_APPEND);
                file_put_contents($debugLog, date('Y-m-d H:i:s') . " [executeForCustomer] Available slots count: " . count($slots) . "\n", FILE_APPEND);
                foreach (array_slice($slots, 0, 10) as $idx => $slot) {
                    $slotStart = new DateTimeImmutable($slot['start_time']);
                    $staffIdInSlot = $slot['staff_id'] ?? 'N/A';
                    file_put_contents($debugLog, date('Y-m-d H:i:s') . " [executeForCustomer] Slot {$idx}: {$slotStart->format('Y-m-d H:i')} staff_id={$staffIdInSlot}\n", FILE_APPEND);
                }
                
                // Find staff that has this exact slot available
                $foundStaff = null;
                foreach ($slots as $slot) {
                    $slotStart = new DateTimeImmutable($slot['start_time']);
                    if ($slotStart->format('Y-m-d H:i') === $requestedStartFormatted) {
                        if (isset($slot['staff_id'])) {
                            $foundStaff = ['id' => $slot['staff_id']];
                            file_put_contents($debugLog, date('Y-m-d H:i:s') . " [executeForCustomer] Found matching slot with staff_id: {$slot['staff_id']}\n", FILE_APPEND);
                            break;
                        }
                    }
                }
                
                if ($foundStaff === null) {
                    file_put_contents($debugLog, date('Y-m-d H:i:s') . " [executeForCustomer] No staff found for slot {$requestedStartFormatted}\n", FILE_APPEND);
                    throw BookingException::slotConflict(['message' => 'No staff available for this time slot']);
                }
                
                $staffId = (int) $foundStaff['id'];
            } else {
                // Fallback: legacy behavior
                $availableStaff = $this->staffRepository->findByLocationId($locationId, $businessId);
                if (empty($availableStaff)) {
                    throw BookingException::invalidStaff(0);
                }
                $staffId = (int) $availableStaff[0]['id'];
            }
        }

        // Validate staff belongs to location
        if (!$this->staffRepository->belongsToLocation($staffId, $locationId)) {
            throw BookingException::invalidStaff($staffId);
        }

        // Validate staff can perform ALL requested services
        if (!$this->staffRepository->canPerformServices($staffId, $serviceIds, $locationId, $businessId)) {
            throw BookingException::invalidStaff($staffId);
        }

        // Start transaction for conflict detection
        $this->db->beginTransaction();

        try {
            $currentTime = $startTime;
            $itemsToCreate = [];

            foreach ($services as $service) {
                // Display duration (what appears in gestionale) - only service time
                $displayDuration = (int) $service['duration_minutes'];
                // Blocked duration (for conflict check and next service start) - includes processing/blocked time
                $blockedDuration = $displayDuration
                    + (int) ($service['processing_time'] ?? 0)
                    + (int) ($service['blocked_time'] ?? 0);
                
                $displayEndTime = $currentTime->modify("+{$displayDuration} minutes");
                $blockedEndTime = $currentTime->modify("+{$blockedDuration} minutes");

                // Check for conflicts (customers ALWAYS check conflicts)
                // Use blockedEndTime to ensure processing/blocked time is reserved
                $conflicts = $this->bookingRepository->checkConflicts(
                    $staffId,
                    $locationId,
                    $currentTime,
                    $blockedEndTime
                );

                if (!empty($conflicts)) {
                    $this->db->rollBack();
                    throw BookingException::slotConflict($conflicts);
                }

                $itemsToCreate[] = [
                    'service_id' => (int) $service['id'],
                    'service_variant_id' => (int) $service['service_variant_id'],
                    'staff_id' => $staffId,
                    'start_time' => $currentTime->format('Y-m-d H:i:s'),
                    'end_time' => $displayEndTime->format('Y-m-d H:i:s'), // Display duration only
                    'price' => (float) $service['price'],
                    'service_name_snapshot' => $service['name'],
                    'client_name_snapshot' => $clientName,
                ];

                // Next service starts after blocked time (not display time)
                $currentTime = $blockedEndTime;
            }

            // Create booking (container) - note: user_id is NULL for customer bookings
            $bookingId = $this->bookingRepository->create([
                'business_id' => $businessId,
                'location_id' => $locationId,
                'client_id' => $clientId,
                'client_name' => $clientName,
                'user_id' => null, // Customer booking, no operator user
                'notes' => $notes,
                'status' => 'confirmed',
                'source' => 'online',
                'idempotency_key' => $idempotencyKey,
            ]);

            // Create booking items
            foreach ($itemsToCreate as $item) {
                $item['location_id'] = $locationId;
                $this->bookingRepository->addBookingItem($bookingId, $item);
            }

            $this->db->commit();

            // Fetch and return created booking
            $booking = $this->bookingRepository->findById($bookingId);
            
            // Create audit event for booking_created (by customer)
            $this->createBookingCreatedEvent($bookingId, 'customer', $clientId, $booking);
            
            // Queue notifications
            $this->queueNotificationsForClient($booking, $location, $clientId);
            
            return $this->formatBookingResponse($booking);

        } catch (BookingException $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        } catch (\Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }

    /**
     * Execute customer booking with items format (per-service staff and start_time).
     */
    private function executeForCustomerWithItems(
        int $clientId,
        int $locationId,
        int $businessId,
        array $items,
        ?string $notes,
        ?string $idempotencyKey
    ): array {
        // Validate location
        $location = $this->locationRepository->findById($locationId);
        if ($location === null || (int) $location['business_id'] !== $businessId) {
            throw BookingException::invalidLocation($locationId);
        }

        // Check if location is closed on booking date(s)
        if ($this->locationClosureRepository !== null && !empty($items)) {
            $firstItemTime = $items[0]['start_time'] ?? null;
            if ($firstItemTime !== null) {
                try {
                    $firstDate = (new DateTimeImmutable($firstItemTime))->format('Y-m-d');
                    $closure = $this->locationClosureRepository->findClosureForDate($locationId, $firstDate);
                    if ($closure !== null) {
                        throw BookingException::businessClosed($firstDate, $closure['reason'] ?? null);
                    }
                } catch (\Exception $e) {
                    if ($e instanceof BookingException) {
                        throw $e;
                    }
                }
            }
        }

        // Validate client belongs to business
        $client = $this->clientRepository->findById($clientId);
        if ($client === null || (int) $client['business_id'] !== $businessId) {
            throw BookingException::invalidClient($clientId);
        }
        $clientName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));

        // Get location timezone for time comparisons
        $locationTimezone = new DateTimeZone($location['timezone'] ?? 'Europe/Rome');

        // Validate all times are in the future
        // Frontend sends local time (business timezone), compare with "now" in same timezone
        $nowLocal = new DateTimeImmutable('now', $locationTimezone);
        foreach ($items as $item) {
            // Parse start_time as local time (frontend sends naive ISO without timezone)
            $itemStartTimeLocal = new DateTimeImmutable($item['start_time'], $locationTimezone);
            
            // DEBUG LOG
            file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " executeForCustomerWithItems: now_local={$nowLocal->format('Y-m-d H:i:s')} start_time_raw={$item['start_time']} start_time_local={$itemStartTimeLocal->format('Y-m-d H:i:s')} tz={$location['timezone']}\n", FILE_APPEND);
            
            if ($itemStartTimeLocal <= $nowLocal) {
                throw BookingException::invalidTime('All start times must be in the future');
            }
        }

        // Collect service IDs
        $serviceIds = array_map(fn($item) => (int) $item['service_id'], $items);

        // Validate services belong to business at this location
        if (!$this->serviceRepository->allBelongToBusiness($serviceIds, $locationId, $businessId)) {
            throw BookingException::invalidService($serviceIds);
        }

        // Start transaction for conflict detection
        $this->db->beginTransaction();

        try {
            $itemsToCreate = [];

            foreach ($items as $item) {
                $serviceId = (int) $item['service_id'];
                $staffId = (int) $item['staff_id'];
                // Frontend sends local time (naive ISO), parse in location timezone
                // Database stores location time, not UTC
                $startTime = new DateTimeImmutable($item['start_time'], $locationTimezone);

                // Validate staff belongs to location
                if (!$this->staffRepository->belongsToLocation($staffId, $locationId)) {
                    throw BookingException::invalidStaff($staffId);
                }

                // Validate staff can perform this service
                if (!$this->staffRepository->canPerformServices($staffId, [$serviceId], $locationId, $businessId)) {
                    throw BookingException::invalidStaff($staffId);
                }

                // Get service with variant
                $services = $this->serviceRepository->findByIds([$serviceId], $locationId, $businessId);
                if (empty($services)) {
                    throw BookingException::invalidService([$serviceId]);
                }
                $service = $services[0];

                // Display duration (what appears in gestionale) - only service time
                $displayDuration = (int) $service['duration_minutes'];
                // Blocked duration (for conflict check) - includes processing/blocked time
                $blockedDuration = $displayDuration
                    + (int) ($service['processing_time'] ?? 0)
                    + (int) ($service['blocked_time'] ?? 0);
                
                $displayEndTime = $startTime->modify("+{$displayDuration} minutes");
                $blockedEndTime = $startTime->modify("+{$blockedDuration} minutes");

                // Check for conflicts (customers ALWAYS check conflicts)
                // Use blockedEndTime to ensure processing/blocked time is reserved
                $conflicts = $this->bookingRepository->checkConflicts(
                    $staffId,
                    $locationId,
                    $startTime,
                    $blockedEndTime
                );

                if (!empty($conflicts)) {
                    $this->db->rollBack();
                    throw BookingException::slotConflict($conflicts);
                }

                $itemsToCreate[] = [
                    'service_id' => $serviceId,
                    'service_variant_id' => (int) $service['service_variant_id'],
                    'staff_id' => $staffId,
                    'start_time' => $startTime->format('Y-m-d H:i:s'),
                    'end_time' => $displayEndTime->format('Y-m-d H:i:s'), // Display duration only
                    'price' => (float) $service['price'],
                    'service_name_snapshot' => $service['name'],
                    'client_name_snapshot' => $clientName,
                ];
            }

            // Create booking (container)
            $source = $staffId === null ? 'online' : 'onlinestaff';
            $bookingId = $this->bookingRepository->create([
                'business_id' => $businessId,
                'location_id' => $locationId,
                'client_id' => $clientId,
                'client_name' => $clientName,
                'user_id' => null, // Customer booking, no operator user
                'notes' => $notes,
                'status' => 'confirmed',
                'source' => $source,
                'idempotency_key' => $idempotencyKey,
            ]);

            // Create booking items
            foreach ($itemsToCreate as $itemData) {
                $itemData['location_id'] = $locationId;
                $this->bookingRepository->addBookingItem($bookingId, $itemData);
            }

            $this->db->commit();

            // Fetch and return created booking
            $booking = $this->bookingRepository->findById($bookingId);
            
            // Create audit event for booking_created (by customer)
            $this->createBookingCreatedEvent($bookingId, 'customer', $clientId, $booking);

            // Queue notifications
            $this->queueNotificationsForClient($booking, $location, $clientId);

            return $this->formatBookingResponse($booking);

        } catch (BookingException $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        } catch (\Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }
    }

    /**
     * Queue email notifications for customer booking.
     */
    private function queueNotificationsForClient(array $booking, array $location, int $clientId): void
    {
        file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " queueNotificationsForClient: notificationRepo=" . ($this->notificationRepo === null ? 'NULL' : 'OK') . " booking_id={$booking['id']} client_id={$clientId}\n", FILE_APPEND);
        
        if ($this->notificationRepo === null) {
            return;
        }

        try {
            $timezoneName = $location['timezone'] ?? 'Europe/Rome';
            $locationTimezone = new DateTimeZone($timezoneName);
            $startTimeValue = $booking['items'][0]['start_time'] ?? null;
            if ($startTimeValue !== null) {
                $startTime = new DateTimeImmutable($startTimeValue, $locationTimezone);
                $nowLocal = new DateTimeImmutable('now', $locationTimezone);
                if ($startTime <= $nowLocal) {
                    return;
                }
            }

            // Get client email
            $client = $this->clientRepository->findById($clientId);
            if ($client === null || empty($client['email'])) {
                return;
            }
            $clientName = trim(
                ($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? '')
            );

            $senderEmail = $location['email'] ?? $location['business_email'] ?? null;
            $senderName = $location['email'] ? $location['name'] : ($location['business_email'] ? $location['business_name'] : null);
            
            $notificationData = [
                'booking_id' => (int) $booking['id'],
                'client_id' => $clientId,
                'client_email' => $client['email'],
                'client_name' => $clientName,
                'business_id' => (int) $booking['business_id'],
                'business_name' => $location['business_name'] ?? '',
                'business_email' => $location['business_email'] ?? '',
                'location_name' => $location['name'] ?? '',
                'location_email' => $location['email'] ?? '',
                'location_address' => $location['address'] ?? '',
                'location_city' => $location['city'] ?? '',
                'location_phone' => $location['phone'] ?? '',
                'location_timezone' => $location['timezone'] ?? 'Europe/Rome',
                'sender_email' => $senderEmail,
                'sender_name' => $senderName,
                'start_time' => $booking['items'][0]['start_time'] ?? $booking['created_at'],
                'end_time' => $booking['items'][count($booking['items']) - 1]['end_time'] ?? null,
                'services' => implode(', ', array_column($booking['items'] ?? [], 'service_name')),
                'total_price' => $booking['total_price'] ?? 0,
                'cancellation_hours' => $location['cancellation_hours'] ?? 24,
                'manage_url' => ($_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it') . '/' . ($location['business_slug'] ?? '') . '/my-bookings',
                'booking_url' => ($_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it') . '/' . ($location['business_slug'] ?? '') . '/booking',
                'locale' => $_ENV['DEFAULT_LOCALE'] ?? 'it',
            ];

            $confirmationUseCase = new QueueBookingConfirmation($this->db, $this->notificationRepo);
            $confirmResult = $confirmationUseCase->execute($notificationData);
            
            file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " queueNotificationsForClient: confirmation result=$confirmResult\n", FILE_APPEND);

            $reminderUseCase = new QueueBookingReminder($this->db, $this->notificationRepo);
            $reminderResult = $reminderUseCase->execute($notificationData);
            
            file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " queueNotificationsForClient: reminder result=$reminderResult\n", FILE_APPEND);
        } catch (\Throwable $e) {
            file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " queueNotificationsForClient ERROR: " . $e->getMessage() . "\n", FILE_APPEND);
        }
    }

    /**
     * Create an audit event for booking_created.
     *
     * @param int $bookingId The created booking ID
     * @param string $actorType 'customer' or 'staff'
     * @param int|null $actorId Client ID for customer, User ID for staff
     * @param array $booking The booking data
     */
    private function createBookingCreatedEvent(int $bookingId, string $actorType, ?int $actorId, array $booking): void
    {
        if ($this->auditRepository === null) {
            return;
        }

        try {
            $items = $booking['items'] ?? [];
            $payload = [
                'booking_id' => $bookingId,
                'status' => $booking['status'] ?? 'confirmed',
                'location_id' => (int) ($booking['location_id'] ?? 0),
                'client_id' => $booking['client_id'] !== null ? (int) $booking['client_id'] : null,
                'notes' => $booking['notes'] ?? null,
                'source' => $booking['source'] ?? 'online',
                'items' => array_map(fn($item) => [
                    'service_id' => (int) ($item['service_id'] ?? 0),
                    'service_name' => $item['service_name'] ?? null,
                    'staff_id' => (int) ($item['staff_id'] ?? 0),
                    'staff_name' => $item['staff_display_name'] ?? $item['staff_name'] ?? null,
                    'start_time' => $item['start_time'] ?? null,
                    'end_time' => $item['end_time'] ?? null,
                    'price' => (float) ($item['price'] ?? 0),
                ], $items),
                'total_price' => (float) ($booking['total_price'] ?? 0),
                'first_start_time' => !empty($items) ? ($items[0]['start_time'] ?? null) : null,
                'last_end_time' => !empty($items) ? ($items[count($items) - 1]['end_time'] ?? null) : null,
            ];

            // Resolve actor name for denormalization
            $actorName = $this->auditRepository->resolveActorName($actorType, $actorId);

            $this->auditRepository->createEvent(
                $bookingId,
                'booking_created',
                $actorType,
                $actorId,
                $payload,
                null, // no correlation_id for initial creation
                $actorName
            );
        } catch (\Throwable $e) {
            // Log error but don't fail the booking creation
            file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " createBookingCreatedEvent ERROR: " . $e->getMessage() . "\n", FILE_APPEND);
        }
    }
}
