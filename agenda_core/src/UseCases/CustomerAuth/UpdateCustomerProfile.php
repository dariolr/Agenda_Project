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
        ?string $phone = null,
        ?bool $marketingOptIn = null,
        ?bool $profilingOptIn = null,
        ?string $preferredChannel = null
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

        if ($preferredChannel !== null) {
            $allowedChannels = ['whatsapp', 'sms', 'email', 'phone', 'none'];
            if (!in_array(strtolower(trim($preferredChannel)), $allowedChannels, true)) {
                throw ValidationException::create('Invalid preferred_channel');
            }
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

        if ($marketingOptIn !== null || $profilingOptIn !== null || $preferredChannel !== null) {
            $this->clientAuthRepository->upsertConsents(
                (int) $client['business_id'],
                $clientId,
                $marketingOptIn ?? (bool) ($client['marketing_opt_in'] ?? false),
                $profilingOptIn ?? (bool) ($client['profiling_opt_in'] ?? false),
                $preferredChannel ?? (string) ($client['preferred_channel'] ?? 'none'),
                null,
                'frontend-profile'
            );
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
            'marketing_opt_in' => (bool) ($updatedClient['marketing_opt_in'] ?? false),
            'profiling_opt_in' => (bool) ($updatedClient['profiling_opt_in'] ?? false),
            'preferred_channel' => (string) ($updatedClient['preferred_channel'] ?? 'none'),
        ];
    }
}
