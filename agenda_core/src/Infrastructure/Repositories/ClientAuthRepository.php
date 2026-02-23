<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use DateTimeImmutable;

/**
 * Repository for customer (client) authentication.
 * Separate from UserRepository which handles operators/admins.
 */
final class ClientAuthRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    // =========================================================================
    // CLIENT AUTH METHODS
    // =========================================================================

    /**
     * Find client by email for authentication (requires password_hash).
     */
    public function findByEmailForAuth(string $email, int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, email, password_hash, first_name, last_name, phone, 
                    email_verified_at, is_archived, created_at 
             FROM clients 
             WHERE email = ? AND business_id = ? AND password_hash IS NOT NULL AND is_archived = 0'
        );
        $stmt->execute([$email, $businessId]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    /**
     * Find client by email (even without password - for password reset/first activation).
     */
    public function findByEmail(string $email, int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, email, password_hash, first_name, last_name, phone, 
                    email_verified_at, is_archived, created_at 
             FROM clients 
             WHERE email = ? AND business_id = ? AND is_archived = 0'
        );
        $stmt->execute([$email, $businessId]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    /**
     * Find client by ID (for JWT validation).
     */
    public function findById(int $id): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT c.id, c.business_id, c.email, c.first_name, c.last_name, c.phone,
                    c.email_verified_at, c.is_archived, c.created_at,
                    COALESCE(cc.marketing_opt_in, 0) AS marketing_opt_in,
                    COALESCE(cc.profiling_opt_in, 0) AS profiling_opt_in,
                    COALESCE(cc.preferred_channel, \'none\') AS preferred_channel
             FROM clients c
             LEFT JOIN client_consents cc
                ON cc.business_id = c.business_id
               AND cc.client_id = c.id
             WHERE c.id = ? AND c.is_archived = 0'
        );
        $stmt->execute([$id]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    /**
     * Check if email exists in a business (for registration validation).
     */
    public function emailExistsInBusiness(string $email, int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM clients WHERE email = ? AND business_id = ?'
        );
        $stmt->execute([$email, $businessId]);
        
        return $stmt->fetch() !== false;
    }

    /**
     * Create new client with password (registration).
     */
    public function createWithPassword(array $data, int $businessId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO clients (business_id, email, password_hash, first_name, last_name, phone) 
             VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $data['email'],
            $data['password_hash'],
            $data['first_name'],
            $data['last_name'],
            $data['phone'] ?? null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Set password for existing client (enables self-service login).
     */
    public function setPassword(int $clientId, string $passwordHash): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE clients SET password_hash = ?, updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$passwordHash, $clientId]);
    }

    /**
     * Update client password.
     */
    public function updatePassword(int $clientId, string $passwordHash): void
    {
        $this->setPassword($clientId, $passwordHash);
    }

    /**
     * Update client profile.
     */
    public function updateProfile(int $clientId, array $data): void
    {
        $fields = [];
        $values = [];

        if (isset($data['first_name'])) {
            $fields[] = 'first_name = ?';
            $values[] = $data['first_name'];
        }
        if (isset($data['last_name'])) {
            $fields[] = 'last_name = ?';
            $values[] = $data['last_name'];
        }
        if (isset($data['phone'])) {
            $fields[] = 'phone = ?';
            $values[] = $data['phone'];
        }
        if (isset($data['email'])) {
            $fields[] = 'email = ?';
            $values[] = $data['email'];
        }

        if (empty($fields)) {
            return;
        }

        $fields[] = 'updated_at = NOW()';
        $values[] = $clientId;

        $sql = 'UPDATE clients SET ' . implode(', ', $fields) . ' WHERE id = ?';
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($values);
    }

    /**
     * Mark email as verified.
     */
    public function markEmailVerified(int $clientId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE clients SET email_verified_at = NOW(), updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$clientId]);
    }

    public function upsertConsents(
        int $businessId,
        int $clientId,
        bool $marketingOptIn,
        bool $profilingOptIn,
        string $preferredChannel,
        ?int $updatedByUserId = null,
        ?string $source = 'frontend-profile'
    ): void {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO client_consents (
                business_id, client_id, marketing_opt_in, profiling_opt_in,
                preferred_channel, updated_by_user_id, source
             ) VALUES (?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                marketing_opt_in = VALUES(marketing_opt_in),
                profiling_opt_in = VALUES(profiling_opt_in),
                preferred_channel = VALUES(preferred_channel),
                updated_by_user_id = VALUES(updated_by_user_id),
                source = VALUES(source),
                updated_at = CURRENT_TIMESTAMP'
        );

        $stmt->execute([
            $businessId,
            $clientId,
            $marketingOptIn ? 1 : 0,
            $profilingOptIn ? 1 : 0,
            $this->sanitizePreferredChannel($preferredChannel),
            $updatedByUserId,
            $source,
        ]);
    }

    private function sanitizePreferredChannel(string $channel): string
    {
        $allowed = ['whatsapp', 'sms', 'email', 'phone', 'none'];
        $normalized = strtolower(trim($channel));

        if (!in_array($normalized, $allowed, true)) {
            return 'none';
        }

        return $normalized;
    }

    // =========================================================================
    // CLIENT SESSION METHODS
    // =========================================================================

    /**
     * Create a new client session (refresh token).
     */
    public function createSession(int $clientId, string $refreshTokenHash, int $expiresInSeconds, ?string $userAgent = null, ?string $ipAddress = null): int
    {
        $expiresAt = (new DateTimeImmutable())->modify("+{$expiresInSeconds} seconds");
        
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO client_sessions (client_id, refresh_token_hash, user_agent, ip_address, expires_at) 
             VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $clientId,
            $refreshTokenHash,
            $userAgent,
            $ipAddress,
            $expiresAt->format('Y-m-d H:i:s'),
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Find session by refresh token hash.
     */
    public function findSessionByTokenHash(string $hash): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, client_id, refresh_token_hash, expires_at, last_used_at, revoked_at, created_at 
             FROM client_sessions WHERE refresh_token_hash = ?'
        );
        $stmt->execute([$hash]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    /**
     * Mark session as used (update last_used_at).
     */
    public function markSessionAsUsed(int $sessionId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE client_sessions SET last_used_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$sessionId]);
    }

    /**
     * Revoke a session.
     */
    public function revokeSession(int $sessionId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE client_sessions SET revoked_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$sessionId]);
    }

    /**
     * Revoke all sessions for a client.
     */
    public function revokeAllSessionsForClient(int $clientId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE client_sessions SET revoked_at = NOW() WHERE client_id = ? AND revoked_at IS NULL'
        );
        $stmt->execute([$clientId]);
    }

    /**
     * Check if a session is valid (not revoked, not expired).
     */
    public function isSessionValid(array $session): bool
    {
        if ($session['revoked_at'] !== null) {
            return false;
        }

        $expiresAt = new DateTimeImmutable($session['expires_at']);
        if ($expiresAt < new DateTimeImmutable()) {
            return false;
        }

        return true;
    }

    /**
     * Delete expired sessions (cleanup).
     */
    public function deleteExpiredSessions(): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM client_sessions WHERE expires_at < NOW() - INTERVAL 7 DAY'
        );
        $stmt->execute();
        
        return $stmt->rowCount();
    }

    // =========================================================================
    // PASSWORD RESET METHODS
    // =========================================================================

    /**
     * Create password reset token.
     */
    public function createPasswordResetToken(int $clientId, string $tokenHash, int $expiresInSeconds = 86400): void
    {
        $expiresAt = (new DateTimeImmutable())->modify("+{$expiresInSeconds} seconds");
        
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO password_reset_token_clients (client_id, token_hash, expires_at) 
             VALUES (?, ?, ?)'
        );
        $stmt->execute([
            $clientId,
            $tokenHash,
            $expiresAt->format('Y-m-d H:i:s'),
        ]);
    }

    /**
     * Find password reset token by hash.
     */
    public function findPasswordResetToken(string $tokenHash): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT prt.id, prt.client_id, prt.token_hash, prt.expires_at, prt.used_at,
                    c.email, c.first_name, c.last_name, c.business_id
             FROM password_reset_token_clients prt
             INNER JOIN clients c ON c.id = prt.client_id
             WHERE prt.token_hash = ?'
        );
        $stmt->execute([$tokenHash]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    /**
     * Mark password reset token as used.
     */
    public function markPasswordResetTokenUsed(int $tokenId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE password_reset_token_clients SET used_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$tokenId]);
    }

    /**
     * Check if password reset token is valid.
     */
    public function isPasswordResetTokenValid(array $token): bool
    {
        if ($token['used_at'] !== null) {
            return false;
        }

        $expiresAt = new DateTimeImmutable($token['expires_at']);
        if ($expiresAt < new DateTimeImmutable()) {
            return false;
        }

        return true;
    }

    /**
     * Delete expired password reset tokens (cleanup).
     */
    public function deleteExpiredPasswordResetTokens(): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM password_reset_token_clients WHERE expires_at < NOW() - INTERVAL 1 DAY'
        );
        $stmt->execute();
        
        return $stmt->rowCount();
    }
}
