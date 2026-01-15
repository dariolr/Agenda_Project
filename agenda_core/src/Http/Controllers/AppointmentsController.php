<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\UseCases\Booking\CreateBooking;
use Agenda\UseCases\Booking\UpdateBooking;
use Agenda\UseCases\Booking\DeleteBooking;

final class AppointmentsController
{
    public function __construct(
        private readonly BookingRepository $bookingRepo,
        private readonly CreateBooking $createBooking,
        private readonly UpdateBooking $updateBooking,
        private readonly DeleteBooking $deleteBooking,
        private readonly LocationRepository $locationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * Check if authenticated user has access to the given business.
     */
    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        // Superadmin has access to all businesses
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        // Normal user: check business_users table
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    /**
     * GET /v1/locations/{location_id}/appointments?date=YYYY-MM-DD
     * Returns all booking_items (appointments) for a specific location and date
     */
    public function index(Request $request): Response
    {
        $locationId = (int) $request->getAttribute('location_id');
        $businessId = $request->getAttribute('business_id');
        $date = $request->queryParam('date');

        if (!$date || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return Response::badRequest('date parameter required (YYYY-MM-DD format)', $request->traceId);
        }

        // Authorization check (middleware should set business_id)
        if ($businessId && !$this->hasBusinessAccess($request, (int) $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        // Get all bookings for this location and date
        $appointments = $this->bookingRepo->getAppointmentsByLocationAndDate($locationId, $date);

        return Response::success([
            'appointments' => array_map(fn($a) => $this->formatAppointment($a), $appointments),
        ]);
    }

    /**
     * GET /v1/locations/{location_id}/appointments/{id}
     * Returns a specific appointment (booking_item)
     */
    public function show(Request $request): Response
    {
        $appointmentId = (int) $request->getAttribute('id');

        $appointment = $this->bookingRepo->getAppointmentById($appointmentId);

        if ($appointment === null) {
            return Response::notFound('Appointment not found');
        }

        // Get location to verify business access
        $locationId = (int) $appointment['location_id'];
        $location = $this->locationRepo->findById($locationId);
        
        if ($location) {
            $businessId = (int) $location['business_id'];
            if (!$this->hasBusinessAccess($request, $businessId)) {
                return Response::notFound('Appointment not found');
            }
        }

        return Response::success($this->formatAppointment($appointment));
    }

    /**
     * PATCH /v1/locations/{location_id}/appointments/{id}
     * Reschedule an appointment (update start_time/end_time)
     * Operators with business access can modify any appointment.
     */
    public function update(Request $request): Response
    {
        $appointmentId = (int) $request->getAttribute('id');
        $body = $request->getBody();

        $appointment = $this->bookingRepo->getAppointmentById($appointmentId);
        if ($appointment === null) {
            return Response::notFound('Appointment not found');
        }

        // Get location to verify business access
        $locationId = (int) $appointment['location_id'];
        $location = $this->locationRepo->findById($locationId);
        
        if (!$location) {
            return Response::notFound('Appointment not found');
        }

        $businessId = (int) $location['business_id'];
        $userId = $request->getAttribute('user_id');
        $booking = $this->bookingRepo->findById((int) $appointment['booking_id']);

        // Allow if: user is owner of booking OR has business access (operator)
        $isOwner = $booking && (int) $booking['user_id'] === (int) $userId;
        $hasAccess = $this->hasBusinessAccess($request, $businessId);

        if (!$isOwner && !$hasAccess) {
            return Response::forbidden('You do not have permission to modify this appointment');
        }

        // Update appointment fields
        $updates = [];
        if (isset($body['start_time'])) {
            $updates['start_time'] = $body['start_time'];
        }
        if (isset($body['end_time'])) {
            $updates['end_time'] = $body['end_time'];
        }
        if (isset($body['staff_id'])) {
            $updates['staff_id'] = (int) $body['staff_id'];
        }
        if (isset($body['service_id'])) {
            $updates['service_id'] = (int) $body['service_id'];
        }
        if (isset($body['service_variant_id'])) {
            $updates['service_variant_id'] = (int) $body['service_variant_id'];
        }
        if (isset($body['service_name_snapshot'])) {
            $updates['service_name_snapshot'] = $body['service_name_snapshot'];
        }
        if (isset($body['extra_blocked_minutes'])) {
            $updates['extra_blocked_minutes'] = (int) $body['extra_blocked_minutes'];
        }
        if (isset($body['extra_processing_minutes'])) {
            $updates['extra_processing_minutes'] = (int) $body['extra_processing_minutes'];
        }
        if (isset($body['client_name_snapshot'])) {
            $updates['client_name_snapshot'] = $body['client_name_snapshot'];
        }

        // Update booking fields (client_id and client_name are on booking, not appointment)
        $bookingId = (int) $appointment['booking_id'];
        $bookingUpdated = false;
        if (isset($body['client_id']) || isset($body['client_name'])) {
            $clientId = isset($body['client_id']) ? (int) $body['client_id'] : null;
            $clientName = $body['client_name'] ?? null;
            $this->bookingRepo->updateBooking($bookingId, null, null, $clientId, $clientName);
            $bookingUpdated = true;
        }

        if (empty($updates) && !$bookingUpdated) {
            return Response::badRequest('No fields to update', $request->traceId);
        }

        // TODO: Add conflict detection before updating
        if (!empty($updates)) {
            $this->bookingRepo->updateAppointment($appointmentId, $updates);
        }

        $updated = $this->bookingRepo->getAppointmentById($appointmentId);

        return Response::success($this->formatAppointment($updated));
    }

    /**
     * POST /v1/bookings/{booking_id}/items
     * Add a new booking_item (appointment) to an existing booking.
     * Used when editing an appointment and adding a new service to the same booking.
     */
    public function store(Request $request): Response
    {
        $bookingId = (int) $request->getAttribute('booking_id');
        $body = $request->getBody();

        // Get the booking to verify it exists and get business access
        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null) {
            return Response::notFound('Booking not found');
        }

        // Get business_id from the booking via location
        $locationId = isset($body['location_id']) ? (int) $body['location_id'] : null;
        if (!$locationId) {
            return Response::badRequest('location_id is required', $request->traceId);
        }

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::badRequest('Location not found', $request->traceId);
        }

        $businessId = (int) $location['business_id'];
        $userId = $request->getAttribute('user_id');

        // Allow if: user is owner of booking OR has business access (operator)
        $isOwner = (int) $booking['user_id'] === (int) $userId;
        $hasAccess = $this->hasBusinessAccess($request, $businessId);

        if (!$isOwner && !$hasAccess) {
            return Response::forbidden('You do not have permission to modify this booking');
        }

        // Validate required fields
        if (!isset($body['staff_id']) || !isset($body['service_id']) || !isset($body['start_time']) || !isset($body['end_time'])) {
            return Response::badRequest('staff_id, service_id, start_time, and end_time are required', $request->traceId);
        }

        // Create the booking item
        $itemData = [
            'location_id' => $locationId,
            'service_id' => (int) $body['service_id'],
            'service_variant_id' => isset($body['service_variant_id']) ? (int) $body['service_variant_id'] : (int) $body['service_id'],
            'staff_id' => (int) $body['staff_id'],
            'start_time' => $body['start_time'],
            'end_time' => $body['end_time'],
            'price' => isset($body['price']) ? (float) $body['price'] : 0,
            'extra_blocked_minutes' => isset($body['extra_blocked_minutes']) ? (int) $body['extra_blocked_minutes'] : 0,
            'extra_processing_minutes' => isset($body['extra_processing_minutes']) ? (int) $body['extra_processing_minutes'] : 0,
            'service_name_snapshot' => $body['service_name_snapshot'] ?? null,
            'client_name_snapshot' => $body['client_name_snapshot'] ?? null,
        ];

        $newItemId = $this->bookingRepo->addBookingItem($bookingId, $itemData);

        // Fetch the newly created appointment
        $newAppointment = $this->bookingRepo->getAppointmentById($newItemId);

        return Response::success($this->formatAppointment($newAppointment));
    }

    /**
     * POST /v1/locations/{location_id}/appointments/{id}/cancel
     * Cancel an appointment (soft delete or status update)
     * Operators with business access can cancel any appointment.
     */
    public function cancel(Request $request): Response
    {
        $appointmentId = (int) $request->getAttribute('id');

        $appointment = $this->bookingRepo->getAppointmentById($appointmentId);
        if ($appointment === null) {
            return Response::notFound('Appointment not found');
        }

        // Get location to verify business access
        $locationId = (int) $appointment['location_id'];
        $location = $this->locationRepo->findById($locationId);
        
        if (!$location) {
            return Response::notFound('Appointment not found');
        }

        $businessId = (int) $location['business_id'];
        $userId = $request->getAttribute('user_id');
        $booking = $this->bookingRepo->findById((int) $appointment['booking_id']);

        // Allow if: user is owner of booking OR has business access (operator)
        $isOwner = $booking && (int) $booking['user_id'] === (int) $userId;
        $hasAccess = $this->hasBusinessAccess($request, $businessId);

        if (!$isOwner && !$hasAccess) {
            return Response::forbidden('You do not have permission to cancel this appointment');
        }

        // Update booking status to 'cancelled' to preserve history
        $this->bookingRepo->updateBooking((int) $appointment['booking_id'], [
            'status' => 'cancelled',
        ]);

        return Response::success([
            'cancelled' => true,
            'appointment_id' => $appointmentId,
        ]);
    }

    /**
     * DELETE /v1/bookings/{booking_id}/items/{item_id}
     * Delete a single booking item (appointment) from a booking.
     * Used when editing a multi-service booking and removing one service.
     */
    public function destroyItem(Request $request): Response
    {
        $bookingId = (int) $request->getAttribute('booking_id');
        $itemId = (int) $request->getAttribute('item_id');

        // Get the booking to verify it exists
        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null) {
            return Response::notFound('Booking not found');
        }

        // Get the appointment to verify it belongs to this booking
        $appointment = $this->bookingRepo->getAppointmentById($itemId);
        if ($appointment === null) {
            return Response::notFound('Appointment not found');
        }

        if ((int) $appointment['booking_id'] !== $bookingId) {
            return Response::badRequest('Appointment does not belong to this booking');
        }

        // Get location to verify business access
        $locationId = (int) $appointment['location_id'];
        $location = $this->locationRepo->findById($locationId);
        
        if (!$location) {
            return Response::notFound('Location not found');
        }

        $businessId = (int) $location['business_id'];
        $userId = $request->getAttribute('user_id');

        // Allow if: user is owner of booking OR has business access (operator)
        $isOwner = (int) $booking['user_id'] === (int) $userId;
        $hasAccess = $this->hasBusinessAccess($request, $businessId);

        if (!$isOwner && !$hasAccess) {
            return Response::forbidden('You do not have permission to delete this appointment');
        }

        // Delete the booking item
        $deleted = $this->bookingRepo->deleteBookingItem($itemId);

        if (!$deleted) {
            return Response::notFound('Appointment not found');
        }

        // Check if booking is now empty and update status if so
        $remainingItems = $this->bookingRepo->countBookingItems($bookingId);
        if ($remainingItems === 0) {
            $this->bookingRepo->updateStatus($bookingId, 'cancelled');
        }

        return Response::success([
            'deleted' => true,
            'item_id' => $itemId,
            'remaining_items' => $remainingItems,
        ]);
    }

    private function formatAppointment(array $appointment): array
    {
        return [
            'id' => (int) $appointment['id'],
            'booking_id' => (int) $appointment['booking_id'],
            'business_id' => isset($appointment['business_id']) ? (int) $appointment['business_id'] : null,
            'location_id' => (int) $appointment['location_id'],
            'staff_id' => (int) $appointment['staff_id'],
            'service_id' => isset($appointment['service_id']) ? (int) $appointment['service_id'] : null,
            'service_variant_id' => (int) $appointment['service_variant_id'],
            'start_time' => $appointment['start_time'],
            'end_time' => $appointment['end_time'],
            'extra_blocked_minutes' => (int) ($appointment['extra_blocked_minutes'] ?? 0),
            'extra_processing_minutes' => (int) ($appointment['extra_processing_minutes'] ?? 0),
            'created_at' => $appointment['created_at'],
            'updated_at' => $appointment['updated_at'],
            // Include booking info if joined
            'booking_status' => $appointment['booking_status'] ?? null,
            'source' => $appointment['source'] ?? null,
            'client_id' => isset($appointment['client_id']) ? (int) $appointment['client_id'] : null,
            'client_name' => $appointment['client_name'] ?? null,
            'service_name' => $appointment['service_name'] ?? null,
            'staff_name' => $appointment['staff_name'] ?? null,
        ];
    }
}
