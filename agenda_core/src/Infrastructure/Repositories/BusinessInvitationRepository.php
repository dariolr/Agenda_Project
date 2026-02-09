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
        $scopeType = $data['scope_type'] ?? 'business';
        $locationIds = $data['location_ids'] ?? [];

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_invitations 
                (business_id, email, role, scope_type, token, expires_at, invited_by)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );

        $stmt->execute([
            $data['business_id'],
            strtolower(trim($data['email'])),
            $data['role'] ?? 'staff',
            $scopeType,
            $token,
            $data['expires_at'] ?? $expiresAt,
            $data['invited_by'],
        ]);

        $invitationId = (int) $this->db->getPdo()->lastInsertId();
        
        // Set locations if scope_type=locations
        if ($scopeType === 'locations' && !empty($locationIds)) {
            $this->setLocationIds($invitationId, $locationIds);
        }

        return [
            'id' => $invitationId,
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
                i.id, i.business_id, i.email, i.role, i.scope_type, i.token, 
                i.expires_at, i.status, i.accepted_by, i.accepted_at,
                i.invited_by, i.created_at,
                b.name as business_name, b.slug as business_slug
             FROM business_invitations i
             JOIN businesses b ON i.business_id = b.id
             WHERE i.token = ?'
        );
        $stmt->execute([$token]);
        $result = $stmt->fetch();

        if (!$result) {
            return null;
        }
        
        // Fetch location_ids if scope_type=locations
        if ($result['scope_type'] === 'locations') {
            $result['location_ids'] = $this->getLocationIds((int)$result['id']);
        } else {
            $result['location_ids'] = [];
        }

        return $result;
    }

    /**
     * Find invitation by id.
     */
    public function findById(int $invitationId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM business_invitations WHERE id = ?'
        );
        $stmt->execute([$invitationId]);
        $result = $stmt->fetch();

        if (!$result) {
            return null;
        }

        if (($result['scope_type'] ?? 'business') === 'locations') {
            $result['location_ids'] = $this->getLocationIds((int) $result['id']);
        } else {
            $result['location_ids'] = [];
        }

        return $result;
    }

    /**
     * Find pending invitation by email and business.
     */
    public function findPendingByEmailAndBusiness(string $email, int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM business_invitations 
             WHERE email = ? AND business_id = ? AND status = \'pending\'
             AND expires_at > NOW()'
        );
        $stmt->execute([strtolower(trim($email)), $businessId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    /**
     * Revoke previous invitations for an email in a business.
     * Keeps accepted invitations for audit/history.
     *
     * Requires DB schema with 'revoked' in business_invitations.status ENUM.
     */
    public function revokePreviousByEmailAndBusiness(string $email, int $businessId): int
    {
        $normalizedEmail = strtolower(trim($email));

        try {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE business_invitations
                 SET status = \'revoked\'
                 WHERE business_id = ? AND email = ? AND status <> \'accepted\''
            );
            $stmt->execute([$businessId, $normalizedEmail]);
            return $stmt->rowCount();
        } catch (\Throwable $e) {
            throw new \RuntimeException(
                "Cannot revoke previous invitations. Ensure migration 0041_business_invitations_reintroduce_revoked.sql is applied.",
                0,
                $e
            );
        }
    }

    /**
     * Find all pending invitations for a business.
     */
    public function findPendingByBusiness(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                i.id, i.email, i.role, i.scope_type, i.token, i.expires_at, 
                i.status, i.invited_by, i.created_at,
                u.first_name as inviter_first_name, u.last_name as inviter_last_name
             FROM business_invitations i
             LEFT JOIN users u ON i.invited_by = u.id
             WHERE i.business_id = ? AND i.status = \'pending\'
             AND i.expires_at > NOW()
             ORDER BY i.created_at DESC'
        );
        $stmt->execute([$businessId]);

        $invitations = $stmt->fetchAll();
        
        // Fetch location_ids for invitations with scope_type=locations
        foreach ($invitations as &$inv) {
            if ($inv['scope_type'] === 'locations') {
                $inv['location_ids'] = $this->getLocationIds((int)$inv['id']);
            } else {
                $inv['location_ids'] = [];
            }
        }

        return $invitations;
    }

    /**
     * Find all invitations for a business (any status).
     */
    public function findByBusiness(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                i.id, i.email, i.role, i.scope_type, i.token, i.expires_at, 
                i.status, i.accepted_at, i.invited_by, i.created_at,
                u.first_name as inviter_first_name, u.last_name as inviter_last_name
             FROM business_invitations i
             LEFT JOIN users u ON i.invited_by = u.id
             WHERE i.business_id = ?
             ORDER BY i.created_at DESC'
        );
        $stmt->execute([$businessId]);

        $invitations = $stmt->fetchAll();

        foreach ($invitations as &$inv) {
            if ($inv['scope_type'] === 'locations') {
                $inv['location_ids'] = $this->getLocationIds((int)$inv['id']);
            } else {
                $inv['location_ids'] = [];
            }
        }

        return $invitations;
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
             WHERE i.email = ? AND i.status = \'pending\'
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
             SET status = \'accepted\', accepted_by = ?, accepted_at = NOW()
             WHERE id = ? AND status = \'pending\''
        );

        return $stmt->execute([$userId, $invitationId]);
    }

    /**
     * Decline an invitation.
     */
    public function decline(int $invitationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_invitations
             SET status = \'declined\'
             WHERE id = ? AND status = \'pending\''
        );

        return $stmt->execute([$invitationId]);
    }

    /**
     * Restore a revoked invitation back to pending.
     * Used as rollback safety when re-send email fails.
     */
    public function restorePending(int $invitationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_invitations
             SET status = \'pending\'
             WHERE id = ? AND status = \'revoked\''
        );
        return $stmt->execute([$invitationId]);
    }

    /**
     * Delete accepted invitations for an email in a business.
     * Used when business access is removed from operators screen.
     */
    public function deleteAcceptedByEmailAndBusiness(string $email, int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM business_invitations
             WHERE business_id = ? AND email = ? AND status = \'accepted\''
        );
        $stmt->execute([$businessId, strtolower(trim($email))]);
        return $stmt->rowCount() > 0;
    }

    /**
     * Expire old invitations (can be run as cron job).
     */
    public function expireOld(): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_invitations 
             SET status = \'expired\'
             WHERE status = \'pending\' AND expires_at < NOW()'
        );
        $stmt->execute();

        return $stmt->rowCount();
    }

    /**
     * Delete an invitation by ID.
     */
    public function delete(int $invitationId): bool
    {
        // Delete locations first (FK cascade should handle but explicit for safety)
        $this->setLocationIds($invitationId, []);
        
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

    // ========== LOCATION MANAGEMENT ==========

    /**
     * Get location IDs for an invitation.
     */
    public function getLocationIds(int $invitationId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT location_id FROM business_invitation_locations WHERE invitation_id = ?'
        );
        $stmt->execute([$invitationId]);
        
        return array_column($stmt->fetchAll(), 'location_id');
    }

    /**
     * Set location IDs for an invitation.
     */
    public function setLocationIds(int $invitationId, array $locationIds): void
    {
        $pdo = $this->db->getPdo();
        
        // Delete existing
        $stmt = $pdo->prepare('DELETE FROM business_invitation_locations WHERE invitation_id = ?');
        $stmt->execute([$invitationId]);
        
        // Insert new
        if (!empty($locationIds)) {
            $stmt = $pdo->prepare(
                'INSERT INTO business_invitation_locations (invitation_id, location_id) VALUES (?, ?)'
            );
            foreach ($locationIds as $locationId) {
                $stmt->execute([$invitationId, (int)$locationId]);
            }
        }
    }
}
