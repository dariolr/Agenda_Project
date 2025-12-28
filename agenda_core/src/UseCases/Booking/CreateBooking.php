<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
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

        // Validate required fields
        $serviceIds = $data['service_ids'] ?? [];
        $staffId = $data['staff_id'] ?? null;
        $startTimeString = $data['start_time'] ?? null;
        $notes = $data['notes'] ?? null;

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

        // Validate start time is in the future
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        if ($startTime <= $now) {
            throw BookingException::invalidTime('start_time must be in the future');
        }

        // Validate location
        $location = $this->locationRepository->findById($locationId);
        if ($location === null || (int) $location['business_id'] !== $businessId) {
            throw BookingException::invalidLocation($locationId);
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

        // If no staff specified, auto-assign first available
        if ($staffId === null) {
            $availableStaff = $this->staffRepository->findByLocationId($locationId, $businessId);
            if (empty($availableStaff)) {
                throw BookingException::invalidStaff(0);
            }
            $staffId = (int) $availableStaff[0]['id'];
        }

        // Validate staff belongs to location
        if (!$this->staffRepository->belongsToLocation($staffId, $locationId)) {
            throw BookingException::invalidStaff($staffId);
        }

        // Find or create client for this user in this business
        $client = $this->clientRepository->findOrCreateForUser($userId, $businessId);
        $clientId = (int) $client['id'];

        // Get user for snapshot
        $user = $this->userRepository->findById($userId);
        $clientName = $user ? ($user['first_name'] . ' ' . $user['last_name']) : null;

        // Start transaction for conflict detection
        $this->db->beginTransaction();

        try {
            // Calculate total duration and check conflicts for each item
            $currentTime = $startTime;
            $itemsToCreate = [];

            foreach ($services as $service) {
                $serviceDuration = (int) $service['duration_minutes'];
                $serviceEndTime = $currentTime->modify("+{$serviceDuration} minutes");

                // Check for conflicts using SELECT FOR UPDATE
                $conflicts = $this->bookingRepository->checkConflicts(
                    $staffId,
                    $locationId,
                    $currentTime,
                    $serviceEndTime
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
                    'end_time' => $serviceEndTime->format('Y-m-d H:i:s'),
                    'price' => (float) $service['price'],
                    'service_name_snapshot' => $service['name'],
                    'client_name_snapshot' => $clientName,
                ];

                $currentTime = $serviceEndTime;
            }

            // Create booking (container)
            $bookingId = $this->bookingRepository->create([
                'business_id' => $businessId,
                'location_id' => $locationId,
                'client_id' => $clientId,
                'user_id' => $userId,
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

    private function formatBookingResponse(array $booking): array
    {
        return [
            'id' => (int) $booking['id'],
            'business_id' => (int) $booking['business_id'],
            'location_id' => (int) $booking['location_id'],
            'client_id' => $booking['client_id'] !== null ? (int) $booking['client_id'] : null,
            'status' => $booking['status'],
            'notes' => $booking['notes'],
            'total_price' => (float) ($booking['total_price'] ?? 0),
            'total_duration_minutes' => (int) ($booking['total_duration_minutes'] ?? 0),
            'created_at' => $booking['created_at'],
            'items' => array_map(fn($item) => [
                'id' => (int) $item['id'],
                'service_id' => (int) $item['service_id'],
                'service_name' => $item['service_name'] ?? $item['service_name_snapshot'],
                'staff_id' => (int) $item['staff_id'],
                'staff_name' => $item['staff_display_name'] ?? null,
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
    private function queueNotifications(array $booking, array $location, int $userId): void
    {
        if ($this->notificationRepo === null) {
            return; // Notifications not configured
        }

        try {
            // Determine sender email/name with priority: location > business > .env
            $senderEmail = $location['email'] ?? $location['business_email'] ?? null;
            $senderName = $location['email'] ? $location['name'] : ($location['business_email'] ? $location['business_name'] : null);
            
            // Prepare notification data
            $notificationData = [
                'booking_id' => (int) $booking['id'],
                'user_id' => $userId,
                'business_id' => (int) $booking['business_id'],
                'business_name' => $location['business_name'] ?? '',
                'business_email' => $location['business_email'] ?? '',
                'location_name' => $location['name'] ?? '',
                'location_email' => $location['email'] ?? '',
                'location_address' => $location['address'] ?? '',
                'location_city' => $location['city'] ?? '',
                'location_phone' => $location['phone'] ?? '',
                'sender_email' => $senderEmail,  // Prioritized email
                'sender_name' => $senderName,    // Prioritized name
                'start_time' => $booking['items'][0]['start_time'] ?? $booking['created_at'],
                'services' => implode(', ', array_column($booking['items'] ?? [], 'service_name')),
                'total_price' => $booking['total_price'] ?? 0,
                'cancellation_hours' => $location['cancellation_hours'] ?? 24,
                'manage_url' => $_ENV['FRONTEND_URL'] ?? 'https://app.example.com' . '/bookings',
                'booking_url' => $_ENV['FRONTEND_URL'] ?? 'https://app.example.com' . '/booking',
            ];

            // Queue confirmation email
            $confirmationUseCase = new QueueBookingConfirmation($this->db, $this->notificationRepo);
            $confirmationUseCase->execute($notificationData);

            // Queue reminder (scheduled for 24h before)
            $reminderUseCase = new QueueBookingReminder($this->db, $this->notificationRepo);
            $reminderUseCase->execute($notificationData);
        } catch (\Throwable $e) {
            // Log error but don't fail the booking
            error_log("Failed to queue notifications for booking {$booking['id']}: " . $e->getMessage());
        }
    }
}
