<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\LocationRepository;

final class LocationsController
{
    public function __construct(
        private readonly LocationRepository $locationRepo,
    ) {}

    /**
     * GET /v1/businesses/{business_id}/locations
     * List all locations for a business
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        $locations = $this->locationRepo->findByBusinessId($businessId);

        return Response::success([
            'data' => array_map(fn($l) => $this->formatLocation($l), $locations),
        ]);
    }

    /**
     * GET /v1/locations/{id}
     * Get a single location by ID
     */
    public function show(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('id');

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        return Response::success($this->formatLocation($location));
    }

    private function formatLocation(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'name' => $row['name'],
            'address' => $row['address'],
            'city' => $row['city'],
            'region' => $row['region'],
            'country' => $row['country'],
            'phone' => $row['phone'],
            'email' => $row['email'],
            'latitude' => $row['latitude'] ? (float) $row['latitude'] : null,
            'longitude' => $row['longitude'] ? (float) $row['longitude'] : null,
            'currency' => $row['currency'],
            'timezone' => $row['timezone'] ?? 'Europe/Rome',
            'is_default' => (bool) $row['is_default'],
            'is_active' => (bool) $row['is_active'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
        ];
    }
}
