<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;

/**
 * Health check endpoint for monitoring and load balancers
 */
final class HealthController
{
    public function check(Request $request): Response
    {
        return Response::json([
            'status' => 'ok',
            'timestamp' => date('c'),
            'version' => '1.0.0',
        ]);
    }
}
