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
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Domain\Exceptions\BookingException;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Replace an existing booking with a new one.
 * 
 * This use case implements an atomic replace pattern:
 * 1. Original booking remains active until commit
 * 2. New booking is created with same or different parameters
 * 3. Original booking is marked as 'replaced' and linked to new booking
 * 4. Audit events are created for both bookings
 * 5. A single "booking_modified" notification is sent (not cancel + new)
 */
final class ReplaceBooking
{
    public function __construct(
        private readonly Connection $db,
        private readonly BookingRepository $bookingRepository,
        private readonly BookingAuditRepository $auditRepository,
        private readonly ServiceRepository $serviceRepository,
        private readonly StaffRepository $staffRepository,
        private readonly ClientRepository $clientRepository,
        private readonly LocationRepository $locationRepository,
        private readonly ?NotificationRepository $notificationRepo = null,
        private readonly ?ComputeAvailability $computeAvailability = null,
    ) {}

    /**
     * Replace an existing booking with a new one.
     * 
     * @param int $originalBookingId The booking to replace
     * @param array $newBookingData New booking data (same format as CreateBooking)
     * @param string $actorType 'customer', 'staff', or 'system'
     * @param int|null $actorId Client ID for customer, User ID for staff
     * @param string|null $reason Optional reason for the replacement
     * @return array Result with original_booking_id, new_booking_id, and new booking data
     * @throws BookingException
     */
    public function execute(
        int $originalBookingId,
        array $newBookingData,
        string $actorType,
        ?int $actorId,
        ?string $reason = null
    ): array {
        // Generate correlation ID for audit
        $correlationId = $this->generateCorrelationId();

        // Start transaction
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();

        try {
            // 1. Lock original booking for update
            $originalBooking = $this->bookingRepository->lockForUpdate($originalBookingId);
            
            if ($originalBooking === null) {
                throw BookingException::notFound('Booking not found');
            }

            // 2. Validate booking can be replaced
            $this->validateBookingCanBeReplaced($originalBooking);

            // 3. Validate permissions (actor must own booking or be staff of business)
            $this->validatePermissions($originalBooking, $actorType, $actorId);

            // Extract location/business from original booking
            $locationId = (int) $originalBooking['location_id'];
            $businessId = (int) $originalBooking['business_id'];
            $clientId = $originalBooking['client_id'] ? (int) $originalBooking['client_id'] : null;

            // 4. Create snapshot of original booking for audit
            $beforeSnapshot = $this->createBookingSnapshot($originalBookingId);

            // 5. Prepare new booking data
            $items = $this->prepareItems($newBookingData, $locationId, $businessId, $originalBookingId);
            
            // 6. Calculate total duration for availability check
            $totalDuration = 0;
            $serviceIds = [];
            foreach ($items as $item) {
                $totalDuration += $item['duration_minutes'];
                $serviceIds[] = $item['service_id'];
            }

            // 7. Check availability (excluding original booking from conflicts)
            if (!($newBookingData['skip_conflict_check'] ?? false)) {
                $this->checkAvailability($items, $locationId, $businessId, $originalBookingId);
            }

            // 8. Create new booking
            $newBookingId = $this->createNewBooking(
                $businessId,
                $locationId,
                $clientId,
                $newBookingData['notes'] ?? $originalBooking['notes'],
                $newBookingData['source'] ?? 'online',
                $items
            );

            // 9. Mark original booking as replaced
            $this->bookingRepository->markAsReplaced($originalBookingId, $newBookingId);

            // 10. Set replaces_booking_id on new booking
            $this->bookingRepository->setReplacesBookingId($newBookingId, $originalBookingId);

            // 11. Create booking_replacements record
            $this->auditRepository->createReplacement(
                $originalBookingId,
                $newBookingId,
                $actorType,
                $actorId,
                $reason
            );

            // 12. Create snapshot of new booking for audit
            $afterSnapshot = $this->createBookingSnapshot($newBookingId);

            // 13. Create audit events
            $this->createAuditEvents(
                $originalBookingId,
                $newBookingId,
                $beforeSnapshot,
                $afterSnapshot,
                $actorType,
                $actorId,
                $reason,
                $correlationId
            );

            // 14. Commit transaction
            $pdo->commit();

            // 15. Queue notification (post-commit)
            $this->queueModifiedNotification($newBookingId, $beforeSnapshot, $afterSnapshot);

            // Return result
            $newBooking = $this->bookingRepository->findByIdWithReplaceInfo($newBookingId);
            
            return [
                'status' => 'success',
                'original_booking_id' => $originalBookingId,
                'new_booking_id' => $newBookingId,
                'booking' => $newBooking,
            ];

        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    private function validateBookingCanBeReplaced(array $booking): void
    {
        // Check status is confirmed (or pending)
        if (!in_array($booking['status'], ['confirmed', 'pending'], true)) {
            throw BookingException::notModifiable(
                (int) $booking['id'],
                'Booking status must be confirmed or pending'
            );
        }

        // Check not already replaced
        if (!empty($booking['replaced_by_booking_id'])) {
            throw BookingException::alreadyReplaced(
                (int) $booking['id'],
                (int) $booking['replaced_by_booking_id']
            );
        }

        // Check booking is modifiable (not in the past, respects cancellation policy)
        $items = $this->bookingRepository->getBookingItems((int) $booking['id']);
        if (empty($items)) {
            throw BookingException::notFound('Booking has no items');
        }

        $earliestStart = new DateTimeImmutable($items[0]['start_time']);
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        
        if ($earliestStart <= $now) {
            throw BookingException::notModifiable(
                (int) $booking['id'],
                'Booking start time has already passed'
            );
        }

        // Check cancellation policy
        $policy = $this->bookingRepository->getCancellationPolicyForBooking((int) $booking['id']);
        if ($policy !== null) {
            $cancellationHours = $policy['location_cancellation_hours'] 
                ?? $policy['business_cancellation_hours'] 
                ?? 24;
            
            $deadline = $earliestStart->modify("-{$cancellationHours} hours");
            if ($now > $deadline) {
                throw BookingException::notModifiable(
                    (int) $booking['id'],
                    "Booking cannot be modified less than {$cancellationHours} hours before start"
                );
            }
        }
    }

    private function validatePermissions(array $booking, string $actorType, ?int $actorId): void
    {
        if ($actorType === 'system') {
            return; // System can always replace
        }

        if ($actorType === 'customer') {
            // Customer must own the booking
            if ($actorId !== (int) ($booking['client_id'] ?? 0)) {
                throw BookingException::unauthorized('You can only modify your own bookings');
            }
        }

        // Staff permissions are validated by the controller/middleware
    }

    private function prepareItems(array $newBookingData, int $locationId, int $businessId, int $excludeBookingId): array
    {
        $items = [];

        if (isset($newBookingData['items']) && is_array($newBookingData['items'])) {
            foreach ($newBookingData['items'] as $item) {
                $serviceId = (int) $item['service_id'];
                $staffId = (int) $item['staff_id'];
                $startTimeStr = $item['start_time'];

                // Get service variant info
                $service = $this->serviceRepository->findById($serviceId, $locationId, $businessId);
                if ($service === null) {
                    throw BookingException::invalidService([$serviceId]);
                }

                // Validate staff can perform service
                if (!$this->staffRepository->canPerformServices($staffId, [$serviceId], $locationId, $businessId)) {
                    throw BookingException::invalidStaff($staffId);
                }

                $startTime = new DateTimeImmutable($startTimeStr, new DateTimeZone('UTC'));
                $durationMinutes = $item['duration_minutes'] ?? (int) $service['duration_minutes'];
                $endTime = $startTime->modify("+{$durationMinutes} minutes");

                $items[] = [
                    'service_id' => $serviceId,
                    'service_variant_id' => (int) $service['variant_id'],
                    'staff_id' => $staffId,
                    'start_time' => $startTime,
                    'end_time' => $endTime,
                    'duration_minutes' => $durationMinutes,
                    'price' => $item['price'] ?? (float) $service['price'],
                    'service_name' => $service['name'],
                ];
            }
        } elseif (isset($newBookingData['service_ids'])) {
            // Legacy format - convert to items
            $serviceIds = array_map('intval', $newBookingData['service_ids']);
            $staffId = isset($newBookingData['staff_id']) ? (int) $newBookingData['staff_id'] : null;
            $startTimeStr = $newBookingData['start_time'];
            
            $startTime = new DateTimeImmutable($startTimeStr, new DateTimeZone('UTC'));

            // Get services
            $services = $this->serviceRepository->findByIds($serviceIds, $locationId, $businessId);
            if (count($services) !== count($serviceIds)) {
                throw BookingException::invalidService($serviceIds);
            }

            // If no staff specified, find available staff
            if ($staffId === null && $this->computeAvailability !== null) {
                $totalDuration = array_sum(array_column($services, 'duration_minutes'));
                $dateStr = $startTime->format('Y-m-d');
                
                $availabilityResult = $this->computeAvailability->execute(
                    $businessId,
                    $locationId,
                    null,
                    $totalDuration,
                    $dateStr,
                    $serviceIds,
                    true, // keepStaffInfo
                    $excludeBookingId
                );

                $slots = $availabilityResult['slots'] ?? [];
                $targetTime = $startTime->format('H:i:s');
                
                foreach ($slots as $slot) {
                    if (substr($slot['start_time'], 11, 8) === $targetTime && isset($slot['staff_id'])) {
                        $staffId = (int) $slot['staff_id'];
                        break;
                    }
                }

                if ($staffId === null) {
                    throw BookingException::slotConflict();
                }
            }

            // Create items sequentially
            $currentTime = $startTime;
            foreach ($services as $service) {
                $durationMinutes = (int) $service['duration_minutes'];
                $endTime = $currentTime->modify("+{$durationMinutes} minutes");

                $items[] = [
                    'service_id' => (int) $service['id'],
                    'service_variant_id' => (int) $service['variant_id'],
                    'staff_id' => $staffId,
                    'start_time' => $currentTime,
                    'end_time' => $endTime,
                    'duration_minutes' => $durationMinutes,
                    'price' => (float) $service['price'],
                    'service_name' => $service['name'],
                ];

                $currentTime = $endTime;
            }
        } else {
            throw BookingException::validationError('Either items or service_ids is required');
        }

        return $items;
    }

    private function checkAvailability(array $items, int $locationId, int $businessId, int $excludeBookingId): void
    {
        foreach ($items as $item) {
            $conflicts = $this->bookingRepository->checkConflicts(
                $item['staff_id'],
                $locationId,
                $item['start_time'],
                $item['end_time'],
                $excludeBookingId
            );

            if (!empty($conflicts)) {
                throw BookingException::slotConflict($conflicts);
            }
        }
    }

    private function createNewBooking(
        int $businessId,
        int $locationId,
        ?int $clientId,
        ?string $notes,
        string $source,
        array $items
    ): int {
        $pdo = $this->db->getPdo();

        // Insert booking
        $stmt = $pdo->prepare(
            'INSERT INTO bookings 
             (business_id, location_id, client_id, notes, status, source, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())'
        );
        $stmt->execute([
            $businessId,
            $locationId,
            $clientId,
            $notes,
            'confirmed',
            $source,
        ]);
        $bookingId = (int) $pdo->lastInsertId();

        // Insert booking items
        $stmtItem = $pdo->prepare(
            'INSERT INTO booking_items 
             (booking_id, location_id, service_id, service_variant_id, staff_id, 
              start_time, end_time, price, service_name_snapshot, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())'
        );

        foreach ($items as $item) {
            $stmtItem->execute([
                $bookingId,
                $locationId,
                $item['service_id'],
                $item['service_variant_id'],
                $item['staff_id'],
                $item['start_time']->format('Y-m-d H:i:s'),
                $item['end_time']->format('Y-m-d H:i:s'),
                $item['price'],
                $item['service_name'],
            ]);
        }

        return $bookingId;
    }

    private function createBookingSnapshot(int $bookingId): array
    {
        $booking = $this->bookingRepository->findById($bookingId);
        if ($booking === null) {
            return [];
        }

        $items = $booking['items'] ?? [];
        
        return [
            'booking_id' => $bookingId,
            'status' => $booking['status'],
            'location_id' => (int) $booking['location_id'],
            'client_id' => $booking['client_id'] ? (int) $booking['client_id'] : null,
            'notes' => $booking['notes'],
            'items' => array_map(fn($item) => [
                'service_id' => (int) $item['service_id'],
                'staff_id' => (int) $item['staff_id'],
                'start_time' => $item['start_time'],
                'end_time' => $item['end_time'],
                'price' => (float) $item['price'],
            ], $items),
            'total_price' => (float) $booking['total_price'],
            'first_start_time' => !empty($items) ? $items[0]['start_time'] : null,
            'last_end_time' => !empty($items) ? $items[count($items) - 1]['end_time'] : null,
        ];
    }

    private function createAuditEvents(
        int $originalBookingId,
        int $newBookingId,
        array $beforeSnapshot,
        array $afterSnapshot,
        string $actorType,
        ?int $actorId,
        ?string $reason,
        string $correlationId
    ): void {
        $commonPayload = [
            'original_booking_id' => $originalBookingId,
            'new_booking_id' => $newBookingId,
            'before_snapshot' => $beforeSnapshot,
            'after_snapshot' => $afterSnapshot,
            'reason' => $reason,
            'actor_type' => $actorType,
            'actor_id' => $actorId,
        ];

        // Event on original booking: booking_replaced
        $this->auditRepository->createEvent(
            $originalBookingId,
            'booking_replaced',
            $actorType,
            $actorId,
            $commonPayload,
            $correlationId
        );

        // Event on new booking: booking_created_by_replace
        $this->auditRepository->createEvent(
            $newBookingId,
            'booking_created_by_replace',
            $actorType,
            $actorId,
            $commonPayload,
            $correlationId
        );
    }

    private function queueModifiedNotification(int $newBookingId, array $beforeSnapshot, array $afterSnapshot): void
    {
        // TODO: Implement booking_modified notification
        // This should send a single notification indicating the booking was modified
        // Not a cancel + new notification
    }

    private function generateCorrelationId(): string
    {
        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );
    }
}
