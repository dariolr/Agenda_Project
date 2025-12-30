<?php

declare(strict_types=1);

namespace Agenda\UseCases\Business;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\ValidationException;

/**
 * Create a new business with owner (superadmin only).
 * Uses transaction to ensure atomicity.
 */
final class CreateBusiness
{
    public function __construct(
        private readonly Connection $db,
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @param int $superadminId Must be superadmin
     * @param string $name Business name
     * @param string $slug Business slug (unique)
     * @param int $ownerUserId Owner user ID
     * @param array $options Optional: email, phone, timezone, currency
     * @return array Created business data
     * @throws AuthException If user is not superadmin
     * @throws ValidationException If validation fails
     */
    public function execute(
        int $superadminId,
        string $name,
        string $slug,
        int $ownerUserId,
        array $options = []
    ): array {
        // Verify superadmin
        $superadmin = $this->userRepo->findById($superadminId);
        if ($superadmin === null || empty($superadmin['is_superadmin'])) {
            throw AuthException::forbidden('Superadmin access required');
        }

        // Check slug uniqueness
        $existingBusiness = $this->businessRepo->findBySlug($slug);
        if ($existingBusiness !== null) {
            throw ValidationException::withErrors(['slug' => 'Business slug already exists']);
        }

        // Check owner exists
        $ownerUser = $this->userRepo->findById($ownerUserId);
        if ($ownerUser === null) {
            throw ValidationException::withErrors(['owner_user_id' => 'User not found']);
        }

        // Start transaction
        $this->db->beginTransaction();

        try {
            // Create business
            $businessId = $this->businessRepo->create(
                $name,
                $slug,
                [
                    'email' => $options['email'] ?? null,
                    'phone' => $options['phone'] ?? null,
                    'timezone' => $options['timezone'] ?? 'Europe/Rome',
                    'currency' => $options['currency'] ?? 'EUR',
                ]
            );

            // Assign owner (businessId, userId)
            $this->businessUserRepo->createOwner($businessId, $ownerUserId);

            // Commit transaction
            $this->db->commit();

            // Fetch created business
            $business = $this->businessRepo->findById($businessId);

            return [
                'id' => $businessId,
                'name' => $business['name'],
                'slug' => $business['slug'],
                'email' => $business['email'],
                'phone' => $business['phone'],
                'timezone' => $business['timezone'],
                'currency' => $business['currency'],
                'owner' => [
                    'id' => $ownerUserId,
                    'email' => $ownerUser['email'],
                    'name' => trim(($ownerUser['first_name'] ?? '') . ' ' . ($ownerUser['last_name'] ?? '')),
                ],
            ];
        } catch (\Throwable $e) {
            // Rollback on any error
            $this->db->rollback();
            throw $e;
        }
    }
}
