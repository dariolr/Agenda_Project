<?php

declare(strict_types=1);

namespace Agenda\UseCases\CustomerAuth;

use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\ForgotPasswordRateLimitRepository;
use Agenda\Infrastructure\Notifications\EmailService;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;

final class RequestCustomerPasswordReset
{
    private const RESET_COOLDOWN_MINUTES = 5;
    private const BUSINESS_WINDOW_MINUTES = 10;
    private const BUSINESS_MAX_REQUESTS = 30;

    public function __construct(
        private readonly ClientAuthRepository $clientAuthRepository,
        private readonly BusinessRepository $businessRepository,
        private readonly ForgotPasswordRateLimitRepository $rateLimitRepository,
    ) {}

    /**
     * Request a password reset for the given customer email.
     * Works for both registered clients (with password) and imported clients (without password).
     * Returns true if email was found (for security, always show success message to user).
     */
    public function execute(string $email, int $businessId, ?string $ipAddress = null): bool
    {
        if ($this->rateLimitRepository->isRateLimited('customer', $businessId, $email, $ipAddress)) {
            error_log("[RequestCustomerPasswordReset] Rate limit exceeded for business {$businessId}");
            return true;
        }

        $this->rateLimitRepository->recordAttempt('customer', $businessId, $email, $ipAddress);

        // Find client by email in business (even without password - for first activation)
        $client = $this->clientAuthRepository->findByEmail($email, $businessId);

        if ($client === null) {
            // Don't reveal if email exists
            return false;
        }

        // Get business info for email
        $business = $this->businessRepository->findById($businessId);
        if ($business === null) {
            return false;
        }

        if ($this->isBusinessResetVolumeExceeded($businessId)) {
            // Silent success: protect this business from reset bursts
            return true;
        }

        if ($this->hasRecentResetRequest((int) $client['id'])) {
            // Silent success to reduce abuse bursts on the same address
            return true;
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

    private function hasRecentResetRequest(int $clientId): bool
    {
        return $this->clientAuthRepository->hasRecentPasswordResetRequest(
            $clientId,
            self::RESET_COOLDOWN_MINUTES
        );
    }

    private function isBusinessResetVolumeExceeded(int $businessId): bool
    {
        $count = $this->clientAuthRepository->countRecentPasswordResetRequestsForBusiness(
            $businessId,
            self::BUSINESS_WINDOW_MINUTES
        );

        return $count >= self::BUSINESS_MAX_REQUESTS;
    }

    private function sendPasswordResetEmail(
        string $email,
        string $clientName,
        string $businessName,
        string $businessSlug,
        string $resetToken
    ): void {
        try {
            $locale = EmailTemplateRenderer::resolvePreferredLocale(
                null,
                $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? null,
                $_ENV['DEFAULT_LOCALE'] ?? 'it'
            );
            $template = EmailTemplateRenderer::customerPasswordReset($locale);
            
            // Reset URL va al FRONTEND prenotazioni
            $frontendUrl = $_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it';
            $resetUrl = $frontendUrl . '/' . $businessSlug . '/reset-password/' . $resetToken;

            $strings = EmailTemplateRenderer::strings($locale);
            $variables = [
                'client_name' => $clientName ?: $strings['client_fallback'],
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
