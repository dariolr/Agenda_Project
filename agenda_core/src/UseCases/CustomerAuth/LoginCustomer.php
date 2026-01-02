<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;

/**
 * Authenticate a customer (client) for self-service booking.
 * Separate from operator auth (LoginUser).
 */
final class LoginCustomer
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
        private readonly JwtService $jwtService,
        private readonly PasswordHasher $passwordHasher,
    ) {}

    /**
     * @return array{access_token: string, refresh_token: string, expires_in: int, client: array}
     * @throws AuthException
     */
    public function execute(string $email, string $password, int $businessId, ?string $userAgent = null, ?string $ipAddress = null): array
    {
        // Find client by email in this business
        $client = $this->clientAuthRepository->findByEmailForAuth($email, $businessId);

        if ($client === null) {
            throw AuthException::invalidCredentials();
        }

        // Verify password
        if (!$this->passwordHasher->verify($password, $client['password_hash'])) {
            throw AuthException::invalidCredentials();
        }

        // Check if client is archived
        if (!empty($client['is_archived'])) {
            throw AuthException::accountDisabled();
        }

        // Generate access token with type=customer and client_id
        $accessToken = $this->jwtService->generateCustomerAccessToken(
            (int) $client['id'],
            (int) $client['business_id']
        );

        // Generate refresh token (random 64 hex chars)
        $refreshToken = bin2hex(random_bytes(32));
        $refreshTokenHash = hash('sha256', $refreshToken);

        // Store refresh token in client_sessions
        $expiresInSeconds = 90 * 24 * 60 * 60; // 90 days
        $this->clientAuthRepository->createSession(
            (int) $client['id'],
            $refreshTokenHash,
            $expiresInSeconds,
            $userAgent,
            $ipAddress
        );

        return [
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            'expires_in' => $this->jwtService->getAccessTokenTtl(),
            'client' => [
                'id' => (int) $client['id'],
                'email' => $client['email'],
                'first_name' => $client['first_name'],
                'last_name' => $client['last_name'],
                'business_id' => (int) $client['business_id'],
            ],
        ];
    }
}
