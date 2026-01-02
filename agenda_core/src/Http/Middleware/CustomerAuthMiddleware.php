<?php

declare(strict_types=1);

namespace Agenda\Http\Middleware;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Security\JwtService;

/**
 * Middleware for customer authentication (self-service booking).
 * Validates JWT tokens with role='customer'.
 * Sets client_id and business_id attributes on request.
 */
final class CustomerAuthMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly JwtService $jwtService,
    ) {}

    public function handle(Request $request): ?Response
    {
        $token = $request->bearerToken();
        
        if ($token === null) {
            return Response::unauthorized('Missing authorization token', $request->traceId);
        }

        $payload = $this->jwtService->validateAccessToken($token);
        
        if ($payload === null) {
            return Response::unauthorized('Invalid token', $request->traceId);
        }

        // Token expired but valid - client can refresh
        if (isset($payload['expired']) && $payload['expired'] === true) {
            return Response::error('Token has expired', 'token_expired', 401);
        }

        // Verify this is a customer token
        $role = $payload['role'] ?? 'operator';
        if ($role !== 'customer') {
            return Response::unauthorized('Invalid token type', $request->traceId);
        }

        // Set client_id and business_id from token
        $request->setAttribute('client_id', (int) $payload['sub']);
        $request->setAttribute('business_id', (int) $payload['business_id']);

        return null;
    }
}
