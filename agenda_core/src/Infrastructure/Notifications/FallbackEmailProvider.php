<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

final class FallbackEmailProvider implements EmailProviderInterface
{
    private ?string $lastError = null;
    private ?string $lastUsedProvider = null;

    public function __construct(
        private readonly EmailProviderInterface $primary,
        private readonly EmailProviderInterface $fallback,
    ) {}

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
        $this->lastError = null;
        $this->lastUsedProvider = null;

        $primarySent = $this->primary->send(
            $to,
            $subject,
            $htmlBody,
            $textBody,
            $attachments,
            $fromEmail,
            $fromName,
            $replyTo,
        );
        if ($primarySent) {
            $this->lastUsedProvider = $this->primary->getName();
            return true;
        }

        $primaryError = $this->primary->getLastError();
        if (!$this->shouldFallback($primaryError)) {
            $this->lastError = $primaryError;
            return false;
        }

        error_log(sprintf(
            '[EmailFallback] Primary provider %s failed with transient error. Retrying via %s',
            $this->primary->getName(),
            $this->fallback->getName(),
        ));

        $fallbackSent = $this->fallback->send(
            $to,
            $subject,
            $htmlBody,
            $textBody,
            $attachments,
            $fromEmail,
            $fromName,
            $replyTo,
        );
        if ($fallbackSent) {
            $this->lastUsedProvider = $this->fallback->getName();
            return true;
        }

        $fallbackError = $this->fallback->getLastError();
        $this->lastError = trim(implode(' | ', array_filter([
            'primary=' . ($primaryError ?? 'unknown error'),
            'fallback=' . ($fallbackError ?? 'unknown error'),
        ])));
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
        return $this->primary->getName() . '->' . $this->fallback->getName();
    }

    public function getLastError(): ?string
    {
        return $this->lastError;
    }

    public function getLastUsedProvider(): ?string
    {
        return $this->lastUsedProvider;
    }

    private function shouldFallback(?string $error): bool
    {
        if ($error === null || trim($error) === '') {
            return false;
        }

        $normalized = strtolower($error);
        $transientPatterns = [
            'already sent',
            'restored in 1 hour',
            'rate limit',
            'too many',
            'temporar',
            'try again later',
            'timeout',
            'connection reset',
            'service unavailable',
        ];

        foreach ($transientPatterns as $pattern) {
            if (str_contains($normalized, $pattern)) {
                return true;
            }
        }

        return false;
    }
}
