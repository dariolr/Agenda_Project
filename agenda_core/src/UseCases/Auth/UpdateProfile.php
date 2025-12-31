<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Domain\Exceptions\ValidationException;

/**
 * Update user profile (email, first_name, last_name, phone).
 * Any authenticated user can update their own profile.
 */
final class UpdateProfile
{
    public function __construct(
        private readonly Connection $db,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @param int $userId The user updating their profile
     * @param array $data Fields to update (email, first_name, last_name, phone)
     * @return array Updated user data
     * @throws ValidationException if validation fails
     */
    public function execute(int $userId, array $data): array
    {
        $user = $this->userRepo->findById($userId);
        if ($user === null) {
            throw ValidationException::withErrors(['user' => 'User not found']);
        }

        // Validate email if changing
        if (isset($data['email']) && $data['email'] !== $user['email']) {
            if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
                throw ValidationException::withErrors(['email' => 'Invalid email address']);
            }

            // Check if email is already taken
            $existing = $this->userRepo->findByEmail($data['email']);
            if ($existing !== null) {
                throw ValidationException::withErrors(['email' => 'Email already in use']);
            }
        }

        // Filter allowed fields
        $allowedFields = ['email', 'first_name', 'last_name', 'phone'];
        $updateData = array_intersect_key($data, array_flip($allowedFields));

        if (empty($updateData)) {
            throw ValidationException::withErrors(['data' => 'No valid fields to update']);
        }

        // Perform update
        $this->updateUser($userId, $updateData);

        // Return updated user
        $updated = $this->userRepo->findById($userId);

        return [
            'id' => (int) $updated['id'],
            'email' => $updated['email'],
            'first_name' => $updated['first_name'],
            'last_name' => $updated['last_name'],
            'phone' => $updated['phone'],
            'is_superadmin' => (bool) ($updated['is_superadmin'] ?? false),
        ];
    }

    private function updateUser(int $userId, array $data): void
    {
        $setClauses = [];
        $values = [];

        foreach ($data as $field => $value) {
            $setClauses[] = "{$field} = ?";
            $values[] = $value;
        }

        $setClauses[] = 'updated_at = NOW()';
        $values[] = $userId;

        $sql = 'UPDATE users SET ' . implode(', ', $setClauses) . ' WHERE id = ?';
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($values);
    }
}
