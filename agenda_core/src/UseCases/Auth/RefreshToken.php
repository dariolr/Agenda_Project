<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\AuthSessionRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Domain\Exceptions\AuthException;

final class RefreshToken
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly AuthSessionRepository $authSessionRepository,
        private readonly JwtService $jwtService,
    ) {}

    /**
     * Refresh access token using refresh token with rotation.
     * 
     * @return array{access_token: string, refresh_token: string, expires_in: int}
     * @throws AuthException
     */
    public function execute(string $refreshToken, ?string $userAgent = null, ?string $ipAddress = null): array
    {
        // Hash the provided refresh token
        $refreshTokenHash = hash('sha256', $refreshToken);

        // Find session by token hash
        $session = $this->authSessionRepository->findByTokenHash($refreshTokenHash);

        if ($session === null) {
            throw AuthException::tokenInvalid();
        }

        // Validate session
        if (!$this->authSessionRepository->isValid($session)) {
            throw AuthException::sessionRevoked();
        }

        $userId = (int) $session['user_id'];

        // Verify user still exists and is active
        $user = $this->userRepository->findById($userId);

        if ($user === null || !$user['is_active']) {
            // Revoke the session
            $this->authSessionRepository->revoke((int) $session['id']);
            throw AuthException::accountDisabled();
        }

        // Revoke old session (rotation)
        $this->authSessionRepository->revoke((int) $session['id']);

        // Generate new access token
        $accessToken = $this->jwtService->generateAccessToken($userId);

        // Generate new refresh token (rotation)
        $newRefreshToken = bin2hex(random_bytes(32));
        $newRefreshTokenHash = hash('sha256', $newRefreshToken);

        // Store new refresh token session
        $expiresInSeconds = 90 * 24 * 60 * 60; // 90 days
        $this->authSessionRepository->create(
            $userId,
            $newRefreshTokenHash,
            $expiresInSeconds,
            $userAgent,
            $ipAddress
        );

        return [
            'access_token' => $accessToken,
            'refresh_token' => $newRefreshToken,
            'expires_in' => $this->jwtService->getAccessTokenTtl(),
        ];
    }
}
