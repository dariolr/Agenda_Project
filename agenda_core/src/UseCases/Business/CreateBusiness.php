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
 * Create a new business with admin (superadmin only).
 * Uses transaction to ensure atomicity.
 * 
 * Flow:
 * 1. Create business
 * 2. Create admin user (or use existing if email already registered)
 * 3. Assign user as business owner
 * 4. Generate password reset token (24h validity)
 * 5. Send welcome email with setup link
 */
final class CreateBusiness
{
    public function __construct(
        private readonly Connection $db,
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @param int $superadminId Must be superadmin
     * @param string $name Business name
     * @param string $slug Business slug (unique)
     * @param string|null $adminEmail Admin email address (optional, can be set later via update)
     * @param array $options Optional: email (business), phone, online_bookings_notification_email, service_color_palette, timezone, currency, admin_first_name, admin_last_name
     * @return array Created business data with admin info
     * @throws AuthException If user is not superadmin
     * @throws ValidationException If validation fails
     */
    public function execute(
        int $superadminId,
        string $name,
        string $slug,
        ?string $adminEmail = null,
        array $options = []
    ): array {
        // Verify superadmin
        $superadmin = $this->userRepo->findById($superadminId);
        if ($superadmin === null || empty($superadmin['is_superadmin'])) {
            throw AuthException::forbidden('Superadmin access required');
        }

        // Validate admin email if provided
        if ($adminEmail !== null && $adminEmail !== '' && !filter_var($adminEmail, FILTER_VALIDATE_EMAIL)) {
            throw ValidationException::withErrors(['admin_email' => 'Invalid email address']);
        }

        $notifyEmail = $options['online_bookings_notification_email'] ?? null;
        if (is_string($notifyEmail)) {
            $notifyEmail = trim($notifyEmail);
            if ($notifyEmail === '') {
                $notifyEmail = null;
            }
        }
        if ($notifyEmail !== null && $notifyEmail !== '' && !filter_var($notifyEmail, FILTER_VALIDATE_EMAIL)) {
            throw ValidationException::withErrors([
                'online_bookings_notification_email' => 'Invalid email address',
            ]);
        }

        $serviceColorPalette = $options['service_color_palette'] ?? 'legacy';
        if (!is_string($serviceColorPalette)) {
            throw ValidationException::withErrors([
                'service_color_palette' => 'Invalid palette value',
            ]);
        }
        $serviceColorPalette = trim(strtolower($serviceColorPalette));
        if (!in_array($serviceColorPalette, ['enhanced', 'legacy'], true)) {
            throw ValidationException::withErrors([
                'service_color_palette' => 'Invalid palette value',
            ]);
        }

        // Check slug uniqueness
        $existingBusiness = $this->businessRepo->findBySlug($slug);
        if ($existingBusiness !== null) {
            throw ValidationException::withErrors(['slug' => 'Business slug already exists']);
        }

        // Start transaction
        $this->db->beginTransaction();

        try {
            // 1. Create business
            $businessId = $this->businessRepo->create(
                $name,
                $slug,
                [
                    'email' => $options['email'] ?? null,
                    'phone' => $options['phone'] ?? null,
                    'online_bookings_notification_email' => $notifyEmail,
                    'service_color_palette' => $serviceColorPalette,
                    'timezone' => $options['timezone'] ?? 'Europe/Rome',
                    'currency' => $options['currency'] ?? 'EUR',
                ]
            );

            $adminUserId = null;
            $isNewUser = false;
            $resetToken = null;

            // 2. Handle admin if email provided
            if ($adminEmail !== null && $adminEmail !== '') {
                // Check if user already exists or create new one
                $existingUser = $this->userRepo->findByEmail($adminEmail);

                if ($existingUser !== null) {
                    $adminUserId = (int) $existingUser['id'];
                } else {
                    // Create new user with random temporary password
                    $tempPassword = bin2hex(random_bytes(16));
                    $adminUserId = $this->userRepo->create([
                        'email' => $adminEmail,
                        'password_hash' => password_hash($tempPassword, PASSWORD_BCRYPT),
                        'first_name' => $options['admin_first_name'] ?? '',
                        'last_name' => $options['admin_last_name'] ?? '',
                        'phone' => null,
                    ]);
                    $isNewUser = true;
                }

                // 3. Assign admin as business owner
                $this->businessUserRepo->createOwner($businessId, $adminUserId);

                // 4. Generate password reset token (30 days validity)
                $resetToken = bin2hex(random_bytes(32));
                $tokenHash = hash('sha256', $resetToken);
                $expiresAt = (new DateTimeImmutable('+30 days'))->format('Y-m-d H:i:s');

                // Delete any existing tokens for this user
                $stmt = $this->db->getPdo()->prepare(
                    'DELETE FROM password_reset_token_users WHERE user_id = ?'
                );
                $stmt->execute([$adminUserId]);

                // Insert new token
                $stmt = $this->db->getPdo()->prepare(
                    'INSERT INTO password_reset_token_users (user_id, token_hash, expires_at) VALUES (?, ?, ?)'
                );
                $stmt->execute([$adminUserId, $tokenHash, $expiresAt]);
            }

            // Commit transaction before sending email
            $this->db->commit();

            // 5. Send welcome email (outside transaction) if admin was assigned
            if ($adminEmail !== null && $adminEmail !== '' && $resetToken !== null) {
                $this->sendWelcomeEmail($adminEmail, $name, $slug, $resetToken);
            }

            // Fetch created business
            $business = $this->businessRepo->findById($businessId);

            $result = [
                'id' => $businessId,
                'name' => $business['name'],
                'slug' => $business['slug'],
                'email' => $business['email'],
                'phone' => $business['phone'],
                'online_bookings_notification_email' => $business['online_bookings_notification_email'] ?? null,
                'service_color_palette' => $business['service_color_palette'] ?? 'legacy',
                'timezone' => $business['timezone'],
                'currency' => $business['currency'],
            ];

            if ($adminUserId !== null) {
                $result['admin'] = [
                    'id' => $adminUserId,
                    'email' => $adminEmail,
                    'is_new_user' => $isNewUser,
                ];
            }

            return $result;
        } catch (\Throwable $e) {
            // Rollback on any error
            $this->db->rollback();
            throw $e;
        }
    }

    /**
     * Send welcome email to new business admin.
     */
    private function sendWelcomeEmail(
        string $adminEmail,
        string $businessName,
        string $businessSlug,
        string $resetToken
    ): void {
        try {
            $locale = $_ENV['DEFAULT_LOCALE'] ?? 'it';
            $template = EmailTemplateRenderer::businessAdminWelcome($locale);
            // Reset password va al GESTIONALE (backend), non al frontend prenotazioni
            $backendUrl = $_ENV['BACKEND_URL'] ?? 'https://gestionale.romeolab.it';
            $frontendUrl = $_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it';
            $resetUrl = $backendUrl . '/reset-password/' . $resetToken;
            $bookingUrl = $frontendUrl . '/' . $businessSlug;

            $variables = [
                'business_name' => $businessName,
                'booking_url' => $bookingUrl,
                'reset_url' => $resetUrl,
            ];

            $subject = EmailTemplateRenderer::render($template['subject'], $variables);
            $htmlBody = EmailTemplateRenderer::render($template['html'], $variables);

            error_log("[CreateBusiness] Sending welcome email to {$adminEmail} for {$businessName}");

            $emailService = EmailService::create();
            $result = $emailService->send($adminEmail, $subject, $htmlBody);

            if ($result) {
                error_log("[CreateBusiness] Welcome email sent successfully to {$adminEmail}");
            } else {
                error_log("[CreateBusiness] Welcome email FAILED for {$adminEmail}");
            }
        } catch (\Throwable $e) {
            error_log("[CreateBusiness] Exception sending email to {$adminEmail}: " . $e->getMessage());
        }
    }
}
