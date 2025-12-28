<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;

final class ChangePassword
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly PasswordHasher $passwordHasher,
    ) {}

    /**
     * Change password for an authenticated user.
     * @throws AuthException
     */
    public function execute(int $userId, string $currentPassword, string $newPassword): void
    {
        $user = $this->userRepository->findById($userId);

        if ($user === null) {
            throw AuthException::unauthorized();
        }

        // Verify current password
        if (!$this->passwordHasher->verify($currentPassword, $user['password_hash'])) {
            throw AuthException::invalidCredentials('Current password is incorrect');
        }

        // Validate new password
        $this->validatePassword($newPassword);

        // Ensure new password is different
        if ($currentPassword === $newPassword) {
            throw AuthException::validationError('New password must be different from current password');
        }

        // Hash and update password
        $passwordHash = $this->passwordHasher->hash($newPassword);
        $this->userRepository->updatePassword($userId, $passwordHash);
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
