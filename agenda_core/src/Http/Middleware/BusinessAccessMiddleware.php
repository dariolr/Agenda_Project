<?php

declare(strict_types=1);

namespace Agenda\Http\Middleware;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Middleware that validates user access to a business.
 * 
 * Logic:
 * - Superadmin: Always allowed, effective_role = 'admin'
 * - Normal user: Must have business_users entry, effective_role from DB
 * - No access: HTTP 403
 * 
 * Requires business_id in request attributes (set by LocationContextMiddleware
 * or extracted from route param).
 * 
 * Sets in request attributes:
 * - effective_role: 'owner' | 'admin' | 'manager' | 'staff'
 * - is_superadmin: bool
 */
final class BusinessAccessMiddleware implements MiddlewareInterface
{
    /**
     * @param string $businessIdSource How to get business_id:
     *   - 'attribute': From request attribute (set by prior middleware)
     *   - 'route': From route param {business_id}
     * @param array<string> $allowedRoles Minimum roles allowed (if empty, any role works)
     */
    public function __construct(
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly string $businessIdSource = 'attribute',
        private readonly array $allowedRoles = [],
    ) {}

    public function handle(Request $request): ?Response
    {
        $userId = $request->userId();
        if ($userId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        // Extract business_id
        $businessId = $this->extractBusinessId($request);
        if ($businessId === null) {
            return Response::validationError('business_id is required', $request->traceId);
        }

        // Check if superadmin
        if ($this->userRepo->isSuperadmin($userId)) {
            $request->setAttribute('effective_role', 'admin');
            $request->setAttribute('is_superadmin', true);
            return null; // Allowed
        }

        // Check business_users for normal users
        $role = $this->businessUserRepo->getRole($userId, $businessId);
        
        if ($role === null) {
            return Response::forbidden(
                'You do not have access to this business',
                $request->traceId
            );
        }

        // Check role restriction if specified
        if (!empty($this->allowedRoles) && !in_array($role, $this->allowedRoles, true)) {
            return Response::forbidden(
                'Insufficient permissions for this action',
                $request->traceId
            );
        }

        $request->setAttribute('effective_role', $role);
        $request->setAttribute('is_superadmin', false);

        return null; // Allowed
    }

    private function extractBusinessId(Request $request): ?int
    {
        if ($this->businessIdSource === 'route') {
            $value = $request->getRouteParam('business_id');
        } else {
            // From attribute (set by LocationContextMiddleware)
            $value = $request->getAttribute('business_id');
        }

        if ($value === null || $value === '') {
            return null;
        }

        return (int) $value;
    }
}
