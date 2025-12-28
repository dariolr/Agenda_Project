<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Domain\Exceptions\AuthException;

/**
 * Controller for managing business operators (users with access to a business).
 * 
 * Endpoints:
 * - GET    /v1/businesses/{business_id}/users           - List operators
 * - POST   /v1/businesses/{business_id}/users           - Invite operator
 * - PATCH  /v1/businesses/{business_id}/users/{user_id} - Update role
 * - DELETE /v1/businesses/{business_id}/users/{user_id} - Remove access
 */
final class BusinessUsersController
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/businesses/{business_id}/users
     * List all operators for a business.
     * Requires: owner/admin role or superadmin.
     */
    public function index(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        
        // Verify access (must be owner/admin or superadmin)
        $accessCheck = $this->checkManageAccess($userId, $businessId);
        if ($accessCheck !== null) {
            return $accessCheck;
        }

        $users = $this->businessUserRepo->findUsersByBusinessId($businessId);

        return Response::success([
            'users' => array_map(fn($u) => $this->formatBusinessUser($u), $users),
        ]);
    }

    /**
     * POST /v1/businesses/{business_id}/users
     * Invite a user to the business.
     * 
     * Body:
     * {
     *   "user_id": 123,
     *   "role": "staff|manager|admin",
     *   "staff_id": 456  // optional: link to staff record
     * }
     */
    public function store(Request $request): Response
    {
        $currentUserId = $request->userId();
        if ($currentUserId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        
        // Verify access
        $accessCheck = $this->checkManageAccess($currentUserId, $businessId);
        if ($accessCheck !== null) {
            return $accessCheck;
        }

        $body = $request->getBody();

        // Validate required fields
        if (empty($body['user_id'])) {
            return Response::validationError(['user_id is required'], $request->traceId);
        }
        
        $targetUserId = (int) $body['user_id'];
        $role = $body['role'] ?? 'staff';
        
        // Validate role
        if (!in_array($role, ['staff', 'manager', 'admin'], true)) {
            return Response::validationError(
                ['role must be staff, manager, or admin'],
                $request->traceId
            );
        }

        // Check if user exists
        $targetUser = $this->userRepo->findById($targetUserId);
        if ($targetUser === null) {
            return Response::validationError(['user_id' => 'User not found'], $request->traceId);
        }

        // Check if already has access
        if ($this->businessUserRepo->hasAccess($targetUserId, $businessId)) {
            return Response::validationError(
                ['user_id' => 'User already has access to this business'],
                $request->traceId
            );
        }

        // Get current user's role to check hierarchy
        $currentRole = $this->getEffectiveRole($currentUserId, $businessId);
        
        // Check role hierarchy (cannot assign role >= own role, except owner can do anything)
        if (!$this->businessUserRepo->canAssignRole($currentRole, $role)) {
            return Response::forbidden(
                'Cannot assign a role equal to or higher than your own',
                $request->traceId
            );
        }

        // Create the business_user record
        $businessUserId = $this->businessUserRepo->create([
            'business_id' => $businessId,
            'user_id' => $targetUserId,
            'role' => $role,
            'staff_id' => $body['staff_id'] ?? null,
            'invited_by' => $currentUserId,
            'invited_at' => date('Y-m-d H:i:s'),
            'accepted_at' => date('Y-m-d H:i:s'), // Auto-accept for now
        ]);

        return Response::created([
            'id' => $businessUserId,
            'user_id' => $targetUserId,
            'business_id' => $businessId,
            'role' => $role,
            'user' => [
                'id' => $targetUserId,
                'email' => $targetUser['email'],
                'name' => trim(($targetUser['first_name'] ?? '') . ' ' . ($targetUser['last_name'] ?? '')),
            ],
        ]);
    }

    /**
     * PATCH /v1/businesses/{business_id}/users/{user_id}
     * Update a user's role in the business.
     * 
     * Body:
     * {
     *   "role": "staff|manager|admin",
     *   "staff_id": 456,  // optional
     *   "can_manage_bookings": true,
     *   "can_manage_clients": true,
     *   ...
     * }
     */
    public function update(Request $request): Response
    {
        $currentUserId = $request->userId();
        if ($currentUserId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        $targetUserId = (int) $request->getAttribute('target_user_id');
        
        // Verify access
        $accessCheck = $this->checkManageAccess($currentUserId, $businessId);
        if ($accessCheck !== null) {
            return $accessCheck;
        }

        // Get current business_user record
        $businessUser = $this->businessUserRepo->findByUserAndBusiness($targetUserId, $businessId);
        if ($businessUser === null) {
            return Response::notFound('User not found in this business', $request->traceId);
        }

        // Cannot modify owner
        if ($businessUser['role'] === 'owner') {
            return Response::forbidden(
                'Cannot modify owner role. Transfer ownership instead.',
                $request->traceId
            );
        }

        $body = $request->getBody();
        $updateData = [];

        // Update role if provided
        if (isset($body['role'])) {
            $newRole = $body['role'];
            
            if (!in_array($newRole, ['staff', 'manager', 'admin'], true)) {
                return Response::validationError(
                    ['role must be staff, manager, or admin'],
                    $request->traceId
                );
            }

            $currentRole = $this->getEffectiveRole($currentUserId, $businessId);
            if (!$this->businessUserRepo->canAssignRole($currentRole, $newRole)) {
                return Response::forbidden(
                    'Cannot assign a role equal to or higher than your own',
                    $request->traceId
                );
            }

            $updateData['role'] = $newRole;
        }

        // Update permissions if provided
        $permissionFields = [
            'can_manage_bookings',
            'can_manage_clients', 
            'can_manage_services',
            'can_manage_staff',
            'can_view_reports',
        ];
        
        foreach ($permissionFields as $field) {
            if (isset($body[$field])) {
                $updateData[$field] = (bool) $body[$field];
            }
        }

        // Update staff_id if provided
        if (array_key_exists('staff_id', $body)) {
            $updateData['staff_id'] = $body['staff_id'];
        }

        if (empty($updateData)) {
            return Response::validationError(['No fields to update'], $request->traceId);
        }

        $this->businessUserRepo->update($businessUser['id'], $updateData);

        // Fetch updated record
        $updated = $this->businessUserRepo->findByUserAndBusiness($targetUserId, $businessId);

        return Response::success($this->formatBusinessUser($updated));
    }

    /**
     * DELETE /v1/businesses/{business_id}/users/{user_id}
     * Remove a user's access to the business.
     */
    public function destroy(Request $request): Response
    {
        $currentUserId = $request->userId();
        if ($currentUserId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        $targetUserId = (int) $request->getAttribute('target_user_id');
        
        // Verify access
        $accessCheck = $this->checkManageAccess($currentUserId, $businessId);
        if ($accessCheck !== null) {
            return $accessCheck;
        }

        // Get business_user record
        $businessUser = $this->businessUserRepo->findByUserAndBusiness($targetUserId, $businessId);
        if ($businessUser === null) {
            return Response::notFound('User not found in this business', $request->traceId);
        }

        // Cannot remove owner
        if ($businessUser['role'] === 'owner') {
            return Response::forbidden(
                'Cannot remove the owner. Transfer ownership first.',
                $request->traceId
            );
        }

        // Cannot remove yourself (except if superadmin)
        if ($targetUserId === $currentUserId && !$this->userRepo->isSuperadmin($currentUserId)) {
            return Response::forbidden(
                'Cannot remove yourself from the business',
                $request->traceId
            );
        }

        $this->businessUserRepo->delete($businessUser['id']);

        return Response::success([
            'message' => 'User removed from business',
            'user_id' => $targetUserId,
            'business_id' => $businessId,
        ]);
    }

    /**
     * Check if user can manage business users.
     * Returns null if allowed, Response if denied.
     */
    private function checkManageAccess(int $userId, int $businessId): ?Response
    {
        // Superadmin can do anything
        if ($this->userRepo->isSuperadmin($userId)) {
            return null;
        }

        // Check business exists
        $business = $this->businessRepo->findById($businessId);
        if ($business === null) {
            return Response::notFound('Business not found');
        }

        // Check user's role
        $role = $this->businessUserRepo->getRole($userId, $businessId);
        if ($role === null) {
            return Response::forbidden('You do not have access to this business');
        }

        // Only owner and admin can manage users
        if (!in_array($role, ['owner', 'admin'], true)) {
            return Response::forbidden('Only owners and admins can manage business users');
        }

        return null;
    }

    /**
     * Get effective role (superadmin = admin).
     */
    private function getEffectiveRole(int $userId, int $businessId): string
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return 'admin';
        }
        return $this->businessUserRepo->getRole($userId, $businessId) ?? 'staff';
    }

    private function formatBusinessUser(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'user_id' => (int) $row['user_id'],
            'role' => $row['role'],
            'staff_id' => $row['staff_id'] ? (int) $row['staff_id'] : null,
            'permissions' => [
                'can_manage_bookings' => (bool) $row['can_manage_bookings'],
                'can_manage_clients' => (bool) $row['can_manage_clients'],
                'can_manage_services' => (bool) $row['can_manage_services'],
                'can_manage_staff' => (bool) $row['can_manage_staff'],
                'can_view_reports' => (bool) $row['can_view_reports'],
            ],
            'is_active' => (bool) $row['is_active'],
            'invited_by' => $row['invited_by'] ? (int) $row['invited_by'] : null,
            'invited_at' => $row['invited_at'],
            'accepted_at' => $row['accepted_at'],
            'user' => [
                'email' => $row['email'] ?? null,
                'first_name' => $row['first_name'] ?? null,
                'last_name' => $row['last_name'] ?? null,
            ],
        ];
    }
}
