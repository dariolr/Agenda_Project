<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Whatsapp;

final class MetaWhatsAppEmbeddedSignupService
{
    private readonly string $graphVersion;
    private readonly string $appId;
    private readonly string $appSecret;
    private readonly ?string $redirectUri;

    public function __construct()
    {
        $this->graphVersion = trim((string) ($_ENV['META_GRAPH_VERSION'] ?? getenv('META_GRAPH_VERSION') ?? 'v22.0'));
        $this->appId = trim((string) ($_ENV['META_APP_ID'] ?? getenv('META_APP_ID') ?? ''));
        $this->appSecret = trim((string) ($_ENV['META_APP_SECRET'] ?? getenv('META_APP_SECRET') ?? ''));
        $redirect = trim((string) ($_ENV['META_EMBEDDED_SIGNUP_REDIRECT_URI'] ?? getenv('META_EMBEDDED_SIGNUP_REDIRECT_URI') ?? ''));
        $this->redirectUri = $redirect !== '' ? $redirect : null;
    }

    /**
     * @return array{access_token:string,waba_id:string,phone_number_id:string,display_phone_number:?string}
     */
    public function completeSignup(
        string $code,
        ?string $preferredWabaId,
        ?string $preferredPhoneNumberId,
        ?string $preferredDisplayPhone
    ): array {
        $accessToken = $this->exchangeCodeForAccessToken($code);
        $assets = $this->resolveAssets($accessToken, $preferredWabaId, $preferredPhoneNumberId, $preferredDisplayPhone);

        return [
            'access_token' => $accessToken,
            'waba_id' => $assets['waba_id'],
            'phone_number_id' => $assets['phone_number_id'],
            'display_phone_number' => $assets['display_phone_number'],
        ];
    }

    private function exchangeCodeForAccessToken(string $code): string
    {
        if ($this->appId === '' || $this->appSecret === '') {
            throw new \RuntimeException('meta_app_not_configured');
        }

        $query = [
            'client_id' => $this->appId,
            'client_secret' => $this->appSecret,
            'code' => $code,
        ];
        if ($this->redirectUri !== null) {
            $query['redirect_uri'] = $this->redirectUri;
        }

        $url = 'https://graph.facebook.com/' . $this->graphVersion . '/oauth/access_token?' . http_build_query($query);
        $result = $this->curlJsonRequest('GET', $url, null);

        $token = trim((string) ($result['access_token'] ?? ''));
        if ($token === '') {
            throw new \RuntimeException('meta_token_not_obtained');
        }

        return $token;
    }

    /**
     * @return array{waba_id:string,phone_number_id:string,display_phone_number:?string}
     */
    private function resolveAssets(
        string $accessToken,
        ?string $preferredWabaId,
        ?string $preferredPhoneNumberId,
        ?string $preferredDisplayPhone
    ): array {
        $url = 'https://graph.facebook.com/' . $this->graphVersion
            . '/me/whatsapp_business_accounts?fields=id,phone_numbers{id,display_phone_number,verified_name}';
        $accounts = $this->curlJsonRequest('GET', $url, $accessToken);
        $items = $accounts['data'] ?? [];

        $resolvedWabaId = '';
        $resolvedPhoneId = '';
        $resolvedDisplay = null;

        if (is_array($items)) {
            foreach ($items as $account) {
                if (!is_array($account)) {
                    continue;
                }
                $wabaId = trim((string) ($account['id'] ?? ''));
                if ($preferredWabaId !== null && $preferredWabaId !== '' && $wabaId !== $preferredWabaId) {
                    continue;
                }

                $phones = $account['phone_numbers']['data'] ?? $account['phone_numbers'] ?? [];
                if (!is_array($phones)) {
                    continue;
                }

                foreach ($phones as $phone) {
                    if (!is_array($phone)) {
                        continue;
                    }
                    $phoneId = trim((string) ($phone['id'] ?? ''));
                    if ($phoneId === '') {
                        continue;
                    }
                    if ($preferredPhoneNumberId !== null && $preferredPhoneNumberId !== '' && $phoneId !== $preferredPhoneNumberId) {
                        continue;
                    }

                    $resolvedWabaId = $wabaId;
                    $resolvedPhoneId = $phoneId;
                    $resolvedDisplay = isset($phone['display_phone_number'])
                        ? (string) $phone['display_phone_number']
                        : $preferredDisplayPhone;
                    break 2;
                }
            }
        }

        if ($resolvedWabaId === '' && $preferredWabaId !== null && $preferredWabaId !== '') {
            $resolvedWabaId = $preferredWabaId;
        }
        if ($resolvedPhoneId === '' && $preferredPhoneNumberId !== null && $preferredPhoneNumberId !== '') {
            $resolvedPhoneId = $preferredPhoneNumberId;
        }
        if ($resolvedDisplay === null) {
            $resolvedDisplay = $preferredDisplayPhone;
        }

        if ($resolvedWabaId === '' || $resolvedPhoneId === '') {
            throw new \RuntimeException('meta_phone_or_waba_not_accessible');
        }

        return [
            'waba_id' => $resolvedWabaId,
            'phone_number_id' => $resolvedPhoneId,
            'display_phone_number' => $resolvedDisplay,
        ];
    }

    /**
     * @return array<string,mixed>
     */
    private function curlJsonRequest(string $method, string $url, ?string $bearerToken): array
    {
        $ch = curl_init($url);
        if ($ch === false) {
            throw new \RuntimeException('meta_http_init_failed');
        }

        $headers = ['Accept: application/json'];
        if ($bearerToken !== null && $bearerToken !== '') {
            $headers[] = 'Authorization: Bearer ' . $bearerToken;
        }

        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_TIMEOUT => 20,
        ]);

        $raw = curl_exec($ch);
        $curlError = curl_error($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if (!is_string($raw)) {
            throw new \RuntimeException('meta_http_no_response');
        }

        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            throw new \RuntimeException('meta_invalid_json_response');
        }

        if ($curlError !== '') {
            throw new \RuntimeException('meta_http_error');
        }

        if ($status >= 400) {
            $code = $decoded['error']['code'] ?? null;
            $subcode = $decoded['error']['error_subcode'] ?? null;
            $type = $decoded['error']['type'] ?? 'meta_error';
            $message = $decoded['error']['message'] ?? 'meta_request_failed';
            throw new \RuntimeException($type . ':' . (string) $code . ':' . (string) $subcode . ':' . (string) $message);
        }

        return $decoded;
    }
}
