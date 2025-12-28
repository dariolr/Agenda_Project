<?php

declare(strict_types=1);

namespace Agenda\Http\Middleware;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\LocationRepository;

final class LocationContextMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly LocationRepository $locationRepo,
        private readonly string $source, // 'path' or 'query'
    ) {}

    public function handle(Request $request): ?Response
    {
        $locationId = $this->extractLocationId($request);
        
        if ($locationId === null) {
            return Response::validationError('location_id is required', $request->traceId);
        }

        $location = $this->locationRepo->findById($locationId);
        
        if ($location === null) {
            return Response::notFound('Location not found', $request->traceId);
        }

        if (!$location['is_active']) {
            return Response::notFound('Location is not active', $request->traceId);
        }

        // Inject business_id and location_id into request context
        // business_id is ALWAYS derived from location, NEVER from JWT or payload
        $request->setAttribute('location_id', (int) $location['id']);
        $request->setAttribute('business_id', (int) $location['business_id']);

        return null;
    }

    private function extractLocationId(Request $request): ?int
    {
        if ($this->source === 'path') {
            $value = $request->getAttribute('location_id');
        } else {
            $value = $request->query['location_id'] ?? null;
        }

        if ($value === null || $value === '') {
            return null;
        }

        return (int) $value;
    }
}
