<?php

declare(strict_types=1);

namespace Agenda\Http\Middleware;

use Agenda\Http\Request;
use Agenda\Http\Response;

interface MiddlewareInterface
{
    /**
     * Handle the request.
     * 
     * @return Response|null Return Response to stop chain, null to continue
     */
    public function handle(Request $request): ?Response;
}
