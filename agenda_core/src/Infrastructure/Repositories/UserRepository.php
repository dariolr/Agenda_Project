<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

final class UserRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findById(int $id): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, email, first_name, last_name, phone, password_hash, email_verified_at, is_active, is_superadmin, created_at 
             FROM users WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$id]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    /**
     * Check if a user is a superadmin.
     */
    public function isSuperadmin(int $userId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT is_superadmin FROM users WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([$userId]);
        $result = $stmt->fetch();
        
        return $result !== false && !empty($result['is_superadmin']);
    }

    public function findByEmail(string $email): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, email, password_hash, first_name, last_name, phone, email_verified_at, is_active, is_superadmin, created_at 
             FROM users WHERE email = ?'
        );
        $stmt->execute([$email]);
        $result = $stmt->fetch();
        
        return $result ?: null;
    }

    public function create(array $data): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO users (email, password_hash, first_name, last_name, phone) 
             VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $data['email'],
            $data['password_hash'],
            $data['first_name'],
            $data['last_name'],
            $data['phone'] ?? null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function updateLastLogin(int $userId): void
    {
        // users table doesn't have last_login column in schema - no-op for now
        // Could add: UPDATE users SET updated_at = NOW() WHERE id = ?
    }

    public function updatePassword(int $userId, string $passwordHash): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute([$passwordHash, $userId]);
    }
}
