<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Whatsapp;

use Agenda\Infrastructure\Security\TokenCipher;

final class MetaWhatsAppCloudApiClient
{
    public function __construct(private readonly TokenCipher $tokenCipher) {}

    /**
     * @param array<string,mixed> $config
     * @param array<string,mixed> $variables
     * @return array{success:bool,provider_message_id:?string,error_code:?string,error_message:?string,raw_response_sanitized:array<string,mixed>}
     */
    public function sendTemplateMessage(
        array $config,
        string $recipientPhoneE164,
        string $templateName,
        string $languageCode,
        array $variables
    ): array {
        $phoneNumberId = trim((string) ($config['phone_number_id'] ?? ''));
        $encryptedToken = trim((string) ($config['access_token_encrypted'] ?? ''));
        if ($phoneNumberId === '' || $encryptedToken === '') {
            return $this->error('whatsapp_provider_not_configured', 'Missing phone number id or token');
        }

        $token = $this->tokenCipher->decrypt($encryptedToken);
        $graphVersion = trim((string) ($_ENV['META_GRAPH_VERSION'] ?? getenv('META_GRAPH_VERSION') ?? 'v22.0'));
        $url = 'https://graph.facebook.com/' . $graphVersion . '/' . rawurlencode($phoneNumberId) . '/messages';
        $payload = [
            'messaging_product' => 'whatsapp',
            'to' => $recipientPhoneE164,
            'type' => 'template',
            'template' => [
                'name' => $templateName,
                'language' => ['code' => $languageCode],
                'components' => $this->buildTemplateComponents($variables),
            ],
        ];

        $ch = curl_init($url);
        if ($ch === false) {
            return $this->error('meta_http_init_failed', 'Unable to initialize Meta request');
        }
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => [
                'Accept: application/json',
                'Content-Type: application/json',
                'Authorization: Bearer ' . $token,
            ],
            CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            CURLOPT_TIMEOUT => 20,
        ]);

        $raw = curl_exec($ch);
        $curlError = curl_error($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $decoded = is_string($raw) ? json_decode($raw, true) : null;
        $response = is_array($decoded) ? $decoded : [];
        if ($curlError !== '' || $status >= 400) {
            $error = is_array($response['error'] ?? null) ? $response['error'] : [];
            return [
                'success' => false,
                'provider_message_id' => null,
                'error_code' => (string) ($error['code'] ?? ($curlError !== '' ? 'meta_http_error' : 'meta_request_failed')),
                'error_message' => mb_substr((string) ($error['message'] ?? $curlError ?: 'Meta request failed'), 0, 500),
                'raw_response_sanitized' => $this->sanitizeResponse($response),
            ];
        }

        $messageId = null;
        if (isset($response['messages'][0]['id']) && is_scalar($response['messages'][0]['id'])) {
            $messageId = (string) $response['messages'][0]['id'];
        }

        return [
            'success' => true,
            'provider_message_id' => $messageId,
            'error_code' => null,
            'error_message' => null,
            'raw_response_sanitized' => $this->sanitizeResponse($response),
        ];
    }

    /**
     * @param array<string,mixed> $variables
     * @return list<array<string,mixed>>
     */
    private function buildTemplateComponents(array $variables): array
    {
        if ($variables === []) {
            return [];
        }

        $components = [];
        $bodyVariables = $variables['__body'] ?? $variables;
        unset($bodyVariables['__body'], $bodyVariables['__button_url']);

        if (is_array($bodyVariables) && $bodyVariables !== []) {
            $components[] = [
                'type' => 'body',
                'parameters' => array_map(
                    static fn (mixed $value): array => ['type' => 'text', 'text' => (string) $value],
                    array_values($bodyVariables)
                ),
            ];
        }

        $buttonUrl = trim((string) ($variables['__button_url'] ?? ''));
        if ($buttonUrl !== '') {
            $components[] = [
                'type' => 'button',
                'sub_type' => 'url',
                'index' => '0',
                'parameters' => [
                    ['type' => 'text', 'text' => $buttonUrl],
                ],
            ];
        }

        return $components;
    }

    /**
     * @param array<string,mixed> $response
     * @return array<string,mixed>
     */
    private function sanitizeResponse(array $response): array
    {
        unset($response['access_token'], $response['token']);
        return $response;
    }

    /**
     * @return array{success:bool,provider_message_id:?string,error_code:?string,error_message:?string,raw_response_sanitized:array<string,mixed>}
     */
    private function error(string $code, string $message): array
    {
        return [
            'success' => false,
            'provider_message_id' => null,
            'error_code' => $code,
            'error_message' => $message,
            'raw_response_sanitized' => [],
        ];
    }
}
