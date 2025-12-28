<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Security;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Throwable;

final class JwtService
{
    private string $secret;
    private int $accessTtl;
    private int $refreshTtl;
    private string $algorithm = 'HS256';

    public function __construct()
    {
        $this->secret = $_ENV['JWT_SECRET'] ?? throw new \RuntimeException('JWT_SECRET not configured');
        $this->accessTtl = (int) ($_ENV['JWT_ACCESS_TTL'] ?? 900); // 15 minutes
        $this->refreshTtl = (int) ($_ENV['JWT_REFRESH_TTL'] ?? 7776000); // 90 days
    }

    /**
     * Generate access token containing ONLY user_id.
     * NEVER include business_id or location_id.
     */
    public function generateAccessToken(int $userId): string
    {
        $now = time();
        
        $payload = [
            'iss' => 'agenda_core',
            'sub' => (string) $userId,
            'iat' => $now,
            'exp' => $now + $this->accessTtl,
            'type' => 'access',
        ];

        return JWT::encode($payload, $this->secret, $this->algorithm);
    }

    /**
     * Generate refresh token (random, stored as hash in DB).
     */
    public function generateRefreshToken(): string
    {
        return bin2hex(random_bytes(32));
    }

    /**
     * Hash refresh token for storage.
     */
    public function hashRefreshToken(string $token): string
    {
        return hash('sha256', $token);
    }

    /**
     * Validate access token and return payload if valid.
     */
    public function validateAccessToken(string $token): ?array
    {
        try {
            $decoded = JWT::decode($token, new Key($this->secret, $this->algorithm));
            $payload = (array) $decoded;

            if (($payload['type'] ?? '') !== 'access') {
                return null;
            }

            return $payload;
        } catch (Throwable) {
            return null;
        }
    }

    public function getRefreshTtl(): int
    {
        return $this->refreshTtl;
    }

    public function getAccessTokenTtl(): int
    {
        return $this->accessTtl;
    }
}
