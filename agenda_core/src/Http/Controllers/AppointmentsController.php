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

        if (empty($updates)) {
            return Response::badRequest('No fields to update', $request->traceId);
        }

        // TODO: Add conflict detection before updating
        $this->bookingRepo->updateAppointment($appointmentId, $updates);

        $updated = $this->bookingRepo->getAppointmentById($appointmentId);

        return Response::success($this->formatAppointment($updated));
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

    private function formatAppointment(array $appointment): array
    {
        return [
            'id' => (int) $appointment['id'],
            'booking_id' => (int) $appointment['booking_id'],
            'location_id' => (int) $appointment['location_id'],
            'staff_id' => (int) $appointment['staff_id'],
            'service_variant_id' => (int) $appointment['service_variant_id'],
            'start_time' => $appointment['start_time'],
            'end_time' => $appointment['end_time'],
            'extra_blocked_minutes' => (int) ($appointment['extra_blocked_minutes'] ?? 0),
            'extra_processing_minutes' => (int) ($appointment['extra_processing_minutes'] ?? 0),
            'created_at' => $appointment['created_at'],
            'updated_at' => $appointment['updated_at'],
            // Include booking info if joined
            'booking_status' => $appointment['booking_status'] ?? null,
            'client_name' => $appointment['client_name'] ?? null,
            'service_name' => $appointment['service_name'] ?? null,
            'staff_name' => $appointment['staff_name'] ?? null,
        ];
    }
}
