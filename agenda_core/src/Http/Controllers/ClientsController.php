<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\ClientRepository;

final class ClientsController
{
    public function __construct(
        private readonly ClientRepository $clientRepo,
    ) {}

    /**
     * GET /v1/clients?business_id=X[&search=term]
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->queryParam('business_id', '0');
        if ($businessId <= 0) {
            return Response::badRequest('business_id is required', $request->traceId);
        }

        $search = $request->queryParam('search');
        $limit = (int) $request->queryParam('limit', '100');
        $offset = (int) $request->queryParam('offset', '0');

        if ($search !== null && $search !== '') {
            $clients = $this->clientRepo->searchByName($businessId, $search, min($limit, 100));
        } else {
            $clients = $this->clientRepo->findByBusinessId($businessId, min($limit, 100), $offset);
        }

        // Format response
        $formatted = array_map(fn(array $c) => $this->formatClient($c), $clients);

        return Response::success([
            'clients' => $formatted,
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

        $updated = $this->clientRepo->findById($clientId);

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

        // Soft delete
        $stmt = $this->clientRepo->db()->getPdo()->prepare(
            'UPDATE clients SET is_archived = 1, updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$clientId]);

        return Response::success(['deleted' => true]);
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
}
