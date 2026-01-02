<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\ValidationException;

/**
 * Register a new customer (client) for self-service booking.
 * 
 * Handles two scenarios:
 * 1. New email: creates new client record with password
 * 2. Existing email without password: sets password on existing client
 */
final class RegisterCustomer
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
        private readonly ClientRepository $clientRepository,
        private readonly JwtService $jwtService,
        private readonly PasswordHasher $passwordHasher,
    ) {}

    /**
     * @return array{access_token: string, refresh_token: string, expires_in: int, client: array}
     * @throws AuthException
     * @throws ValidationException
     */
    public function execute(
        string $email,
        string $password,
        string $firstName,
        string $lastName,
        int $businessId,
        ?string $phone = null,
        ?string $userAgent = null,
        ?string $ipAddress = null
    ): array {
        // Validate password strength
        $this->validatePassword($password);

        // Check if client exists with this email in this business
        $existingClient = $this->clientRepository->findByEmail($email, $businessId);

        if ($existingClient !== null) {
            // Check if already has password (already registered)
            if (!empty($existingClient['password_hash'])) {
                throw new AuthException('Email already registered', 'email_exists', 409);
            }

            // Existing client without password - enable login
            $clientId = (int) $existingClient['id'];
            $passwordHash = $this->passwordHasher->hash($password);
            $this->clientAuthRepository->setPassword($clientId, $passwordHash);
            
            // Update profile if provided
            $updateData = [];
            if ($firstName !== ($existingClient['first_name'] ?? '')) {
                $updateData['first_name'] = $firstName;
            }
            if ($lastName !== ($existingClient['last_name'] ?? '')) {
                $updateData['last_name'] = $lastName;
            }
            if ($phone !== null && $phone !== ($existingClient['phone'] ?? '')) {
                $updateData['phone'] = $phone;
            }
            if (!empty($updateData)) {
                $this->clientAuthRepository->updateProfile($clientId, $updateData);
            }
        } else {
            // New client
            $passwordHash = $this->passwordHasher->hash($password);
            $clientId = $this->clientAuthRepository->createWithPassword([
                'email' => $email,
                'password_hash' => $passwordHash,
                'first_name' => $firstName,
                'last_name' => $lastName,
                'phone' => $phone,
            ], $businessId);
        }

        // Fetch client data
        $client = $this->clientAuthRepository->findById($clientId);

        // Generate access token with type=customer and client_id
        $accessToken = $this->jwtService->generateCustomerAccessToken(
            $clientId,
            $businessId
        );

        // Generate refresh token
        $refreshToken = bin2hex(random_bytes(32));
        $refreshTokenHash = hash('sha256', $refreshToken);

        // Store refresh token in client_sessions
        $expiresInSeconds = 90 * 24 * 60 * 60; // 90 days
        $this->clientAuthRepository->createSession(
            $clientId,
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
                'id' => $clientId,
                'email' => $client['email'],
                'first_name' => $client['first_name'],
                'last_name' => $client['last_name'],
                'business_id' => (int) $client['business_id'],
            ],
        ];
    }

    private function validatePassword(string $password): void
    {
        if (strlen($password) < 8) {
            throw new ValidationException('Password must be at least 8 characters');
        }

        if (!preg_match('/[A-Z]/', $password)) {
            throw new ValidationException('Password must contain at least one uppercase letter');
        }

        if (!preg_match('/[a-z]/', $password)) {
            throw new ValidationException('Password must contain at least one lowercase letter');
        }

        if (!preg_match('/[0-9]/', $password)) {
            throw new ValidationException('Password must contain at least one number');
        }
    }
}
