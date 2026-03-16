<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use Agenda\Infrastructure\Environment\EnvironmentPolicy;
use Agenda\Infrastructure\Notifications\FallbackEmailProvider;
use Agenda\Infrastructure\Notifications\Providers\BrevoProvider;
use Agenda\Infrastructure\Notifications\Providers\MailgunProvider;
use Agenda\Infrastructure\Notifications\Providers\SmtpProvider;

/**
 * Email service factory.
 * Creates the appropriate email provider based on configuration.
 * 
 * Usage:
 *   $emailService = EmailService::create();
 *   $emailService->send($to, $subject, $htmlBody);
 * 
 * Configuration via .env:
 *   MAIL_PROVIDER=brevo|mailgun|smtp
 */
final class EmailService
{
    private static ?EmailProviderInterface $instance = null;
    private const TRUE_VALUES = ['1', 'true', 'yes', 'on'];

    /**
     * Create an email provider based on environment configuration.
     */
    public static function create(): EmailProviderInterface
    {
        if (self::$instance !== null) {
            return self::$instance;
        }

        $policy = EnvironmentPolicy::current();
        if (!$policy->canSendRealEmails()) {
            self::$instance = new class implements EmailProviderInterface {
                private ?string $lastError = 'demo_blocked: real email sending disabled by environment policy';

                public function send(
                    string $to,
                    string $subject,
                    string $htmlBody,
                    ?string $textBody = null,
                    ?array $attachments = null,
                    ?string $fromEmail = null,
                    ?string $fromName = null,
                    ?string $replyTo = null,
                ): bool {
                    error_log('[EmailService] demo_blocked: prevented real email send');
                    return false;
                }

                public function sendBatch(array $messages): array
                {
                    error_log('[EmailService] demo_blocked: prevented real batch email send');
                    $results = [];
                    foreach ($messages as $message) {
                        $recipient = (string) ($message['to'] ?? '');
                        if ($recipient !== '') {
                            $results[$recipient] = false;
                        }
                    }
                    return $results;
                }

                public function getName(): string
                {
                    return 'blocked-demo-provider';
                }

                public function getLastError(): ?string
                {
                    return $this->lastError;
                }
            };
            return self::$instance;
        }

        // Security default: force authenticated SMTP from app code only.
        $smtpOnly = self::isEnabled($_ENV['EMAIL_SMTP_ONLY'] ?? 'true');
        if ($smtpOnly) {
            self::$instance = self::createSmtp();
            return self::$instance;
        }

        error_log('[EmailService] WARNING: EMAIL_SMTP_ONLY is disabled. Non-SMTP providers/fallback may be used.');

        $primary = self::createProvider($_ENV['MAIL_PROVIDER'] ?? 'smtp');
        $fallbackProvider = trim((string) ($_ENV['MAIL_FALLBACK_PROVIDER'] ?? ''));

        self::$instance = $fallbackProvider !== ''
            ? new FallbackEmailProvider($primary, self::createProvider($fallbackProvider, 'GEKO_'))
            : $primary;

        return self::$instance;
    }

    /**
     * Reset instance (useful for testing).
     */
    public static function reset(): void
    {
        self::$instance = null;
    }

    /**
     * Set a specific provider instance (useful for testing).
     */
    public static function setInstance(EmailProviderInterface $provider): void
    {
        self::$instance = $provider;
    }

    private static function createProvider(string $provider, string $envPrefix = ''): EmailProviderInterface
    {
        return match ($provider) {
            'brevo' => self::createBrevo($envPrefix),
            'mailgun' => self::createMailgun($envPrefix),
            'geko', 'smtp' => self::createSmtp($envPrefix),
            default => self::createSmtp($envPrefix),
        };
    }

    private static function createBrevo(string $envPrefix = ''): BrevoProvider
    {
        return new BrevoProvider(
            apiKey: $_ENV[$envPrefix . 'BREVO_API_KEY'] ?? $_ENV['BREVO_API_KEY'] ?? throw new \RuntimeException($envPrefix . 'BREVO_API_KEY not configured'),
            smtpPassword: $_ENV[$envPrefix . 'BREVO_SMTP_PASSWORD'] ?? $_ENV[$envPrefix . 'BREVO_API_KEY'] ?? $_ENV['BREVO_SMTP_PASSWORD'] ?? $_ENV['BREVO_API_KEY'],
            defaultFromEmail: $_ENV[$envPrefix . 'MAIL_FROM_ADDRESS'] ?? $_ENV['MAIL_FROM_ADDRESS'] ?? throw new \RuntimeException($envPrefix . 'MAIL_FROM_ADDRESS not configured'),
            defaultFromName: $_ENV[$envPrefix . 'MAIL_FROM_NAME'] ?? $_ENV['MAIL_FROM_NAME'] ?? 'Agenda',
        );
    }

    private static function createMailgun(string $envPrefix = ''): MailgunProvider
    {
        return new MailgunProvider(
            apiKey: $_ENV[$envPrefix . 'MAILGUN_API_KEY'] ?? $_ENV['MAILGUN_API_KEY'] ?? throw new \RuntimeException($envPrefix . 'MAILGUN_API_KEY not configured'),
            domain: $_ENV[$envPrefix . 'MAILGUN_DOMAIN'] ?? $_ENV['MAILGUN_DOMAIN'] ?? throw new \RuntimeException($envPrefix . 'MAILGUN_DOMAIN not configured'),
            defaultFromEmail: $_ENV[$envPrefix . 'MAIL_FROM_ADDRESS'] ?? $_ENV['MAIL_FROM_ADDRESS'] ?? throw new \RuntimeException($envPrefix . 'MAIL_FROM_ADDRESS not configured'),
            defaultFromName: $_ENV[$envPrefix . 'MAIL_FROM_NAME'] ?? $_ENV['MAIL_FROM_NAME'] ?? 'Agenda',
            useEuRegion: (($_ENV[$envPrefix . 'MAILGUN_REGION'] ?? $_ENV['MAILGUN_REGION'] ?? 'eu')) === 'eu',
        );
    }

    private static function createSmtp(string $envPrefix = ''): SmtpProvider
    {
        $username = $_ENV[$envPrefix . 'SMTP_USERNAME']
            ?? $_ENV[$envPrefix . 'SMTP_USER']
            ?? $_ENV[$envPrefix . 'MAIL_USERNAME']
            ?? $_ENV['SMTP_USERNAME']
            ?? $_ENV['SMTP_USER']
            ?? $_ENV['MAIL_USERNAME']
            ?? '';
        $password = $_ENV[$envPrefix . 'SMTP_PASSWORD']
            ?? $_ENV[$envPrefix . 'SMTP_PASS']
            ?? $_ENV[$envPrefix . 'MAIL_PASSWORD']
            ?? $_ENV['SMTP_PASSWORD']
            ?? $_ENV['SMTP_PASS']
            ?? $_ENV['MAIL_PASSWORD']
            ?? '';

        if (trim((string) $username) === '' || trim((string) $password) === '') {
            throw new \RuntimeException('SMTP credentials not configured');
        }

        return new SmtpProvider(
            host: $_ENV[$envPrefix . 'SMTP_HOST'] ?? $_ENV[$envPrefix . 'MAIL_HOST'] ?? $_ENV['SMTP_HOST'] ?? $_ENV['MAIL_HOST'] ?? 'localhost',
            port: (int) ($_ENV[$envPrefix . 'SMTP_PORT'] ?? $_ENV[$envPrefix . 'MAIL_PORT'] ?? $_ENV['SMTP_PORT'] ?? $_ENV['MAIL_PORT'] ?? 587),
            username: $username,
            password: $password,
            encryption: $_ENV[$envPrefix . 'SMTP_ENCRYPTION'] ?? $_ENV[$envPrefix . 'MAIL_ENCRYPTION'] ?? $_ENV['SMTP_ENCRYPTION'] ?? $_ENV['MAIL_ENCRYPTION'] ?? 'tls',
            defaultFromEmail: $_ENV[$envPrefix . 'MAIL_FROM_ADDRESS'] ?? $_ENV['MAIL_FROM_ADDRESS'] ?? $_ENV[$envPrefix . 'SMTP_USERNAME'] ?? $_ENV[$envPrefix . 'SMTP_USER'] ?? $_ENV['SMTP_USERNAME'] ?? $_ENV['SMTP_USER'] ?? '',
            defaultFromName: $_ENV[$envPrefix . 'MAIL_FROM_NAME'] ?? $_ENV['MAIL_FROM_NAME'] ?? 'Agenda',
        );
    }

    private static function isEnabled(string $value): bool
    {
        return in_array(strtolower(trim($value)), self::TRUE_VALUES, true);
    }
}
