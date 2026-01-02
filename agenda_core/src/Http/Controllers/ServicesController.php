<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class ServicesController
{
    public function __construct(
        private readonly ServiceRepository $serviceRepository,
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
     * GET /v1/services?location_id=X
     * Public endpoint - returns services for a location.
     */
    public function index(Request $request): Response
    {
        $businessId = $request->getAttribute('business_id');
        $locationId = $request->getAttribute('location_id');

        if ($businessId === null || $locationId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        $services = $this->serviceRepository->findByLocationId($locationId, $businessId);
        $categories = $this->serviceRepository->getCategories($businessId);

        // Group services by category
        $grouped = [];
        $uncategorized = [];

        foreach ($services as $service) {
            $formatted = [
                'id' => (int) $service['id'],
                'business_id' => (int) $businessId,
                'name' => $service['name'],
                'description' => $service['description'],
                'duration_minutes' => (int) ($service['duration_minutes'] ?? 0),
                'price' => (float) ($service['price'] ?? 0),
                'color' => $service['color'],
                'is_price_starting_from' => (bool) ($service['is_price_from'] ?? false),
                'category_id' => $service['category_id'] ? (int) $service['category_id'] : null,
                'category_name' => $service['category_name'] ?? null,
                'service_variant_id' => isset($service['service_variant_id']) ? (int) $service['service_variant_id'] : null,
            ];

            if ($service['category_id'] !== null) {
                $categoryId = (int) $service['category_id'];
                if (!isset($grouped[$categoryId])) {
                    $grouped[$categoryId] = [
                        'id' => $categoryId,
                        'name' => $service['category_name'],
                        'services' => [],
                    ];
                }
                $grouped[$categoryId]['services'][] = $formatted;
            } else {
                $uncategorized[] = $formatted;
            }
        }

        // Format categories with their services
        $categoriesFormatted = [];
        foreach ($categories as $category) {
            $categoryId = (int) $category['id'];
            if (isset($grouped[$categoryId])) {
                $categoriesFormatted[] = $grouped[$categoryId];
            }
        }

        // Add uncategorized at the end if any
        if (!empty($uncategorized)) {
            $categoriesFormatted[] = [
                'id' => null,
                'name' => null,
                'services' => $uncategorized,
            ];
        }

        return Response::success([
            'categories' => $categoriesFormatted,
            'services' => array_map(fn($s) => [
                'id' => (int) $s['id'],
                'business_id' => (int) $businessId,
                'name' => $s['name'],
                'description' => $s['description'],
                'duration_minutes' => (int) ($s['duration_minutes'] ?? 0),
                'price' => (float) ($s['price'] ?? 0),
                'color' => $s['color'],
                'is_price_starting_from' => (bool) ($s['is_price_from'] ?? false),
                'category_id' => $s['category_id'] ? (int) $s['category_id'] : null,
                'service_variant_id' => isset($s['service_variant_id']) ? (int) $s['service_variant_id'] : null,
            ], $services),
        ], 200);
    }

    /**
     * POST /v1/locations/{location_id}/services
     * Create a new service for a location. Auth required.
     */
    public function store(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');

        // Get location to verify business access
        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        $businessId = (int) $location['business_id'];

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getParsedBody();
        $name = trim($body['name'] ?? '');
        if (empty($name)) {
            return Response::error('Name is required', 'validation_error', 400);
        }

        $service = $this->serviceRepository->create(
            businessId: $businessId,
            locationId: $locationId,
            name: $name,
            categoryId: isset($body['category_id']) ? (int) $body['category_id'] : null,
            description: $body['description'] ?? null,
            durationMinutes: (int) ($body['duration_minutes'] ?? 30),
            price: (float) ($body['price'] ?? 0),
            colorHex: $body['color'] ?? $body['color_hex'] ?? null,
            isBookableOnline: (bool) ($body['is_bookable_online'] ?? true),
            isPriceStartingFrom: (bool) ($body['is_price_starting_from'] ?? false)
        );

        return Response::success(['service' => $this->formatService($service, $businessId)], 201);
    }

    /**
     * PUT /v1/services/{id}
     * Update a service. Auth required.
     */
    public function update(Request $request): Response
    {
        $serviceId = (int) $request->getRouteParam('id');
        
        // Get service to verify ownership
        $existingService = $this->serviceRepository->findServiceById($serviceId);
        if (!$existingService) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $businessId = (int) $existingService['business_id'];

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $body = $request->getParsedBody();
        $locationId = isset($body['location_id']) ? (int) $body['location_id'] : null;

        if (!$locationId) {
            return Response::error('location_id is required', 'missing_location', 400);
        }

        // Verify location belongs to same business
        $location = $this->locationRepo->findById($locationId);
        if (!$location || (int) $location['business_id'] !== $businessId) {
            return Response::error('Invalid location_id', 'validation_error', 400);
        }

        $service = $this->serviceRepository->update(
            serviceId: $serviceId,
            locationId: $locationId,
            name: $body['name'] ?? null,
            categoryId: array_key_exists('category_id', $body) ? ($body['category_id'] ? (int) $body['category_id'] : null) : null,
            description: $body['description'] ?? null,
            durationMinutes: isset($body['duration_minutes']) ? (int) $body['duration_minutes'] : null,
            price: isset($body['price']) ? (float) $body['price'] : null,
            colorHex: $body['color'] ?? $body['color_hex'] ?? null,
            isBookableOnline: isset($body['is_bookable_online']) ? (bool) $body['is_bookable_online'] : null,
            isPriceStartingFrom: isset($body['is_price_starting_from']) ? (bool) $body['is_price_starting_from'] : null,
            sortOrder: isset($body['sort_order']) ? (int) $body['sort_order'] : null
        );

        if (!$service) {
            return Response::error('Service not found or unauthorized', 'not_found', 404);
        }

        return Response::success(['service' => $this->formatService($service, $businessId)]);
    }

    /**
     * DELETE /v1/services/{id}
     * Soft delete a service. Auth required.
     */
    public function destroy(Request $request): Response
    {
        $serviceId = (int) $request->getRouteParam('id');

        // Get service to verify ownership
        $existingService = $this->serviceRepository->findServiceById($serviceId);
        if (!$existingService) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $businessId = (int) $existingService['business_id'];

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $this->serviceRepository->delete($serviceId);

        return Response::success(['message' => 'Service deleted successfully']);
    }

    // ===== Categories =====

    /**
     * GET /v1/businesses/{business_id}/categories
     * Get all service categories for a business.
     */
    public function indexCategories(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        // Authorization check (middleware should handle this, but double-check)
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $categories = $this->serviceRepository->getCategories($businessId);

        return Response::success([
            'categories' => array_map(fn($c) => [
                'id' => (int) $c['id'],
                'business_id' => (int) $c['business_id'],
                'name' => $c['name'],
                'description' => $c['description'],
                'sort_order' => (int) $c['sort_order'],
            ], $categories),
        ]);
    }

    /**
     * POST /v1/businesses/{business_id}/categories
     * Create a new service category.
     */
    public function storeCategory(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        // Authorization check (middleware should handle this, but double-check)
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getParsedBody();
        $name = trim($body['name'] ?? '');
        if (empty($name)) {
            return Response::error('Name is required', 'validation_error', 400);
        }

        $category = $this->serviceRepository->createCategory(
            businessId: $businessId,
            name: $name,
            description: $body['description'] ?? null
        );

        return Response::success(['category' => $category], 201);
    }

    /**
     * PUT /v1/categories/{id}
     * Update a service category.
     */
    public function updateCategory(Request $request): Response
    {
        $categoryId = (int) $request->getRouteParam('id');

        // Get category to verify ownership
        $existingCategory = $this->serviceRepository->getCategoryById($categoryId);
        if (!$existingCategory) {
            return Response::notFound('Category not found', $request->traceId);
        }

        $businessId = (int) $existingCategory['business_id'];

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Category not found', $request->traceId);
        }

        $body = $request->getParsedBody();

        $category = $this->serviceRepository->updateCategory(
            categoryId: $categoryId,
            name: $body['name'] ?? null,
            description: $body['description'] ?? null,
            sortOrder: isset($body['sort_order']) ? (int) $body['sort_order'] : null
        );

        if (!$category) {
            return Response::error('Category not found', 'not_found', 404);
        }

        return Response::success(['category' => [
            'id' => (int) $category['id'],
            'business_id' => (int) $category['business_id'],
            'name' => $category['name'],
            'description' => $category['description'],
            'sort_order' => (int) $category['sort_order'],
        ]]);
    }

    /**
     * DELETE /v1/categories/{id}
     * Delete a service category.
     */
    public function destroyCategory(Request $request): Response
    {
        $categoryId = (int) $request->getRouteParam('id');

        // Get category to verify ownership
        $existingCategory = $this->serviceRepository->getCategoryById($categoryId);
        if (!$existingCategory) {
            return Response::notFound('Category not found', $request->traceId);
        }

        $businessId = (int) $existingCategory['business_id'];

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Category not found', $request->traceId);
        }

        $this->serviceRepository->deleteCategory($categoryId);

        return Response::success(['message' => 'Category deleted successfully']);
    }

    private function formatService(array $service, int $businessId): array
    {
        return [
            'id' => (int) $service['id'],
            'business_id' => (int) $businessId,
            'name' => $service['name'],
            'description' => $service['description'],
            'duration_minutes' => (int) ($service['duration_minutes'] ?? 0),
            'price' => (float) ($service['price'] ?? 0),
            'color' => $service['color'],
            'is_price_starting_from' => (bool) ($service['is_price_from'] ?? false),
            'category_id' => $service['category_id'] ? (int) $service['category_id'] : null,
            'service_variant_id' => isset($service['service_variant_id']) ? (int) $service['service_variant_id'] : null,
            'sort_order' => (int) ($service['sort_order'] ?? 0),
        ];
    }
}
