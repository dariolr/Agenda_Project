<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\AuthSessionRepository;

final class LogoutUser
{
    public function __construct(
        private readonly AuthSessionRepository $authSessionRepository,
    ) {}

    /**
     * Logout user by revoking the refresh token session.
     */
    public function execute(string $refreshToken): void
    {
        $refreshTokenHash = hash('sha256', $refreshToken);
        
        $session = $this->authSessionRepository->findByTokenHash($refreshTokenHash);

        if ($session !== null) {
            $this->authSessionRepository->revoke((int) $session['id']);
        }
    }

    /**
     * Logout from all devices by revoking all sessions for a user.
     */
    public function executeAllDevices(int $userId): void
    {
        $this->authSessionRepository->revokeAllForUser($userId);
    }
}
