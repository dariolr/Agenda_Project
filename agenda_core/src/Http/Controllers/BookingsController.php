<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\Booking\CreateBooking;
use Agenda\UseCases\Booking\GetMyBookings;
use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class BookingsController
{
    public function __construct(
        private readonly CreateBooking $createBooking,
        private readonly BookingRepository $bookingRepo,
        private readonly GetMyBookings $getMyBookings,
        private readonly ?\Agenda\UseCases\Booking\UpdateBooking $updateBooking = null,
        private readonly ?\Agenda\UseCases\Booking\DeleteBooking $deleteBooking = null,
        private readonly ?LocationRepository $locationRepo = null,
        private readonly ?BusinessUserRepository $businessUserRepo = null,
        private readonly ?UserRepository $userRepo = null,
    ) {}

    /**
     * Check if authenticated user has access to the given business.
     */
    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null || $this->userRepo === null || $this->businessUserRepo === null) {
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
     * GET /v1/locations/{location_id}/bookings?date=YYYY-MM-DD[&staff_id=X]
     * Protected endpoint - gets bookings for a location on a date.
     */
    public function index(Request $request): Response
    {
        $locationId = $request->getAttribute('location_id');
        $businessId = $request->getAttribute('business_id');
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

        // Authorization check (middleware should set business_id)
        if ($businessId && !$this->hasBusinessAccess($request, (int) $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
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

        // Authorization check: verify user has access to the booking's business
        $businessId = (int) $booking['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
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
     *   "items": [{"service_id": int, "staff_id": int, "start_time": "ISO8601"}, ...],
     *   "notes": "string|null",
     *   "client_id": int|null
     * }
     * 
     * Legacy format also supported:
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

        // Support both new "items" format and legacy "service_ids" format
        $items = null;
        if (isset($body['items']) && is_array($body['items'])) {
            // New format: items with per-service staff and start_time, plus optional overrides
            $items = [];
            foreach ($body['items'] as $item) {
                if (!isset($item['service_id']) || !isset($item['staff_id']) || !isset($item['start_time'])) {
                    return Response::error(
                        'Each item must have service_id, staff_id, and start_time',
                        'validation_error',
                        400
                    );
                }
                $parsedItem = [
                    'service_id' => (int) $item['service_id'],
                    'staff_id' => (int) $item['staff_id'],
                    'start_time' => $item['start_time'],
                ];
                // Optional overrides (operator can modify from service defaults)
                if (isset($item['service_variant_id'])) {
                    $parsedItem['service_variant_id'] = (int) $item['service_variant_id'];
                }
                if (isset($item['duration_minutes'])) {
                    $parsedItem['duration_minutes'] = (int) $item['duration_minutes'];
                }
                if (isset($item['blocked_extra_minutes'])) {
                    $parsedItem['blocked_extra_minutes'] = (int) $item['blocked_extra_minutes'];
                }
                if (isset($item['processing_extra_minutes'])) {
                    $parsedItem['processing_extra_minutes'] = (int) $item['processing_extra_minutes'];
                }
                if (isset($item['price'])) {
                    $parsedItem['price'] = (float) $item['price'];
                }
                $items[] = $parsedItem;
            }
            if (empty($items)) {
                return Response::error('items array cannot be empty', 'validation_error', 400);
            }
        } elseif (isset($body['service_ids']) && is_array($body['service_ids'])) {
            // Legacy format: convert to items
            if (!isset($body['start_time'])) {
                return Response::error('start_time is required', 'validation_error', 400);
            }
            $staffId = isset($body['staff_id']) ? (int) $body['staff_id'] : null;
            // Will be handled in CreateBooking as sequential services
            $items = null; // Let CreateBooking handle legacy format
        } else {
            return Response::error(
                'Either items array or service_ids array is required',
                'validation_error',
                400
            );
        }

        try {
            // Operatori del business possono creare appuntamenti nel passato e sovrapposti
            $isOperator = $this->hasBusinessAccess($request, $businessId);
            
            $bookingData = [
                'notes' => $body['notes'] ?? null,
                'client_id' => isset($body['client_id']) ? (int) $body['client_id'] : null,
                'allow_past' => $isOperator,
                'skip_conflict_check' => $isOperator,
            ];
            
            if ($items !== null) {
                // New format with items
                $bookingData['items'] = $items;
            } else {
                // Legacy format
                $bookingData['service_ids'] = array_map('intval', $body['service_ids']);
                $bookingData['staff_id'] = isset($body['staff_id']) ? (int) $body['staff_id'] : null;
                $bookingData['start_time'] = $body['start_time'];
            }
            
            $booking = $this->createBooking->execute(
                $userId,
                $locationId,
                $businessId,
                $bookingData,
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
        // Nota: array_key_exists per client_id perché può essere null (rimuovi cliente)
        if (!isset($body['status']) && !isset($body['notes']) && !isset($body['start_time']) && !array_key_exists('client_id', $body)) {
            return Response::error(
                'At least one field required: status, notes, start_time, or client_id',
                'validation_error',
                400
            );
        }

        try {
            // Operatori possono modificare qualsiasi booking senza vincoli
            $businessId = $request->getAttribute('business_id');
            $isOperator = $businessId !== null && $this->hasBusinessAccess($request, $businessId);
            
            $booking = $this->updateBooking->execute($bookingId, $userId, $body, $isOperator);
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
            // Operatori possono cancellare qualsiasi booking senza vincoli
            $businessId = $request->getAttribute('business_id');
            $isOperator = $businessId !== null && $this->hasBusinessAccess($request, $businessId);
            
            $this->deleteBooking->execute($bookingId, $userId, $isOperator);
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

    // =========================================================================
    // CUSTOMER ENDPOINTS (self-service booking)
    // Uses client_id from CustomerAuthMiddleware instead of user_id
    // =========================================================================

    /**
     * POST /v1/customer/{business_id}/bookings
     * Create a booking as an authenticated customer.
     * 
     * Payload:
     * {
     *   "location_id": int,
     *   "service_ids": [int],
     *   "staff_id": int|null,
     *   "start_time": "ISO8601",
     *   "notes": "string|null"
     * }
     */
    public function storeCustomer(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');
        $customerBusinessId = $request->getAttribute('business_id'); // from JWT
        $routeBusinessId = (int) $request->getRouteParam('business_id');
        $idempotencyKey = $request->getAttribute('idempotency_key');

        if ($clientId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401);
        }

        // Verify business matches
        if ($customerBusinessId !== $routeBusinessId) {
            return Response::error('Invalid token for this business', 'unauthorized', 401);
        }

        $body = $request->getBody();

        // Validate required fields
        if (!isset($body['location_id'])) {
            return Response::error('location_id is required', 'validation_error', 400);
        }

        if (!isset($body['service_ids']) || !is_array($body['service_ids'])) {
            return Response::error('service_ids is required and must be an array', 'validation_error', 400);
        }

        if (!isset($body['start_time'])) {
            return Response::error('start_time is required', 'validation_error', 400);
        }

        $locationId = (int) $body['location_id'];

        // Verify location belongs to business
        if ($this->locationRepo !== null) {
            $location = $this->locationRepo->findById($locationId);
            if ($location === null || (int) $location['business_id'] !== $routeBusinessId) {
                return Response::error('Invalid location for this business', 'validation_error', 400);
            }
        }

        try {
            // Customer bookings: no past dates, no conflict override
            $booking = $this->createBooking->executeForCustomer(
                (int) $clientId,
                $locationId,
                $routeBusinessId,
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
     * GET /v1/customer/bookings
     * Get all bookings for the authenticated customer.
     */
    public function myCustomerBookings(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');

        if ($clientId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401);
        }

        try {
            // Get bookings for this client
            $bookings = $this->bookingRepo->findByClientId((int) $clientId);

            $now = new \DateTimeImmutable();
            $upcoming = [];
            $past = [];

            foreach ($bookings as $booking) {
                $formatted = $this->formatBooking($booking);
                
                // Determine if booking is upcoming or past based on first item start_time
                $startTime = null;
                if (!empty($booking['items'])) {
                    $startTime = new \DateTimeImmutable($booking['items'][0]['start_time']);
                }
                
                if ($startTime !== null && $startTime > $now) {
                    $upcoming[] = $formatted;
                } else {
                    $past[] = $formatted;
                }
            }

            // Sort upcoming by start_time ascending, past by start_time descending
            usort($upcoming, fn($a, $b) => ($a['items'][0]['start_time'] ?? '') <=> ($b['items'][0]['start_time'] ?? ''));
            usort($past, fn($a, $b) => ($b['items'][0]['start_time'] ?? '') <=> ($a['items'][0]['start_time'] ?? ''));

            return Response::success([
                'upcoming' => $upcoming,
                'past' => $past,
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
            'client_name' => $booking['client_name'],
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
