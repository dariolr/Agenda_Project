<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Domain\Exceptions\AuthException;

/**
 * Refresh access token for customer using refresh token.
 */
final class RefreshCustomerToken
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
        private readonly JwtService $jwtService,
    ) {}

    /**
     * @return array{access_token: string, refresh_token: string, expires_in: int, client: array}
     * @throws AuthException
     */
    public function execute(string $refreshToken, ?string $userAgent = null, ?string $ipAddress = null): array
    {
        // Hash the token to find session
        $tokenHash = hash('sha256', $refreshToken);
        $session = $this->clientAuthRepository->findSessionByTokenHash($tokenHash);

        if ($session === null) {
            throw AuthException::invalidRefreshToken();
        }

        // Validate session
        if (!$this->clientAuthRepository->isSessionValid($session)) {
            throw AuthException::invalidRefreshToken();
        }

        // Get client
        $client = $this->clientAuthRepository->findById((int) $session['client_id']);
        if ($client === null) {
            throw AuthException::invalidRefreshToken();
        }

        // Check if client is archived
        if (!empty($client['is_archived'])) {
            throw AuthException::accountDisabled();
        }

        // Revoke old session (token rotation)
        $this->clientAuthRepository->revokeSession((int) $session['id']);

        // Generate new access token
        $accessToken = $this->jwtService->generateCustomerAccessToken(
            (int) $client['id'],
            (int) $client['business_id']
        );

        // Generate new refresh token
        $newRefreshToken = bin2hex(random_bytes(32));
        $newRefreshTokenHash = hash('sha256', $newRefreshToken);

        // Store new session
        $expiresInSeconds = 90 * 24 * 60 * 60; // 90 days
        $this->clientAuthRepository->createSession(
            (int) $client['id'],
            $newRefreshTokenHash,
            $expiresInSeconds,
            $userAgent,
            $ipAddress
        );

        return [
            'access_token' => $accessToken,
            'refresh_token' => $newRefreshToken,
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
