<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Domain\Exceptions\AuthException;
use DateTimeImmutable;

/**
 * Verifies if a password reset token is valid (not expired, not used).
 */
final class VerifyResetToken
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Verify the token is valid.
     * @throws AuthException if token is invalid or expired
     */
    public function execute(string $token): void
    {
        $tokenHash = hash('sha256', $token);

        // Find token
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
    }
}
