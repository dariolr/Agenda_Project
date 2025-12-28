<?php

declare(strict_types=1);

namespace Agenda\Http\Middleware;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Security\JwtService;

final class AuthMiddleware implements MiddlewareInterface
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
            return Response::unauthorized('Invalid or expired token', $request->traceId);
        }

        // Inject ONLY user_id into request context
        // NEVER extract business_id from JWT
        $request->setAttribute('user_id', (int) $payload['sub']);

        return null;
    }
}
