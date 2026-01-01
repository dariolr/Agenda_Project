<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\ServiceRepository;

final class ServicesController
{
    public function __construct(
        private readonly ServiceRepository $serviceRepository,
    ) {}

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
                'category_id' => $s['category_id'] ? (int) $s['category_id'] : null,
                'service_variant_id' => isset($s['service_variant_id']) ? (int) $s['service_variant_id'] : null,
            ], $services),
        ], 200);
    }
}
