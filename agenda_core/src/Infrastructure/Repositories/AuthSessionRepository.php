<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use DateTimeImmutable;

final class AuthSessionRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function create(int $userId, string $refreshTokenHash, int $expiresInSeconds, ?string $userAgent = null, ?string $ipAddress = null): int
    {
        $expiresAt = (new DateTimeImmutable())->modify("+{$expiresInSeconds} seconds");
        
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO auth_sessions (user_id, refresh_token_hash, user_agent, ip_address, expires_at) 
             VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $userId,
            $refreshTokenHash,
            $userAgent,
            $ipAddress,
            $expiresAt->format('Y-m-d H:i:s'),
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function findByTokenHash(string $hash): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, user_id, refresh_token_hash, expires_at, last_used_at, revoked_at, created_at 
             FROM auth_sessions WHERE refresh_token_hash = ?'
        );
        $stmt->execute([$hash]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    public function markAsUsed(int $sessionId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE auth_sessions SET last_used_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$sessionId]);
    }

    public function revoke(int $sessionId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE auth_sessions SET revoked_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$sessionId]);
    }

    public function revokeAllForUser(int $userId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE auth_sessions SET revoked_at = NOW() WHERE user_id = ? AND revoked_at IS NULL'
        );
        $stmt->execute([$userId]);
    }

    public function isValid(array $session): bool
    {
        // Check if revoked
        if ($session['revoked_at'] !== null) {
            return false;
        }

        // Check if expired
        $expiresAt = new DateTimeImmutable($session['expires_at']);
        if ($expiresAt < new DateTimeImmutable()) {
            return false;
        }

        return true;
    }

    public function deleteExpired(): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM auth_sessions WHERE expires_at < NOW() - INTERVAL 7 DAY'
        );
        $stmt->execute();
        
        return $stmt->rowCount();
    }
}
