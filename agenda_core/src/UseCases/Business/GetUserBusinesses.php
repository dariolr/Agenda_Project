<?php

declare(strict_types=1);

namespace Agenda\UseCases\Business;

use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Get businesses where user has access.
 * 
 * For superadmin: returns empty (use GetAllBusinesses instead)
 * For normal users: returns businesses from business_users table
 */
final class GetUserBusinesses
{
    public function __construct(
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @return array List of businesses with user's role and permissions
     */
    public function execute(int $userId): array
    {
        $user = $this->userRepo->findById($userId);
        
        if ($user === null) {
            return [];
        }

        // Superadmin should use GetAllBusinesses endpoint
        if (!empty($user['is_superadmin'])) {
            return [];
        }

        $businesses = $this->businessUserRepo->findBusinessesByUserId($userId);

        return array_map(fn($b) => [
            'id' => (int) $b['id'],
            'name' => $b['name'],
            'slug' => $b['slug'],
            'email' => $b['email'],
            'phone' => $b['phone'],
            'timezone' => $b['timezone'],
            'currency' => $b['currency'],
            'created_at' => $b['created_at'],
            'role' => $b['role'],
            'permissions' => [
                'can_manage_bookings' => (bool) $b['can_manage_bookings'],
                'can_manage_clients' => (bool) $b['can_manage_clients'],
                'can_manage_services' => (bool) $b['can_manage_services'],
                'can_manage_staff' => (bool) $b['can_manage_staff'],
                'can_view_reports' => (bool) $b['can_view_reports'],
            ],
            'staff_id' => $b['staff_id'] ? (int) $b['staff_id'] : null,
        ], $businesses);
    }
}
