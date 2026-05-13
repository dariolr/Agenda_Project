<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Domain\Helpers\ColorHex;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\ServiceVariantResourceRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\ServicePackageRepository;
use Agenda\Infrastructure\Repositories\PopularServiceRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\BookingDirectLinkRepository;
use Agenda\Infrastructure\Authorization\LocationAuthorizationService;
use DomainException;

final class ServicesController
{
    public function __construct(
        private readonly ServiceRepository $serviceRepository,
        private readonly ServiceVariantResourceRepository $variantResourceRepo,
        private readonly LocationRepository $locationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly ServicePackageRepository $packageRepo,
        private readonly PopularServiceRepository $popularServiceRepo,
        private readonly StaffRepository $staffRepo,
        private readonly ?BookingDirectLinkRepository $directLinkRepo = null,
        private readonly ?LocationAuthorizationService $locationAuth = null,
    ) {}

    /**
     * Check if authenticated user can read business data in the given business.
     */
    private function hasBusinessReadAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        // Superadmin has access to all businesses
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        // Normal user: any active business operator can read.
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    /**
     * Check if authenticated user has services manage permission in the given business.
     */
    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        // Normal user: enforce services permission
        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_services', false);
    }

    private function forbiddenLocationScope(Request $request): Response
    {
        return Response::error(
            LocationAuthorizationService::ERROR_CODE,
            LocationAuthorizationService::ERROR_CODE,
            403,
            $request->traceId
        );
    }

    private function requireBusinessWideLocationScope(Request $request, int $businessId): ?Response
    {
        if ($this->locationAuth === null || $this->locationAuth->canAccessAllBusinessLocations($request, $businessId)) {
            return null;
        }

        return $this->forbiddenLocationScope($request);
    }

    /**
     * @param int[] $locationIds
     */
    private function requireLocationScope(Request $request, int $businessId, array $locationIds): ?Response
    {
        if ($this->locationAuth === null) {
            return null;
        }

        try {
            $this->locationAuth->assertCanAccessOnlyLocations($request, $businessId, $locationIds);
            return null;
        } catch (DomainException $e) {
            if ($e->getMessage() === LocationAuthorizationService::ERROR_CODE) {
                return $this->forbiddenLocationScope($request);
            }
            throw $e;
        }
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

        $directLinkScope = $this->directLinkScopeFromQuery($request, (int) $businessId, (int) $locationId);
        if ($directLinkScope === false) {
            return Response::error('Link di prenotazione non valido', 'direct_link_location_mismatch', 409);
        }
        $services = $this->serviceRepository->findPublicByLocationId($locationId, $businessId, $directLinkScope);
        $categories = $this->serviceRepository->getCategories($businessId, $directLinkScope);

        // Collect all variant IDs to load resource requirements in batch
        $variantIds = [];
        foreach ($services as $service) {
            if (isset($service['service_variant_id']) && $service['service_variant_id']) {
                $variantIds[] = (int) $service['service_variant_id'];
            }
        }

        // Load all resource requirements in one query
        $resourceRequirementsByVariant = $this->variantResourceRepo->findByVariantIds($variantIds);

        // Group services by category
        $grouped = [];
        $uncategorized = [];
        $categoriesById = [];
        foreach ($categories as $category) {
            $categoriesById[(int) $category['id']] = $category;
        }

        foreach ($services as $service) {
            $variantId = isset($service['service_variant_id']) ? (int) $service['service_variant_id'] : null;
            $requirements = $variantId ? ($resourceRequirementsByVariant[$variantId] ?? []) : [];

            $formatted = [
                'id' => (int) $service['id'],
                'business_id' => (int) $businessId,
                'name' => $service['name'],
                'description' => $service['description'],
                'duration_minutes' => (int) ($service['duration_minutes'] ?? 0),
                'processing_time' => (int) ($service['processing_time'] ?? 0),
                'blocked_time' => (int) ($service['blocked_time'] ?? 0),
                'price' => (float) ($service['price'] ?? 0),
                'color' => $service['color'],
                'is_active' => (bool) ($service['is_active'] ?? true),
                'is_bookable_online' => (bool) ($service['is_bookable_online'] ?? true),
                'online_visibility' => (string) ($service['online_visibility'] ?? 'public'),
                'is_price_starting_from' => (bool) ($service['is_price_from'] ?? false),
                'parallel_capacity' => (int) ($service['parallel_capacity'] ?? 1),
                'category_id' => $service['category_id'] ? (int) $service['category_id'] : null,
                'category_name' => $service['category_name'] ?? null,
                'service_variant_id' => $variantId,
                'sort_order' => (int) ($service['sort_order'] ?? 0),
                'online_payment_required' => (bool) ($service['online_payment_required'] ?? false),
                'resource_requirements' => array_map(fn($req) => [
                    'id' => (int) $req['id'],
                    'resource_id' => (int) $req['resource_id'],
                    'resource_name' => $req['resource_name'],
                    'quantity' => (int) $req['quantity'],
                ], $requirements),
            ];

            if ($service['category_id'] !== null) {
                $categoryId = (int) $service['category_id'];
                if (!isset($grouped[$categoryId])) {
                    $category = $categoriesById[$categoryId] ?? [];
                    $grouped[$categoryId] = [
                        'id' => $categoryId,
                        'business_id' => (int) ($category['business_id'] ?? $businessId),
                        'name' => $category['name'] ?? $service['category_name'],
                        'description' => $category['description'] ?? null,
                        'sort_order' => (int) ($category['sort_order'] ?? 0),
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
        $directCategoryId = $directLinkScope !== null
            && ($directLinkScope['target_type'] ?? null) === BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY
            ? (int) ($directLinkScope['target_id'] ?? 0)
            : null;
        foreach ($categories as $category) {
            $categoryId = (int) $category['id'];
            if (isset($grouped[$categoryId]) || $categoryId === $directCategoryId) {
                $categoriesFormatted[] = [
                    'id' => $categoryId,
                    'business_id' => (int) ($category['business_id'] ?? $businessId),
                    'name' => (string) ($category['name'] ?? ''),
                    'description' => $category['description'] ?? null,
                    'sort_order' => (int) ($category['sort_order'] ?? 0),
                    'services' => $grouped[$categoryId]['services'] ?? [],
                ];
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
            'services' => array_map(function($s) use ($businessId, $resourceRequirementsByVariant) {
                $variantId = isset($s['service_variant_id']) ? (int) $s['service_variant_id'] : null;
                $requirements = $variantId ? ($resourceRequirementsByVariant[$variantId] ?? []) : [];
                
                return [
                    'id' => (int) $s['id'],
                    'business_id' => (int) $businessId,
                    'name' => $s['name'],
                    'description' => $s['description'],
                    'duration_minutes' => (int) ($s['duration_minutes'] ?? 0),
                    'processing_time' => (int) ($s['processing_time'] ?? 0),
                    'blocked_time' => (int) ($s['blocked_time'] ?? 0),
                    'price' => (float) ($s['price'] ?? 0),
                    'color' => $s['color'],
                    'is_active' => (bool) ($s['is_active'] ?? true),
                    'is_bookable_online' => (bool) ($s['is_bookable_online'] ?? true),
                    'online_visibility' => (string) ($s['online_visibility'] ?? 'public'),
                    'is_price_starting_from' => (bool) ($s['is_price_from'] ?? false),
                    'parallel_capacity' => (int) ($s['parallel_capacity'] ?? 1),
                    'category_id' => $s['category_id'] ? (int) $s['category_id'] : null,
                    'service_variant_id' => $variantId,
                    'sort_order' => (int) ($s['sort_order'] ?? 0),
                    'resource_requirements' => array_map(fn($req) => [
                        'id' => (int) $req['id'],
                        'resource_id' => (int) $req['resource_id'],
                        'resource_name' => $req['resource_name'],
                        'quantity' => (int) $req['quantity'],
                    ], $requirements),
                ];
            }, $services),
        ], 200);
    }

    /**
     * GET /v1/locations/{location_id}/services
     * Admin endpoint - returns all active services for the location.
     */
    public function indexByLocation(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        $businessId = (int) $location['business_id'];
        if (!$this->hasBusinessReadAccess($request, $businessId)) {
            return Response::notFound('Location not found', $request->traceId);
        }

        $services = $this->serviceRepository->findAdminByLocationId($locationId, $businessId);
        $categories = $this->serviceRepository->getCategories($businessId, null, true);

        $variantIds = [];
        foreach ($services as $service) {
            if (isset($service['service_variant_id']) && $service['service_variant_id']) {
                $variantIds[] = (int) $service['service_variant_id'];
            }
        }

        $resourceRequirementsByVariant = $this->variantResourceRepo->findByVariantIds($variantIds);

        return Response::success([
            'categories' => array_map(fn($category) => [
                'id' => (int) $category['id'],
                'business_id' => (int) ($category['business_id'] ?? $businessId),
                'name' => (string) ($category['name'] ?? ''),
                'description' => $category['description'] ?? null,
                'sort_order' => (int) ($category['sort_order'] ?? 0),
                'services' => [],
            ], $categories),
            'services' => array_map(function ($service) use ($businessId, $resourceRequirementsByVariant) {
                $variantId = isset($service['service_variant_id']) ? (int) $service['service_variant_id'] : null;
                $requirements = $variantId ? ($resourceRequirementsByVariant[$variantId] ?? []) : [];

                return [
                    'id' => (int) $service['id'],
                    'business_id' => (int) $businessId,
                    'name' => $service['name'],
                    'description' => $service['description'],
                    'duration_minutes' => (int) ($service['duration_minutes'] ?? 0),
                    'processing_time' => (int) ($service['processing_time'] ?? 0),
                    'blocked_time' => (int) ($service['blocked_time'] ?? 0),
                    'price' => (float) ($service['price'] ?? 0),
                    'color' => $service['color'],
                    'is_active' => (bool) ($service['is_active'] ?? true),
                    'is_bookable_online' => (bool) ($service['is_bookable_online'] ?? true),
                    'online_visibility' => (string) ($service['online_visibility'] ?? 'public'),
                    'is_price_starting_from' => (bool) ($service['is_price_from'] ?? false),
                    'parallel_capacity' => (int) ($service['parallel_capacity'] ?? 1),
                    'category_id' => $service['category_id'] ? (int) $service['category_id'] : null,
                    'service_variant_id' => $variantId,
                    'sort_order' => (int) ($service['sort_order'] ?? 0),
                    'online_payment_required' => (bool) ($service['online_payment_required'] ?? false),
                    'resource_requirements' => array_map(fn($req) => [
                        'id' => (int) $req['id'],
                        'resource_id' => (int) $req['resource_id'],
                        'resource_name' => $req['resource_name'],
                        'quantity' => (int) $req['quantity'],
                    ], $requirements),
                ];
            }, $services),
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

        $body = $request->getBody();
        $onlineVisibility = $this->validatedOnlineVisibility($body, $request);
        if ($onlineVisibility instanceof Response) {
            return $onlineVisibility;
        }
        $name = trim($body['name'] ?? '');
        if (empty($name)) {
            return Response::error('Name is required', 'validation_error', 400);
        }
        $rawColor = array_key_exists('color', $body) ? $body['color'] : ($body['color_hex'] ?? null);
        $colorHexResult = ColorHex::normalizeOptional($rawColor, 'color');
        if (isset($colorHexResult['error'])) {
            return Response::error((string) $colorHexResult['error'], 'validation_error', 400, $request->traceId);
        }
        $colorHex = $colorHexResult['value'] ?? null;
        $parallelCapacity = $this->validateParallelCapacity($body, true);
        if (is_string($parallelCapacity)) {
            return Response::error($parallelCapacity, 'validation_error', 400, $request->traceId);
        }

        $service = $this->serviceRepository->create(
            businessId: $businessId,
            locationId: $locationId,
            name: $name,
            categoryId: isset($body['category_id']) ? (int) $body['category_id'] : null,
            description: $body['description'] ?? null,
            durationMinutes: (int) ($body['duration_minutes'] ?? 30),
            price: (float) ($body['price'] ?? 0),
            colorHex: $colorHex,
            isBookableOnline: (bool) ($body['is_bookable_online'] ?? true),
            onlineVisibility: $onlineVisibility,
            isPriceStartingFrom: (bool) ($body['is_price_starting_from'] ?? false),
            processingTime: isset($body['processing_time']) ? (int) $body['processing_time'] : null,
            blockedTime: isset($body['blocked_time']) ? (int) $body['blocked_time'] : null,
            parallelCapacity: $parallelCapacity,
            onlinePaymentRequired: (bool) ($body['online_payment_required'] ?? false)
        );
        $this->createDirectLinkIfNeeded((int) $businessId, $service, $onlineVisibility);

        return Response::success(['service' => $this->formatService($service, $businessId)], 201);
    }

    /**
     * POST /v1/businesses/{business_id}/services
     * Create a new service with variants for multiple locations. Auth required.
     */
    public function storeMultiLocation(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody();
        $onlineVisibility = $this->validatedOnlineVisibility($body, $request);
        if ($onlineVisibility instanceof Response) {
            return $onlineVisibility;
        }
        $name = trim($body['name'] ?? '');
        if (empty($name)) {
            return Response::error('Name is required', 'validation_error', 400);
        }
        $rawColor = array_key_exists('color', $body) ? $body['color'] : ($body['color_hex'] ?? null);
        $colorHexResult = ColorHex::normalizeOptional($rawColor, 'color');
        if (isset($colorHexResult['error'])) {
            return Response::error((string) $colorHexResult['error'], 'validation_error', 400, $request->traceId);
        }
        $colorHex = $colorHexResult['value'] ?? null;
        $parallelCapacity = $this->validateParallelCapacity($body, true);
        if (is_string($parallelCapacity)) {
            return Response::error($parallelCapacity, 'validation_error', 400, $request->traceId);
        }

        $locationIds = $body['location_ids'] ?? [];
        if (empty($locationIds) || !is_array($locationIds)) {
            return Response::error('location_ids is required and must be a non-empty array', 'validation_error', 400);
        }

        // Verify all locations belong to this business
        foreach ($locationIds as $locationId) {
            $location = $this->locationRepo->findById((int) $locationId);
            if (!$location || (int) $location['business_id'] !== $businessId) {
                return Response::error("Invalid location_id: $locationId", 'validation_error', 400);
            }
        }
        $locationScopeError = $this->requireLocationScope($request, $businessId, array_map('intval', $locationIds));
        if ($locationScopeError !== null) {
            return $locationScopeError;
        }

        $service = $this->serviceRepository->createMultiLocation(
            businessId: $businessId,
            locationIds: array_map('intval', $locationIds),
            name: $name,
            categoryId: isset($body['category_id']) ? (int) $body['category_id'] : null,
            description: $body['description'] ?? null,
            durationMinutes: (int) ($body['duration_minutes'] ?? 30),
            price: (float) ($body['price'] ?? 0),
            colorHex: $colorHex,
            isBookableOnline: (bool) ($body['is_bookable_online'] ?? true),
            onlineVisibility: $onlineVisibility,
            isPriceStartingFrom: (bool) ($body['is_price_starting_from'] ?? false),
            processingTime: isset($body['processing_time']) ? (int) $body['processing_time'] : null,
            blockedTime: isset($body['blocked_time']) ? (int) $body['blocked_time'] : null,
            parallelCapacity: $parallelCapacity,
            onlinePaymentRequired: (bool) ($body['online_payment_required'] ?? false)
        );
        $this->createDirectLinkIfNeeded((int) $businessId, $service, $onlineVisibility);

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

        $body = $request->getBody();
        $onlineVisibility = $this->validatedOnlineVisibility($body, $request);
        if ($onlineVisibility instanceof Response) {
            return $onlineVisibility;
        }
        $locationId = isset($body['location_id']) ? (int) $body['location_id'] : null;

        if (!$locationId) {
            return Response::error('location_id is required', 'missing_location', 400);
        }

        // Verify location belongs to same business
        $location = $this->locationRepo->findById($locationId);
        if (!$location || (int) $location['business_id'] !== $businessId) {
            return Response::error('Invalid location_id', 'validation_error', 400);
        }
        $locationScopeError = $this->requireLocationScope($request, $businessId, [$locationId]);
        if ($locationScopeError !== null) {
            return $locationScopeError;
        }
        $globalFields = ['name', 'description', 'set_description_null', 'category_id', 'sort_order'];
        foreach ($globalFields as $field) {
            if (array_key_exists($field, $body)) {
                $businessWideError = $this->requireBusinessWideLocationScope($request, $businessId);
                if ($businessWideError !== null) {
                    return $businessWideError;
                }
                break;
            }
        }
        $hasColor = array_key_exists('color', $body) || array_key_exists('color_hex', $body);
        $colorHex = null;
        if ($hasColor) {
            $rawColor = array_key_exists('color', $body) ? $body['color'] : ($body['color_hex'] ?? null);
            $colorHexResult = ColorHex::normalizeOptional($rawColor, 'color');
            if (isset($colorHexResult['error'])) {
                return Response::error((string) $colorHexResult['error'], 'validation_error', 400, $request->traceId);
            }
            $colorHex = $colorHexResult['value'] ?? null;
        }

        // Handle processing_time and blocked_time (can be set to 0 explicitly)
        $processingTime = null;
        $setProcessingTimeNull = false;
        if (array_key_exists('processing_time', $body)) {
            $processingTime = (int) $body['processing_time'];
            $setProcessingTimeNull = $processingTime === 0;
        }
        
        $blockedTime = null;
        $setBlockedTimeNull = false;
        if (array_key_exists('blocked_time', $body)) {
            $blockedTime = (int) $body['blocked_time'];
            $setBlockedTimeNull = $blockedTime === 0;
        }

        // Handle description null
        $setDescriptionNull = (bool) ($body['set_description_null'] ?? false);
        $parallelCapacity = $this->validateParallelCapacity($body, false);
        if (is_string($parallelCapacity)) {
            return Response::error($parallelCapacity, 'validation_error', 400, $request->traceId);
        }

        $service = $this->serviceRepository->update(
            serviceId: $serviceId,
            locationId: $locationId,
            name: $body['name'] ?? null,
            categoryId: array_key_exists('category_id', $body) ? ($body['category_id'] ? (int) $body['category_id'] : null) : null,
            description: $body['description'] ?? null,
            durationMinutes: isset($body['duration_minutes']) ? (int) $body['duration_minutes'] : null,
            price: isset($body['price']) ? (float) $body['price'] : null,
            colorHex: $colorHex,
            isBookableOnline: isset($body['is_bookable_online']) ? (bool) $body['is_bookable_online'] : null,
            onlineVisibility: $onlineVisibility,
            isPriceStartingFrom: isset($body['is_price_starting_from']) ? (bool) $body['is_price_starting_from'] : null,
            sortOrder: isset($body['sort_order']) ? (int) $body['sort_order'] : null,
            processingTime: $processingTime,
            blockedTime: $blockedTime,
            parallelCapacity: $parallelCapacity,
            setProcessingTimeNull: $setProcessingTimeNull,
            setBlockedTimeNull: $setBlockedTimeNull,
            setDescriptionNull: $setDescriptionNull,
            onlinePaymentRequired: array_key_exists('online_payment_required', $body) ? (bool) $body['online_payment_required'] : null
        );

        if (!$service) {
            return Response::error('Service not found or unauthorized', 'not_found', 404);
        }
        $this->createDirectLinkIfNeeded((int) $businessId, $service, $onlineVisibility);

        return Response::success(['service' => $this->formatService($service, $businessId)]);
    }

    /**
     * DELETE /v1/services/{id}
     * Soft delete a service. Auth required.
     * Blocked if service has multiple active locations.
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

        // Check if service has multiple active locations (variants)
        $activeVariantCount = $this->serviceRepository->countActiveVariants($serviceId);
        if ($activeVariantCount > 1) {
            return Response::conflict(
                'service_has_multiple_active_locations',
                'service_has_multiple_active_locations',
                $request->traceId
            );
        }
        $onlyLocationId = $this->serviceRepository->getSingleActiveVariantLocationId($serviceId);
        if ($onlyLocationId !== null) {
            $locationScopeError = $this->requireLocationScope($request, $businessId, [$onlyLocationId]);
            if ($locationScopeError !== null) {
                return $locationScopeError;
            }
        }

        $this->serviceRepository->delete($serviceId);
        $this->packageRepo->markBrokenByServiceId($serviceId);

        return Response::success(['message' => 'Service deleted successfully']);
    }

    /**
     * DELETE /v1/locations/{location_id}/services/{service_id}
     * Remove a service from the current location only. Auth required.
     */
    public function removeFromLocation(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $serviceId = (int) $request->getRouteParam('service_id');

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        $businessId = (int) $location['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $existingService = $this->serviceRepository->findServiceById($serviceId);
        if (!$existingService || (int) $existingService['business_id'] !== $businessId) {
            return Response::notFound('Service not found', $request->traceId);
        }

        try {
            $result = $this->serviceRepository->removeFromLocation($serviceId, $locationId);
        } catch (\DomainException $e) {
            return Response::conflict(
                'service_used_by_active_packages',
                $e->getMessage(),
                $request->traceId
            );
        } catch (\InvalidArgumentException) {
            return Response::notFound('Service not found', $request->traceId);
        }

        return Response::success($result);
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
        if (!$this->hasBusinessReadAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $categories = $this->serviceRepository->getCategories($businessId, null, true);

        return Response::success([
            'categories' => array_map(fn($c) => [
                'id' => (int) $c['id'],
                'business_id' => (int) $c['business_id'],
                'name' => $c['name'],
                'description' => $c['description'],
                'sort_order' => (int) $c['sort_order'],
                'has_active_entries' => $this->serviceRepository->hasActiveCategoryLinkedEntries((int) $c['id']),
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
        $businessWideError = $this->requireBusinessWideLocationScope($request, $businessId);
        if ($businessWideError !== null) {
            return $businessWideError;
        }

        $body = $request->getBody();
        $name = trim($body['name'] ?? '');
        if (empty($name)) {
            return Response::error('Name is required', 'validation_error', 400);
        }

        $category = $this->serviceRepository->createCategory(
            businessId: $businessId,
            name: $name,
            description: $body['description'] ?? null,
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
        $businessWideError = $this->requireBusinessWideLocationScope($request, $businessId);
        if ($businessWideError !== null) {
            return $businessWideError;
        }

        $body = $request->getBody();

        $category = $this->serviceRepository->updateCategory(
            categoryId: $categoryId,
            name: $body['name'] ?? null,
            description: $body['description'] ?? null,
            sortOrder: isset($body['sort_order']) ? (int) $body['sort_order'] : null,
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
        $businessWideError = $this->requireBusinessWideLocationScope($request, $businessId);
        if ($businessWideError !== null) {
            return $businessWideError;
        }

        if ($this->serviceRepository->hasActiveCategoryLinkedEntries($categoryId)) {
            return Response::conflict(
                'category_not_empty',
                'Cannot delete category because it still contains services or packages',
                $request->traceId
            );
        }

        try {
            $this->serviceRepository->deleteCategory($categoryId);
        } catch (\PDOException) {
            // Safety net for FK/race conditions: never surface as 503 to UI.
            return Response::conflict(
                'category_not_empty',
                'Cannot delete category because it still contains services or packages',
                $request->traceId
            );
        }

        return Response::success(['message' => 'Category deleted successfully']);
    }

    /**
     * POST /v1/services/reorder
     * Batch update sort_order and category_id for multiple services.
     * Auth required.
     * 
     * Payload:
     * {
     *   "services": [{"id": 1, "category_id": 5, "sort_order": 0}, ...]
     * }
     */
    public function reorderServices(Request $request): Response
    {
        $body = $request->getBody();
        $services = $body['services'] ?? [];

        if (empty($services) || !is_array($services)) {
            return Response::error('services array is required', 'validation_error', 400);
        }

        // Get first service to determine business
        $firstServiceId = (int) $services[0]['id'];
        $existingService = $this->serviceRepository->findServiceById($firstServiceId);
        if (!$existingService) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $businessId = (int) $existingService['business_id'];

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $businessWideError = $this->requireBusinessWideLocationScope($request, $businessId);
        if ($businessWideError !== null) {
            return $businessWideError;
        }

        // Validate all services belong to same business
        $serviceIds = array_map(fn($s) => (int) $s['id'], $services);
        if (!$this->serviceRepository->allBelongToSameBusiness($serviceIds, $businessId)) {
            return Response::error('All services must belong to the same business', 'validation_error', 400);
        }

        // Update each service
        foreach ($services as $svc) {
            $this->serviceRepository->updateSortOrder(
                (int) $svc['id'],
                isset($svc['category_id']) ? (int) $svc['category_id'] : null,
                (int) $svc['sort_order']
            );
        }

        return Response::success(['message' => 'Services reordered successfully']);
    }

    /**
     * POST /v1/categories/reorder
     * Batch update sort_order for multiple categories.
     * Auth required.
     * 
     * Payload:
     * {
     *   "categories": [{"id": 1, "sort_order": 0}, ...]
     * }
     */
    public function reorderCategories(Request $request): Response
    {
        $body = $request->getBody();
        $categories = $body['categories'] ?? [];

        if (empty($categories) || !is_array($categories)) {
            return Response::error('categories array is required', 'validation_error', 400);
        }

        // Get first category to determine business
        $firstCategoryId = (int) $categories[0]['id'];
        $existingCategory = $this->serviceRepository->getCategoryById($firstCategoryId);
        if (!$existingCategory) {
            return Response::notFound('Category not found', $request->traceId);
        }

        $businessId = (int) $existingCategory['business_id'];

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $businessWideError = $this->requireBusinessWideLocationScope($request, $businessId);
        if ($businessWideError !== null) {
            return $businessWideError;
        }

        foreach ($categories as $cat) {
            $category = $this->serviceRepository->getCategoryById((int) $cat['id']);
            if (!$category || (int) $category['business_id'] !== $businessId) {
                return Response::error('All categories must belong to the same business', 'validation_error', 400);
            }
        }

        // Update each category
        foreach ($categories as $cat) {
            $this->serviceRepository->updateCategorySortOrder(
                (int) $cat['id'],
                (int) $cat['sort_order']
            );
        }

        return Response::success(['message' => 'Categories reordered successfully']);
    }

    /**
     * GET /v1/staff/{staff_id}/services/popular
     * Returns most booked services for a staff member.
     * Number of popular services is proportional to staff's enabled services:
     * - 1 per 7 enabled services, max 5
     * - 0 if less than 7 enabled services
     */
    public function popular(Request $request): Response
    {
        $staffId = (int) $request->getRouteParam('staff_id');
        $staff = $this->staffRepo->findById($staffId);

        // Do not reveal staff existence across businesses.
        if ($staff === null) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        $businessId = (int) $staff['business_id'];

        // Authorization check
        if (!$this->hasBusinessReadAccess($request, $businessId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        // Count services enabled for this staff
        $enabledServicesCount = $this->popularServiceRepo->getEnabledServicesCountForStaff($staffId);

        // Calculate how many popular services to show: 1 per 7 services, max 5
        // If less than 7 services, show none
        $maxPopularToShow = min(5, intdiv($enabledServicesCount, 7));

        if ($maxPopularToShow === 0) {
            return Response::success([
                'popular_services' => [],
                'enabled_services_count' => $enabledServicesCount,
                'show_popular_section' => false,
            ]);
        }

        $popularServices = $this->popularServiceRepo->findByStaffId($staffId);
        
        // Limit to calculated max
        $popularServices = array_slice($popularServices, 0, $maxPopularToShow);

        // Check if all popular services belong to the same category
        $categoryIds = array_unique(array_column($popularServices, 'category_id'));
        $showCategoryLabel = count($categoryIds) > 1;

        $formatted = array_map(fn($ps) => [
            'rank' => (int) $ps['rank'],
            'booking_count' => (int) $ps['booking_count'],
            'service_id' => (int) $ps['service_id'],
            'service_name' => $ps['service_name'],
            'category_id' => $ps['category_id'] ? (int) $ps['category_id'] : null,
            'category_name' => $showCategoryLabel ? $ps['category_name'] : null,
            'price' => (float) ($ps['price'] ?? 0),
            'duration_minutes' => (int) ($ps['duration_minutes'] ?? 0),
            'color' => $ps['color'],
        ], $popularServices);

        return Response::success([
            'popular_services' => $formatted,
            'enabled_services_count' => $enabledServicesCount,
            'show_popular_section' => !empty($formatted),
        ]);
    }

    private function formatService(array $service, int $businessId): array
    {
        return [
            'id' => (int) $service['id'],
            'business_id' => (int) $businessId,
            'name' => $service['name'],
            'description' => $service['description'],
            'duration_minutes' => (int) ($service['duration_minutes'] ?? 0),
            'processing_time' => (int) ($service['processing_time'] ?? 0),
            'blocked_time' => (int) ($service['blocked_time'] ?? 0),
            'price' => (float) ($service['price'] ?? 0),
            'color' => $service['color'],
            'is_active' => (bool) ($service['is_active'] ?? true),
            'is_bookable_online' => (bool) ($service['is_bookable_online'] ?? true),
            'online_visibility' => (string) ($service['online_visibility'] ?? 'public'),
            'is_price_starting_from' => (bool) ($service['is_price_from'] ?? false),
            'parallel_capacity' => (int) ($service['parallel_capacity'] ?? 1),
            'category_id' => $service['category_id'] ? (int) $service['category_id'] : null,
            'service_variant_id' => isset($service['service_variant_id']) ? (int) $service['service_variant_id'] : null,
            'sort_order' => (int) ($service['sort_order'] ?? 0),
            'online_payment_required' => (bool) ($service['online_payment_required'] ?? false),
        ];
    }

    private function validateParallelCapacity(array $body, bool $isCreate): int|string|null
    {
        if (!array_key_exists('parallel_capacity', $body)) {
            return $isCreate ? 1 : null;
        }

        $value = $body['parallel_capacity'];
        if (is_string($value)) {
            $value = trim($value);
        }

        if ($value === null || $value === '' || filter_var($value, FILTER_VALIDATE_INT) === false) {
            return 'parallel_capacity must be an integer';
        }

        $capacity = (int) $value;
        if ($capacity < 1) {
            return 'parallel_capacity must be >= 1';
        }
        if ($capacity > 999) {
            return 'parallel_capacity must be <= 999';
        }

        return $capacity;
    }

    private function validatedOnlineVisibility(array $body, Request $request): string|Response|null
    {
        if (!array_key_exists('online_visibility', $body)) {
            return null;
        }

        $value = strtolower(trim((string) $body['online_visibility']));
        if (!in_array($value, ['public', 'direct_link', 'hidden'], true)) {
            return Response::error('Invalid online_visibility', 'validation_error', 400, $request->traceId);
        }

        return $value;
    }

    /**
     * @return array|false|null  null = no `link` param; false = link present but invalid; array = valid scope
     */
    private function directLinkScopeFromQuery(Request $request, int $businessId, ?int $locationId = null): array|false|null
    {
        $link = trim((string) ($request->queryParam('link') ?? ''));
        if ($link === '') {
            return null;
        }

        $scope = $this->directLinkRepo?->resolveAvailableScope($businessId, $link, $locationId);
        if ($scope === null) {
            return false;
        }

        if (($scope['target_type'] ?? null) === BookingDirectLinkRepository::TARGET_SERVICE_CATEGORY) {
            $scope['child_visibility_scope'] = $this->directLinkRepo?->resolveCategoryChildVisibilityScope(
                $businessId,
                (int) ($scope['target_id'] ?? 0),
                $locationId
            ) ?? 'empty';
        }

        return $scope;
    }

    private function createDirectLinkIfNeeded(int $businessId, ?array $service, ?string $onlineVisibility): void
    {
        if ($onlineVisibility !== 'direct_link' || $service === null || empty($service['service_variant_id'])) {
            return;
        }

        $this->directLinkRepo?->createOrUpdateForTarget(
            $businessId,
            BookingDirectLinkRepository::TARGET_SERVICE_VARIANT,
            (int) $service['service_variant_id'],
            (int) ($service['location_id'] ?? 0),
            (string) ($service['name'] ?? 'booking-link')
        );
    }

    /**
     * GET /v1/services/{id}/locations
     * Get location IDs where a service has active variants.
     * Auth required.
     */
    public function getLocations(Request $request): Response
    {
        $serviceId = (int) $request->getRouteParam('id');

        // Get service to verify ownership
        $existingService = $this->serviceRepository->findServiceById($serviceId);
        if (!$existingService) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $businessId = (int) $existingService['business_id'];

        // Authorization check
        if (!$this->hasBusinessReadAccess($request, $businessId)) {
            return Response::notFound('Service not found', $request->traceId);
        }

        $locationIds = $this->serviceRepository->getServiceLocationIds($serviceId);

        return Response::success(['location_ids' => array_map('intval', $locationIds)]);
    }

    /**
     * PUT /v1/services/{id}/locations
     * Update which locations a service is available in.
     * Auth required.
     * 
     * Payload:
     * {
     *   "location_ids": [1, 2, 3]
     * }
     */
    public function updateLocations(Request $request): Response
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

        $body = $request->getBody();
        $locationIds = $body['location_ids'] ?? [];

        if (!is_array($locationIds) || empty($locationIds)) {
            return Response::error('location_ids array is required and cannot be empty', 'validation_error', 400);
        }

        $locationIds = array_map('intval', $locationIds);
        $locationIds = array_values(array_unique($locationIds));

        // Verify all locations belong to this business
        foreach ($locationIds as $locId) {
            $location = $this->locationRepo->findById($locId);
            if (!$location || (int) $location['business_id'] !== $businessId) {
                return Response::error("Invalid location_id: {$locId}", 'validation_error', 400);
            }
        }
        $currentLocationIds = array_map('intval', $this->serviceRepository->getServiceLocationIds($serviceId));
        $addedLocationIds = array_values(array_diff($locationIds, $currentLocationIds));
        $removedLocationIds = array_values(array_diff($currentLocationIds, $locationIds));
        $changedLocationIds = array_values(array_unique(array_merge($addedLocationIds, $removedLocationIds)));
        $locationScopeError = $this->requireLocationScope($request, $businessId, $changedLocationIds);
        if ($locationScopeError !== null) {
            return $locationScopeError;
        }

        $this->serviceRepository->updateServiceLocations($serviceId, $locationIds);

        return Response::success([
            'message' => 'Service locations updated successfully',
            'location_ids' => $locationIds,
        ]);
    }
}
