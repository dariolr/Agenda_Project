<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

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

    /**
     * Create an email provider based on environment configuration.
     */
    public static function create(): EmailProviderInterface
    {
        if (self::$instance !== null) {
            return self::$instance;
        }

        $provider = $_ENV['MAIL_PROVIDER'] ?? 'smtp';

        self::$instance = match ($provider) {
            'brevo' => self::createBrevo(),
            'mailgun' => self::createMailgun(),
            default => self::createSmtp(),
        };

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

    private static function createBrevo(): BrevoProvider
    {
        return new BrevoProvider(
            apiKey: $_ENV['BREVO_API_KEY'] ?? throw new \RuntimeException('BREVO_API_KEY not configured'),
            smtpPassword: $_ENV['BREVO_SMTP_PASSWORD'] ?? $_ENV['BREVO_API_KEY'],
            defaultFromEmail: $_ENV['MAIL_FROM_ADDRESS'] ?? throw new \RuntimeException('MAIL_FROM_ADDRESS not configured'),
            defaultFromName: $_ENV['MAIL_FROM_NAME'] ?? 'Agenda',
        );
    }

    private static function createMailgun(): MailgunProvider
    {
        return new MailgunProvider(
            apiKey: $_ENV['MAILGUN_API_KEY'] ?? throw new \RuntimeException('MAILGUN_API_KEY not configured'),
            domain: $_ENV['MAILGUN_DOMAIN'] ?? throw new \RuntimeException('MAILGUN_DOMAIN not configured'),
            defaultFromEmail: $_ENV['MAIL_FROM_ADDRESS'] ?? throw new \RuntimeException('MAIL_FROM_ADDRESS not configured'),
            defaultFromName: $_ENV['MAIL_FROM_NAME'] ?? 'Agenda',
            useEuRegion: ($_ENV['MAILGUN_REGION'] ?? 'eu') === 'eu',
        );
    }

    private static function createSmtp(): SmtpProvider
    {
        return new SmtpProvider(
            host: $_ENV['SMTP_HOST'] ?? $_ENV['MAIL_HOST'] ?? 'localhost',
            port: (int) ($_ENV['SMTP_PORT'] ?? $_ENV['MAIL_PORT'] ?? 587),
            username: $_ENV['SMTP_USER'] ?? $_ENV['MAIL_USERNAME'] ?? '',
            password: $_ENV['SMTP_PASS'] ?? $_ENV['MAIL_PASSWORD'] ?? '',
            encryption: $_ENV['SMTP_ENCRYPTION'] ?? $_ENV['MAIL_ENCRYPTION'] ?? 'tls',
            defaultFromEmail: $_ENV['MAIL_FROM_ADDRESS'] ?? $_ENV['SMTP_USER'] ?? '',
            defaultFromName: $_ENV['MAIL_FROM_NAME'] ?? 'Agenda',
        );
    }
}
