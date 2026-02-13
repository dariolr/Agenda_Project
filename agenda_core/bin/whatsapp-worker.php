#!/usr/bin/env php
<?php

declare(strict_types=1);

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\WhatsAppRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Security\EncryptionService;

require_once __DIR__ . '/../vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->safeLoad();

date_default_timezone_set($_ENV['APP_TIMEZONE'] ?? 'UTC');

$db = new Connection();
$repo = new WhatsAppRepository($db);
$clientRepo = new ClientRepository($db);
$encryption = new EncryptionService();

$limit = (int) ($_ENV['WHATSAPP_WORKER_BATCH_SIZE'] ?? 50);
$perMinuteCap = (int) ($_ENV['WHATSAPP_RATE_LIMIT_PER_MINUTE'] ?? 60);
$dailyCap = (int) ($_ENV['WHATSAPP_DAILY_CAP'] ?? 1000);
$apiVersion = $_ENV['WHATSAPP_API_VERSION'] ?? 'v22.0';

$outboxItems = $repo->getDispatchableOutbox($limit);
if ($outboxItems === []) {
    echo '[' . date('Y-m-d H:i:s') . "] No queued WhatsApp notifications.\n";
    exit(0);
}

foreach ($outboxItems as $item) {
    $businessId = (int) $item['business_id'];

    $minuteCount = $repo->countRecentBusinessSends($businessId, 1);
    $dailyCount = $repo->countBusinessDailySends($businessId);
    if ($minuteCount >= $perMinuteCap || $dailyCount >= $dailyCap) {
        $repo->markFailedWithRetry((string) $item['id'], 'rate_limited');
        continue;
    }

    $config = $repo->getConfig($businessId);
    if ($config === null || $config['status'] !== 'active') {
        $repo->markFailedWithRetry((string) $item['id'], 'business_not_connected');
        continue;
    }

    if (!$repo->hasApprovedTemplate($businessId, (string) $item['template_name'])) {
        $repo->markFailedWithRetry((string) $item['id'], 'template_rejected');
        continue;
    }

    $customerId = (int) $item['customer_id'];
    if (!$repo->hasValidConsent($businessId, $customerId)) {
        $repo->markFailedWithRetry((string) $item['id'], 'consent_missing');
        continue;
    }

    $client = $clientRepo->findById($customerId);
    $phone = $client['phone'] ?? null;
    if ($client === null || !is_string($phone) || trim($phone) === '') {
        $repo->markFailedWithRetry((string) $item['id'], 'invalid_phone');
        continue;
    }

    $token = $encryption->decrypt((string) $config['access_token_encrypted']);
    $payload = json_decode((string) $item['payload_json'], true) ?: [];

    $sendBody = [
        'messaging_product' => 'whatsapp',
        'to' => preg_replace('/[^0-9]/', '', $phone),
        'type' => 'template',
        'template' => [
            'name' => (string) $item['template_name'],
            'language' => ['code' => $payload['language_code'] ?? 'it'],
            'components' => $payload['components'] ?? [],
        ],
    ];

    $url = sprintf('https://graph.facebook.com/%s/%s/messages', $apiVersion, $config['phone_number_id']);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $token,
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS => json_encode($sendBody),
        CURLOPT_TIMEOUT => 20,
    ]);

    $response = curl_exec($ch);
    $httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr = curl_error($ch);
    curl_close($ch);

    if ($response === false || $curlErr !== '') {
        $repo->markFailedWithRetry((string) $item['id'], 'network_error');
        continue;
    }

    $decoded = json_decode((string) $response, true) ?: [];

    if ($httpCode >= 200 && $httpCode < 300) {
        $providerMessageId = (string) ($decoded['messages'][0]['id'] ?? '');
        if ($providerMessageId === '') {
            $providerMessageId = 'unknown';
        }

        $repo->markSent((string) $item['id'], $providerMessageId);
        $repo->logMessage($businessId, $customerId, 'outbound', 'template', json_encode($sendBody), $providerMessageId, 'sent');
        continue;
    }

    $errorCode = 'provider_error';
    $providerError = strtolower((string) ($decoded['error']['message'] ?? ''));
    if (str_contains($providerError, 'phone')) {
        $errorCode = 'invalid_phone';
    } elseif (str_contains($providerError, 'template')) {
        $errorCode = 'template_rejected';
    } elseif (str_contains($providerError, 'policy')) {
        $errorCode = 'policy_violation';
    }

    $repo->markFailedWithRetry((string) $item['id'], $errorCode);
}

echo '[' . date('Y-m-d H:i:s') . '] WhatsApp worker run complete.' . PHP_EOL;
