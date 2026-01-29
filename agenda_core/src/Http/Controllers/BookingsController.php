<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\Booking\CreateBooking;
use Agenda\UseCases\Booking\CreateRecurringBooking;
use Agenda\UseCases\Booking\PreviewRecurringBooking;
use Agenda\UseCases\Booking\GetMyBookings;
use Agenda\UseCases\Booking\ModifyRecurringSeries;
use Agenda\UseCases\Booking\ReplaceBooking;
use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Repositories\RecurrenceRuleRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;

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
        private readonly ?ReplaceBooking $replaceBooking = null,
        private readonly ?BookingAuditRepository $auditRepo = null,
        private readonly ?ClientRepository $clientRepo = null,
        private readonly ?CreateRecurringBooking $createRecurringBooking = null,
        private readonly ?PreviewRecurringBooking $previewRecurringBooking = null,
        private readonly ?RecurrenceRuleRepository $recurrenceRuleRepo = null,
        private readonly ?ModifyRecurringSeries $modifyRecurringSeries = null,
    ) {}

    /**

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
     * GET /v1/businesses/{business_id}/bookings/list
     * Protected endpoint - gets paginated list of bookings with filters.
     * 
     * Query params:
     * - location_id: filter by location
     * - staff_id: filter by staff
     * - service_id: filter by service
     * - client_search: search in client name/email/phone
     * - status: filter by status (comma-separated for multiple)
     * - start_date: filter from date (YYYY-MM-DD)
     * - end_date: filter to date (YYYY-MM-DD)
     * - include_past: bool, include past bookings (default: false, only future)
     * - sort_by: 'appointment' or 'created' (default: appointment)
     * - sort_order: 'asc' or 'desc' (default: desc)
     * - limit: max results (default: 50)
     * - offset: pagination offset (default: 0)
     */
    public function listAll(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        // Build filters from query params
        $filters = [];
        
        if ($request->queryParam('location_id') !== null) {
            $filters['location_id'] = (int) $request->queryParam('location_id');
        }
        
        if ($request->queryParam('staff_id') !== null) {
            $filters['staff_id'] = (int) $request->queryParam('staff_id');
        }
        
        if ($request->queryParam('service_id') !== null) {
            $filters['service_id'] = (int) $request->queryParam('service_id');
        }
        
        if ($request->queryParam('client_search') !== null) {
            $filters['client_search'] = trim($request->queryParam('client_search'));
        }
        
        if ($request->queryParam('status') !== null) {
            $statusParam = $request->queryParam('status');
            $filters['status'] = strpos($statusParam, ',') !== false 
                ? explode(',', $statusParam) 
                : $statusParam;
        }
        
        if ($request->queryParam('start_date') !== null) {
            $filters['start_date'] = $request->queryParam('start_date');
        }
        
        if ($request->queryParam('end_date') !== null) {
            $filters['end_date'] = $request->queryParam('end_date');
        }
        
        $filters['include_past'] = $request->queryParam('include_past') === 'true' 
            || $request->queryParam('include_past') === '1';
        
        if ($request->queryParam('sort_by') !== null) {
            $filters['sort_by'] = $request->queryParam('sort_by');
        }
        
        if ($request->queryParam('sort_order') !== null) {
            $filters['sort_order'] = $request->queryParam('sort_order');
        }
        
        $limit = min(100, max(1, (int) ($request->queryParam('limit') ?? 50)));
        $offset = max(0, (int) ($request->queryParam('offset') ?? 0));
        
        $result = $this->bookingRepo->findWithFilters($businessId, $filters, $limit, $offset);
        
        // Format bookings for response
        $formatted = array_map(fn($b) => $this->formatBookingForList($b), $result['bookings']);
        
        return Response::success([
            'bookings' => $formatted,
            'total' => $result['total'],
            'limit' => $limit,
            'offset' => $offset,
        ]);
    }

    /**
     * Format a booking for the list view (includes aggregated fields).
     */
    private function formatBookingForList(array $booking): array
    {
        $clientName = $booking['client_name'];
        if (empty($clientName) && (!empty($booking['client_first_name']) || !empty($booking['client_last_name']))) {
            $clientName = trim(($booking['client_first_name'] ?? '') . ' ' . ($booking['client_last_name'] ?? ''));
        }
        
        $creatorName = null;
        if (!empty($booking['creator_first_name']) || !empty($booking['creator_last_name'])) {
            $creatorName = trim(($booking['creator_first_name'] ?? '') . ' ' . ($booking['creator_last_name'] ?? ''));
        }

        return [
            'id' => (int) $booking['id'],
            'business_id' => (int) $booking['business_id'],
            'location_id' => (int) $booking['location_id'],
            'location_name' => $booking['location_name'] ?? null,
            'client_id' => $booking['client_id'] !== null ? (int) $booking['client_id'] : null,
            'client_name' => $clientName,
            'client_email' => $booking['client_email'] ?? null,
            'client_phone' => $booking['client_phone'] ?? null,
            'notes' => $booking['notes'],
            'status' => $booking['status'],
            'source' => $booking['source'] ?? 'online',
            'first_start_time' => $booking['first_start_time'],
            'last_end_time' => $booking['last_end_time'],
            'total_price' => (float) ($booking['total_price'] ?? 0),
            'service_names' => $booking['service_names'],
            'staff_names' => $booking['staff_names'],
            'created_at' => $booking['created_at'],
            'creator_name' => $creatorName,
            'recurrence_rule_id' => $booking['recurrence_rule_id'] !== null ? (int) $booking['recurrence_rule_id'] : null,
            'recurrence_index' => $booking['recurrence_index'] !== null ? (int) $booking['recurrence_index'] : null,
            'items' => array_map(fn($item) => $this->formatBookingItem($item), $booking['items'] ?? []),
        ];
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
     * GET /v1/bookings/{booking_id}/history
     * Protected endpoint - gets audit history for a booking.
     */
    public function history(Request $request): Response
    {
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($this->auditRepo === null) {
            return Response::error('Audit repository not available', 'server_error', 500);
        }

        $booking = $this->bookingRepo->findById($bookingId);

        if ($booking === null) {
            return Response::notFound('Booking not found');
        }

        // Authorization check: verify user has access to the booking's business
        $businessId = (int) $booking['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Booking not found');
        }

        $events = $this->auditRepo->getEventsByBookingId($bookingId);

        // Format events for response (with actor name resolution)
        $formattedEvents = array_map(fn($e) => $this->formatAuditEvent($e), $events);

        return Response::success([
            'booking_id' => $bookingId,
            'events' => $formattedEvents,
        ]);
    }

    /**
     * GET /v1/customer/bookings/{booking_id}/history
     * Customer endpoint - gets audit history for a booking owned by the customer.
     */
    public function historyCustomer(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($clientId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401);
        }

        if ($this->auditRepo === null) {
            return Response::error('Audit repository not available', 'server_error', 500);
        }

        $booking = $this->bookingRepo->findById($bookingId);

        if ($booking === null) {
            return Response::notFound('Booking not found');
        }

        // Authorization: customer can only see history of their own bookings
        if (empty($booking['client_id']) || (int) $booking['client_id'] !== $clientId) {
            return Response::notFound('Booking not found');
        }

        $events = $this->auditRepo->getEventsByBookingId($bookingId);

        // Format events for response (with actor name resolution)
        $formattedEvents = array_map(fn($e) => $this->formatAuditEvent($e), $events);

        return Response::success([
            'booking_id' => $bookingId,
            'events' => $formattedEvents,
        ]);
    }

    /**
     * Format a single audit event for API response.
     * Uses stored actor_name with fallback to dynamic lookup for old events.
     */
    private function formatAuditEvent(array $event): array
    {
        $actorType = $event['actor_type'];
        $actorId = $event['actor_id'] ? (int) $event['actor_id'] : null;
        
        // Use stored actor_name if available (new events)
        $actorName = $event['actor_name'] ?? null;

        // Fallback to dynamic lookup for old events without stored actor_name
        if ($actorName === null && $actorId !== null) {
            if ($actorType === 'staff' && $this->userRepo !== null) {
                // Staff = user from users table
                $user = $this->userRepo->findByIdUnfiltered($actorId);
                if ($user !== null) {
                    $actorName = trim(($user['first_name'] ?? '') . ' ' . ($user['last_name'] ?? ''));
                    if (empty($actorName)) {
                        $actorName = $user['email'] ?? null;
                    }
                }
            } elseif ($actorType === 'customer' && $this->clientRepo !== null) {
                // Customer = client from clients table
                $client = $this->clientRepo->findByIdUnfiltered($actorId);
                if ($client !== null) {
                    $actorName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));
                    if (empty($actorName)) {
                        $actorName = $client['email'] ?? null;
                    }
                }
            }
        }

        return [
            'id' => (int) $event['id'],
            'booking_id' => (int) $event['booking_id'],
            'event_type' => $event['event_type'],
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'actor_name' => $actorName, // null only if actor deleted AND no stored name
            'correlation_id' => $event['correlation_id'],
            'payload' => json_decode($event['payload_json'], true),
            'created_at' => $event['created_at'],
        ];
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
            
            $booking = $this->updateBooking->execute($bookingId, $userId, $body, $isOperator, false);
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
            
            $this->deleteBooking->execute($bookingId, $userId, $isOperator, false);
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
     * PUT /v1/customer/bookings/{booking_id}
     * Customer endpoint - updates a booking (notes or reschedule with start_time).
     */
    public function updateCustomer(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');
        $businessId = $request->getAttribute('business_id');
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($clientId === null || $businessId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401);
        }

        if ($this->updateBooking === null) {
            return Response::serverError('UpdateBooking use case not initialized');
        }

        $body = $request->getBody();

        if (!isset($body['notes']) && !isset($body['start_time'])) {
            return Response::error(
                'At least one field required: notes or start_time',
                'validation_error',
                400
            );
        }

        if (isset($body['status']) || array_key_exists('client_id', $body)) {
            return Response::error('Field not allowed for customers', 'validation_error', 400);
        }

        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null) {
            return Response::notFound('Booking not found', $request->traceId);
        }
        if ((int) $booking['business_id'] !== (int) $businessId) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        try {
            $updated = $this->updateBooking->execute(
                $bookingId,
                (int) $clientId,
                $body,
                false,
                true
            );
            return Response::success($this->formatBooking($updated));
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
     * DELETE /v1/customer/bookings/{booking_id}
     * Customer endpoint - deletes a booking and all its items.
     */
    public function destroyCustomer(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');
        $businessId = $request->getAttribute('business_id');
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($clientId === null || $businessId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401);
        }

        if ($this->deleteBooking === null) {
            return Response::serverError('DeleteBooking use case not initialized');
        }

        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null) {
            return Response::notFound('Booking not found', $request->traceId);
        }
        if ((int) $booking['business_id'] !== (int) $businessId) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        try {
            $this->deleteBooking->execute($bookingId, (int) $clientId, false, true);
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

        // DEBUG: Log request body
        file_put_contents(__DIR__ . '/../../../logs/debug.log', date('Y-m-d H:i:s') . " storeCustomer body: " . json_encode($body) . "\n", FILE_APPEND);

        // Validate required fields
        if (!isset($body['location_id'])) {
            return Response::error('location_id is required', 'validation_error', 400);
        }

        $locationId = (int) $body['location_id'];

        // Verify location belongs to business
        if ($this->locationRepo !== null) {
            $location = $this->locationRepo->findById($locationId);
            if ($location === null || (int) $location['business_id'] !== $routeBusinessId) {
                return Response::error('Invalid location for this business', 'validation_error', 400);
            }
        }

        // Support both "items" format and "service_ids" format
        $items = null;
        if (isset($body['items']) && is_array($body['items'])) {
            // New format: items with per-service staff and start_time
            $items = [];
            foreach ($body['items'] as $item) {
                if (!isset($item['service_id']) || !isset($item['staff_id']) || !isset($item['start_time'])) {
                    return Response::error(
                        'Each item must have service_id, staff_id, and start_time',
                        'validation_error',
                        400
                    );
                }
                $items[] = [
                    'service_id' => (int) $item['service_id'],
                    'staff_id' => (int) $item['staff_id'],
                    'start_time' => $item['start_time'],
                ];
            }
            if (empty($items)) {
                return Response::error('items array cannot be empty', 'validation_error', 400);
            }
        } elseif (isset($body['service_ids']) && is_array($body['service_ids'])) {
            // Legacy format: service_ids + start_time + optional staff_id
            if (!isset($body['start_time'])) {
                return Response::error('start_time is required', 'validation_error', 400);
            }
        } else {
            return Response::error(
                'Either items array or service_ids array is required',
                'validation_error',
                400
            );
        }

        try {
            // Customer bookings: no past dates, no conflict override
            if ($items !== null) {
                // Use items format
                $booking = $this->createBooking->executeForCustomer(
                    (int) $clientId,
                    $locationId,
                    $routeBusinessId,
                    [
                        'items' => $items,
                        'notes' => $body['notes'] ?? null,
                    ],
                    $idempotencyKey
                );
            } else {
                // Use legacy service_ids format
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
            }

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
            $cancellationPolicyCache = [];

            foreach ($bookings as $booking) {
                $formatted = $this->formatBooking($booking);
                
                // Determine if booking is upcoming or past based on first item start_time
                $startTime = null;
                $policy = $this->bookingRepo->getCancellationPolicyForBooking((int) $booking['id']);
                if ($policy && !empty($policy['earliest_start'])) {
                    $startTime = new \DateTimeImmutable($policy['earliest_start']);
                } elseif (!empty($booking['items'])) {
                    $startTime = new \DateTimeImmutable($booking['items'][0]['start_time']);
                }
                
                if ($startTime !== null) {
                    $cancellationHours = 24;
                    if ($policy) {
                        $cancellationHours = $policy['location_cancellation_hours']
                            ?? $policy['business_cancellation_hours']
                            ?? 24;
                    } else {
                        $locationId = (int) ($booking['location_id'] ?? 0);
                        if ($locationId > 0) {
                            if (!array_key_exists($locationId, $cancellationPolicyCache)) {
                                $policy = $this->locationRepo !== null
                                    ? $this->locationRepo->getCancellationPolicy($locationId)
                                    : ['location_cancellation_hours' => null, 'business_cancellation_hours' => null];
                                $cancellationPolicyCache[$locationId] = $policy;
                            }
                            $policy = $cancellationPolicyCache[$locationId];
                            $cancellationHours = $policy['location_cancellation_hours']
                                ?? $policy['business_cancellation_hours']
                                ?? 24;
                        }
                    }

                    $canModifyUntil = $startTime->modify("-{$cancellationHours} hours");
                    $formatted['can_modify'] = $now < $canModifyUntil;
                    $formatted['can_modify_until'] = $canModifyUntil->format('c');
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

    /**
     * POST /v1/bookings/{booking_id}/replace
     * Protected endpoint (staff) - replaces a booking with a new one.
     * 
     * This is the atomic replace pattern:
     * - Original booking is marked as 'replaced' 
     * - New booking is created and linked
     * - Single "booking_modified" notification sent
     * 
     * Payload: same as store (items or service_ids format)
     * Additional optional fields: reason
     */
    public function replace(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($userId === null) {
            return Response::error('Authentication required', 'unauthorized', 401);
        }

        if ($this->replaceBooking === null) {
            return Response::serverError('ReplaceBooking use case not initialized');
        }

        // Get original booking to check permissions
        $originalBooking = $this->bookingRepo->findById($bookingId);
        if ($originalBooking === null) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        // Check user has access to this business
        $businessId = (int) $originalBooking['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        $body = $request->getBody();
        $reason = $body['reason'] ?? null;

        try {
            $result = $this->replaceBooking->execute(
                $bookingId,
                $body,
                'staff',
                $userId,
                $reason
            );

            return Response::success($result, 200);

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
     * POST /v1/customer/bookings/{booking_id}/replace
     * Customer endpoint - replaces own booking with a new one.
     */
    public function replaceCustomer(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');
        $businessId = $request->getAttribute('business_id');
        $bookingId = (int) $request->getAttribute('booking_id');

        if ($clientId === null || $businessId === null) {
            return Response::error('Customer authentication required', 'unauthorized', 401);
        }

        if ($this->replaceBooking === null) {
            return Response::serverError('ReplaceBooking use case not initialized');
        }

        // Get original booking
        $originalBooking = $this->bookingRepo->findById($bookingId);
        if ($originalBooking === null) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        // Verify booking belongs to this business
        if ((int) $originalBooking['business_id'] !== (int) $businessId) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        // Verify customer owns this booking
        if ((int) ($originalBooking['client_id'] ?? 0) !== (int) $clientId) {
            return Response::forbidden('You can only modify your own bookings', $request->traceId);
        }

        $body = $request->getBody();
        $reason = $body['reason'] ?? null;

        try {
            $result = $this->replaceBooking->execute(
                $bookingId,
                $body,
                'customer',
                (int) $clientId,
                $reason
            );

            return Response::success($result, 200);

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

    // ========================================
    // RECURRING BOOKING METHODS
    // ========================================

    /**
     * POST /v1/locations/{location_id}/bookings/recurring
     * Create a recurring booking series.
     */
    public function storeRecurring(Request $request): Response
    {
        if ($this->createRecurringBooking === null) {
            return Response::error('Recurring bookings not configured', 'not_configured', 500);
        }

        $userId = $request->getAttribute('user_id');
        $locationId = $request->getAttribute('location_id');
        $businessId = $request->getAttribute('business_id');

        if ($userId === null) {
            return Response::error('Authentication required', 'auth_required', 401);
        }

        if ($locationId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        $data = $request->getBody();

        // Validate required fields
        if (!isset($data['service_ids']) || empty($data['service_ids'])) {
            return Response::error('service_ids is required', 'validation_error', 400);
        }

        if (!isset($data['start_time'])) {
            return Response::error('start_time is required', 'validation_error', 400);
        }

        if (!isset($data['client_id'])) {
            return Response::error('client_id is required for recurring bookings', 'validation_error', 400);
        }

        if (!isset($data['recurrence']) || !isset($data['recurrence']['frequency'])) {
            return Response::error('recurrence.frequency is required', 'validation_error', 400);
        }

        // Validate frequency
        $validFrequencies = ['daily', 'weekly', 'monthly', 'custom'];
        if (!in_array($data['recurrence']['frequency'], $validFrequencies)) {
            return Response::error(
                'Invalid frequency. Must be one of: ' . implode(', ', $validFrequencies),
                'validation_error',
                400
            );
        }

        // Validate conflict_strategy if provided
        if (isset($data['recurrence']['conflict_strategy'])) {
            $validStrategies = ['skip', 'force'];
            if (!in_array($data['recurrence']['conflict_strategy'], $validStrategies)) {
                return Response::error(
                    'Invalid conflict_strategy. Must be one of: ' . implode(', ', $validStrategies),
                    'validation_error',
                    400
                );
            }
        }

        try {
            $result = $this->createRecurringBooking->execute(
                userId: (int) $userId,
                locationId: (int) $locationId,
                businessId: (int) $businessId,
                data: $data
            );

            return Response::json([
                'success' => true,
                'recurrence_rule_id' => $result['recurrence_rule_id'],
                'total_requested' => $result['total_requested'],
                'created_count' => $result['created_count'],
                'skipped_count' => $result['skipped_count'],
                'conflict_strategy' => $result['conflict_strategy'],
                'bookings' => $result['bookings'],
                'skipped_dates' => $result['skipped_dates'] ?? [],
            ], 201);

        } catch (BookingException $e) {
            return Response::json([
                'success' => false,
                'error' => [
                    'code' => $e->getCode(),
                    'message' => $e->getMessage(),
                    'details' => $e->getDetails(),
                ],
            ], $e->getHttpStatus());

        } catch (\InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400);

        } catch (\Exception $e) {
            error_log("Error creating recurring booking: " . $e->getMessage());
            return Response::error('An error occurred while creating the recurring booking', 'internal_error', 500);
        }
    }

    /**
     * POST /v1/locations/{location_id}/bookings/recurring/preview
     * Preview a recurring booking series (without creating).
     * Returns all dates with conflict information so user can review and exclude dates.
     */
    public function previewRecurring(Request $request): Response
    {
        if ($this->previewRecurringBooking === null) {
            return Response::error('Recurring bookings not configured', 'not_configured', 500);
        }

        $userId = $request->getAttribute('user_id');
        $locationId = $request->getAttribute('location_id');
        $businessId = $request->getAttribute('business_id');

        if ($userId === null) {
            return Response::error('Authentication required', 'auth_required', 401);
        }

        if ($locationId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        $data = $request->getBody();

        // Validate required fields
        if (!isset($data['service_ids']) || empty($data['service_ids'])) {
            return Response::error('service_ids is required', 'validation_error', 400);
        }

        if (!isset($data['start_time'])) {
            return Response::error('start_time is required', 'validation_error', 400);
        }

        if (!isset($data['client_id'])) {
            return Response::error('client_id is required for recurring bookings', 'validation_error', 400);
        }

        if (!isset($data['recurrence']) || !isset($data['recurrence']['frequency'])) {
            return Response::error('recurrence.frequency is required', 'validation_error', 400);
        }

        try {
            $result = $this->previewRecurringBooking->execute(
                locationId: (int) $locationId,
                businessId: (int) $businessId,
                data: $data
            );

            return Response::json([
                'success' => true,
                'total_dates' => $result['total_dates'],
                'dates' => $result['dates'],
            ], 200);

        } catch (BookingException $e) {
            return Response::json([
                'success' => false,
                'error' => [
                    'code' => $e->getCode(),
                    'message' => $e->getMessage(),
                    'details' => $e->getDetails(),
                ],
            ], $e->getHttpStatus());

        } catch (\InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400);

        } catch (\Exception $e) {
            error_log("Error previewing recurring booking: " . $e->getMessage());
            return Response::error('An error occurred while previewing the recurring booking', 'internal_error', 500);
        }
    }

    /**
     * GET /v1/bookings/recurring/{recurrence_rule_id}
     * Get all bookings in a recurring series.
     */
    public function showRecurringSeries(Request $request): Response
    {
        if ($this->recurrenceRuleRepo === null) {
            return Response::error('Recurring bookings not configured', 'not_configured', 500);
        }

        $userId = $request->getAttribute('user_id');
        $ruleId = (int) $request->getRouteParam('recurrence_rule_id');

        if ($userId === null) {
            return Response::error('Authentication required', 'auth_required', 401);
        }

        // Get recurrence rule
        $rule = $this->recurrenceRuleRepo->findById($ruleId);
        if ($rule === null) {
            return Response::error('Recurrence rule not found', 'not_found', 404);
        }

        // Check business access
        if (!$this->hasBusinessAccess($request, $rule->businessId)) {
            return Response::error('Recurrence rule not found', 'not_found', 404);
        }

        // Get all bookings in the series
        $bookings = $this->bookingRepo->findByRecurrenceRuleId($ruleId);

        // Count conflicts
        $conflictCount = $this->bookingRepo->countConflictsByRecurrenceRuleId($ruleId);

        return Response::json([
            'success' => true,
            'recurrence_rule' => $rule->jsonSerialize(),
            'total_bookings' => count($bookings),
            'conflict_count' => $conflictCount,
            'bookings' => array_map([$this, 'formatBooking'], $bookings),
        ]);
    }

    /**
     * DELETE /v1/bookings/recurring/{recurrence_rule_id}?scope=all|future&from_index=N
     * Cancel recurring bookings.
     */
    public function cancelRecurringSeries(Request $request): Response
    {
        if ($this->recurrenceRuleRepo === null) {
            return Response::error('Recurring bookings not configured', 'not_configured', 500);
        }

        $userId = $request->getAttribute('user_id');
        $ruleId = (int) $request->getRouteParam('recurrence_rule_id');
        $scope = $request->queryParam('scope', 'all'); // 'all' or 'future'
        $fromIndex = (int) $request->queryParam('from_index', '0');

        if ($userId === null) {
            return Response::error('Authentication required', 'auth_required', 401);
        }

        // Get recurrence rule
        $rule = $this->recurrenceRuleRepo->findById($ruleId);
        if ($rule === null) {
            return Response::error('Recurrence rule not found', 'not_found', 404);
        }

        // Check business access
        if (!$this->hasBusinessAccess($request, $rule->businessId)) {
            return Response::error('Recurrence rule not found', 'not_found', 404);
        }

        $cancelledCount = 0;

        if ($scope === 'all') {
            $cancelledCount = $this->bookingRepo->cancelAllRecurrences($ruleId);
        } elseif ($scope === 'future') {
            $cancelledCount = $this->bookingRepo->cancelFutureRecurrences($ruleId, $fromIndex);
        } else {
            return Response::error('Invalid scope. Must be "all" or "future"', 'validation_error', 400);
        }

        return Response::json([
            'success' => true,
            'cancelled_count' => $cancelledCount,
            'scope' => $scope,
            'from_index' => $scope === 'future' ? $fromIndex : null,
        ]);
    }

    /**
     * PATCH /v1/bookings/recurring/{recurrence_rule_id}
     * Modify bookings in a recurring series.
     * 
     * Query params:
     * - scope: 'all' (default) or 'future'
     * - from_index: For scope='future', start from this index (default 0)
     * 
     * Body:
     * - staff_id: Change staff for all/future bookings
     * - notes: Update notes for all/future bookings
     * - time: Change time (HH:MM) for all/future bookings
     */
    public function patchRecurringSeries(Request $request): Response
    {
        if ($this->modifyRecurringSeries === null || $this->recurrenceRuleRepo === null) {
            return Response::error('Recurring bookings not configured', 'not_configured', 500);
        }

        $userId = $request->getAttribute('user_id');
        $ruleId = (int) $request->getRouteParam('recurrence_rule_id');
        $scope = $request->queryParam('scope', 'all');
        $fromIndex = (int) $request->queryParam('from_index', '0');

        if ($userId === null) {
            return Response::error('Authentication required', 'auth_required', 401);
        }

        // Get recurrence rule
        $rule = $this->recurrenceRuleRepo->findById($ruleId);
        if ($rule === null) {
            return Response::error('Recurrence rule not found', 'not_found', 404);
        }

        // Check business access
        if (!$this->hasBusinessAccess($request, $rule->businessId)) {
            return Response::error('Recurrence rule not found', 'not_found', 404);
        }

        // Parse request body
        $body = $request->getBody() ?? [];
        
        // Build changes array
        $changes = [];
        if (isset($body['staff_id'])) {
            $changes['staff_id'] = (int) $body['staff_id'];
        }
        if (array_key_exists('notes', $body)) {
            $changes['notes'] = $body['notes'];
        }
        if (isset($body['time'])) {
            $changes['time'] = $body['time'];
        }

        if (empty($changes)) {
            return Response::error('No changes provided', 'validation_error', 400);
        }

        try {
            $result = $this->modifyRecurringSeries->execute(
                userId: $userId,
                ruleId: $ruleId,
                changes: $changes,
                scope: $scope,
                fromIndex: $fromIndex
            );

            return Response::json([
                'success' => true,
                'modified_count' => $result['modified_count'],
                'scope' => $result['scope'],
                'from_index' => $result['from_index'],
                'changes_applied' => $result['changes_applied'],
            ]);

        } catch (BookingException $e) {
            return Response::error($e->getMessage(), $e->getCode(), 400);
        } catch (\InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400);
        } catch (\Exception $e) {
            error_log("Error modifying recurring series: " . $e->getMessage());
            return Response::error('An error occurred while modifying the recurring series', 'internal_error', 500);
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
            'recurrence_rule_id' => isset($booking['recurrence_rule_id']) ? (int) $booking['recurrence_rule_id'] : null,
            'recurrence_index' => isset($booking['recurrence_index']) ? (int) $booking['recurrence_index'] : null,
            'is_recurrence_parent' => (bool) ($booking['is_recurrence_parent'] ?? false),
            'has_conflict' => (bool) ($booking['has_conflict'] ?? false),
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
