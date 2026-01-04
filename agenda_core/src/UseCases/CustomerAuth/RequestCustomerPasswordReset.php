<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Notifications\EmailService;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;

final class RequestCustomerPasswordReset
{
    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
        private readonly BusinessRepository $businessRepository,
    ) {}

    /**
     * Request a password reset for the given customer email.
     * Returns true if email was found (for security, always show success message to user).
     */
    public function execute(string $email, int $businessId): bool
    {
        // Find client by email in business
        $client = $this->clientAuthRepository->findByEmailForAuth($email, $businessId);

        if ($client === null) {
            // Don't reveal if email exists
            return false;
        }

        // Get business info for email
        $business = $this->businessRepository->findById($businessId);
        if ($business === null) {
            return false;
        }

        // Generate reset token
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);

        // Store reset token (24 hours expiry)
        $this->clientAuthRepository->createPasswordResetToken(
            (int) $client['id'],
            $tokenHash,
            86400 // 24 hours
        );

        // Send password reset email
        $this->sendPasswordResetEmail(
            email: $client['email'],
            clientName: $client['first_name'] ?? '',
            businessName: $business['name'],
            businessSlug: $business['slug'],
            resetToken: $token
        );

        return true;
    }

    private function sendPasswordResetEmail(
        string $email,
        string $clientName,
        string $businessName,
        string $businessSlug,
        string $resetToken
    ): void {
        try {
            $template = EmailTemplateRenderer::customerPasswordReset();
            
            // Reset URL va al FRONTEND prenotazioni
            $frontendUrl = $_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it';
            $resetUrl = $frontendUrl . '/' . $businessSlug . '/reset-password/' . $resetToken;

            $variables = [
                'client_name' => $clientName ?: 'Cliente',
                'business_name' => $businessName,
                'reset_url' => $resetUrl,
            ];

            $subject = EmailTemplateRenderer::render($template['subject'], $variables);
            $htmlBody = EmailTemplateRenderer::render($template['html'], $variables);

            error_log("[RequestCustomerPasswordReset] Sending email to {$email} for {$businessName}");

            $emailService = EmailService::create();
            $result = $emailService->send($email, $subject, $htmlBody);

            if ($result) {
                error_log("[RequestCustomerPasswordReset] Email sent successfully to {$email}");
            } else {
                error_log("[RequestCustomerPasswordReset] Email FAILED for {$email}");
            }
        } catch (\Throwable $e) {
            // Log but don't fail - token is already created
            error_log("[RequestCustomerPasswordReset] Exception: " . $e->getMessage());
        }
    }
}
