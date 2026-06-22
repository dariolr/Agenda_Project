<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Whatsapp;

final class MetaWhatsAppTemplateClient
{
    /**
     * @param array<int,string> $examples
     * @return array{success:bool,provider_template_id:?string,status:?string,error_code:?string,error_message:?string,raw_response_sanitized:array<string,mixed>}
     */
    public function submitTemplate(
        string $wabaId,
        string $templateName,
        string $languageCode,
        string $category,
        string $bodyText,
        array $examples
    ): array {
        $token = trim((string) ($_ENV['META_SYSTEM_USER_ACCESS_TOKEN'] ?? getenv('META_SYSTEM_USER_ACCESS_TOKEN') ?? ''));
        if ($token === '') {
            return $this->error('meta_system_user_token_missing', 'META_SYSTEM_USER_ACCESS_TOKEN non configurato');
        }

        $graphVersion = trim((string) (
            $_ENV['META_GRAPH_API_VERSION']
            ?? getenv('META_GRAPH_API_VERSION')
            ?: ($_ENV['META_GRAPH_VERSION'] ?? getenv('META_GRAPH_VERSION') ?: 'v22.0')
        ));
        $url = 'https://graph.facebook.com/' . $graphVersion . '/' . rawurlencode($wabaId) . '/message_templates';
        $bodyComponent = [
            'type' => 'BODY',
            'text' => $bodyText,
        ];
        if ($examples !== []) {
            $bodyComponent['example'] = [
                'body_text' => [array_values($examples)],
            ];
        }
        $payload = [
            'name' => $templateName,
            'language' => $languageCode,
            'category' => strtoupper($category),
            'components' => [$bodyComponent],
        ];

        $ch = curl_init($url);
        if ($ch === false) {
            return $this->error('meta_http_init_failed', 'Unable to initialize Meta template request');
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
                'provider_template_id' => null,
                'status' => null,
                'error_code' => (string) ($error['code'] ?? ($curlError !== '' ? 'meta_http_error' : 'meta_template_request_failed')),
                'error_message' => mb_substr((string) ($error['message'] ?? $curlError ?: 'Meta template request failed'), 0, 500),
                'raw_response_sanitized' => $this->sanitizeResponse($response),
            ];
        }

        return [
            'success' => true,
            'provider_template_id' => isset($response['id']) && is_scalar($response['id']) ? (string) $response['id'] : null,
            'status' => isset($response['status']) && is_scalar($response['status']) ? strtolower((string) $response['status']) : 'submitted',
            'error_code' => null,
            'error_message' => null,
            'raw_response_sanitized' => $this->sanitizeResponse($response),
        ];
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
     * @return array{success:bool,provider_template_id:?string,status:?string,error_code:?string,error_message:?string,raw_response_sanitized:array<string,mixed>}
     */
    private function error(string $code, string $message): array
    {
        return [
            'success' => false,
            'provider_template_id' => null,
            'status' => null,
            'error_code' => $code,
            'error_message' => $message,
            'raw_response_sanitized' => [],
        ];
    }
}
