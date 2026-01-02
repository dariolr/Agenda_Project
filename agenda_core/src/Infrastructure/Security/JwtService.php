<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Security;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
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
        $this->refreshTtl = (int) ($_ENV['JWT_REFRESH_TTL'] ?? 864000); // 10 days
    }

    /**
     * Generate access token for OPERATORS (users table).
     * Contains user_id in 'sub', role='operator'.
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
            'role' => 'operator', // Distinguishes from customer tokens
        ];

        return JWT::encode($payload, $this->secret, $this->algorithm);
    }

    /**
     * Generate access token for CUSTOMERS (clients table).
     * Contains client_id in 'sub', role='customer', business_id.
     */
    public function generateCustomerAccessToken(int $clientId, int $businessId): string
    {
        $now = time();
        
        $payload = [
            'iss' => 'agenda_core',
            'sub' => (string) $clientId,
            'iat' => $now,
            'exp' => $now + $this->accessTtl,
            'type' => 'access',
            'role' => 'customer',
            'business_id' => $businessId,
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
     * Returns array with payload on success.
     * Returns ['expired' => true] if token is expired (for refresh flow).
     * Returns null if token is invalid.
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
        } catch (ExpiredException) {
            // Token scaduto ma valido - permette refresh
            return ['expired' => true];
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
