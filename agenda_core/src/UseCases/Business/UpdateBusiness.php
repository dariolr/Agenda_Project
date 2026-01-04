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
 * UseCase: Update an existing business.
 * Superadmin only.
 * 
 * If admin_email is provided and different from current owner:
 * - Creates new user if needed
 * - Transfers ownership
 * - Sends welcome email to new admin
 */
final class UpdateBusiness
{
    public function __construct(
        private readonly Connection $db,
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * @param int $executorUserId The user executing this action (must be superadmin)
     * @param int $businessId The business to update
     * @param array $data Fields to update (name, slug, email, phone, timezone, currency, admin_email)
     * @return array The updated business data
     * @throws AuthException if user is not superadmin
     * @throws ValidationException if validation fails
     */
    public function execute(int $executorUserId, int $businessId, array $data): array
    {
        // Verify superadmin
        $superadmin = $this->userRepo->findById($executorUserId);
        if ($superadmin === null || empty($superadmin['is_superadmin'])) {
            throw new AuthException('Superadmin access required');
        }

        // Verify business exists
        $business = $this->businessRepo->findById($businessId);
        if ($business === null) {
            throw new ValidationException('Business not found');
        }

        // Validate slug if changing
        if (isset($data['slug']) && $data['slug'] !== $business['slug']) {
            $existing = $this->businessRepo->findBySlug($data['slug']);
            if ($existing !== null) {
                throw new ValidationException('Slug already in use');
            }
        }

        // Handle admin_email change
        $newAdminInfo = null;
        if (isset($data['admin_email']) && !empty($data['admin_email'])) {
            $newAdminInfo = $this->handleAdminChange($businessId, $business, $data['admin_email']);
        }

        // Filter allowed fields for business update
        $allowedFields = ['name', 'slug', 'email', 'phone', 'timezone', 'currency'];
        $updateData = array_intersect_key($data, array_flip($allowedFields));

        if (!empty($updateData)) {
            $this->businessRepo->update($businessId, $updateData);
        }

        // Return updated business
        $updated = $this->businessRepo->findById($businessId);
        $currentOwner = $this->businessUserRepo->getOwner($businessId);

        $result = [
            'business' => [
                'id' => $updated['id'],
                'name' => $updated['name'],
                'slug' => $updated['slug'],
                'email' => $updated['email'],
                'phone' => $updated['phone'],
                'timezone' => $updated['timezone'],
                'currency' => $updated['currency'],
                'is_active' => (bool) $updated['is_active'],
                'created_at' => $updated['created_at'],
            ],
        ];

        if ($currentOwner !== null) {
            $result['admin'] = [
                'id' => (int) $currentOwner['user_id'],
                'email' => $currentOwner['email'],
            ];
        }

        if ($newAdminInfo !== null) {
            $result['admin_changed'] = true;
            $result['admin_is_new_user'] = $newAdminInfo['is_new_user'];
        }

        return $result;
    }

    /**
     * Handle admin email change.
     * Creates user if needed, transfers ownership, sends welcome email.
     */
    private function handleAdminChange(int $businessId, array $business, string $newAdminEmail): ?array
    {
        // Validate email
        if (!filter_var($newAdminEmail, FILTER_VALIDATE_EMAIL)) {
            throw ValidationException::withErrors(['admin_email' => 'Invalid email address']);
        }

        // Get current owner
        $currentOwner = $this->businessUserRepo->getOwner($businessId);
        if ($currentOwner !== null && $currentOwner['email'] === $newAdminEmail) {
            // Same admin, nothing to do
            return null;
        }

        $this->db->beginTransaction();

        try {
            // Check if new admin user exists
            $existingUser = $this->userRepo->findByEmail($newAdminEmail);
            $isNewUser = false;

            if ($existingUser !== null) {
                $newAdminUserId = (int) $existingUser['id'];
            } else {
                // Create new user
                $tempPassword = bin2hex(random_bytes(16));
                $newAdminUserId = $this->userRepo->create([
                    'email' => $newAdminEmail,
                    'password_hash' => password_hash($tempPassword, PASSWORD_BCRYPT),
                    'first_name' => '',
                    'last_name' => '',
                    'phone' => null,
                ]);
                $isNewUser = true;
            }

            // Transfer ownership
            if ($currentOwner !== null) {
                $this->businessUserRepo->transferOwnership(
                    $businessId,
                    (int) $currentOwner['user_id'],
                    $newAdminUserId
                );
            } else {
                // No current owner, just create one
                $this->businessUserRepo->createOwner($businessId, $newAdminUserId);
            }

            // Generate password reset token for new user
            $resetToken = null;
            if ($isNewUser) {
                $resetToken = bin2hex(random_bytes(32));
                $tokenHash = hash('sha256', $resetToken);
                $expiresAt = (new DateTimeImmutable('+24 hours'))->format('Y-m-d H:i:s');

                $stmt = $this->db->getPdo()->prepare(
                    'DELETE FROM password_reset_token_users WHERE user_id = ?'
                );
                $stmt->execute([$newAdminUserId]);

                $stmt = $this->db->getPdo()->prepare(
                    'INSERT INTO password_reset_token_users (user_id, token_hash, expires_at) VALUES (?, ?, ?)'
                );
                $stmt->execute([$newAdminUserId, $tokenHash, $expiresAt]);
            }

            $this->db->commit();

            // Send welcome email to new admin
            if ($isNewUser && $resetToken !== null) {
                $this->sendWelcomeEmail($newAdminEmail, $business['name'], $business['slug'], $resetToken);
            }

            return [
                'user_id' => $newAdminUserId,
                'is_new_user' => $isNewUser,
            ];
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    /**
     * Send welcome email to new admin.
     */
    private function sendWelcomeEmail(string $adminEmail, string $businessName, string $businessSlug, string $resetToken): void
    {
        try {
            $template = EmailTemplateRenderer::businessAdminWelcome();
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

            $emailService = EmailService::create();
            $emailService->send($adminEmail, $subject, $htmlBody);

            error_log("[UpdateBusiness] Welcome email sent to {$adminEmail} for business {$businessName}");
        } catch (\Throwable $e) {
            error_log("[UpdateBusiness] Failed to send welcome email: " . $e->getMessage());
        }
    }
}
