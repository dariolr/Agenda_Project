<?php

declare(strict_types=1);

namespace Agenda\UseCases\Auth;

use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\EmailService;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use DateTimeImmutable;

final class RequestPasswordReset
{
    public function __construct(
        private readonly Connection $db,
        private readonly UserRepository $userRepository,
    ) {}

    /**
     * Request a password reset for the given email.
     * Returns true if email was found (for security, always returns success message to user).
     */
    public function execute(string $email): bool
    {
        $user = $this->userRepository->findByEmail($email);

        if ($user === null) {
            // Don't reveal if email exists
            return false;
        }

        // Generate reset token
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $expiresAt = (new DateTimeImmutable('+1 hour'))->format('Y-m-d H:i:s');

        // Store reset token (invalidate any existing tokens for this user)
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM password_reset_token_users WHERE user_id = ?'
        );
        $stmt->execute([(int) $user['id']]);

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO password_reset_token_users (user_id, token_hash, expires_at) VALUES (?, ?, ?)'
        );
        $stmt->execute([
            (int) $user['id'],
            $tokenHash,
            $expiresAt,
        ]);

        // Send email with reset link
        $this->sendPasswordResetEmail(
            email: $email,
            userName: trim(($user['first_name'] ?? '') . ' ' . ($user['last_name'] ?? '')),
            resetToken: $token
        );

        return true;
    }

    private function sendPasswordResetEmail(
        string $email,
        string $userName,
        string $resetToken
    ): void {
        try {
            $locale = EmailTemplateRenderer::resolvePreferredLocale(
                null,
                $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? null,
                $_ENV['DEFAULT_LOCALE'] ?? 'it'
            );
            $template = EmailTemplateRenderer::operatorPasswordReset($locale);
            $strings = EmailTemplateRenderer::strings($locale);
            
            // Reset URL va al GESTIONALE (usa BACKEND_URL dalla config)
            $gestionaleUrl = $_ENV['BACKEND_URL'] ?? 'https://gestionale.romeolab.it';
            $resetUrl = $gestionaleUrl . '/reset-password/' . $resetToken;

            $variables = [
                'user_name' => $userName !== '' ? $userName : $strings['operator_fallback'],
                'reset_url' => $resetUrl,
            ];

            $subject = EmailTemplateRenderer::render($template['subject'], $variables);
            $htmlBody = EmailTemplateRenderer::render($template['html'], $variables);

            error_log("[RequestPasswordReset] Sending email to {$email}");

            $emailService = EmailService::create();
            $result = $emailService->send($email, $subject, $htmlBody);

            if ($result) {
                error_log("[RequestPasswordReset] Email sent successfully to {$email}");
            } else {
                error_log("[RequestPasswordReset] Email FAILED for {$email}");
            }
        } catch (\Throwable $e) {
            // Log but don't fail - token is already created
            error_log("[RequestPasswordReset] Exception: " . $e->getMessage());
        }
    }
}
