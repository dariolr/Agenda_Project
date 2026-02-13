<?php

declare(strict_types=1);

namespace Agenda\Http;

use Ramsey\Uuid\Uuid;

final class Request
{
    private array $attributes = [];
    private array $cookies = [];

    public function __construct(
        public readonly string $method,
        public readonly string $path,
        public readonly array $query,
        public readonly array $headers,
        public readonly ?array $body,
        public readonly string $traceId,
        array $cookies = [],
        public readonly string $rawBody = '',
    ) {
        $this->cookies = $cookies;
    }

    public static function fromGlobals(): self
    {
        $method = $_SERVER['REQUEST_METHOD'];
        $rawPath = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        
        // Strip base path prefix (e.g., /agenda_core/public) for MAMP compatibility
        $basePath = $_ENV['APP_BASE_PATH'] ?? '';
        if ($basePath !== '' && str_starts_with($rawPath, $basePath)) {
            $path = substr($rawPath, strlen($basePath)) ?: '/';
        } else {
            $path = $rawPath;
        }
        
        $query = $_GET;
        
        $headers = [];
        
        // Try getallheaders() first (Apache/FPM with mod_php)
        if (function_exists('getallheaders')) {
            foreach (getallheaders() as $name => $value) {
                $headers[strtolower($name)] = $value;
            }
        }
        
        // Fallback to $_SERVER parsing
        foreach ($_SERVER as $key => $value) {
            if (str_starts_with($key, 'HTTP_')) {
                $headerName = strtolower(str_replace('_', '-', substr($key, 5)));
                // Only add if not already set from getallheaders
                if (!isset($headers[$headerName])) {
                    $headers[$headerName] = $value;
                }
            }
        }
        
        // Special case: Authorization header may be set by htaccess
        if (!isset($headers['authorization']) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers['authorization'] = $_SERVER['HTTP_AUTHORIZATION'];
        }
        // Also check REDIRECT_ prefixed (mod_rewrite sometimes adds this)
        if (!isset($headers['authorization']) && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $headers['authorization'] = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        
        $body = null;
        $rawBody = file_get_contents('php://input');
        if ($rawBody !== '' && $rawBody !== false) {
            $body = json_decode($rawBody, true);
        }
        
        $traceId = Uuid::uuid4()->toString();
        
        return new self($method, $path, $query, $headers, $body, $traceId, $_COOKIE, (string) $rawBody);
    }

    public function getHeader(string $name): ?string
    {
        return $this->headers[strtolower($name)] ?? null;
    }

    public function header(string $name): ?string
    {
        return $this->getHeader($name);
    }

    public function bearerToken(): ?string
    {
        $auth = $this->getHeader('authorization');
        if ($auth && str_starts_with($auth, 'Bearer ')) {
            return substr($auth, 7);
        }
        return null;
    }

    public function setAttribute(string $key, mixed $value): void
    {
        $this->attributes[$key] = $value;
    }

    public function getAttribute(string $key, mixed $default = null): mixed
    {
        return $this->attributes[$key] ?? $default;
    }

    public function getBody(): ?array
    {
        return $this->body;
    }

    public function getRawBody(): string
    {
        return $this->rawBody;
    }

    public function getQuery(): array
    {
        return $this->query;
    }

    public function queryParam(string $name, ?string $default = null): ?string
    {
        return $this->query[$name] ?? $default;
    }

    public function getCookie(string $name): ?string
    {
        return $this->cookies[$name] ?? null;
    }

    public function getClientIp(): ?string
    {
        // Check X-Forwarded-For first (for proxies)
        $forwarded = $this->getHeader('x-forwarded-for');
        if ($forwarded !== null) {
            $ips = explode(',', $forwarded);
            return trim($ips[0]);
        }

        return $_SERVER['REMOTE_ADDR'] ?? null;
    }

    public function userId(): ?int
    {
        return $this->getAttribute('user_id');
    }

    public function businessId(): ?int
    {
        return $this->getAttribute('business_id');
    }

    public function locationId(): ?int
    {
        return $this->getAttribute('location_id');
    }

    /**
     * Get a route parameter (alias for getAttribute).
     * Route params are set as attributes by the Kernel after routing.
     */
    public function getRouteParam(string $name): mixed
    {
        return $this->getAttribute($name);
    }
}
