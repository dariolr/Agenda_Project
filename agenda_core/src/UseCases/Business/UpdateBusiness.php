<?php

declare(strict_types=1);

namespace Agenda\UseCases\Business;

use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\ValidationException;

/**
 * UseCase: Update an existing business.
 * Superadmin only.
 */
final class UpdateBusiness
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @param int $executorUserId The user executing this action (must be superadmin)
     * @param int $businessId The business to update
     * @param array $data Fields to update (name, slug, email, phone, timezone, currency)
     * @return array The updated business data
     * @throws AuthException if user is not superadmin
     * @throws ValidationException if validation fails
     */
    public function execute(int $executorUserId, int $businessId, array $data): array
    {
        // Verify superadmin
        $superadmin = $this->userRepo->findById($executorUserId);
        if ($superadmin === null || empty($superadmin['is_superadmin'])) {
            throw new AuthException('Superadmin access required');
        }

        // Verify business exists
        $business = $this->businessRepo->findById($businessId);
        if ($business === null) {
            throw new ValidationException('Business not found');
        }

        // Validate slug if changing
        if (isset($data['slug']) && $data['slug'] !== $business['slug']) {
            $existing = $this->businessRepo->findBySlug($data['slug']);
            if ($existing !== null) {
                throw new ValidationException('Slug already in use');
            }
        }

        // Filter allowed fields
        $allowedFields = ['name', 'slug', 'email', 'phone', 'timezone', 'currency'];
        $updateData = array_intersect_key($data, array_flip($allowedFields));

        if (empty($updateData)) {
            throw new ValidationException('No valid fields to update');
        }

        // Perform update
        $this->businessRepo->update($businessId, $updateData);

        // Return updated business
        $updated = $this->businessRepo->findById($businessId);

        return [
            'business' => [
                'id' => $updated['id'],
                'name' => $updated['name'],
                'slug' => $updated['slug'],
                'email' => $updated['email'],
                'phone' => $updated['phone'],
                'timezone' => $updated['timezone'],
                'currency' => $updated['currency'],
                'is_active' => (bool) $updated['is_active'],
                'created_at' => $updated['created_at'],
            ],
        ];
    }
}
