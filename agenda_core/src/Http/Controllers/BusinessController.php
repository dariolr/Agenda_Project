<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class BusinessController
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
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
     * GET /v1/businesses
     * List businesses the authenticated user has access to.
     * Superadmin sees all businesses.
     */
    public function index(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        // Superadmin can see all businesses
        if ($this->userRepo->isSuperadmin($userId)) {
            $businesses = $this->businessRepo->findAll();
        } else {
            // Normal user: only businesses they have access to
            $businesses = $this->businessRepo->findByUserId($userId);
        }

        return Response::success([
            'data' => array_map(fn($b) => $this->formatBusiness($b), $businesses),
        ]);
    }

    /**
     * GET /v1/businesses/{id}
     * Get a single business by ID (only if user has access)
     */
    public function show(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('id');

        $business = $this->businessRepo->findById($businessId);
        if (!$business) {
            return Response::notFound('Business not found', $request->traceId);
        }

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
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
        $slug = $request->getAttribute('slug');

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

        // Get default location for this business
        $defaultLocation = $this->locationRepo->findDefaultByBusinessId((int) $business['id']);
        $defaultLocationId = $defaultLocation ? (int) $defaultLocation['id'] : null;

        return Response::success($this->formatBusinessPublic($business, $defaultLocationId));
    }

    /**
     * Format business for public display (limited fields)
     */
    private function formatBusinessPublic(array $row, ?int $defaultLocationId = null): array
    {
        return [
            'id' => (int) $row['id'],
            'name' => $row['name'],
            'slug' => $row['slug'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'timezone' => $row['timezone'],
            'currency' => $row['currency'],
            'service_color_palette' => $row['service_color_palette'] ?? 'legacy',
            'default_location_id' => $defaultLocationId,
        ];
    }

    private function formatBusiness(array $row): array
    {
        $result = [
            'id' => (int) $row['id'],
            'name' => $row['name'],
            'slug' => $row['slug'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'online_bookings_notification_email' => $row['online_bookings_notification_email'] ?? null,
            'timezone' => $row['timezone'],
            'currency' => $row['currency'],
            'service_color_palette' => $row['service_color_palette'] ?? 'legacy',
            'is_active' => (bool) $row['is_active'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
        ];

        if (isset($row['user_role']) && is_string($row['user_role'])) {
            $result['user_role'] = $row['user_role'];
        }
        if (isset($row['user_scope_type']) && is_string($row['user_scope_type'])) {
            $result['user_scope_type'] = $row['user_scope_type'];
        }

        return $result;
    }
}
