<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Domain\Exceptions\ValidationException;

final class UpdateCustomerProfile
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
    ) {}

    /**
     * Update customer profile.
     */
    public function execute(
        int $clientId,
        ?string $firstName = null,
        ?string $lastName = null,
        ?string $email = null,
        ?string $phone = null
    ): array {
        // Validate email if provided
        if ($email !== null && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw ValidationException::create('Invalid email format');
        }

        // Get current client data
        $client = $this->clientAuthRepository->findById($clientId);
        if ($client === null) {
            throw ValidationException::create('Client not found');
        }

        // Build update data
        $updateData = [];
        if ($firstName !== null) {
            $updateData['first_name'] = $firstName;
        }
        if ($lastName !== null) {
            $updateData['last_name'] = $lastName;
        }
        if ($email !== null) {
            $updateData['email'] = $email;
        }
        if ($phone !== null) {
            $updateData['phone'] = $phone;
        }

        // Update if there's data to update
        if (!empty($updateData)) {
            $this->clientAuthRepository->updateProfile($clientId, $updateData);
        }

        // Return updated client
        $updatedClient = $this->clientAuthRepository->findById($clientId);
        
        return [
            'id' => $updatedClient['id'],
            'email' => $updatedClient['email'],
            'first_name' => $updatedClient['first_name'],
            'last_name' => $updatedClient['last_name'],
            'phone' => $updatedClient['phone'],
            'business_id' => $updatedClient['business_id'],
        ];
    }
}
