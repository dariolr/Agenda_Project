<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\AuthSessionRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;

final class RegisterUser
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
    public function execute(
        string $email,
        string $password,
        ?string $firstName = null,
        ?string $lastName = null,
        ?string $phone = null,
        ?string $userAgent = null,
        ?string $ipAddress = null
    ): array {
        // Check if email already exists
        $existingUser = $this->userRepository->findByEmail($email);
        if ($existingUser !== null) {
            throw AuthException::emailAlreadyExists();
        }

        // Validate password strength
        $this->validatePassword($password);

        // Hash password
        $passwordHash = $this->passwordHasher->hash($password);

        // Create user
        $userId = $this->userRepository->create([
            'email' => $email,
            'password_hash' => $passwordHash,
            'first_name' => $firstName,
            'last_name' => $lastName,
            'phone' => $phone,
            'is_active' => true,
        ]);

        // Generate access token
        $accessToken = $this->jwtService->generateAccessToken($userId);

        // Generate refresh token
        $refreshToken = bin2hex(random_bytes(32));
        $refreshTokenHash = hash('sha256', $refreshToken);

        // Store refresh token session
        $expiresInSeconds = 90 * 24 * 60 * 60; // 90 days
        $this->authSessionRepository->create(
            $userId,
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
                'id' => $userId,
                'email' => $email,
                'first_name' => $firstName,
                'last_name' => $lastName,
            ],
        ];
    }

    private function validatePassword(string $password): void
    {
        if (strlen($password) < 8) {
            throw AuthException::weakPassword('Password must be at least 8 characters');
        }

        if (!preg_match('/[A-Z]/', $password)) {
            throw AuthException::weakPassword('Password must contain at least one uppercase letter');
        }

        if (!preg_match('/[a-z]/', $password)) {
            throw AuthException::weakPassword('Password must contain at least one lowercase letter');
        }

        if (!preg_match('/[0-9]/', $password)) {
            throw AuthException::weakPassword('Password must contain at least one number');
        }
    }
}
