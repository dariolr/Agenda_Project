<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for business_invitations table.
 * Manages email-based invitations to join a business.
 */
final class BusinessInvitationRepository
{
    private const TOKEN_LENGTH = 32;
    private const DEFAULT_EXPIRY_DAYS = 7;

    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Create a new invitation.
     * Returns the invitation ID and token.
     */
    public function create(array $data): array
    {
        $token = $this->generateToken();
        $expiresAt = date('Y-m-d H:i:s', strtotime('+' . self::DEFAULT_EXPIRY_DAYS . ' days'));

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_invitations 
                (business_id, email, role, token, expires_at, invited_by)
             VALUES (?, ?, ?, ?, ?, ?)'
        );

        $stmt->execute([
            $data['business_id'],
            strtolower(trim($data['email'])),
            $data['role'] ?? 'staff',
            $token,
            $data['expires_at'] ?? $expiresAt,
            $data['invited_by'],
        ]);

        return [
            'id' => (int) $this->db->getPdo()->lastInsertId(),
            'token' => $token,
            'expires_at' => $data['expires_at'] ?? $expiresAt,
        ];
    }

    /**
     * Find invitation by token.
     */
    public function findByToken(string $token): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                i.id, i.business_id, i.email, i.role, i.token, 
                i.expires_at, i.status, i.accepted_by, i.accepted_at,
                i.invited_by, i.created_at,
                b.name as business_name, b.slug as business_slug
             FROM business_invitations i
             JOIN businesses b ON i.business_id = b.id
             WHERE i.token = ?'
        );
        $stmt->execute([$token]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    /**
     * Find pending invitation by email and business.
     */
    public function findPendingByEmailAndBusiness(string $email, int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM business_invitations 
             WHERE email = ? AND business_id = ? AND status = "pending"
             AND expires_at > NOW()'
        );
        $stmt->execute([strtolower(trim($email)), $businessId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    /**
     * Find all pending invitations for a business.
     */
    public function findPendingByBusiness(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                i.id, i.email, i.role, i.token, i.expires_at, 
                i.status, i.invited_by, i.created_at,
                u.first_name as inviter_first_name, u.last_name as inviter_last_name
             FROM business_invitations i
             LEFT JOIN users u ON i.invited_by = u.id
             WHERE i.business_id = ? AND i.status = "pending"
             AND i.expires_at > NOW()
             ORDER BY i.created_at DESC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll();
    }

    /**
     * Find all pending invitations for an email.
     * Used when a user registers to auto-accept pending invitations.
     */
    public function findPendingByEmail(string $email): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                i.*, b.name as business_name
             FROM business_invitations i
             JOIN businesses b ON i.business_id = b.id
             WHERE i.email = ? AND i.status = "pending"
             AND i.expires_at > NOW()'
        );
        $stmt->execute([strtolower(trim($email))]);

        return $stmt->fetchAll();
    }

    /**
     * Accept an invitation.
     */
    public function accept(int $invitationId, int $userId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_invitations 
             SET status = "accepted", accepted_by = ?, accepted_at = NOW()
             WHERE id = ? AND status = "pending"'
        );

        return $stmt->execute([$userId, $invitationId]);
    }

    /**
     * Revoke an invitation.
     */
    public function revoke(int $invitationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_invitations 
             SET status = "revoked"
             WHERE id = ? AND status = "pending"'
        );

        return $stmt->execute([$invitationId]);
    }

    /**
     * Expire old invitations (can be run as cron job).
     */
    public function expireOld(): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_invitations 
             SET status = "expired"
             WHERE status = "pending" AND expires_at < NOW()'
        );
        $stmt->execute();

        return $stmt->rowCount();
    }

    /**
     * Delete an invitation by ID.
     */
    public function delete(int $invitationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM business_invitations WHERE id = ?'
        );

        return $stmt->execute([$invitationId]);
    }

    /**
     * Generate a secure random token.
     */
    private function generateToken(): string
    {
        return bin2hex(random_bytes(self::TOKEN_LENGTH));
    }
}
