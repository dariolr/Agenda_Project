<?php

declare(strict_types=1);

namespace Agenda\Http;

final class Router
{
    private array $routes = [];

    public function get(string $path, string $controller, string $method, array $middleware = []): void
    {
        $this->addRoute('GET', $path, $controller, $method, $middleware);
    }

    public function post(string $path, string $controller, string $method, array $middleware = []): void
    {
        $this->addRoute('POST', $path, $controller, $method, $middleware);
    }

    public function put(string $path, string $controller, string $method, array $middleware = []): void
    {
        $this->addRoute('PUT', $path, $controller, $method, $middleware);
    }

    public function patch(string $path, string $controller, string $method, array $middleware = []): void
    {
        $this->addRoute('PATCH', $path, $controller, $method, $middleware);
    }

    public function delete(string $path, string $controller, string $method, array $middleware = []): void
    {
        $this->addRoute('DELETE', $path, $controller, $method, $middleware);
    }

    private function addRoute(string $httpMethod, string $path, string $controller, string $method, array $middleware): void
    {
        $pattern = preg_replace('/\{([a-zA-Z_]+)\}/', '(?P<$1>[^/]+)', $path);
        $pattern = '#^' . $pattern . '$#';
        
        $this->routes[] = [
            'httpMethod' => $httpMethod,
            'pattern' => $pattern,
            'path' => $path,
            'controller' => $controller,
            'method' => $method,
            'middleware' => $middleware,
        ];
    }

    public function match(string $method, string $path): ?array
    {
        foreach ($this->routes as $route) {
            if ($route['httpMethod'] !== $method) {
                continue;
            }
            
            if (preg_match($route['pattern'], $path, $matches)) {
                $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
                return [
                    'controller' => $route['controller'],
                    'method' => $route['method'],
                    'middleware' => $route['middleware'],
                    'params' => $params,
                ];
            }
        }
        
        return null;
    }
}
