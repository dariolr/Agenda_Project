<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\AuthSessionRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;

final class LoginUser
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly AuthSessionRepository $authSessionRepository,
        private readonly JwtService $jwtService,
        private readonly PasswordHasher $passwordHasher,
    ) {}

    /**
     * @return array{access_token: string, refresh_token: string, expires_in: int, user: array}
     * @throws AuthException
     */
    public function execute(string $email, string $password, ?string $userAgent = null, ?string $ipAddress = null): array
    {
        // Find user by email
        $user = $this->userRepository->findByEmail($email);

        if ($user === null) {
            throw AuthException::invalidCredentials();
        }

        // Verify password
        if (!$this->passwordHasher->verify($password, $user['password_hash'])) {
            throw AuthException::invalidCredentials();
        }

        // Check if user is active
        if (!$user['is_active']) {
            throw AuthException::accountDisabled();
        }

        // Update last login timestamp
        $this->userRepository->updateLastLogin((int) $user['id']);

        // Generate access token (contains ONLY user_id)
        $accessToken = $this->jwtService->generateAccessToken((int) $user['id']);

        // Generate refresh token (random 64 hex chars)
        $refreshToken = bin2hex(random_bytes(32));
        $refreshTokenHash = hash('sha256', $refreshToken);

        // Store refresh token session
        $expiresInSeconds = 90 * 24 * 60 * 60; // 90 days
        $this->authSessionRepository->create(
            (int) $user['id'],
            $refreshTokenHash,
            $expiresInSeconds,
            $userAgent,
            $ipAddress
        );

        return [
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            'expires_in' => $this->jwtService->getAccessTokenTtl(),
            'user' => [
                'id' => (int) $user['id'],
                'email' => $user['email'],
                'first_name' => $user['first_name'],
                'last_name' => $user['last_name'],
            ],
        ];
    }
}
