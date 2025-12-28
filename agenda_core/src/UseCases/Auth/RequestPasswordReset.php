<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Database\Connection;
use DateTimeImmutable;

final class RequestPasswordReset
{
    public function __construct(
        private readonly Connection $db,
        private readonly UserRepository $userRepository,
    ) {}

    /**
     * Request a password reset for the given email.
     * Returns true if email was found (for security, always returns success message to user).
     */
    public function execute(string $email): bool
    {
        $user = $this->userRepository->findByEmail($email);

        if ($user === null) {
            // Don't reveal if email exists
            return false;
        }

        // Generate reset token
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $expiresAt = (new DateTimeImmutable('+1 hour'))->format('Y-m-d H:i:s');

        // Store reset token (invalidate any existing tokens for this user)
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM password_reset_tokens WHERE user_id = ?'
        );
        $stmt->execute([(int) $user['id']]);

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)'
        );
        $stmt->execute([
            (int) $user['id'],
            $tokenHash,
            $expiresAt,
        ]);

        // In production: send email with token
        // For now, log the token for testing
        error_log("Password reset token for {$email}: {$token}");

        return true;
    }
}
