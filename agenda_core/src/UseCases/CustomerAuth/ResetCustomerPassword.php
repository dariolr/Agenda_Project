<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;
use DateTimeImmutable;

final class ResetCustomerPassword
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
        private readonly PasswordHasher $passwordHasher,
    ) {}

    /**
     * Reset customer password using a valid token.
     * @throws AuthException
     */
    public function execute(string $token, string $newPassword): void
    {
        $tokenHash = hash('sha256', $token);

        // Find valid token
        $resetToken = $this->clientAuthRepository->findPasswordResetToken($tokenHash);

        if ($resetToken === null) {
            throw AuthException::invalidResetToken();
        }

        // Check if token is valid
        if (!$this->clientAuthRepository->isPasswordResetTokenValid($resetToken)) {
            if ($resetToken['used_at'] !== null) {
                throw AuthException::invalidResetToken();
            }
            throw AuthException::resetTokenExpired();
        }

        // Validate new password
        $this->validatePassword($newPassword);

        // Hash new password
        $passwordHash = $this->passwordHasher->hash($newPassword);

        // Update client password
        $this->clientAuthRepository->updatePassword(
            (int) $resetToken['client_id'],
            $passwordHash
        );

        // Mark token as used
        $this->clientAuthRepository->markPasswordResetTokenUsed((int) $resetToken['id']);

        // Invalidate all sessions for this client (force re-login)
        $this->clientAuthRepository->revokeAllSessionsForClient((int) $resetToken['client_id']);
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
