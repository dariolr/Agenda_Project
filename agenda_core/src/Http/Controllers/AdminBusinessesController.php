<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Database\Connection;
use Agenda\UseCases\Business\CreateBusiness;
use Agenda\UseCases\Business\GetAllBusinesses;
use Agenda\UseCases\Business\GetUserBusinesses;
use Agenda\UseCases\Business\UpdateBusiness;
use Agenda\UseCases\Business\ResendAdminInvite;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\ValidationException;

/**
 * Controller for admin-level business operations.
 * 
 * Endpoints:
 * - GET  /v1/admin/businesses       - Superadmin: list all businesses
 * - POST /v1/admin/businesses       - Superadmin: create new business + owner
 * - PUT  /v1/admin/businesses/{id}  - Superadmin: update business
 * - DELETE /v1/admin/businesses/{id} - Superadmin: soft-delete business
 * 
 * - GET /v1/me/businesses           - User: list own businesses with roles
 */
final class AdminBusinessesController
{
    public function __construct(
        private readonly Connection $db,
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/admin/businesses
     * Superadmin only: list all businesses with pagination and search.
     */
    public function index(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $user = $this->userRepo->findById($userId);
        if ($user === null || empty($user['is_superadmin'])) {
            return Response::forbidden('Superadmin access required', $request->traceId);
        }

        $search = $request->queryParam('search');
        // If limit not specified, return all results (null)
        $limitParam = $request->queryParam('limit');
        $limit = $limitParam !== null ? (int) $limitParam : null;
        $offset = (int) ($request->queryParam('offset') ?? 0);

        $useCase = new GetAllBusinesses($this->businessRepo, $this->userRepo);
        
        try {
            $result = $useCase->execute($userId, $search, $limit, $offset);
            return Response::success($result);
        } catch (AuthException $e) {
            return Response::forbidden($e->getMessage(), $request->traceId);
        }
    }

    /**
     * POST /v1/admin/businesses
     * Superadmin only: create a new business and optionally assign admin.
     * Creates admin user if not exists and sends welcome email.
     * Uses transaction for atomicity - rollback on any failure.
     * 
     * Body:
     * {
     *   "name": "Business Name",
     *   "slug": "business-slug",
     *   "admin_email": "admin@business.com",  // Optional: admin receives welcome email
     *   "email": "contact@business.com",      // Optional: business contact email
     *   "phone": "+39123456789",
     *   "online_bookings_notification_email": "notify@business.com", // Optional: notifications for customer online bookings
     *   "timezone": "Europe/Rome",
     *   "currency": "EUR",
     *   "admin_first_name": "Mario",          // Optional
     *   "admin_last_name": "Rossi"            // Optional
     * }
     */
    public function store(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $body = $request->getBody();

        // Validate required fields (admin_email is now optional)
        $required = ['name', 'slug'];
        foreach ($required as $field) {
            if (empty($body[$field])) {
                return Response::validationError(
                    "$field is required",
                    $request->traceId
                );
            }
        }

        $useCase = new CreateBusiness(
            $this->db,
            $this->businessRepo,
            $this->businessUserRepo,
            $this->userRepo
        );

        try {
            $result = $useCase->execute(
                $userId,
                $body['name'],
                $body['slug'],
                $body['admin_email'] ?? null,
                [
                    'email' => $body['email'] ?? null,
                    'phone' => $body['phone'] ?? null,
                    'online_bookings_notification_email' => $body['online_bookings_notification_email'] ?? null,
                    'timezone' => $body['timezone'] ?? 'Europe/Rome',
                    'currency' => $body['currency'] ?? 'EUR',
                    'admin_first_name' => $body['admin_first_name'] ?? null,
                    'admin_last_name' => $body['admin_last_name'] ?? null,
                ]
            );

            return Response::created($result);
        } catch (AuthException $e) {
            return Response::forbidden($e->getMessage(), $request->traceId);
        } catch (ValidationException $e) {
            return Response::validationError($e->getMessage(), $request->traceId);
        }
    }

    /**
     * PUT /v1/admin/businesses/{id}
     * Superadmin only: update a business.
     * 
     * Body (all optional):
     * {
     *   "name": "New Business Name",
     *   "slug": "new-business-slug",
     *   "admin_email": "newadmin@business.com",  // Changes business owner
     *   "email": "contact@business.com",
     *   "phone": "+39123456789",
     *   "online_bookings_notification_email": "notify@business.com",
     *   "timezone": "Europe/Rome",
     *   "currency": "EUR"
     * }
     */
    public function update(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('id');
        $body = $request->getBody();

        $useCase = new UpdateBusiness(
            $this->db,
            $this->businessRepo,
            $this->businessUserRepo,
            $this->userRepo
        );

        try {
            $result = $useCase->execute($userId, $businessId, $body);
            return Response::success($result);
        } catch (AuthException $e) {
            return Response::forbidden($e->getMessage(), $request->traceId);
        } catch (ValidationException $e) {
            return Response::validationError($e->getMessage(), $request->traceId);
        }
    }

    /**
     * DELETE /v1/admin/businesses/{id}
     * Superadmin only: soft-delete a business.
     */
    public function destroy(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $user = $this->userRepo->findById($userId);
        if ($user === null || empty($user['is_superadmin'])) {
            return Response::forbidden('Superadmin access required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('id');

        $business = $this->businessRepo->findById($businessId);
        if ($business === null) {
            return Response::notFound('Business not found', $request->traceId);
        }

        // Soft delete by setting is_active = false
        $this->businessRepo->delete($businessId);

        return Response::success([
            'message' => 'Business deleted successfully',
            'id' => $businessId,
        ]);
    }

    /**
     * POST /v1/admin/businesses/{id}/resend-invite
     * Superadmin only: resend welcome email to business admin.
     */
    public function resendInvite(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('id');

        $useCase = new ResendAdminInvite(
            $this->db,
            $this->businessRepo,
            $this->businessUserRepo,
            $this->userRepo
        );

        try {
            $result = $useCase->execute($userId, $businessId);
            return Response::success($result);
        } catch (AuthException $e) {
            return Response::forbidden($e->getMessage(), $request->traceId);
        } catch (ValidationException $e) {
            return Response::validationError($e->getMessage(), $request->traceId);
        } catch (\RuntimeException $e) {
            return Response::error($e->getMessage(), 500, $request->traceId);
        }
    }

    /**
     * GET /v1/me/businesses
     * Get businesses for the authenticated user with their roles.
     * Superadmin gets empty list (they use /v1/admin/businesses instead).
     */
    public function myBusinesses(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $useCase = new GetUserBusinesses(
            $this->businessUserRepo,
            $this->userRepo,
        );

        try {
            $result = $useCase->execute($userId);
            return Response::success($result);
        } catch (AuthException $e) {
            return Response::forbidden($e->getMessage(), $request->traceId);
        }
    }
}
