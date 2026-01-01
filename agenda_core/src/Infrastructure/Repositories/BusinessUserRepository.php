<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for business_users table.
 * Manages operator-business associations with roles and permissions.
 */
final class BusinessUserRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Find all businesses where a user has access.
     * Returns businesses with user's role and permissions.
     */
    public function findBusinessesByUserId(int $userId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                b.id, b.name, b.slug, b.email, b.phone, b.timezone, b.currency,
                b.created_at, b.updated_at,
                bu.role,
                bu.can_manage_bookings, bu.can_manage_clients,
                bu.can_manage_services, bu.can_manage_staff, bu.can_view_reports,
                bu.staff_id
             FROM business_users bu
             JOIN businesses b ON bu.business_id = b.id
             WHERE bu.user_id = ? 
               AND bu.is_active = 1 
               AND b.is_active = 1
             ORDER BY b.name ASC'
        );
        $stmt->execute([$userId]);

        return $stmt->fetchAll();
    }

    /**
     * Find a specific business-user association.
     */
    public function findByUserAndBusiness(int $userId, int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                bu.id, bu.business_id, bu.user_id, bu.role, bu.staff_id,
                bu.can_manage_bookings, bu.can_manage_clients,
                bu.can_manage_services, bu.can_manage_staff, bu.can_view_reports,
                bu.is_active, bu.invited_by, bu.invited_at, bu.accepted_at,
                bu.created_at, bu.updated_at
             FROM business_users bu
             WHERE bu.user_id = ? AND bu.business_id = ? AND bu.is_active = 1'
        );
        $stmt->execute([$userId, $businessId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    /**
     * Check if user has access to a business.
     * Superadmins have access to all businesses.
     */
    public function hasAccess(int $userId, int $businessId, bool $isSuperadmin = false): bool
    {
        // Superadmins have access to all businesses
        if ($isSuperadmin) {
            return true;
        }

        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM business_users 
             WHERE user_id = ? AND business_id = ? AND is_active = 1'
        );
        $stmt->execute([$userId, $businessId]);

        return $stmt->fetchColumn() !== false;
    }

    /**
     * Get user's role in a business.
     * Returns null if no access.
     */
    public function getRole(int $userId, int $businessId): ?string
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT role FROM business_users 
             WHERE user_id = ? AND business_id = ? AND is_active = 1'
        );
        $stmt->execute([$userId, $businessId]);
        $result = $stmt->fetchColumn();

        return $result ?: null;
    }

    /**
     * Find all users with access to a business.
     */
    public function findUsersByBusinessId(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                bu.id, bu.user_id, bu.role, bu.staff_id,
                bu.can_manage_bookings, bu.can_manage_clients,
                bu.can_manage_services, bu.can_manage_staff, bu.can_view_reports,
                bu.is_active, bu.invited_by, bu.invited_at, bu.accepted_at,
                bu.created_at,
                u.email, u.first_name, u.last_name, u.phone as user_phone
             FROM business_users bu
             JOIN users u ON bu.user_id = u.id
             WHERE bu.business_id = ? AND bu.is_active = 1 AND u.is_active = 1
             ORDER BY 
                FIELD(bu.role, "owner", "admin", "manager", "staff"),
                u.first_name ASC'
        );
        $stmt->execute([$businessId]);

        return $stmt->fetchAll();
    }

    /**
     * Create a new business-user association.
     * If a deactivated record exists, reactivate it instead.
     */
    public function create(array $data): int
    {
        // Check if there's an existing (possibly deactivated) record
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, is_active FROM business_users 
             WHERE business_id = ? AND user_id = ?'
        );
        $stmt->execute([$data['business_id'], $data['user_id']]);
        $existing = $stmt->fetch();

        if ($existing) {
            // Reactivate and update existing record
            $updateStmt = $this->db->getPdo()->prepare(
                'UPDATE business_users SET
                    role = ?, staff_id = ?,
                    can_manage_bookings = ?, can_manage_clients = ?, can_manage_services = ?,
                    can_manage_staff = ?, can_view_reports = ?,
                    invited_by = ?, invited_at = ?, accepted_at = ?,
                    is_active = 1, updated_at = NOW()
                 WHERE id = ?'
            );
            $updateStmt->execute([
                $data['role'] ?? 'staff',
                $data['staff_id'] ?? null,
                $data['can_manage_bookings'] ?? 1,
                $data['can_manage_clients'] ?? 1,
                $data['can_manage_services'] ?? 0,
                $data['can_manage_staff'] ?? 0,
                $data['can_view_reports'] ?? 0,
                $data['invited_by'] ?? null,
                $data['invited_at'] ?? null,
                $data['accepted_at'] ?? date('Y-m-d H:i:s'),
                $existing['id'],
            ]);
            return (int) $existing['id'];
        }

        // Insert new record
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_users 
                (business_id, user_id, role, staff_id, 
                 can_manage_bookings, can_manage_clients, can_manage_services, 
                 can_manage_staff, can_view_reports, invited_by, invited_at, accepted_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );

        $stmt->execute([
            $data['business_id'],
            $data['user_id'],
            $data['role'] ?? 'staff',
            $data['staff_id'] ?? null,
            $data['can_manage_bookings'] ?? 1,
            $data['can_manage_clients'] ?? 1,
            $data['can_manage_services'] ?? 0,
            $data['can_manage_staff'] ?? 0,
            $data['can_view_reports'] ?? 0,
            $data['invited_by'] ?? null,
            $data['invited_at'] ?? null,
            $data['accepted_at'] ?? date('Y-m-d H:i:s'),
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Create owner for a business (used when creating new business).
     */
    public function createOwner(int $businessId, int $userId): int
    {
        return $this->create([
            'business_id' => $businessId,
            'user_id' => $userId,
            'role' => 'owner',
            'can_manage_bookings' => 1,
            'can_manage_clients' => 1,
            'can_manage_services' => 1,
            'can_manage_staff' => 1,
            'can_view_reports' => 1,
        ]);
    }

    /**
     * Update a business-user association.
     */
    public function update(int $id, array $data): bool
    {
        $fields = [];
        $params = [];

        $allowedFields = [
            'role', 'staff_id', 'can_manage_bookings', 'can_manage_clients',
            'can_manage_services', 'can_manage_staff', 'can_view_reports', 'is_active'
        ];

        foreach ($allowedFields as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = ?";
                $params[] = $data[$field];
            }
        }

        if (empty($fields)) {
            return false;
        }

        $params[] = $id;
        $sql = 'UPDATE business_users SET ' . implode(', ', $fields) . ' WHERE id = ?';
        $stmt = $this->db->getPdo()->prepare($sql);

        return $stmt->execute($params);
    }

    /**
     * Soft delete (deactivate) a business-user association.
     */
    public function delete(int $id): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_users SET is_active = 0 WHERE id = ?'
        );

        return $stmt->execute([$id]);
    }

    /**
     * Remove user from business (by user_id and business_id).
     */
    public function removeUserFromBusiness(int $userId, int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_users SET is_active = 0 
             WHERE user_id = ? AND business_id = ?'
        );

        return $stmt->execute([$userId, $businessId]);
    }

    /**
     * Check if user can assign a specific role.
     */
    public function canAssignRole(string $assignerRole, string $targetRole): bool
    {
        $hierarchy = [
            'owner' => ['owner', 'admin', 'manager', 'staff'],
            'admin' => ['admin', 'manager', 'staff'],
            'manager' => [],
            'staff' => [],
        ];

        return in_array($targetRole, $hierarchy[$assignerRole] ?? [], true);
    }

    /**
     * Count owners in a business (to prevent removing last owner).
     */
    public function countOwners(int $businessId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM business_users 
             WHERE business_id = ? AND role = "owner" AND is_active = 1'
        );
        $stmt->execute([$businessId]);

        return (int) $stmt->fetchColumn();
    }

    /**
     * Get the primary owner of a business (first owner).
     */
    public function getOwner(int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT bu.*, u.email, u.first_name, u.last_name
             FROM business_users bu
             JOIN users u ON bu.user_id = u.id
             WHERE bu.business_id = ? AND bu.role = "owner" AND bu.is_active = 1
             ORDER BY bu.created_at ASC
             LIMIT 1'
        );
        $stmt->execute([$businessId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    /**
     * Transfer ownership to a new user.
     * The old owner becomes an admin.
     */
    public function transferOwnership(int $businessId, int $oldOwnerId, int $newOwnerId): void
    {
        // Demote old owner to admin
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_users SET role = "admin", updated_at = NOW()
             WHERE business_id = ? AND user_id = ? AND role = "owner"'
        );
        $stmt->execute([$businessId, $oldOwnerId]);

        // Check if new owner already has a business_user record
        $existing = $this->findByUserAndBusiness($newOwnerId, $businessId);

        if ($existing !== null) {
            // Promote to owner
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE business_users SET role = "owner", is_active = 1, updated_at = NOW()
                 WHERE business_id = ? AND user_id = ?'
            );
            $stmt->execute([$businessId, $newOwnerId]);
        } else {
            // Create new owner record
            $this->createOwner($businessId, $newOwnerId);
        }
    }
}
