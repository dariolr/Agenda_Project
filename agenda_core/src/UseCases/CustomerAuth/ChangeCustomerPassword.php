<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;

final class ChangeCustomerPassword
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
        private readonly PasswordHasher $passwordHasher,
    ) {}

    /**
     * Change password for authenticated customer.
     * @throws AuthException
     */
    public function execute(
        int $clientId,
        string $currentPassword,
        string $newPassword
    ): void {
        // Get client with password
        $client = $this->clientAuthRepository->findById($clientId);
        if ($client === null) {
            throw AuthException::invalidCredentials();
        }

        // Get full client data including password_hash
        $clientWithPassword = $this->clientAuthRepository->findByEmailForAuth(
            $client['email'],
            (int) $client['business_id']
        );

        if ($clientWithPassword === null) {
            throw AuthException::invalidCredentials();
        }

        // Verify current password
        if (!$this->passwordHasher->verify($currentPassword, $clientWithPassword['password_hash'])) {
            throw AuthException::invalidCredentials();
        }

        // Validate new password
        $this->validatePassword($newPassword);

        // Hash and update password
        $newPasswordHash = $this->passwordHasher->hash($newPassword);
        $this->clientAuthRepository->updatePassword($clientId, $newPasswordHash);
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
