<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Domain\Helpers\DataMasker;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class ClientsController
{
    public function __construct(
        private readonly ClientRepository $clientRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly BookingRepository $bookingRepo,
    ) {}

    /**
     * Check if authenticated user has clients permission in the given business.
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

        // Normal user: enforce clients permission
        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_clients', false);
    }

    /**
     * GET /v1/clients?business_id=X[&search=term][&limit=N][&offset=N]
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->queryParam('business_id', '0');
        if ($businessId <= 0) {
            return Response::badRequest('business_id is required', $request->traceId);
        }

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $search = $request->queryParam('search');
        $limit = (int) $request->queryParam('limit', '100');
        $offset = (int) $request->queryParam('offset', '0');
        $sort = $request->queryParam('sort', 'name_asc'); // name_asc, name_desc, last_name_asc, last_name_desc, created_asc, created_desc
        $masked = $request->queryParam('masked', 'false') === 'true';

        if ($search !== null && $search !== '') {
            $clients = $this->clientRepo->searchByName($businessId, $search, $limit > 0 ? $limit : null, $offset, $sort);
            $total = $this->clientRepo->countBySearch($businessId, $search);
        } else {
            $clients = $this->clientRepo->findByBusinessId($businessId, $limit > 0 ? $limit : null, $offset, $sort);
            $total = $this->clientRepo->countByBusinessId($businessId);
        }

        // Format response (masked for list view, full for detail)
        $formatted = array_map(
            fn(array $c) => $masked ? $this->formatClientMasked($c) : $this->formatClient($c),
            $clients
        );

        return Response::success([
            'clients' => $formatted,
            'total' => $total,
            'limit' => $limit,
            'offset' => $offset,
            'has_more' => ($offset + count($clients)) < $total,
        ]);
    }

    /**
     * GET /v1/clients/{id}
     */
    public function show(Request $request): Response
    {
        $clientId = (int) $request->getAttribute('id');

        $client = $this->clientRepo->findById($clientId);

        if ($client === null) {
            return Response::notFound('Client not found');
        }

        // Authorization check: verify user has access to the client's business
        $businessId = (int) $client['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Client not found'); // Return 404 to avoid leaking existence
        }

        return Response::success($this->formatClient($client));
    }

    /**
     * POST /v1/clients
     */
    public function store(Request $request): Response
    {
        $body = $request->getBody();

        $businessId = (int) ($body['business_id'] ?? 0);
        if ($businessId <= 0) {
            return Response::error('business_id is required', 'validation_error', 400);
        }

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        // Create client
        $stmt = $this->clientRepo->db()->getPdo()->prepare(
            'INSERT INTO clients (business_id, first_name, last_name, email, phone, notes, is_archived)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $body['first_name'] ?? null,
            $body['last_name'] ?? null,
            $body['email'] ?? null,
            $body['phone'] ?? null,
            $body['notes'] ?? null,
            $body['is_archived'] ?? false,
        ]);

        $clientId = (int) $this->clientRepo->db()->getPdo()->lastInsertId();
        $client = $this->clientRepo->findById($clientId);

        return Response::created($this->formatClient($client));
    }

    /**
     * PUT /v1/clients/{id}
     */
    public function update(Request $request): Response
    {
        $clientId = (int) $request->getAttribute('id');
        $body = $request->getBody();

        $client = $this->clientRepo->findById($clientId);
        if ($client === null) {
            return Response::notFound('Client not found');
        }

        // Authorization check: verify user has access to the client's business
        $businessId = (int) $client['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Client not found'); // Return 404 to avoid leaking existence
        }

        // Update allowed fields
        $data = [];
        foreach (['first_name', 'last_name', 'email', 'phone', 'notes'] as $field) {
            if (array_key_exists($field, $body)) {
                $data[$field] = $body[$field];
            }
        }

        if (!empty($data)) {
            $this->clientRepo->update($clientId, $data);
        }

        // Handle is_archived separately
        if (array_key_exists('is_archived', $body)) {
            $stmt = $this->clientRepo->db()->getPdo()->prepare(
                'UPDATE clients SET is_archived = ?, updated_at = NOW() WHERE id = ?'
            );
            $stmt->execute([(bool) $body['is_archived'], $clientId]);
        }

        // Use findByIdUnfiltered to return client even if just archived
        $updated = $this->clientRepo->findByIdUnfiltered($clientId);

        return Response::success($this->formatClient($updated));
    }

    /**
     * DELETE /v1/clients/{id}
     */
    public function destroy(Request $request): Response
    {
        $clientId = (int) $request->getAttribute('id');

        $client = $this->clientRepo->findById($clientId);
        if ($client === null) {
            return Response::notFound('Client not found');
        }

        // Authorization check: verify user has access to the client's business
        $businessId = (int) $client['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Client not found'); // Return 404 to avoid leaking existence
        }

        // Soft delete
        $stmt = $this->clientRepo->db()->getPdo()->prepare(
            'UPDATE clients SET is_archived = 1, updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$clientId]);

        return Response::success(['deleted' => true]);
    }

    /**
     * GET /v1/clients/{id}/appointments
     * Returns all appointments for a specific client.
     */
    public function appointments(Request $request): Response
    {
        $clientId = (int) $request->getRouteParam('id');
        if ($clientId <= 0) {
            return Response::badRequest('Invalid client ID', $request->traceId);
        }

        // Verify client exists
        $client = $this->clientRepo->findById($clientId);
        if ($client === null) {
            return Response::notFound('Client not found');
        }

        // Authorization check: verify user has access to the client's business
        $businessId = (int) $client['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Client not found');
        }

        try {
            // Get all bookings for this client
            $bookings = $this->bookingRepo->findByClientId($clientId, 200);

            $now = new \DateTimeImmutable();
            $upcoming = [];
            $past = [];

            foreach ($bookings as $booking) {
                foreach ($booking['items'] ?? [] as $item) {
                    $startTime = new \DateTimeImmutable($item['start_time']);
                    $formatted = $this->formatAppointmentItem($item, $booking);

                    if ($startTime > $now) {
                        $upcoming[] = $formatted;
                    } else {
                        $past[] = $formatted;
                    }
                }
            }

            // Sort upcoming by start_time ascending, past by start_time descending
            usort($upcoming, fn($a, $b) => $a['start_time'] <=> $b['start_time']);
            usort($past, fn($a, $b) => $b['start_time'] <=> $a['start_time']);

            return Response::success([
                'upcoming' => $upcoming,
                'past' => $past,
            ]);

        } catch (\Exception $e) {
            return Response::serverError($e->getMessage());
        }
    }

    /**
     * Format a booking item as an appointment for client history.
     */
    private function formatAppointmentItem(array $item, array $booking): array
    {
        return [
            'id' => (int) $item['id'],
            'booking_id' => (int) $booking['id'],
            'location_id' => (int) $booking['location_id'],
            'service_id' => (int) $item['service_id'],
            'service_variant_id' => $item['service_variant_id'] ? (int) $item['service_variant_id'] : null,
            'staff_id' => (int) $item['staff_id'],
            'start_time' => $item['start_time'],
            'end_time' => $item['end_time'],
            'duration_minutes' => (int) ($item['duration_minutes'] ?? 0),
            'service_name' => $item['service_name'] ?? '',
            'staff_name' => $item['staff_name'] ?? '',
            'price' => (float) ($item['price'] ?? 0),
            'status' => $booking['status'] ?? 'confirmed',
            'recurrence_rule_id' => $booking['recurrence_rule_id'] ? (int) $booking['recurrence_rule_id'] : null,
            'recurrence_index' => $booking['recurrence_index'] ? (int) $booking['recurrence_index'] : null,
        ];
    }

    private function formatClient(array $client): array
    {
        return [
            'id' => (int) $client['id'],
            'business_id' => (int) $client['business_id'],
            'user_id' => $client['user_id'] ? (int) $client['user_id'] : null,
            'first_name' => $client['first_name'],
            'last_name' => $client['last_name'],
            'email' => $client['email'],
            'phone' => $client['phone'],
            'notes' => $client['notes'],
            'is_archived' => (bool) ($client['is_archived'] ?? false),
            'created_at' => $client['created_at'],
            'updated_at' => $client['updated_at'],
        ];
    }

    /**
     * Format client with masked personal data (for list views).
     */
    private function formatClientMasked(array $client): array
    {
        return [
            'id' => (int) $client['id'],
            'business_id' => (int) $client['business_id'],
            'user_id' => $client['user_id'] ? (int) $client['user_id'] : null,
            'first_name' => $client['first_name'],
            'last_name' => $client['last_name'],
            'email' => null, // Hidden in masked mode
            'email_masked' => DataMasker::maskEmail($client['email']),
            'phone' => null, // Hidden in masked mode
            'phone_masked' => DataMasker::maskPhone($client['phone']),
            'notes' => null, // Hidden in masked mode
            'is_archived' => (bool) ($client['is_archived'] ?? false),
            'created_at' => $client['created_at'],
            'updated_at' => $client['updated_at'],
        ];
    }
}
