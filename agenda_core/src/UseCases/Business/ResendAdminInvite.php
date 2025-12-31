<?php

declare(strict_types=1);

namespace Agenda\UseCases\Business;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Notifications\EmailService;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\ValidationException;
use DateTimeImmutable;

/**
 * Resend admin invitation email.
 * Superadmin only.
 * 
 * Generates a new password reset token (24h) and sends welcome email.
 */
final class ResendAdminInvite
{
    public function __construct(
        private readonly Connection $db,
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @param int $superadminId Must be superadmin
     * @param int $businessId Business to resend invite for
     * @return array Result with admin info
     * @throws AuthException If user is not superadmin
     * @throws ValidationException If business not found or no admin
     */
    public function execute(int $superadminId, int $businessId): array
    {
        // Verify superadmin
        $superadmin = $this->userRepo->findById($superadminId);
        if ($superadmin === null || empty($superadmin['is_superadmin'])) {
            throw AuthException::forbidden('Superadmin access required');
        }

        // Get business
        $business = $this->businessRepo->findById($businessId);
        if ($business === null) {
            throw ValidationException::withErrors(['business_id' => 'Business not found']);
        }

        // Get current owner/admin
        $owner = $this->businessUserRepo->getOwner($businessId);
        if ($owner === null) {
            throw ValidationException::withErrors(['business_id' => 'Business has no admin']);
        }

        $adminEmail = $owner['email'];
        $adminUserId = (int) $owner['user_id'];

        // Generate new reset token (24h)
        $resetToken = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $resetToken);
        $expiresAt = (new DateTimeImmutable('+24 hours'))->format('Y-m-d H:i:s');

        // Delete existing tokens and create new one
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM password_reset_tokens WHERE user_id = ?'
        );
        $stmt->execute([$adminUserId]);

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)'
        );
        $stmt->execute([$adminUserId, $tokenHash, $expiresAt]);

        // Send welcome email
        $this->sendWelcomeEmail($adminEmail, $business['name'], $business['slug'], $resetToken);

        return [
            'success' => true,
            'message' => 'Invitation email sent',
            'admin' => [
                'id' => $adminUserId,
                'email' => $adminEmail,
            ],
            'expires_at' => $expiresAt,
        ];
    }

    private function sendWelcomeEmail(string $adminEmail, string $businessName, string $businessSlug, string $resetToken): void
    {
        try {
            $template = EmailTemplateRenderer::businessAdminWelcome();
            $frontendUrl = $_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it';
            $resetUrl = $frontendUrl . '/reset-password/' . $resetToken;
            $bookingUrl = $frontendUrl . '/' . $businessSlug;

            $variables = [
                'business_name' => $businessName,
                'booking_url' => $bookingUrl,
                'reset_url' => $resetUrl,
            ];

            $subject = EmailTemplateRenderer::render($template['subject'], $variables);
            $htmlBody = EmailTemplateRenderer::render($template['html'], $variables);

            error_log("[ResendAdminInvite] Sending email to {$adminEmail} for {$businessName}");

            $emailService = EmailService::create();
            $result = $emailService->send($adminEmail, $subject, $htmlBody);

            if ($result) {
                error_log("[ResendAdminInvite] Email sent successfully to {$adminEmail}");
            } else {
                error_log("[ResendAdminInvite] Email FAILED for {$adminEmail}");
                throw new \RuntimeException('Email service returned false');
            }
        } catch (\Throwable $e) {
            error_log("[ResendAdminInvite] Exception: " . $e->getMessage());
            throw new \RuntimeException('Failed to send invitation email: ' . $e->getMessage());
        }
    }
}
