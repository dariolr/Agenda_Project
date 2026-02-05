<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

/**
 * Interface for email providers.
 * Allows switching between different email services (SMTP, Brevo, Mailgun, etc.)
 */
interface EmailProviderInterface
{
    /**
     * Send a single email.
     *
     * @param string $to Recipient email address
     * @param string $subject Email subject
     * @param string $htmlBody HTML content
     * @param string|null $textBody Plain text fallback (optional)
     * @param array<int, array{filename: string, content: string, content_type?: string, encoding?: string}>|null $attachments
     *        Attachments with base64 content and metadata (optional)
     * @param string|null $fromEmail Override sender email (optional)
     * @param string|null $fromName Override sender name (optional)
     * @param string|null $replyTo Reply-to address (optional)
     * @return bool True if sent successfully
     */
    public function send(
        string $to,
        string $subject,
        string $htmlBody,
        ?string $textBody = null,
        ?array $attachments = null,
        ?string $fromEmail = null,
        ?string $fromName = null,
        ?string $replyTo = null,
    ): bool;

    /**
     * Send multiple emails in batch (if supported).
     *
     * @param array<array{to: string, subject: string, htmlBody: string, textBody?: string}> $messages
     * @return array<string, bool> Map of recipient => success
     */
    public function sendBatch(array $messages): array;

    /**
     * Get the provider name for logging.
     */
    public function getName(): string;
}
