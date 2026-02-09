<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BusinessInvitationRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Notifications\EmailService;
use Agenda\UseCases\Auth\RegisterUser;
use Agenda\Domain\Exceptions\AuthException;

/**
 * Controller for business invitations.
 * 
 * Endpoints:
 * - GET    /v1/businesses/{business_id}/invitations       - List invitations
 * - POST   /v1/businesses/{business_id}/invitations       - Create invitation
 * - DELETE /v1/businesses/{business_id}/invitations/{id}  - Revoke invitation
 * - GET    /v1/invitations/{token}                        - Get invitation details (public)
 * - POST   /v1/invitations/{token}/accept                 - Accept invitation (auth required)
 * - POST   /v1/invitations/{token}/accept-public          - Accept invitation without login (existing user)
 * - POST   /v1/invitations/{token}/decline                - Decline invitation (public)
 * - POST   /v1/invitations/{token}/register               - Register and accept invitation
 */
final class BusinessInvitationsController
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly BusinessInvitationRepository $invitationRepo,
        private readonly LocationRepository $locationRepo,
        private readonly StaffRepository $staffRepo,
        private readonly UserRepository $userRepo,
        private readonly RegisterUser $registerUser,
    ) {}

    /**
     * GET /v1/businesses/{business_id}/invitations
     * List invitations for a business.
     * Query param:
     * - status=pending|accepted|expired|declined|revoked|all (default: pending)
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

        $statusFilter = strtolower((string) ($request->queryParam('status', 'pending') ?? 'pending'));
        $allowedFilters = ['pending', 'accepted', 'expired', 'declined', 'revoked', 'all'];
        if (!in_array($statusFilter, $allowedFilters, true)) {
            return Response::validationError('Invalid status filter', $request->traceId);
        }

        $invitations = $this->invitationRepo->findByBusiness($businessId);
        $nowTs = time();
        $normalized = array_map(function (array $inv) use ($nowTs): array {
            $effectiveStatus = $inv['status'];
            if ($inv['status'] === 'pending' && strtotime((string) $inv['expires_at']) < $nowTs) {
                $effectiveStatus = 'expired';
            }

            return [
                'id' => (int) $inv['id'],
                'email' => $inv['email'],
                'role' => $inv['role'],
                'staff_id' => isset($inv['staff_id']) && $inv['staff_id'] !== null ? (int) $inv['staff_id'] : null,
                'scope_type' => $inv['scope_type'],
                'location_ids' => array_map('intval', $inv['location_ids'] ?? []),
                'status' => $inv['status'],
                'effective_status' => $effectiveStatus,
                'expires_at' => $inv['expires_at'],
                'accepted_at' => $inv['accepted_at'] ?? null,
                'created_at' => $inv['created_at'],
                'invited_by' => [
                    'first_name' => $inv['inviter_first_name'],
                    'last_name' => $inv['inviter_last_name'],
                ],
            ];
        }, $invitations);

        if ($statusFilter !== 'all') {
            $normalized = array_values(array_filter(
                $normalized,
                fn(array $inv): bool => $inv['effective_status'] === $statusFilter
            ));
        }

        return Response::success([
            'invitations' => $normalized,
        ]);
    }

    /**
     * POST /v1/businesses/{business_id}/invitations
     * Create a new invitation.
     * 
     * Body:
     * {
     *   "email": "user@example.com",
     *   "role": "staff|manager|viewer|admin"
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
        $staffId = isset($body['staff_id']) ? (int) $body['staff_id'] : null;

        // Validate role
        if (!in_array($role, ['staff', 'manager', 'viewer', 'admin'], true)) {
            return Response::validationError('Role must be staff, manager, viewer, or admin', $request->traceId);
        }

        if ($role === 'staff' && ($staffId === null || $staffId <= 0)) {
            return Response::validationError('staff_id is required when role is staff', $request->traceId);
        }

        if ($role !== 'staff') {
            $staffId = null;
        }

        // Check if user already has access
        $existingUser = $this->userRepo->findByEmail($email);
        if ($existingUser && $this->businessUserRepo->hasAccess((int) $existingUser['id'], $businessId)) {
            return Response::validationError(
                'User already has access to this business',
                $request->traceId
            );
        }

        $previousPending = $this->invitationRepo->findPendingByEmailAndBusiness($email, $businessId);

        // Invalidate previous invites for the same business/email.
        // The new invitation must be the only pending valid token.
        $this->invitationRepo->revokePreviousByEmailAndBusiness($email, $businessId);

        // Check role hierarchy
        $currentRole = $this->getEffectiveRole($userId, $businessId);
        if (!$this->businessUserRepo->canAssignRole($currentRole, $role)) {
            return Response::forbidden(
                'Cannot invite with a role equal to or higher than your own',
                $request->traceId
            );
        }

        // Validate scope_type and location_ids
        $scopeType = $body['scope_type'] ?? 'business';
        $locationIds = $body['location_ids'] ?? [];
        
        if (!in_array($scopeType, ['business', 'locations'], true)) {
            return Response::validationError('scope_type must be business or locations', $request->traceId);
        }
        
        if ($scopeType === 'locations' && empty($locationIds)) {
            return Response::validationError('location_ids required when scope_type is locations', $request->traceId);
        }
        
        if ($scopeType === 'locations') {
            $normalizedLocationIds = array_values(array_unique(array_map('intval', $locationIds)));
            $normalizedLocationIds = array_values(array_filter($normalizedLocationIds, fn(int $id): bool => $id > 0));

            if (empty($normalizedLocationIds)) {
                return Response::validationError('location_ids required when scope_type is locations', $request->traceId);
            }

            $locationsBusinessId = $this->locationRepo->allBelongToSameBusiness($normalizedLocationIds);
            if ($locationsBusinessId === null || $locationsBusinessId !== $businessId) {
                return Response::validationError(
                    'location_ids must belong to the specified business',
                    $request->traceId
                );
            }

            $locationIds = $normalizedLocationIds;
        } else {
            $locationIds = [];
        }

        if ($role === 'staff' && $scopeType === 'locations' && count($locationIds) > 1) {
            return Response::validationError(
                'staff role supports only one location when scope_type is locations',
                $request->traceId
            );
        }

        if ($staffId !== null) {
            if (!$this->staffRepo->belongsToBusiness($staffId, $businessId)) {
                return Response::validationError(
                    'staff_id must belong to the specified business',
                    $request->traceId
                );
            }

            if ($scopeType === 'locations') {
                $staffLocationIds = array_map('intval', $this->staffRepo->getLocationIds($staffId));
                $allowedLocationIds = array_map('intval', $locationIds);
                if (empty(array_intersect($staffLocationIds, $allowedLocationIds))) {
                    return Response::validationError(
                        'staff_id must be assigned to at least one selected location',
                        $request->traceId
                    );
                }
            }
        }

        // Create invitation
        $result = $this->invitationRepo->create([
            'business_id' => $businessId,
            'email' => $email,
            'role' => $role,
            'staff_id' => $staffId,
            'scope_type' => $scopeType,
            'location_ids' => $locationIds,
            'invited_by' => $userId,
        ]);

        $business = $this->businessRepo->findById($businessId);
        $inviteUrl = $this->buildInviteUrl($result['token']);

        $emailSent = $this->sendInvitationEmail(
            $email,
            (string) ($business['name'] ?? 'Agenda'),
            $inviteUrl,
            $role,
        );

        if (!$emailSent) {
            $this->invitationRepo->delete((int) $result['id']);
            if ($previousPending !== null && isset($previousPending['id'])) {
                $this->invitationRepo->restorePending((int) $previousPending['id']);
            }
            return Response::serverError('Failed to send invitation email', $request->traceId);
        }

        return Response::created([
            'id' => $result['id'],
            'email' => $email,
            'role' => $role,
            'staff_id' => $staffId,
            'scope_type' => $scopeType,
            'location_ids' => array_map('intval', $locationIds),
            'token' => $result['token'],
            'expires_at' => $result['expires_at'],
            'invite_url' => $inviteUrl,
            'business' => [
                'id' => $businessId,
                'name' => $business['name'],
            ],
            'email_sent' => true,
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

        $invitation = $this->invitationRepo->findById($invitationId);
        if ($invitation === null || (int) $invitation['business_id'] !== $businessId) {
            return Response::notFound('Invitation not found', $request->traceId);
        }

        // Any non-pending invitation can be removed from history.
        // Pending is removed directly as well.
        $this->invitationRepo->delete($invitationId);
        return Response::success([
            'message' => 'Invitation deleted',
            'id' => $invitationId,
            'action' => 'deleted',
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

        $existingUser = $this->userRepo->findByEmail((string) $invitation['email']);

        return Response::success([
            'email' => $invitation['email'],
            'role' => $invitation['role'],
            'staff_id' => isset($invitation['staff_id']) && $invitation['staff_id'] !== null ? (int) $invitation['staff_id'] : null,
            'user_exists' => $existingUser !== null,
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
            $this->syncExistingUserScopeWithInvitation($userId, $invitation);
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
            'staff_id' => isset($invitation['staff_id']) && $invitation['staff_id'] !== null ? (int) $invitation['staff_id'] : null,
            'scope_type' => $invitation['scope_type'],
            'location_ids' => $invitation['location_ids'] ?? [],
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
            'staff_id' => isset($invitation['staff_id']) && $invitation['staff_id'] !== null ? (int) $invitation['staff_id'] : null,
            'scope_type' => $invitation['scope_type'],
            'location_ids' => array_map('intval', $invitation['location_ids'] ?? []),
        ]);
    }

    /**
     * POST /v1/invitations/{token}/accept-public
     * Accept invitation using token only.
     * If invited email already has an account, grant business access immediately.
     */
    public function acceptPublic(Request $request): Response
    {
        $token = $request->getAttribute('token');
        $invitation = $this->invitationRepo->findByToken((string) $token);
        if ($invitation === null) {
            return Response::notFound('Invitation not found', $request->traceId);
        }

        if (strtotime($invitation['expires_at']) < time()) {
            return Response::validationError('Invitation has expired', $request->traceId);
        }

        if (($invitation['status'] ?? '') !== 'pending') {
            return Response::validationError('Invitation is no longer valid', $request->traceId);
        }

        $email = strtolower((string) $invitation['email']);
        $user = $this->userRepo->findByEmail($email);
        if ($user === null) {
            return Response::error(
                'Account not found for invited email. Please register first',
                'invitation_account_not_found',
                409,
                $request->traceId
            );
        }

        $userId = (int) $user['id'];
        $businessId = (int) $invitation['business_id'];

        if ($this->businessUserRepo->hasAccess($userId, $businessId)) {
            $this->invitationRepo->accept((int) $invitation['id'], $userId);
            $this->syncExistingUserScopeWithInvitation($userId, $invitation);
            return Response::success([
                'message' => 'Invitation accepted',
                'business_id' => $businessId,
                'already_had_access' => true,
            ]);
        }

        $this->invitationRepo->accept((int) $invitation['id'], $userId);
        $this->businessUserRepo->create([
            'business_id' => $businessId,
            'user_id' => $userId,
            'role' => $invitation['role'],
            'staff_id' => isset($invitation['staff_id']) && $invitation['staff_id'] !== null ? (int) $invitation['staff_id'] : null,
            'scope_type' => $invitation['scope_type'],
            'location_ids' => $invitation['location_ids'] ?? [],
            'invited_by' => (int) $invitation['invited_by'],
            'invited_at' => $invitation['created_at'],
            'accepted_at' => date('Y-m-d H:i:s'),
        ]);

        return Response::success([
            'message' => 'Invitation accepted',
            'business_id' => $businessId,
            'already_had_access' => false,
        ]);
    }

    /**
     * POST /v1/invitations/{token}/decline
     * Decline an invitation (public endpoint via token).
     */
    public function decline(Request $request): Response
    {
        $token = $request->getAttribute('token');
        $invitation = $this->invitationRepo->findByToken($token);
        if ($invitation === null) {
            return Response::notFound('Invitation not found', $request->traceId);
        }

        if (strtotime($invitation['expires_at']) < time()) {
            return Response::validationError('Invitation has expired', $request->traceId);
        }

        if ($invitation['status'] !== 'pending') {
            return Response::validationError(
                'Invitation is no longer valid',
                $request->traceId
            );
        }

        $this->invitationRepo->decline((int) $invitation['id']);

        return Response::success([
            'message' => 'Invitation declined',
            'business_id' => (int) $invitation['business_id'],
        ]);
    }

    /**
     * POST /v1/invitations/{token}/register
     * Register a new operator account and accept invitation in one step.
     */
    public function register(Request $request): Response
    {
        $token = $request->getAttribute('token');
        $invitation = $this->invitationRepo->findByToken((string) $token);
        if ($invitation === null) {
            return Response::notFound('Invitation not found', $request->traceId);
        }

        if (strtotime($invitation['expires_at']) < time()) {
            return Response::validationError('Invitation has expired', $request->traceId);
        }

        if (($invitation['status'] ?? '') !== 'pending') {
            return Response::validationError('Invitation is no longer valid', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $password = (string) ($body['password'] ?? '');
        $firstName = trim((string) ($body['first_name'] ?? ''));
        $lastName = trim((string) ($body['last_name'] ?? ''));

        if ($password === '') {
            return Response::validationError('Password is required', $request->traceId);
        }

        if ($firstName === '') {
            return Response::validationError('First name is required', $request->traceId);
        }

        $email = strtolower((string) $invitation['email']);
        if ($this->userRepo->findByEmail($email) !== null) {
            return Response::error(
                'Email already registered. Please sign in to accept invitation',
                'invitation_email_already_registered',
                409,
                $request->traceId
            );
        }

        try {
            $auth = $this->registerUser->execute(
                $email,
                $password,
                $firstName,
                $lastName,
                null,
                $request->getHeader('User-Agent'),
                $request->getClientIp()
            );
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus(), $request->traceId);
        }

        $userId = (int) ($auth['user']['id'] ?? 0);
        if ($userId <= 0) {
            return Response::serverError('Unable to register user', $request->traceId);
        }

        $this->invitationRepo->accept((int) $invitation['id'], $userId);
        $this->businessUserRepo->create([
            'business_id' => (int) $invitation['business_id'],
            'user_id' => $userId,
            'role' => $invitation['role'],
            'staff_id' => isset($invitation['staff_id']) && $invitation['staff_id'] !== null ? (int) $invitation['staff_id'] : null,
            'scope_type' => $invitation['scope_type'],
            'location_ids' => $invitation['location_ids'] ?? [],
            'invited_by' => (int) $invitation['invited_by'],
            'invited_at' => $invitation['created_at'],
            'accepted_at' => date('Y-m-d H:i:s'),
        ]);

        $response = Response::success([
            'message' => 'Invitation accepted',
            'access_token' => $auth['access_token'],
            'refresh_token' => $auth['refresh_token'],
            'expires_in' => $auth['expires_in'],
            'user' => $auth['user'],
            'business' => [
                'id' => (int) $invitation['business_id'],
                'name' => $invitation['business_name'],
            ],
            'role' => $invitation['role'],
        ], 201);

        $response->setCookie(
            'refresh_token',
            (string) $auth['refresh_token'],
            [
                'httpOnly' => true,
                'secure' => true,
                'sameSite' => 'Strict',
                'maxAge' => 90 * 24 * 60 * 60,
                'path' => '/v1/auth',
            ]
        );

        return $response;
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

    /**
     * For already-associated users, align scope/locations (and role) to invitation payload.
     */
    private function syncExistingUserScopeWithInvitation(int $userId, array $invitation): void
    {
        $businessUser = $this->businessUserRepo->findByUserAndBusiness(
            $userId,
            (int) $invitation['business_id']
        );
        if ($businessUser === null || !isset($businessUser['id'])) {
            return;
        }

        $scopeType = (string) ($invitation['scope_type'] ?? 'business');
        $locationIds = $scopeType === 'locations'
            ? array_map('intval', $invitation['location_ids'] ?? [])
            : [];

        $this->businessUserRepo->update((int) $businessUser['id'], [
            'role' => (string) ($invitation['role'] ?? 'staff'),
            'staff_id' => isset($invitation['staff_id']) && $invitation['staff_id'] !== null ? (int) $invitation['staff_id'] : null,
            'scope_type' => $scopeType,
            'location_ids' => $locationIds,
        ]);
    }

    private function buildInviteUrl(string $token): string
    {
        // Invitations are for operator access in the gestionale (agenda_backend),
        // not for customer booking frontend.
        $baseUrl = $_ENV['BACKEND_URL'] ?? 'https://gestionale.romeolab.it';
        return $baseUrl . '/invitation/' . $token;
    }

    private function sendInvitationEmail(
        string $recipientEmail,
        string $businessName,
        string $inviteUrl,
        string $role
    ): bool {
        $locale = strtolower((string) ($_ENV['DEFAULT_LOCALE'] ?? 'it'));
        $roleLabel = match ($role) {
            'admin' => $locale === 'en' ? 'Administrator' : 'Amministratore',
            'manager' => $locale === 'en' ? 'Manager' : 'Manager',
            'viewer' => $locale === 'en' ? 'Viewer' : 'Visualizzatore',
            default => $locale === 'en' ? 'Staff' : 'Staff',
        };

        if ($locale === 'en') {
            $subject = 'You have been invited to ' . $businessName;
            $html = <<<HTML
<p>Hello,</p>
<p>You have been invited to join <strong>{$businessName}</strong> as <strong>{$roleLabel}</strong>.</p>
<p>Open this link to continue:</p>
<p><a href="{$inviteUrl}">{$inviteUrl}</a></p>
HTML;
        } else {
            $subject = 'Invito a collaborare con ' . $businessName;
            $html = <<<HTML
<p>Ciao,</p>
<p>Sei stato invitato a collaborare con <strong>{$businessName}</strong> con ruolo <strong>{$roleLabel}</strong>.</p>
<p>Apri questo link per continuare:</p>
<p><a href="{$inviteUrl}">{$inviteUrl}</a></p>
HTML;
        }

        try {
            return EmailService::create()->send($recipientEmail, $subject, $html);
        } catch (\Throwable $e) {
            error_log('[BusinessInvitationsController] Failed to send invitation email: ' . $e->getMessage());
            return false;
        }
    }
}
