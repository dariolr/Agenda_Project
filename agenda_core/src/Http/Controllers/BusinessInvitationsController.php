<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BusinessInvitationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Controller for business invitations.
 * 
 * Endpoints:
 * - GET    /v1/businesses/{business_id}/invitations       - List pending invitations
 * - POST   /v1/businesses/{business_id}/invitations       - Create invitation
 * - DELETE /v1/businesses/{business_id}/invitations/{id}  - Revoke invitation
 * - GET    /v1/invitations/{token}                        - Get invitation details (public)
 * - POST   /v1/invitations/{token}/accept                 - Accept invitation (auth required)
 */
final class BusinessInvitationsController
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly BusinessInvitationRepository $invitationRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/businesses/{business_id}/invitations
     * List pending invitations for a business.
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

        $invitations = $this->invitationRepo->findPendingByBusiness($businessId);

        return Response::success([
            'invitations' => array_map(fn($i) => [
                'id' => (int) $i['id'],
                'email' => $i['email'],
                'role' => $i['role'],
                'expires_at' => $i['expires_at'],
                'created_at' => $i['created_at'],
                'invited_by' => [
                    'first_name' => $i['inviter_first_name'],
                    'last_name' => $i['inviter_last_name'],
                ],
            ], $invitations),
        ]);
    }

    /**
     * POST /v1/businesses/{business_id}/invitations
     * Create a new invitation.
     * 
     * Body:
     * {
     *   "email": "user@example.com",
     *   "role": "staff|manager|admin"
     * }
     */
    public function store(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        
        // Verify access
        $accessCheck = $this->checkManageAccess($userId, $businessId);
        if ($accessCheck !== null) {
            return $accessCheck;
        }

        $body = $request->getBody();

        // Validate email
        if (empty($body['email']) || !filter_var($body['email'], FILTER_VALIDATE_EMAIL)) {
            return Response::validationError('Valid email is required', $request->traceId);
        }

        $email = strtolower(trim($body['email']));
        $role = $body['role'] ?? 'staff';

        // Validate role
        if (!in_array($role, ['staff', 'manager', 'admin'], true)) {
            return Response::validationError('Role must be staff, manager, or admin', $request->traceId);
        }

        // Check if user already has access
        $existingUser = $this->userRepo->findByEmail($email);
        if ($existingUser && $this->businessUserRepo->hasAccess((int) $existingUser['id'], $businessId)) {
            return Response::validationError(
                'User already has access to this business',
                $request->traceId
            );
        }

        // Check if there's already a pending invitation
        $existingInvite = $this->invitationRepo->findPendingByEmailAndBusiness($email, $businessId);
        if ($existingInvite) {
            return Response::validationError(
                'An invitation is already pending for this email',
                $request->traceId
            );
        }

        // Check role hierarchy
        $currentRole = $this->getEffectiveRole($userId, $businessId);
        if (!$this->businessUserRepo->canAssignRole($currentRole, $role)) {
            return Response::forbidden(
                'Cannot invite with a role equal to or higher than your own',
                $request->traceId
            );
        }

        // Create invitation
        $result = $this->invitationRepo->create([
            'business_id' => $businessId,
            'email' => $email,
            'role' => $role,
            'invited_by' => $userId,
        ]);

        $business = $this->businessRepo->findById($businessId);

        return Response::created([
            'id' => $result['id'],
            'email' => $email,
            'role' => $role,
            'token' => $result['token'],
            'expires_at' => $result['expires_at'],
            'invite_url' => $this->buildInviteUrl($result['token']),
            'business' => [
                'id' => $businessId,
                'name' => $business['name'],
            ],
        ]);
    }

    /**
     * DELETE /v1/businesses/{business_id}/invitations/{id}
     * Revoke an invitation.
     */
    public function destroy(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        $invitationId = (int) $request->getAttribute('invitation_id');
        
        // Verify access
        $accessCheck = $this->checkManageAccess($userId, $businessId);
        if ($accessCheck !== null) {
            return $accessCheck;
        }

        $this->invitationRepo->revoke($invitationId);

        return Response::success([
            'message' => 'Invitation revoked',
            'id' => $invitationId,
        ]);
    }

    /**
     * GET /v1/invitations/{token}
     * Get invitation details by token (public endpoint).
     */
    public function show(Request $request): Response
    {
        $token = $request->getAttribute('token');
        
        $invitation = $this->invitationRepo->findByToken($token);
        if ($invitation === null) {
            return Response::notFound('Invitation not found', $request->traceId);
        }

        // Check if expired
        if (strtotime($invitation['expires_at']) < time()) {
            return Response::validationError('Invitation has expired', $request->traceId);
        }

        // Check status
        if ($invitation['status'] !== 'pending') {
            return Response::validationError(
                'Invitation is no longer valid (status: ' . $invitation['status'] . ')',
                $request->traceId
            );
        }

        return Response::success([
            'email' => $invitation['email'],
            'role' => $invitation['role'],
            'business' => [
                'id' => (int) $invitation['business_id'],
                'name' => $invitation['business_name'],
                'slug' => $invitation['business_slug'],
            ],
            'expires_at' => $invitation['expires_at'],
        ]);
    }

    /**
     * POST /v1/invitations/{token}/accept
     * Accept an invitation (requires authentication).
     */
    public function accept(Request $request): Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $token = $request->getAttribute('token');
        
        $invitation = $this->invitationRepo->findByToken($token);
        if ($invitation === null) {
            return Response::notFound('Invitation not found', $request->traceId);
        }

        // Check if expired
        if (strtotime($invitation['expires_at']) < time()) {
            return Response::validationError('Invitation has expired', $request->traceId);
        }

        // Check status
        if ($invitation['status'] !== 'pending') {
            return Response::validationError(
                'Invitation is no longer valid',
                $request->traceId
            );
        }

        // Verify email matches
        $user = $this->userRepo->findById($userId);
        if (strtolower($user['email']) !== strtolower($invitation['email'])) {
            return Response::forbidden(
                'This invitation was sent to a different email address',
                $request->traceId
            );
        }

        // Check if already has access
        if ($this->businessUserRepo->hasAccess($userId, (int) $invitation['business_id'])) {
            // Mark as accepted anyway
            $this->invitationRepo->accept((int) $invitation['id'], $userId);
            return Response::success([
                'message' => 'You already have access to this business',
                'business_id' => (int) $invitation['business_id'],
            ]);
        }

        // Accept invitation and create business_user
        $this->invitationRepo->accept((int) $invitation['id'], $userId);
        
        $businessUserId = $this->businessUserRepo->create([
            'business_id' => (int) $invitation['business_id'],
            'user_id' => $userId,
            'role' => $invitation['role'],
            'invited_by' => (int) $invitation['invited_by'],
            'invited_at' => $invitation['created_at'],
            'accepted_at' => date('Y-m-d H:i:s'),
        ]);

        return Response::success([
            'message' => 'Invitation accepted',
            'business' => [
                'id' => (int) $invitation['business_id'],
                'name' => $invitation['business_name'],
            ],
            'role' => $invitation['role'],
        ]);
    }

    /**
     * Check if user can manage invitations.
     */
    private function checkManageAccess(int $userId, int $businessId): ?Response
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return null;
        }

        $business = $this->businessRepo->findById($businessId);
        if ($business === null) {
            return Response::notFound('Business not found');
        }

        $role = $this->businessUserRepo->getRole($userId, $businessId);
        if ($role === null) {
            return Response::forbidden('You do not have access to this business');
        }

        if (!in_array($role, ['owner', 'admin'], true)) {
            return Response::forbidden('Only owners and admins can manage invitations');
        }

        return null;
    }

    private function getEffectiveRole(int $userId, int $businessId): string
    {
        if ($this->userRepo->isSuperadmin($userId)) {
            return 'admin';
        }
        return $this->businessUserRepo->getRole($userId, $businessId) ?? 'staff';
    }

    private function buildInviteUrl(string $token): string
    {
        $baseUrl = $_ENV['FRONTEND_URL'] ?? 'https://app.example.com';
        return $baseUrl . '/invitation/' . $token;
    }
}
