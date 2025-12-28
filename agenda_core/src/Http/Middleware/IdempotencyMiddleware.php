<?php

declare(strict_types=1);

namespace Agenda\Http\Middleware;

use Agenda\Http\Request;
use Agenda\Http\Response;

final class IdempotencyMiddleware implements MiddlewareInterface
{
    public function handle(Request $request): ?Response
    {
        // Try both formats: with and without X- prefix
        $idempotencyKey = $request->header('x-idempotency-key') 
            ?? $request->header('idempotency-key');
        
        if ($idempotencyKey !== null) {
            // Validate UUID format
            if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i', $idempotencyKey)) {
                return Response::validationError('Invalid Idempotency-Key format (expected UUID v4)', $request->traceId);
            }
            
            $request->setAttribute('idempotency_key', $idempotencyKey);
        }

        return null;
    }
}
