<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

final class ClientRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function db(): Connection
    {
        return $this->db;
    }

    public function findById(int $clientId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, user_id, first_name, last_name, email, phone, 
                    notes, is_archived, created_at, updated_at
             FROM clients
             WHERE id = ? AND is_archived = 0'
        );
        $stmt->execute([$clientId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function findByUserIdAndBusiness(int $userId, int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, user_id, first_name, last_name, email, phone, 
                    notes, is_archived, created_at, updated_at
             FROM clients
             WHERE user_id = ? AND business_id = ? AND is_archived = 0'
        );
        $stmt->execute([$userId, $businessId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function findOrCreateForUser(int $userId, int $businessId, array $userData = []): array
    {
        // 1. Cerca client già associato a questo user
        $client = $this->findByUserIdAndBusiness($userId, $businessId);

        if ($client !== null) {
            return $client;
        }

        // Fetch user data if not provided
        if (empty($userData)) {
            $stmt = $this->db->getPdo()->prepare(
                'SELECT email, first_name, last_name, phone FROM users WHERE id = ?'
            );
            $stmt->execute([$userId]);
            $userData = $stmt->fetch() ?: [];
        }

        // 2. Cerca client esistente per email o telefono (senza user_id)
        $existingClient = $this->findUnlinkedByEmailOrPhone(
            $businessId,
            $userData['email'] ?? null,
            $userData['phone'] ?? null
        );

        if ($existingClient !== null) {
            // Associa user_id al client esistente
            $this->linkUserToClient($existingClient['id'], $userId);
            return $this->findById($existingClient['id']);
        }

        // 3. Crea nuovo client
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO clients (business_id, user_id, first_name, last_name, email, phone) 
             VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $userId,
            $userData['first_name'] ?? null,
            $userData['last_name'] ?? null,
            $userData['email'] ?? null,
            $userData['phone'] ?? null,
        ]);

        $clientId = (int) $this->db->getPdo()->lastInsertId();

        return $this->findById($clientId);
    }

    /**
     * Find client without user_id by email or phone.
     * Priority: email match first, then phone.
     */
    public function findUnlinkedByEmailOrPhone(int $businessId, ?string $email, ?string $phone): ?array
    {
        // Prima cerca per email (più affidabile)
        if (!empty($email)) {
            $stmt = $this->db->getPdo()->prepare(
                'SELECT id, business_id, user_id, first_name, last_name, email, phone, 
                        notes, is_archived, created_at, updated_at
                 FROM clients
                 WHERE business_id = ? AND email = ? AND user_id IS NULL AND is_archived = 0
                 LIMIT 1'
            );
            $stmt->execute([$businessId, $email]);
            $result = $stmt->fetch();
            if ($result) {
                return $result;
            }
        }

        // Poi cerca per telefono
        if (!empty($phone)) {
            // Normalizza il telefono per il confronto
            $normalizedPhone = preg_replace('/[^\d+]/', '', $phone);
            
            $stmt = $this->db->getPdo()->prepare(
                'SELECT id, business_id, user_id, first_name, last_name, email, phone, 
                        notes, is_archived, created_at, updated_at
                 FROM clients
                 WHERE business_id = ? AND REPLACE(REPLACE(phone, " ", ""), "-", "") = ? 
                   AND user_id IS NULL AND is_archived = 0
                 LIMIT 1'
            );
            $stmt->execute([$businessId, $normalizedPhone]);
            $result = $stmt->fetch();
            if ($result) {
                return $result;
            }
        }

        return null;
    }

    /**
     * Link an existing client to a user account.
     */
    public function linkUserToClient(int $clientId, int $userId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE clients SET user_id = ?, updated_at = NOW() WHERE id = ? AND user_id IS NULL'
        );
        return $stmt->execute([$userId, $clientId]);
    }

    public function findByBusinessId(int $businessId, int $limit = 100, int $offset = 0): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, user_id, first_name, last_name, email, phone, 
                    notes, is_archived, created_at, updated_at
             FROM clients
             WHERE business_id = ? AND is_archived = 0
             ORDER BY last_name ASC, first_name ASC
             LIMIT ? OFFSET ?'
        );
        $stmt->execute([$businessId, $limit, $offset]);

        return $stmt->fetchAll();
    }

    public function searchByName(int $businessId, string $query, int $limit = 20): array
    {
        $searchTerm = '%' . $query . '%';
        
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, user_id, first_name, last_name, email, phone, 
                    notes, is_archived, created_at, updated_at
             FROM clients
             WHERE business_id = ? AND is_archived = 0
               AND (first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR phone LIKE ?)
             ORDER BY last_name ASC, first_name ASC
             LIMIT ?'
        );
        $stmt->execute([$businessId, $searchTerm, $searchTerm, $searchTerm, $searchTerm, $limit]);

        return $stmt->fetchAll();
    }

    public function update(int $clientId, array $data): bool
    {
        $fields = [];
        $values = [];

        foreach (['first_name', 'last_name', 'email', 'phone', 'notes'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "{$field} = ?";
                $values[] = $data[$field];
            }
        }

        if (empty($fields)) {
            return false;
        }

        $values[] = $clientId;

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE clients SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE id = ?'
        );

        return $stmt->execute($values);
    }

    public function belongsToBusiness(int $clientId, int $businessId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM clients WHERE id = ? AND business_id = ? AND is_archived = 0'
        );
        $stmt->execute([$clientId, $businessId]);

        return $stmt->fetchColumn() !== false;
    }

    /**
     * Find all businesses where user is a client.
     */
    public function findByUserId(int $userId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT c.id, c.business_id, c.first_name, c.last_name, c.email, c.phone,
                    b.name AS business_name
             FROM clients c
             JOIN businesses b ON c.business_id = b.id
             WHERE c.user_id = ? AND c.is_archived = 0
             ORDER BY b.name ASC'
        );
        $stmt->execute([$userId]);

        return $stmt->fetchAll();
    }
}
