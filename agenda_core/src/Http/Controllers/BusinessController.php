<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessRepository;

final class BusinessController
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
    ) {}

    /**
     * GET /v1/businesses
     * List all active businesses
     */
    public function index(Request $request): Response
    {
        $businesses = $this->businessRepo->findAll();

        return Response::success([
            'data' => array_map(fn($b) => $this->formatBusiness($b), $businesses),
        ]);
    }

    /**
     * GET /v1/businesses/{id}
     * Get a single business by ID
     */
    public function show(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('id');

        $business = $this->businessRepo->findById($businessId);
        if (!$business) {
            return Response::notFound('Business not found', $request->traceId);
        }

        return Response::success($this->formatBusiness($business));
    }

    /**
     * GET /v1/businesses/by-slug/{slug}
     * Get a single business by slug (PUBLIC - no auth required)
     * Used for subdomain-based booking pages
     */
    public function showBySlug(Request $request): Response
    {
        $slug = $request->getRouteParam('slug');

        if (!$slug || !preg_match('/^[a-z0-9-]+$/', $slug)) {
            return Response::error('Invalid slug format', 'validation_error', 400, $request->traceId);
        }

        $business = $this->businessRepo->findBySlug($slug);
        if (!$business) {
            return Response::notFound('Business not found', $request->traceId);
        }

        if (!$business['is_active']) {
            return Response::notFound('Business not found', $request->traceId);
        }

        return Response::success($this->formatBusinessPublic($business));
    }

    /**
     * Format business for public display (limited fields)
     */
    private function formatBusinessPublic(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'name' => $row['name'],
            'slug' => $row['slug'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'timezone' => $row['timezone'],
            'currency' => $row['currency'],
        ];
    }

    private function formatBusiness(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'name' => $row['name'],
            'slug' => $row['slug'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'timezone' => $row['timezone'],
            'currency' => $row['currency'],
            'is_active' => (bool) $row['is_active'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
        ];
    }
}
