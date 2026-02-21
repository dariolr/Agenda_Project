<?php

declare(strict_types=1);

namespace Agenda\UseCases\Business;

use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Domain\Exceptions\AuthException;

/**
 * Get all businesses (superadmin only).
 * Supports search and pagination.
 */
final class GetAllBusinesses
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @param int $userId Must be superadmin
     * @param string|null $search Search term for name/slug/email
     * @param int|null $limit Max results (null = no limit)
     * @param int $offset Pagination offset
     * @return array List of all businesses
     * @throws AuthException If user is not superadmin
     */
    public function execute(
        int $userId,
        ?string $search = null,
        ?int $limit = null,
        int $offset = 0
    ): array {
        $user = $this->userRepo->findById($userId);
        
        if ($user === null || empty($user['is_superadmin'])) {
            throw AuthException::forbidden('Superadmin access required');
        }

        $businesses = $this->businessRepo->findAllWithSearch($search, $limit, $offset);
        $total = $this->businessRepo->countAll($search);

        return [
            'businesses' => array_map(fn($b) => [
                'id' => (int) $b['id'],
                'name' => $b['name'],
                'slug' => $b['slug'],
                'email' => $b['email'],
                'phone' => $b['phone'],
                'online_bookings_notification_email' => $b['online_bookings_notification_email'] ?? null,
                'service_color_palette' => $b['service_color_palette'] ?? 'legacy',
                'timezone' => $b['timezone'],
                'currency' => $b['currency'],
                'cancellation_hours' => isset($b['cancellation_hours']) ? (int) $b['cancellation_hours'] : null,
                'is_active' => (bool) $b['is_active'],
                'is_suspended' => (bool) ($b['is_suspended'] ?? false),
                'suspension_message' => $b['suspension_message'] ?? null,
                'created_at' => $b['created_at'],
                'updated_at' => $b['updated_at'],
                'admin_email' => $b['admin_email'] ?? null,
            ], $businesses),
            'pagination' => [
                'total' => $total,
                'limit' => $limit,
                'offset' => $offset,
                'has_more' => $limit !== null && ($offset + count($businesses)) < $total,
            ],
        ];
    }
}
