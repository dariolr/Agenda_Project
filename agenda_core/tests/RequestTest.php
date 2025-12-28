<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Http\Request;

final class RequestTest extends TestCase
{
    public function testCanCreateRequestManually(): void
    {
        $request = new Request(
            'GET',
            '/v1/services',
            ['location_id' => '1'],
            ['content-type' => 'application/json'],
            null,
            'test-trace-id'
        );

        $this->assertEquals('GET', $request->method);
        $this->assertEquals('/v1/services', $request->path);
        $this->assertEquals(['location_id' => '1'], $request->query);
        $this->assertEquals('test-trace-id', $request->traceId);
    }

    public function testCanSetAndGetAttributes(): void
    {
        $request = new Request('GET', '/', [], [], null, 'trace');
        
        $request->setAttribute('user_id', 42);
        $request->setAttribute('business_id', 1);

        $this->assertEquals(42, $request->getAttribute('user_id'));
        $this->assertEquals(1, $request->getAttribute('business_id'));
        $this->assertNull($request->getAttribute('missing'));
        $this->assertEquals('default', $request->getAttribute('missing', 'default'));
    }

    public function testCanExtractBearerToken(): void
    {
        $request = new Request(
            'GET',
            '/',
            [],
            ['authorization' => 'Bearer test-token-123'],
            null,
            'trace'
        );

        $this->assertEquals('test-token-123', $request->bearerToken());
    }

    public function testBearerTokenReturnsNullWithoutAuth(): void
    {
        $request = new Request('GET', '/', [], [], null, 'trace');
        $this->assertNull($request->bearerToken());
    }

    public function testCanGetCookies(): void
    {
        $request = new Request(
            'GET',
            '/',
            [],
            [],
            null,
            'trace',
            ['refresh_token' => 'my-refresh-token']
        );

        $this->assertEquals('my-refresh-token', $request->getCookie('refresh_token'));
        $this->assertNull($request->getCookie('missing'));
    }
}
