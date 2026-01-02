<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Domain\Exceptions\AuthException;

/**
 * Get current customer profile from JWT.
 */
final class GetCustomerMe
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
    ) {}

    /**
     * @return array{id: int, email: string|null, first_name: string|null, last_name: string|null, phone: string|null, business_id: int}
     * @throws AuthException
     */
    public function execute(int $clientId): array
    {
        $client = $this->clientAuthRepository->findById($clientId);

        if ($client === null) {
            throw AuthException::userNotFound();
        }

        if (!empty($client['is_archived'])) {
            throw AuthException::accountDisabled();
        }

        return [
            'id' => (int) $client['id'],
            'email' => $client['email'],
            'first_name' => $client['first_name'],
            'last_name' => $client['last_name'],
            'phone' => $client['phone'] ?? null,
            'business_id' => (int) $client['business_id'],
        ];
    }
}
