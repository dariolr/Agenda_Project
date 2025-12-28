<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\Business\GetAllBusinesses;
use Agenda\UseCases\Business\GetUserBusinesses;
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
 * - DELETE /v1/admin/businesses/{id} - Superadmin: soft-delete business
 * 
 * - GET /v1/me/businesses           - User: list own businesses with roles
 */
final class AdminBusinessesController
{
    public function __construct(
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
        $limit = min((int) ($request->queryParam('limit') ?? 50), 100);
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
     * Superadmin only: create a new business and assign owner.
     * 
     * Body:
     * {
     *   "name": "Business Name",
     *   "slug": "business-slug",
     *   "email": "contact@business.com",
     *   "phone": "+39123456789",
     *   "timezone": "Europe/Rome",
     *   "currency": "EUR",
     *   "owner_user_id": 123  // The user who becomes owner
     * }
     */
    public function store(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $user = $this->userRepo->findById($userId);
        if ($user === null || empty($user['is_superadmin'])) {
            return Response::forbidden('Superadmin access required', $request->traceId);
        }

        $body = $request->getBody();

        // Validate required fields
        $required = ['name', 'slug', 'owner_user_id'];
        foreach ($required as $field) {
            if (empty($body[$field])) {
                return Response::validationError(
                    ["$field is required"],
                    $request->traceId
                );
            }
        }

        // Check slug uniqueness
        $existingBusiness = $this->businessRepo->findBySlug($body['slug']);
        if ($existingBusiness !== null) {
            return Response::validationError(
                ['slug' => 'Business slug already exists'],
                $request->traceId
            );
        }

        // Check owner user exists
        $ownerUserId = (int) $body['owner_user_id'];
        $ownerUser = $this->userRepo->findById($ownerUserId);
        if ($ownerUser === null) {
            return Response::validationError(
                ['owner_user_id' => 'User not found'],
                $request->traceId
            );
        }

        // Create business
        $businessId = $this->businessRepo->create(
            $body['name'],
            $body['slug'],
            [
                'email' => $body['email'] ?? null,
                'phone' => $body['phone'] ?? null,
                'timezone' => $body['timezone'] ?? 'Europe/Rome',
                'currency' => $body['currency'] ?? 'EUR',
            ]
        );

        // Assign owner
        $this->businessUserRepo->createOwner($ownerUserId, $businessId);

        $business = $this->businessRepo->findById($businessId);

        return Response::created([
            'id' => $businessId,
            'name' => $business['name'],
            'slug' => $business['slug'],
            'email' => $business['email'],
            'phone' => $business['phone'],
            'timezone' => $business['timezone'],
            'currency' => $business['currency'],
            'owner' => [
                'id' => $ownerUserId,
                'email' => $ownerUser['email'],
                'name' => ($ownerUser['first_name'] ?? '') . ' ' . ($ownerUser['last_name'] ?? ''),
            ],
        ]);
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
        $this->businessRepo->update($businessId, ['is_active' => false]);

        return Response::success([
            'message' => 'Business deleted successfully',
            'id' => $businessId,
        ]);
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
