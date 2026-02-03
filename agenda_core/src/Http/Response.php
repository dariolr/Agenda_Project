<?php

declare(strict_types=1);

namespace Agenda\Http;

final class Response
{
    private array $cookies = [];

    public function __construct(
        public readonly int $status,
        public readonly array $data,
        public readonly ?string $traceId = null,
    ) {}

    public static function success(array $data, int $status = 200): self
    {
        return new self($status, [
            'success' => true,
            'data' => $data,
        ]);
    }

    public static function json(array $data, int $status = 200): self
    {
        return new self($status, $data);
    }

    public static function created(array $data): self
    {
        return self::success($data, 201);
    }

    public static function error(string $message, string $code, int $status = 400, ?string $traceId = null): self
    {
        return new self($status, [
            'success' => false,
            'error' => [
                'code' => $code,
                'message' => $message,
            ],
        ], $traceId);
    }

    public static function unauthorized(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'unauthorized', 401);
    }

    public static function badRequest(array $data, ?string $traceId = null): self
    {
        $message = $data['error'] ?? 'Bad request';
        return self::error($message, 'bad_request', 400, $traceId);
    }

    public static function ok(array $data): self
    {
        return self::success($data, 200);
    }

    public static function forbidden(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'forbidden', 403);
    }

    public static function notFound(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'not_found', 404);
    }

    public static function noContent(?string $traceId = null): self
    {
        return new self(204, ['success' => true], $traceId);
    }

    public static function conflict(string $code, string $message, ?string $traceId = null): self
    {
        return self::error($message, $code, 409);
    }

    public static function validationError(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'validation_error', 422);
    }

    public static function serverError(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'internal_error', 500);
    }

    public function setCookie(string $name, string $value, array $options = []): self
    {
        $this->cookies[$name] = [
            'value' => $value,
            'options' => $options,
        ];
        return $this;
    }

    public function send(): void
    {
        http_response_code($this->status);
        header('Content-Type: application/json; charset=utf-8');
        
        // Determina l'origin consentito dinamicamente
        $allowedOrigins = array_map('trim', explode(',', $_ENV['CORS_ALLOWED_ORIGINS'] ?? '*'));
        $requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
        $corsOrigin = in_array($requestOrigin, $allowedOrigins, true) ? $requestOrigin : ($allowedOrigins[0] ?? '*');
        header('Access-Control-Allow-Origin: ' . $corsOrigin);
        header('Access-Control-Allow-Credentials: true');
        header('Vary: Origin');
        header('Cache-Control: no-store, no-cache, must-revalidate');  // Disabilita cache proxy
        
        if ($this->traceId !== null) {
            header('X-Trace-Id: ' . $this->traceId);
        }

        // Set cookies
        foreach ($this->cookies as $name => $cookie) {
            $options = $cookie['options'];
            $cookieOptions = [
                'expires' => time() + ($options['maxAge'] ?? 0),
                'path' => $options['path'] ?? '/',
                'domain' => $options['domain'] ?? '',
                'secure' => $options['secure'] ?? true,
                'httponly' => $options['httpOnly'] ?? true,
                'samesite' => $options['sameSite'] ?? 'Lax',
            ];
            setcookie($name, $cookie['value'], $cookieOptions);
        }
        
        echo json_encode($this->data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
}
