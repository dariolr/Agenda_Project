<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications\Providers;

use Agenda\Infrastructure\Notifications\EmailProviderInterface;

/**
 * Brevo (ex Sendinblue) email provider.
 * Uses Brevo's SMTP relay for simplicity.
 * 
 * Free tier: 300 emails/day
 * 
 * @see https://www.brevo.com/
 */
final class BrevoProvider implements EmailProviderInterface
{
    private const SMTP_HOST = 'smtp-relay.brevo.com';
    private const SMTP_PORT = 587;

    private string $apiKey;
    private string $smtpPassword;
    private string $defaultFromEmail;
    private string $defaultFromName;

    public function __construct(
        string $apiKey,
        string $smtpPassword,
        string $defaultFromEmail,
        string $defaultFromName = 'Agenda',
    ) {
        $this->apiKey = $apiKey;
        $this->smtpPassword = $smtpPassword;
        $this->defaultFromEmail = $defaultFromEmail;
        $this->defaultFromName = $defaultFromName;
    }

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
        $from = $fromEmail ?? $this->defaultFromEmail;
        $name = $fromName ?? $this->defaultFromName;
        $replyTo = $replyTo ?? $from;

        // Check if we have an API key (starts with 'xkeysib-') or SMTP key (starts with 'xsmtpsib-')
        // SMTP keys should use SMTP transport, API keys should use API
        $isSmtpKey = str_starts_with($this->apiKey, 'xsmtpsib-');
        
        if (!$isSmtpKey && function_exists('curl_init')) {
            return $this->sendViaApi($to, $subject, $htmlBody, $textBody, $attachments, $from, $name, $replyTo);
        }

        // Use SMTP for SMTP keys or when curl is not available
        return $this->sendViaSmtp($to, $subject, $htmlBody, $textBody, $attachments, $from, $name, $replyTo);
    }

    private function sendViaApi(
        string $to,
        string $subject,
        string $htmlBody,
        ?string $textBody,
        ?array $attachments,
        string $from,
        string $name,
        string $replyTo,
    ): bool {
        $data = [
            'sender' => [
                'name' => $name,
                'email' => $from,
            ],
            'to' => [
                ['email' => $to],
            ],
            'replyTo' => ['email' => $replyTo],
            'subject' => $subject,
            'htmlContent' => $htmlBody,
        ];

        if ($textBody) {
            $data['textContent'] = $textBody;
        }
        if (!empty($attachments)) {
            $data['attachment'] = [];
            foreach ($attachments as $attachment) {
                $data['attachment'][] = [
                    'content' => $attachment['content'] ?? '',
                    'name' => $attachment['filename'] ?? 'attachment',
                ];
            }
        }

        $ch = curl_init('https://api.brevo.com/v3/smtp/email');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($data),
            CURLOPT_HTTPHEADER => [
                'Accept: application/json',
                'Content-Type: application/json',
                'api-key: ' . $this->apiKey,
            ],
            CURLOPT_TIMEOUT => 30,
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($error) {
            error_log("[Brevo] curl error: {$error} (to: {$to})");
            return false;
        }

        if ($httpCode >= 200 && $httpCode < 300) {
            return true;
        }

        error_log("[Brevo] HTTP {$httpCode}: {$response} (to: {$to})");
        return false;
    }

    private function sendViaSmtp(
        string $to,
        string $subject,
        string $htmlBody,
        ?string $textBody,
        ?array $attachments,
        string $from,
        string $name,
        string $replyTo,
    ): bool {
        // Fallback to SMTP provider
        $smtp = new SmtpProvider(
            self::SMTP_HOST,
            self::SMTP_PORT,
            $this->defaultFromEmail,
            $this->smtpPassword,
            'tls',
            $from,
            $name,
        );

        return $smtp->send($to, $subject, $htmlBody, $textBody, $attachments, $from, $name, $replyTo);
    }

    public function sendBatch(array $messages): array
    {
        $results = [];
        foreach ($messages as $message) {
            $results[$message['to']] = $this->send(
                $message['to'],
                $message['subject'],
                $message['htmlBody'],
                $message['textBody'] ?? null,
                $message['attachments'] ?? null,
            );
            // Rate limiting: Brevo free has 300/day limit
            usleep(100000); // 100ms between emails
        }
        return $results;
    }

    public function getName(): string
    {
        return 'brevo';
    }
}
