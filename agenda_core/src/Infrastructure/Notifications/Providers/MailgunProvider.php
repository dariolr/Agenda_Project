<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications\Providers;

use Agenda\Infrastructure\Notifications\EmailProviderInterface;

/**
 * Mailgun email provider.
 * Uses Mailgun's REST API.
 * 
 * Free tier: 100 emails/day for first 3 months
 * 
 * @see https://www.mailgun.com/
 */
final class MailgunProvider implements EmailProviderInterface
{
    private const API_BASE_US = 'https://api.mailgun.net/v3';
    private const API_BASE_EU = 'https://api.eu.mailgun.net/v3';

    private string $apiKey;
    private string $domain;
    private string $apiBase;
    private string $defaultFromEmail;
    private string $defaultFromName;

    public function __construct(
        string $apiKey,
        string $domain,
        string $defaultFromEmail,
        string $defaultFromName = 'Agenda',
        bool $useEuRegion = true,
    ) {
        $this->apiKey = $apiKey;
        $this->domain = $domain;
        $this->defaultFromEmail = $defaultFromEmail;
        $this->defaultFromName = $defaultFromName;
        $this->apiBase = $useEuRegion ? self::API_BASE_EU : self::API_BASE_US;
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

        $data = [
            'from' => "{$name} <{$from}>",
            'to' => $to,
            'subject' => $subject,
            'html' => $htmlBody,
            'h:Reply-To' => $replyTo,
        ];

        if ($textBody) {
            $data['text'] = $textBody;
        }

        $tmpFiles = [];
        $postFields = $data;
        if (!empty($attachments)) {
            foreach ($attachments as $index => $attachment) {
                $filename = $attachment['filename'] ?? 'attachment';
                $contentType = $attachment['content_type'] ?? 'application/octet-stream';
                $encoding = $attachment['encoding'] ?? 'base64';
                $content = $attachment['content'] ?? '';

                if ($encoding === 'base64') {
                    $content = base64_decode((string) $content);
                }

                $tmpPath = tempnam(sys_get_temp_dir(), 'mg-');
                if ($tmpPath === false) {
                    continue;
                }
                file_put_contents($tmpPath, (string) $content);
                $tmpFiles[] = $tmpPath;

                $postFields["attachment[{$index}]"] = new \CURLFile($tmpPath, $contentType, $filename);
            }
        }

        $ch = curl_init("{$this->apiBase}/{$this->domain}/messages");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => !empty($attachments) ? $postFields : http_build_query($data),
            CURLOPT_USERPWD => 'api:' . $this->apiKey,
            CURLOPT_TIMEOUT => 30,
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        foreach ($tmpFiles as $tmpPath) {
            @unlink($tmpPath);
        }

        if ($error) {
            error_log("Mailgun API Error: {$error}");
            return false;
        }

        if ($httpCode >= 200 && $httpCode < 300) {
            return true;
        }

        error_log("Mailgun API Error ({$httpCode}): {$response}");
        return false;
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
        }
        return $results;
    }

    public function getName(): string
    {
        return 'mailgun';
    }
}
