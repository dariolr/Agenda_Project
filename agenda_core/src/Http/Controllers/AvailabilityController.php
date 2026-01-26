<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\Booking\ComputeAvailability;
use Agenda\Infrastructure\Repositories\ServiceRepository;

final class AvailabilityController
{
    public function __construct(
        private readonly ComputeAvailability $computeAvailability,
        private readonly ServiceRepository $serviceRepository,
    ) {}

    /**
     * GET /v1/availability?location_id=X&date=YYYY-MM-DD&service_ids=1,2,3&staff_id=X&exclude_booking_id=Y
     * Public endpoint - returns available time slots.
     * 
     * Use exclude_booking_id when checking availability for editing an existing booking.
     * This will exclude the original booking from conflict detection.
     */
    public function index(Request $request): Response
    {
        $businessId = $request->getAttribute('business_id');
        $locationId = $request->getAttribute('location_id');

        if ($businessId === null || $locationId === null) {
            return Response::error('Location context required', 'missing_location', 400);
        }

        // Get query parameters
        $query = $request->getQuery();
        $date = $query['date'] ?? null;
        $serviceIdsParam = $query['service_ids'] ?? null;
        $staffId = isset($query['staff_id']) ? (int) $query['staff_id'] : null;
        $excludeBookingId = isset($query['exclude_booking_id']) ? (int) $query['exclude_booking_id'] : null;

        if ($date === null) {
            return Response::error('Date parameter is required (YYYY-MM-DD)', 'validation_error', 400);
        }

        if ($serviceIdsParam === null) {
            return Response::error('service_ids parameter is required', 'validation_error', 400);
        }

        // Parse service IDs
        $serviceIds = array_map('intval', explode(',', $serviceIdsParam));
        $serviceIds = array_filter($serviceIds, fn($id) => $id > 0);

        if (empty($serviceIds)) {
            return Response::error('At least one valid service_id is required', 'validation_error', 400);
        }

        // Validate services belong to business (check at location level)
        if (!$this->serviceRepository->allBelongToBusiness($serviceIds, $locationId, $businessId)) {
            return Response::error('One or more services are invalid', 'invalid_service', 400);
        }

        // Calculate total duration (from service_variants)
        $totalDuration = $this->serviceRepository->getTotalDuration($serviceIds, $locationId, $businessId);

        if ($totalDuration === 0) {
            return Response::error('Could not calculate duration for services', 'invalid_service', 400);
        }

        $result = $this->computeAvailability->execute(
            $businessId,
            $locationId,
            $staffId,
            $totalDuration,
            $date,
            $serviceIds,
            false, // keepStaffInfo
            $excludeBookingId,
            true   // isPublic - apply slot display mode filtering
        );

        return Response::success($result, 200);
    }
}
