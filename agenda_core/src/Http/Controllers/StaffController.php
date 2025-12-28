<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\StaffRepository;

final class StaffController
{
    public function __construct(
        private readonly StaffRepository $staffRepository,
    ) {}

    /**
     * GET /v1/staff?location_id=X
     * Public endpoint - returns staff members for a location.
     */
    public function index(Request $request): Response
    {
        $businessId = $request->getAttribute('business_id');
        $locationId = $request->getAttribute('location_id');

        if ($businessId === null || $locationId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        $staff = $this->staffRepository->findByLocationId($locationId, $businessId);

        return Response::success([
            'staff' => array_map(fn($s) => [
                'id' => (int) $s['id'],
                'display_name' => $s['display_name'],
                'color' => $s['color_hex'],
                'avatar_url' => $s['avatar_url'] ?? null,
            ], $staff),
        ], 200);
    }

    /**
     * GET /v1/staff/{id}
     */
    public function show(Request $request, int $id): Response
    {
        $businessId = $request->getAttribute('business_id');
        $locationId = $request->getAttribute('location_id');
        
        $staff = $this->staffRepository->findById($id);

        if ($staff === null || (int) $staff['business_id'] !== $businessId) {
            return Response::error('Staff member not found', 'not_found', 404);
        }

        // Verify staff belongs to this location
        if ($locationId !== null && !$this->staffRepository->belongsToLocation($id, $locationId)) {
            return Response::error('Staff member not found', 'not_found', 404);
        }

        // Get services this staff member can perform
        $services = $this->staffRepository->getServicesForStaff($id, $locationId);

        return Response::success([
            'id' => (int) $staff['id'],
            'display_name' => $staff['display_name'],
            'color' => $staff['color_hex'],
            'avatar_url' => $staff['avatar_url'] ?? null,
            'services' => array_map(fn($s) => [
                'id' => (int) $s['id'],
                'name' => $s['name'],
                'duration_minutes' => (int) ($s['duration_minutes'] ?? 0),
                'price' => (float) ($s['price'] ?? 0),
            ], $services),
        ], 200);
    }
}
