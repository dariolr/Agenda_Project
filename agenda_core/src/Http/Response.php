<?php

declare(strict_types=1);

namespace Agenda\Http;

use Agenda\Infrastructure\Environment\EnvironmentConfig;
use Agenda\Infrastructure\Support\Json;

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

    public static function error(
        string $message,
        string $code,
        int $status = 400,
        ?string $traceId = null,
        array $params = [],
        ?string $messageKey = null
    ): self
    {
        $resolvedParams = self::resolveParams($code, $message, $params);
        $resolvedMessageKey = $messageKey ?? self::resolveMessageKey($code, $message);

        return new self($status, [
            'success' => false,
            'error' => [
                'code' => $code,
                'message' => $message,
                'message_key' => $resolvedMessageKey,
                'params' => (object) $resolvedParams,
            ],
        ], $traceId);
    }

    public static function unauthorized(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'unauthorized', 401, $traceId);
    }

    public static function badRequest(array|string $data, ?string $traceId = null): self
    {
        $message = is_array($data)
            ? (string) ($data['error'] ?? 'Bad request')
            : (string) $data;
        return self::error($message, 'bad_request', 400, $traceId);
    }

    public static function ok(array $data): self
    {
        return self::success($data, 200);
    }

    public static function forbidden(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'forbidden', 403, $traceId);
    }

    public static function notFound(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'not_found', 404, $traceId);
    }

    public static function noContent(?string $traceId = null): self
    {
        return new self(204, ['success' => true], $traceId);
    }

    public static function conflict(string $code, string $message, ?string $traceId = null): self
    {
        return self::error($message, $code, 409, $traceId);
    }

    public static function validationError(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'validation_error', 422, $traceId);
    }

    public static function serverError(string $message, ?string $traceId = null): self
    {
        return self::error($message, 'internal_error', 500, $traceId);
    }

    public static function demoBlocked(string $message = 'Action is blocked in demo environment', ?string $traceId = null): self
    {
        $resolvedParams = self::resolveParams('demo_blocked', $message, ['reason' => 'demo_blocked']);

        return new self(403, [
            'success' => false,
            'error' => [
                'code' => 'demo_blocked',
                'message' => $message,
                'message_key' => 'errors.demo_blocked',
                'params' => (object) $resolvedParams,
                'demo_blocked' => true,
            ],
        ], $traceId);
    }

    private static function resolveMessageKey(string $code, string $message): string
    {
        if (self::isGenericErrorCode($code)) {
            if (self::isMachineKey($message)) {
                return 'errors.' . str_replace('-', '_', $message);
            }

            return 'errors.' . $code . '.' . self::normalizeToKey($message);
        }

        return 'errors.' . str_replace('-', '_', $code);
    }

    private static function resolveParams(string $code, string $message, array $params): array
    {
        if (isset($params['reason'])) {
            return $params;
        }

        $params['reason'] = self::resolveReasonCode($code, $message);
        return $params;
    }

    private static function resolveReasonCode(string $code, string $message): string
    {
        if (self::isMachineKey($message)) {
            return str_replace('-', '_', $message);
        }

        if (!self::isGenericErrorCode($code)) {
            return str_replace('-', '_', $code);
        }

        return $code . '__' . self::normalizeToKey($message);
    }

    private static function isMachineKey(string $value): bool
    {
        return (bool) preg_match('/^[a-z0-9]+([._-][a-z0-9]+)*$/', $value);
    }

    private static function isGenericErrorCode(string $code): bool
    {
        return in_array($code, [
            'bad_request',
            'validation_error',
            'forbidden',
            'not_found',
            'unauthorized',
            'internal_error',
        ], true);
    }

    private static function normalizeToKey(string $value): string
    {
        $normalized = strtolower(trim($value));
        $normalized = preg_replace('/[^a-z0-9]+/', '_', $normalized) ?? '';
        $normalized = trim($normalized, '_');

        return $normalized !== '' ? $normalized : 'unknown';
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
        $allowedOrigins = array_map('trim', explode(',', EnvironmentConfig::current()->corsAllowedOrigins));
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
        
        echo Json::encode($this->normalizeOutputData());
    }

    private function normalizeOutputData(): array
    {
        $payload = $this->data;

        if ($this->status < 400) {
            return $payload;
        }

        $error = $payload['error'] ?? null;
        if (!is_array($error)) {
            $message = is_string($error) ? $error : (string) ($payload['message'] ?? 'Request failed');
            $payload['success'] = false;
            $payload['error'] = [
                'code' => 'internal_error',
                'message_key' => self::resolveMessageKey('internal_error', $message),
                'params' => (object) self::resolveParams('internal_error', $message, []),
            ];
            unset($payload['message']);
            return $payload;
        }

        $code = isset($error['code']) && is_string($error['code']) && $error['code'] !== ''
            ? $error['code']
            : 'internal_error';
        $message = is_string($error['message'] ?? null)
            ? $error['message']
            : (string) ($payload['message'] ?? $code);
        $params = is_array($error['params'] ?? null) ? $error['params'] : [];
        $messageKey = (isset($error['message_key']) && is_string($error['message_key']) && $error['message_key'] !== '')
            ? $error['message_key']
            : self::resolveMessageKey($code, $message);

        $error['code'] = $code;
        $error['message_key'] = $messageKey;
        $error['params'] = (object) self::resolveParams($code, $message, $params);
        unset($error['message']);

        $payload['success'] = false;
        $payload['error'] = $error;
        unset($payload['message']);

        return $payload;
    }
}
