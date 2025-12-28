<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\Booking\CreateBooking;
use Agenda\UseCases\Booking\GetMyBookings;
use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Repositories\BookingRepository;

final class BookingsController
{
    public function __construct(
        private readonly CreateBooking $createBooking,
        private readonly BookingRepository $bookingRepo,
        private readonly GetMyBookings $getMyBookings,
        private readonly ?\Agenda\UseCases\Booking\UpdateBooking $updateBooking = null,
        private readonly ?\Agenda\UseCases\Booking\DeleteBooking $deleteBooking = null,
    ) {}

    /**
     * GET /v1/locations/{location_id}/bookings?date=YYYY-MM-DD[&staff_id=X]
     * Protected endpoint - gets bookings for a location on a date.
     */
    public function index(Request $request): Response
    {
        $locationId = $request->getAttribute('location_id');
        $date = $request->queryParam('date');
        $staffId = $request->queryParam('staff_id');

        if ($locationId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        if ($date === null) {
            return Response::error('date query parameter is required (YYYY-MM-DD)', 'validation_error', 400);
        }

        // Validate date format
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return Response::error('Invalid date format. Use YYYY-MM-DD', 'validation_error', 400);
        }

        $bookings = $this->bookingRepo->findByLocationAndDate(
            (int) $locationId,
            $date,
            $staffId !== null ? (int) $staffId : null
        );

        // Format bookings for response
        $formatted = array_map(fn($b) => $this->formatBooking($b), $bookings);

        return Response::success([
            'bookings' => $formatted,
        ]);
    }

    /**
     * GET /v1/locations/{location_id}/bookings/{booking_id}
     * Protected endpoint - gets a single booking.
     */
    public function show(Request $request): Response
    {
        $bookingId = (int) $request->getAttribute('booking_id');

        $booking = $this->bookingRepo->findById($bookingId);

        if ($booking === null) {
            return Response::notFound('Booking not found');
        }

        return Response::success($this->formatBooking($booking));
    }

    /**
     * POST /v1/locations/{location_id}/bookings
     * Protected endpoint - creates a new booking.
     * 
     * Payload (VINCOLANTE):
     * {
     *   "service_ids": [int],
     *   "staff_id": int|null,
     *   "start_time": "ISO8601",
     *   "notes": "string|null"
     * }
     */
    public function store(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        $locationId = $request->getAttribute('location_id');
        $businessId = $request->getAttribute('business_id');
        $idempotencyKey = $request->getAttribute('idempotency_key');

        if ($userId === null) {
            return Response::error('Authentication required', 'unauthorized', 401);
        }

        if ($locationId === null || $businessId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        $body = $request->getBody();

        // Validate required fields
        if (!isset($body['service_ids']) || !is_array($body['service_ids'])) {
            return Response::error('service_ids is required and must be an array', 'validation_error', 400);
        }

        if (!isset($body['start_time'])) {
            return Response::error('start_time is required', 'validation_error', 400);
        }

        try {
            $booking = $this->createBooking->execute(
                $userId,
                $locationId,
                $businessId,
                [
                    'service_ids' => array_map('intval', $body['service_ids']),
                    'staff_id' => isset($body['staff_id']) ? (int) $body['staff_id'] : null,
                    'start_time' => $body['start_time'],
                    'notes' => $body['notes'] ?? null,
                ],
                $idempotencyKey
            );

            return Response::success($booking, 201);

        } catch (BookingException $e) {
            $errorData = ['code' => $e->getErrorCode()];
            
            if (!empty($e->getDetails())) {
                $errorData['details'] = $e->getDetails();
            }

            return Response::json([
                'success' => false,
                'error' => [
                    'message' => $e->getMessage(),
                    'code' => $e->getErrorCode(),
                    'details' => $e->getDetails(),
                ],
            ], $e->getHttpStatus());
        }
    }

    /**
     * PUT /v1/locations/{location_id}/bookings/{booking_id}
     * Protected endpoint - updates a booking (status, notes, or reschedule with start_time).
     */
    public function update(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($userId === null) {
            return Response::error('Authentication required', 'unauthorized', 401);
        }

        if ($this->updateBooking === null) {
            return Response::serverError('UpdateBooking use case not initialized');
        }

        $body = $request->getBody();

        // Valida che ci sia almeno un campo da aggiornare
        if (!isset($body['status']) && !isset($body['notes']) && !isset($body['start_time'])) {
            return Response::error(
                'At least one field required: status, notes, or start_time',
                'validation_error',
                400
            );
        }

        try {
            $booking = $this->updateBooking->execute($bookingId, $userId, $body);
            return Response::success($this->formatBooking($booking));

        } catch (BookingException $e) {
            return Response::json([
                'success' => false,
                'error' => [
                    'message' => $e->getMessage(),
                    'code' => $e->getErrorCode(),
                    'details' => $e->getDetails(),
                ],
            ], $e->getHttpStatus());
        }
    }

    /**
     * DELETE /v1/locations/{location_id}/bookings/{booking_id}
     * Protected endpoint - deletes a booking and all its items.
     */
    public function destroy(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($userId === null) {
            return Response::error('Authentication required', 'unauthorized', 401);
        }

        if ($this->deleteBooking === null) {
            return Response::serverError('DeleteBooking use case not initialized');
        }

        try {
            $this->deleteBooking->execute($bookingId, $userId);
            return Response::success(['message' => 'Booking deleted successfully']);

        } catch (BookingException $e) {
            return Response::json([
                'success' => false,
                'error' => [
                    'message' => $e->getMessage(),
                    'code' => $e->getErrorCode(),
                    'details' => $e->getDetails(),
                ],
            ], $e->getHttpStatus());
        }
    }

    /**
     * GET /v1/me/bookings
     * Get all bookings for the authenticated user (upcoming and past).
     */
    public function myBookings(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');

        if ($userId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        try {
            $result = $this->getMyBookings->execute((int) $userId);
            
            // I dati sono già formattati dal use case
            return Response::success([
                'upcoming' => $result['upcoming'],
                'past' => $result['past'],
            ]);

        } catch (\Exception $e) {
            return Response::serverError($e->getMessage());
        }
    }

    private function formatBooking(array $booking): array
    {
        return [
            'id' => (int) $booking['id'],
            'business_id' => (int) $booking['business_id'],
            'location_id' => (int) $booking['location_id'],
            'client_id' => $booking['client_id'] ? (int) $booking['client_id'] : null,
            'user_id' => $booking['user_id'] ? (int) $booking['user_id'] : null,
            'customer_name' => $booking['customer_name'],
            'notes' => $booking['notes'],
            'status' => $booking['status'],
            'source' => $booking['source'],
            'total_price' => (float) ($booking['total_price'] ?? 0),
            'total_duration_minutes' => (int) ($booking['total_duration_minutes'] ?? 0),
            'created_at' => $booking['created_at'],
            'updated_at' => $booking['updated_at'],
            'items' => array_map(fn($item) => [
                'id' => (int) $item['id'],
                'booking_id' => (int) $item['booking_id'],
                'service_id' => (int) $item['service_id'],
                'service_variant_id' => $item['service_variant_id'] ? (int) $item['service_variant_id'] : null,
                'staff_id' => (int) $item['staff_id'],
                'start_time' => $item['start_time'],
                'end_time' => $item['end_time'],
                'price' => (float) ($item['price'] ?? 0),
                'duration_minutes' => (int) ($item['duration_minutes'] ?? 0),
                'service_name' => $item['service_name'] ?? $item['service_name_snapshot'],
                'staff_display_name' => $item['staff_display_name'],
            ], $booking['items'] ?? []),
        ];
    }
}
