<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Notifications\WhatsAppRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Security\EncryptionService;

final class WhatsAppController
{
    public function __construct(
        private readonly WhatsAppRepository $whatsAppRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly ClientRepository $clientRepo,
        private readonly EncryptionService $encryption,
    ) {
    }

    private function canAccessBusiness(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    public function getConfig(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->canAccessBusiness($request, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $config = $this->whatsAppRepo->getConfig($businessId);
        if ($config === null) {
            return Response::success(['connected' => false]);
        }

        return Response::success([
            'connected' => true,
            'config' => [
                'business_id' => (int) $config['business_id'],
                'waba_id' => $config['waba_id'],
                'phone_number_id' => $config['phone_number_id'],
                'token_expires_at' => $config['token_expires_at'],
                'status' => $config['status'],
                'quality_rating' => $config['quality_rating'],
                'connected_at' => $config['connected_at'],
                'created_at' => $config['created_at'],
                'updated_at' => $config['updated_at'],
            ],
        ]);
    }

    public function upsertConfig(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->canAccessBusiness($request, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $wabaId = trim((string) ($body['waba_id'] ?? ''));
        $phoneNumberId = trim((string) ($body['phone_number_id'] ?? ''));
        $accessToken = trim((string) ($body['access_token'] ?? ''));

        if ($wabaId === '' || $phoneNumberId === '' || $accessToken === '') {
            return Response::validationError('waba_id, phone_number_id and access_token are required', $request->traceId);
        }

        $encryptedToken = $this->encryption->encrypt($accessToken);
        $this->whatsAppRepo->upsertConfig(
            $businessId,
            $wabaId,
            $phoneNumberId,
            $encryptedToken,
            $body['token_expires_at'] ?? null,
            (string) ($body['status'] ?? 'active')
        );

        return Response::success(['saved' => true]);
    }

    public function listTemplates(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->canAccessBusiness($request, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        return Response::success(['data' => $this->whatsAppRepo->listTemplates($businessId)]);
    }

    public function upsertTemplate(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->canAccessBusiness($request, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $templateName = trim((string) ($body['template_name'] ?? ''));
        $category = (string) ($body['category'] ?? 'utility');
        $languageCode = (string) ($body['language_code'] ?? 'it');
        $status = (string) ($body['status'] ?? 'pending');

        if ($templateName === '') {
            return Response::validationError('template_name is required', $request->traceId);
        }

        $this->whatsAppRepo->upsertTemplate($businessId, $templateName, $category, $languageCode, $status);

        return Response::created(['saved' => true]);
    }

    public function saveConsent(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->canAccessBusiness($request, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $customerId = (int) ($body['customer_id'] ?? 0);
        $optIn = (bool) ($body['opt_in'] ?? false);
        $source = (string) ($body['source'] ?? 'web');
        $proofReference = isset($body['proof_reference']) ? (string) $body['proof_reference'] : null;

        if ($customerId <= 0) {
            return Response::validationError('customer_id is required', $request->traceId);
        }

        $customer = $this->clientRepo->findById($customerId);
        if ($customer === null || (int) $customer['business_id'] !== $businessId) {
            return Response::notFound('Customer not found', $request->traceId);
        }

        $this->whatsAppRepo->saveConsent($businessId, $customerId, $optIn, $source, $proofReference);

        return Response::created(['saved' => true]);
    }

    public function queueNotification(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->canAccessBusiness($request, $businessId)) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $customerId = (int) ($body['customer_id'] ?? 0);
        $eventType = trim((string) ($body['event_type'] ?? ''));
        $templateName = trim((string) ($body['template_name'] ?? ''));
        $payload = is_array($body['payload'] ?? null) ? $body['payload'] : [];

        if ($customerId <= 0 || $eventType === '' || $templateName === '') {
            return Response::validationError('customer_id, event_type and template_name are required', $request->traceId);
        }

        if (!$this->whatsAppRepo->hasApprovedTemplate($businessId, $templateName)) {
            return Response::error('Template is not approved', 'template_not_approved', 422, $request->traceId);
        }

        if (!$this->whatsAppRepo->hasValidConsent($businessId, $customerId)) {
            return Response::error('Customer consent missing', 'consent_missing', 422, $request->traceId);
        }

        $id = $this->whatsAppRepo->queueOutbox($businessId, $customerId, $eventType, $templateName, $payload);

        return Response::created(['id' => $id, 'status' => 'queued']);
    }

    public function webhookVerify(Request $request): Response
    {
        $mode = (string) ($request->queryParam('hub_mode', $request->queryParam('hub.mode')) ?? '');
        $verifyToken = (string) ($request->queryParam('hub_verify_token', $request->queryParam('hub.verify_token')) ?? '');
        $challenge = (string) ($request->queryParam('hub_challenge', $request->queryParam('hub.challenge')) ?? '');

        $expected = (string) ($_ENV['WHATSAPP_WEBHOOK_VERIFY_TOKEN'] ?? '');
        if ($mode !== 'subscribe' || $challenge === '' || $verifyToken === '' || !hash_equals($expected, $verifyToken)) {
            return Response::forbidden('Invalid webhook verification', $request->traceId);
        }

        return Response::json(['challenge' => $challenge]);
    }

    public function webhookReceive(Request $request): Response
    {
        if (!$this->isValidWebhookSignature($request)) {
            return Response::forbidden('Invalid webhook signature', $request->traceId);
        }

        $payload = $request->getBody() ?? [];
        foreach (($payload['entry'] ?? []) as $entry) {
            foreach (($entry['changes'] ?? []) as $change) {
                $value = $change['value'] ?? [];

                foreach (($value['statuses'] ?? []) as $status) {
                    $providerMessageId = (string) ($status['id'] ?? '');
                    if ($providerMessageId !== '') {
                        $mappedStatus = (string) ($status['status'] ?? 'sent');
                        $this->whatsAppRepo->markStatusByProviderMessageId($providerMessageId, $mappedStatus);
                    }
                }

                foreach (($value['messages'] ?? []) as $message) {
                    $businessId = (int) ($_ENV['WHATSAPP_DEFAULT_BUSINESS_ID'] ?? 0);
                    if ($businessId > 0) {
                        $this->whatsAppRepo->logMessage(
                            $businessId,
                            null,
                            'inbound',
                            (string) ($message['type'] ?? 'text'),
                            json_encode($message),
                            (string) ($message['id'] ?? null),
                            'received'
                        );
                    }
                }
            }
        }

        return Response::success(['received' => true]);
    }

    private function isValidWebhookSignature(Request $request): bool
    {
        $secret = (string) ($_ENV['WHATSAPP_APP_SECRET'] ?? '');
        if ($secret === '') {
            return false;
        }

        $signature = (string) ($request->header('x-hub-signature-256') ?? '');
        if (!str_starts_with($signature, 'sha256=')) {
            return false;
        }

        $expected = 'sha256=' . hash_hmac('sha256', $request->getRawBody(), $secret);

        return hash_equals($expected, $signature);
    }
}
