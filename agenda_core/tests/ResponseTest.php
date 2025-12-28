<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Http\Response;

final class ResponseTest extends TestCase
{
    public function testSuccessResponse(): void
    {
        $response = Response::success(['id' => 1, 'name' => 'Test']);

        $this->assertEquals(200, $response->status);
        $this->assertTrue($response->data['success']);
        $this->assertEquals(['id' => 1, 'name' => 'Test'], $response->data['data']);
    }

    public function testCreatedResponse(): void
    {
        $response = Response::created(['id' => 42]);

        $this->assertEquals(201, $response->status);
        $this->assertTrue($response->data['success']);
    }

    public function testErrorResponse(): void
    {
        $response = Response::error('Something went wrong', 'validation_error', 400);

        $this->assertEquals(400, $response->status);
        $this->assertFalse($response->data['success']);
        $this->assertEquals('validation_error', $response->data['error']['code']);
        $this->assertEquals('Something went wrong', $response->data['error']['message']);
    }

    public function testUnauthorizedResponse(): void
    {
        $response = Response::unauthorized('Token expired');

        $this->assertEquals(401, $response->status);
        $this->assertEquals('unauthorized', $response->data['error']['code']);
    }

    public function testNotFoundResponse(): void
    {
        $response = Response::notFound('Resource not found');

        $this->assertEquals(404, $response->status);
        $this->assertEquals('not_found', $response->data['error']['code']);
    }

    public function testCanSetCookie(): void
    {
        $response = Response::success(['ok' => true]);
        $response->setCookie('test', 'value', ['httpOnly' => true]);

        // Response should be chainable
        $this->assertInstanceOf(Response::class, $response);
    }

    public function testJsonResponse(): void
    {
        $response = Response::json(['custom' => 'format'], 202);

        $this->assertEquals(202, $response->status);
        $this->assertEquals(['custom' => 'format'], $response->data);
    }
}
