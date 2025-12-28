<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Http\Router;

final class RouterTest extends TestCase
{
    private Router $router;

    protected function setUp(): void
    {
        $this->router = new Router();
    }

    public function testCanRegisterGetRoute(): void
    {
        $this->router->get('/v1/services', 'TestController', 'index');

        $match = $this->router->match('GET', '/v1/services');

        $this->assertNotNull($match);
        $this->assertEquals('TestController', $match['controller']);
        $this->assertEquals('index', $match['method']);
    }

    public function testCanRegisterPostRoute(): void
    {
        $this->router->post('/v1/auth/login', 'AuthController', 'login');

        $match = $this->router->match('POST', '/v1/auth/login');

        $this->assertNotNull($match);
        $this->assertEquals('AuthController', $match['controller']);
        $this->assertEquals('login', $match['method']);
    }

    public function testCanMatchRouteWithParameters(): void
    {
        $this->router->post('/v1/locations/{location_id}/bookings', 'BookingsController', 'store');

        $match = $this->router->match('POST', '/v1/locations/42/bookings');

        $this->assertNotNull($match);
        $this->assertEquals('BookingsController', $match['controller']);
        $this->assertEquals('store', $match['method']);
        $this->assertEquals('42', $match['params']['location_id']);
    }

    public function testReturnsNullForUnknownRoute(): void
    {
        $match = $this->router->match('GET', '/unknown');
        $this->assertNull($match);
    }

    public function testReturnsNullForWrongMethod(): void
    {
        $this->router->get('/v1/services', 'ServicesController', 'index');

        $match = $this->router->match('POST', '/v1/services');
        $this->assertNull($match);
    }

    public function testMiddlewareIsIncluded(): void
    {
        $this->router->get('/v1/me', 'AuthController', 'me', ['auth']);

        $match = $this->router->match('GET', '/v1/me');

        $this->assertNotNull($match);
        $this->assertEquals(['auth'], $match['middleware']);
    }

    public function testMultipleMiddleware(): void
    {
        $this->router->post('/v1/locations/{id}/bookings', 'BookingsController', 'store', ['auth', 'location_path', 'idempotency']);

        $match = $this->router->match('POST', '/v1/locations/1/bookings');

        $this->assertNotNull($match);
        $this->assertEquals(['auth', 'location_path', 'idempotency'], $match['middleware']);
    }
}
