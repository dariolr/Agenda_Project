<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Domain\Exceptions\AuthException;

final class GetMe
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly ClientRepository $clientRepository,
    ) {}

    /**
     * Get current user profile with client memberships.
     * 
     * Users are global identities. They become clients when they book at a business.
     * Staff are business employees (separate from users).
     * 
     * @return array User profile data
     * @throws AuthException
     */
    public function execute(int $userId): array
    {
        $user = $this->userRepository->findById($userId);

        if ($user === null) {
            throw AuthException::tokenInvalid();
        }

        // Get businesses where user is a client
        $clientMemberships = $this->clientRepository->findByUserId($userId);

        return [
            'id' => (int) $user['id'],
            'email' => $user['email'],
            'first_name' => $user['first_name'],
            'last_name' => $user['last_name'],
            'phone' => $user['phone'],
            'is_active' => (bool) $user['is_active'],
            'email_verified_at' => $user['email_verified_at'],
            'created_at' => $user['created_at'],
            'client_memberships' => array_map(fn($client) => [
                'client_id' => (int) $client['id'],
                'business_id' => (int) $client['business_id'],
                'business_name' => $client['business_name'] ?? null,
            ], $clientMemberships),
        ];
    }
}
