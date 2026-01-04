<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;
use DateTimeImmutable;

final class ResetPassword
{
    public function __construct(
        private readonly Connection $db,
        private readonly UserRepository $userRepository,
        private readonly PasswordHasher $passwordHasher,
    ) {}

    /**
     * Reset password using a valid token.
     * @throws AuthException
     */
    public function execute(string $token, string $newPassword): void
    {
        $tokenHash = hash('sha256', $token);

        // Find valid token
        $stmt = $this->db->getPdo()->prepare(
            'SELECT user_id, expires_at FROM password_reset_token_users 
             WHERE token_hash = ? AND used_at IS NULL'
        );
        $stmt->execute([$tokenHash]);
        $resetToken = $stmt->fetch();

        if ($resetToken === null) {
            throw AuthException::invalidResetToken();
        }

        // Check expiration
        $expiresAt = new DateTimeImmutable($resetToken['expires_at']);
        if ($expiresAt < new DateTimeImmutable()) {
            throw AuthException::resetTokenExpired();
        }

        // Validate new password
        $this->validatePassword($newPassword);

        // Hash new password
        $passwordHash = $this->passwordHasher->hash($newPassword);

        // Update user password
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$passwordHash, (int) $resetToken['user_id']]);

        // Mark token as used
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE password_reset_token_users SET used_at = NOW() WHERE token_hash = ?'
        );
        $stmt->execute([$tokenHash]);

        // Invalidate all refresh tokens for this user (force re-login)
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE auth_sessions SET revoked_at = NOW() WHERE user_id = ? AND revoked_at IS NULL'
        );
        $stmt->execute([(int) $resetToken['user_id']]);
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
