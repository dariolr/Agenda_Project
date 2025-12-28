<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Http\Middleware\IdempotencyMiddleware;
use Agenda\Http\Request;

/**
 * Idempotency middleware tests
 */
final class IdempotencyTest extends TestCase
{
    private IdempotencyMiddleware $middleware;

    protected function setUp(): void
    {
        $this->middleware = new IdempotencyMiddleware();
    }

    public function testAcceptsValidUuidV4(): void
    {
        // Valid UUID v4
        $uuid = '550e8400-e29b-41d4-a716-446655440000';
        
        $request = $this->createRequestWithIdempotencyKey($uuid);
        $result = $this->middleware->handle($request);

        // Should not return a Response (allows request to proceed)
        $this->assertNull($result);
        $this->assertEquals($uuid, $request->getAttribute('idempotency_key'));
    }

    public function testAcceptsMissingIdempotencyKeyForOtherEndpoints(): void
    {
        // The middleware doesn't require idempotency key - it's enforced elsewhere
        // This test verifies the middleware allows requests without the key
        $request = $this->createRequestWithIdempotencyKey(null);
        $result = $this->middleware->handle($request);

        // Should allow request to proceed (returns null)
        $this->assertNull($result);
    }

    public function testRejectsInvalidUuidFormat(): void
    {
        // Not a valid UUID v4
        $invalidUuid = 'invalid-uuid-format';
        
        $request = $this->createRequestWithIdempotencyKey($invalidUuid);
        $result = $this->middleware->handle($request);

        $this->assertInstanceOf(\Agenda\Http\Response::class, $result);
        $this->assertEquals(422, $result->status);
    }

    public function testRejectsShortUuid(): void
    {
        // Too short
        $shortUuid = '550e8400-e29b-41d4-a716';
        
        $request = $this->createRequestWithIdempotencyKey($shortUuid);
        $result = $this->middleware->handle($request);

        $this->assertInstanceOf(\Agenda\Http\Response::class, $result);
    }

    public function testRejectsNonHexCharacters(): void
    {
        // Contains non-hex characters
        $invalidUuid = 'gggggggg-gggg-4ggg-gggg-gggggggggggg';
        
        $request = $this->createRequestWithIdempotencyKey($invalidUuid);
        $result = $this->middleware->handle($request);

        $this->assertInstanceOf(\Agenda\Http\Response::class, $result);
    }

    private function createRequestWithIdempotencyKey(?string $key): Request
    {
        $headers = [];
        if ($key !== null) {
            $headers['x-idempotency-key'] = $key;
        }

        return new Request(
            method: 'POST',
            path: '/v1/locations/1/bookings',
            query: [],
            headers: $headers,
            body: [],
            traceId: 'test-trace-id',
        );
    }
}
