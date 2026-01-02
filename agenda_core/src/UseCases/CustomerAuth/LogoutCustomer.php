<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;

/**
 * Logout customer by revoking refresh token.
 */
final class LogoutCustomer
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
    ) {}

    public function execute(string $refreshToken): void
    {
        $tokenHash = hash('sha256', $refreshToken);
        $session = $this->clientAuthRepository->findSessionByTokenHash($tokenHash);

        if ($session !== null) {
            $this->clientAuthRepository->revokeSession((int) $session['id']);
        }
    }
}
