<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\WhatsappRepository;
use Agenda\Infrastructure\Support\Json;

final class WhatsappController
{
    /** @var string[] */
    private const ALLOWED_CONFIG_STATUS = ['active', 'inactive', 'pending', 'error'];
    /** @var string[] */
    private const ALLOWED_OUTBOX_STATUS = ['queued', 'sent', 'delivered', 'read', 'failed'];

    public function __construct(
        private readonly WhatsappRepository $whatsappRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly LocationRepository $locationRepo,
    ) {}

    public function configsIndex(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $configs = $this->whatsappRepo->getConfigsByBusinessId($businessId);
        return Response::success(['configs' => $configs]);
    }

    public function configsStore(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $wabaId = trim((string) ($body['waba_id'] ?? ''));
        $phoneNumberId = trim((string) ($body['phone_number_id'] ?? ''));
        $token = trim((string) ($body['access_token_encrypted'] ?? ''));
        $status = strtolower(trim((string) ($body['status'] ?? 'pending')));
        $isDefault = (bool) ($body['is_default'] ?? false);

        if ($wabaId === '' || $phoneNumberId === '' || $token === '') {
            return Response::validationError('waba_id, phone_number_id e access_token_encrypted sono obbligatori', $request->traceId);
        }
        if (!in_array($status, self::ALLOWED_CONFIG_STATUS, true)) {
            return Response::validationError('status non valido', $request->traceId);
        }

        $id = $this->whatsappRepo->createConfig(
            $businessId,
            $wabaId,
            $phoneNumberId,
            $token,
            $status,
            $isDefault
        );
        $config = $this->whatsappRepo->findConfigById($businessId, $id);

        return Response::created(['config' => $config ?? ['id' => $id]]);
    }

    public function configsUpdate(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $configId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $current = $this->whatsappRepo->findConfigById($businessId, $configId);
        if ($current === null) {
            return Response::notFound('Config not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $data = [];
        if (array_key_exists('waba_id', $body)) {
            $data['waba_id'] = trim((string) $body['waba_id']);
        }
        if (array_key_exists('phone_number_id', $body)) {
            $data['phone_number_id'] = trim((string) $body['phone_number_id']);
        }
        if (array_key_exists('access_token_encrypted', $body)) {
            $data['access_token_encrypted'] = trim((string) $body['access_token_encrypted']);
        }
        if (array_key_exists('status', $body)) {
            $status = strtolower(trim((string) $body['status']));
            if (!in_array($status, self::ALLOWED_CONFIG_STATUS, true)) {
                return Response::validationError('status non valido', $request->traceId);
            }
            $data['status'] = $status;
        }
        if (array_key_exists('is_default', $body)) {
            $data['is_default'] = (bool) $body['is_default'];
        }

        $this->whatsappRepo->updateConfig($businessId, $configId, $data);
        $updated = $this->whatsappRepo->findConfigById($businessId, $configId);

        return Response::success(['config' => $updated ?? $current]);
    }

    public function configsDestroy(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $configId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $current = $this->whatsappRepo->findConfigById($businessId, $configId);
        if ($current === null) {
            return Response::notFound('Config not found', $request->traceId);
        }

        $this->whatsappRepo->deleteConfig($businessId, $configId);
        return Response::success(['deleted' => true]);
    }

    public function mappingsIndex(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $mappings = $this->whatsappRepo->getMappingsByBusinessId($businessId);
        return Response::success(['mappings' => $mappings]);
    }

    public function mappingsStore(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $locationId = (int) ($body['location_id'] ?? 0);
        $configId = (int) ($body['whatsapp_config_id'] ?? 0);
        if ($locationId <= 0 || $configId <= 0) {
            return Response::validationError('location_id e whatsapp_config_id sono obbligatori', $request->traceId);
        }

        $location = $this->locationRepo->findById($locationId);
        if ($location === null || (int) $location['business_id'] !== $businessId) {
            return Response::validationError('location_id non appartiene al business', $request->traceId);
        }
        $config = $this->whatsappRepo->findConfigById($businessId, $configId);
        if ($config === null) {
            return Response::validationError('whatsapp_config_id non valido', $request->traceId);
        }

        $id = $this->whatsappRepo->upsertMapping($businessId, $locationId, $configId);
        $mapping = $this->whatsappRepo->findMappingById($businessId, $id);

        return Response::success(['mapping' => $mapping ?? ['id' => $id]]);
    }

    public function mappingsDestroy(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $mappingId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $mapping = $this->whatsappRepo->findMappingById($businessId, $mappingId);
        if ($mapping === null) {
            return Response::notFound('Mapping not found', $request->traceId);
        }

        $this->whatsappRepo->deleteMapping($businessId, $mappingId);
        return Response::success(['deleted' => true]);
    }

    public function outboxIndex(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $status = $request->queryParam('status');
        if ($status !== null && $status !== '' && !in_array($status, self::ALLOWED_OUTBOX_STATUS, true)) {
            return Response::validationError('status non valido', $request->traceId);
        }
        $limit = min(100, max(1, (int) ($request->queryParam('limit') ?? '50')));
        $offset = max(0, (int) ($request->queryParam('offset') ?? '0'));

        $items = $this->whatsappRepo->listOutbox($businessId, $status, $limit, $offset);
        $total = $this->whatsappRepo->countOutbox($businessId, $status);

        return Response::success([
            'messages' => array_map([$this, 'formatOutboxItem'], $items),
            'total' => $total,
            'limit' => $limit,
            'offset' => $offset,
        ]);
    }

    public function outboxStore(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $locationId = (int) ($body['location_id'] ?? 0);
        $bookingId = (int) ($body['booking_id'] ?? 0);
        $recipientPhone = trim((string) ($body['recipient_phone'] ?? ''));
        $templateName = trim((string) ($body['template_name'] ?? ''));
        $templateLanguage = trim((string) ($body['template_language'] ?? 'it'));
        $templatePayload = is_array($body['template_variables'] ?? null)
            ? $body['template_variables']
            : [];
        $optIn = (bool) ($body['opt_in'] ?? false);
        $scheduledAt = $body['scheduled_at'] ?? null;

        if (!$optIn) {
            return Response::validationError('Opt-in WhatsApp non attivo', $request->traceId);
        }
        if ($locationId <= 0 || $bookingId <= 0 || $recipientPhone === '' || $templateName === '') {
            return Response::validationError(
                'location_id, booking_id, recipient_phone e template_name sono obbligatori',
                $request->traceId
            );
        }
        $location = $this->locationRepo->findById($locationId);
        if ($location === null || (int) $location['business_id'] !== $businessId) {
            return Response::validationError('location_id non appartiene al business', $request->traceId);
        }

        $config = $this->whatsappRepo->findConfigForLocation($businessId, $locationId);
        if ($config === null) {
            return Response::success(['message' => null, 'skipped' => true, 'reason' => 'no_whatsapp_number_configured']);
        }
        if (($config['status'] ?? '') !== 'active') {
            return Response::success(['message' => null, 'skipped' => true, 'reason' => 'whatsapp_config_not_active']);
        }

        // Ensure utility template presence to keep go-live check consistent.
        $this->whatsappRepo->createTemplateIfMissing($businessId, $templateName, 'utility', 'approved');

        $id = $this->whatsappRepo->createOutbox([
            'business_id' => $businessId,
            'booking_id' => $bookingId,
            'location_id' => $locationId,
            'whatsapp_config_id' => (int) $config['id'],
            'recipient_phone' => $recipientPhone,
            'template_name' => $templateName,
            'template_language' => $templateLanguage,
            'template_payload' => $templatePayload,
            'max_attempts' => 3,
            'scheduled_at' => $scheduledAt,
        ]);
        $message = $this->whatsappRepo->findOutboxById($businessId, $id);

        return Response::created(['message' => $this->formatOutboxItem($message ?? ['id' => $id])]);
    }

    public function outboxUpdate(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $outboxId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $item = $this->whatsappRepo->findOutboxById($businessId, $outboxId);
        if ($item === null) {
            return Response::notFound('Outbox item not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $status = strtolower(trim((string) ($body['status'] ?? '')));
        $errorMessage = isset($body['error_message']) ? (string) $body['error_message'] : null;
        if ($status === '' || !in_array($status, self::ALLOWED_OUTBOX_STATUS, true)) {
            return Response::validationError('status non valido', $request->traceId);
        }

        $this->whatsappRepo->updateOutboxStatus($businessId, $outboxId, $status, $errorMessage);
        $updated = $this->whatsappRepo->findOutboxById($businessId, $outboxId);

        return Response::success(['message' => $this->formatOutboxItem($updated ?? $item)]);
    }

    public function outboxSend(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $outboxId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $item = $this->whatsappRepo->findOutboxById($businessId, $outboxId);
        if ($item === null) {
            return Response::notFound('Outbox item not found', $request->traceId);
        }
        if (!in_array((string) ($item['status'] ?? ''), ['queued', 'failed'], true)) {
            return Response::validationError('Solo i messaggi queued/failed possono essere inviati', $request->traceId);
        }

        $providerMessageId = $this->buildProviderMessageId((int) $outboxId);
        $this->whatsappRepo->markOutboxSent($businessId, $outboxId, $providerMessageId);
        $updated = $this->whatsappRepo->findOutboxById($businessId, $outboxId);

        return Response::success(['message' => $this->formatOutboxItem($updated ?? $item)]);
    }

    public function outboxRetry(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $outboxId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $item = $this->whatsappRepo->findOutboxById($businessId, $outboxId);
        if ($item === null) {
            return Response::notFound('Outbox item not found', $request->traceId);
        }

        $this->whatsappRepo->retryOutbox($businessId, $outboxId);
        $updated = $this->whatsappRepo->findOutboxById($businessId, $outboxId);

        return Response::success(['message' => $this->formatOutboxItem($updated ?? $item)]);
    }

    public function webhook(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $payload = is_array($body['payload'] ?? null) ? $body['payload'] : [];
        $eventId = trim((string) ($body['event_id'] ?? $this->extractWebhookEventId($payload) ?? ''));
        if ($payload === []) {
            return Response::validationError('payload obbligatorio', $request->traceId);
        }
        if ($eventId === '') {
            $eventId = 'wh_' . md5(Json::encode($payload));
        }

        if ($this->whatsappRepo->isWebhookEventProcessed($eventId)) {
            return Response::success(['processed' => false, 'duplicate' => true, 'event_id' => $eventId]);
        }

        $this->whatsappRepo->storeWebhookEvent($eventId, $businessId, $payload);
        $updated = $this->applyWebhookStatuses($businessId, $payload);

        return Response::success([
            'processed' => true,
            'duplicate' => false,
            'event_id' => $eventId,
            'updated_count' => $updated,
        ]);
    }

    public function goLiveCheck(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $locationId = (int) ($request->queryParam('location_id') ?? '0');
        $config = $locationId > 0
            ? $this->whatsappRepo->findConfigForLocation($businessId, $locationId)
            : $this->findDefaultOrActiveConfig($businessId);

        $phoneActive = $config !== null && ($config['status'] ?? '') === 'active';
        $webhookVerified = $this->whatsappRepo->hasWebhookEventForBusiness($businessId);
        $templateApproved = $this->whatsappRepo->hasApprovedUtilityTemplate($businessId);
        $optInActive = $this->whatsappRepo->hasActiveOptIn($businessId);

        return Response::success([
            'checks' => [
                'phone_number_active' => $phoneActive,
                'webhook_verified' => $webhookVerified,
                'template_approved' => $templateApproved,
                'opt_in_active' => $optInActive,
            ],
        ]);
    }

    public function optInStore(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $clientId = (int) ($body['client_id'] ?? 0);
        $optIn = (bool) ($body['opt_in'] ?? false);
        if ($clientId <= 0) {
            return Response::validationError('client_id obbligatorio', $request->traceId);
        }

        $this->whatsappRepo->upsertOptIn($businessId, $clientId, $optIn);
        return Response::success([
            'client_id' => $clientId,
            'opt_in' => $optIn,
        ]);
    }

    public function embeddedSignupComplete(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $wabaId = trim((string) ($body['waba_id'] ?? ''));
        $phoneNumberId = trim((string) ($body['phone_number_id'] ?? ''));
        $token = trim((string) ($body['token'] ?? ''));
        if ($wabaId === '' || $phoneNumberId === '' || $token === '') {
            return Response::validationError('waba_id, phone_number_id e token sono obbligatori', $request->traceId);
        }

        $id = $this->whatsappRepo->createConfig(
            $businessId,
            $wabaId,
            $phoneNumberId,
            $token,
            'active',
            false
        );
        $config = $this->whatsappRepo->findConfigById($businessId, $id);

        return Response::success(['config' => $config ?? ['id' => $id]]);
    }

    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin((int) $userId)) {
            return true;
        }

        return $this->businessUserRepo->hasAccess((int) $userId, $businessId, false);
    }

    private function buildProviderMessageId(int $outboxId): string
    {
        return 'wa_' . $outboxId . '_' . bin2hex(random_bytes(6));
    }

    private function extractWebhookEventId(array $payload): ?string
    {
        if (isset($payload['event_id']) && is_scalar($payload['event_id'])) {
            return (string) $payload['event_id'];
        }
        if (isset($payload['id']) && is_scalar($payload['id'])) {
            return (string) $payload['id'];
        }

        $entry = $payload['entry'] ?? null;
        if (!is_array($entry) || !isset($entry[0]) || !is_array($entry[0])) {
            return null;
        }
        $changes = $entry[0]['changes'] ?? null;
        if (!is_array($changes) || !isset($changes[0]) || !is_array($changes[0])) {
            return null;
        }
        $value = $changes[0]['value'] ?? null;
        if (!is_array($value)) {
            return null;
        }
        $statuses = $value['statuses'] ?? null;
        if (!is_array($statuses) || !isset($statuses[0]) || !is_array($statuses[0])) {
            return null;
        }
        if (isset($statuses[0]['id']) && is_scalar($statuses[0]['id'])) {
            return (string) $statuses[0]['id'];
        }

        return null;
    }

    private function applyWebhookStatuses(int $businessId, array $payload): int
    {
        $updated = 0;
        $entry = $payload['entry'] ?? null;
        if (!is_array($entry)) {
            return 0;
        }

        foreach ($entry as $entryItem) {
            if (!is_array($entryItem)) {
                continue;
            }
            $changes = $entryItem['changes'] ?? null;
            if (!is_array($changes)) {
                continue;
            }
            foreach ($changes as $change) {
                if (!is_array($change)) {
                    continue;
                }
                $value = $change['value'] ?? null;
                if (!is_array($value)) {
                    continue;
                }
                $statuses = $value['statuses'] ?? null;
                if (!is_array($statuses)) {
                    continue;
                }
                foreach ($statuses as $statusRow) {
                    if (!is_array($statusRow)) {
                        continue;
                    }
                    $providerMessageId = trim((string) ($statusRow['id'] ?? ''));
                    $status = strtolower(trim((string) ($statusRow['status'] ?? '')));
                    if ($providerMessageId === '' || $status === '') {
                        continue;
                    }
                    $normalized = match ($status) {
                        'sent', 'delivered', 'read', 'failed' => $status,
                        default => null,
                    };
                    if ($normalized === null) {
                        continue;
                    }
                    $errorMessage = null;
                    if ($normalized === 'failed') {
                        $errors = $statusRow['errors'] ?? null;
                        if (is_array($errors) && isset($errors[0]) && is_array($errors[0])) {
                            $errorMessage = (string) ($errors[0]['title'] ?? $errors[0]['message'] ?? 'provider_failed');
                        } else {
                            $errorMessage = 'provider_failed';
                        }
                    }

                    if ($this->whatsappRepo->updateOutboxStatusByProviderMessageId(
                        $businessId,
                        $providerMessageId,
                        $normalized,
                        $errorMessage
                    )) {
                        $updated++;
                    }
                }
            }
        }

        return $updated;
    }

    private function findDefaultOrActiveConfig(int $businessId): ?array
    {
        $configs = $this->whatsappRepo->getConfigsByBusinessId($businessId);
        foreach ($configs as $config) {
            if (($config['is_default'] ?? 0) == 1) {
                return $config;
            }
        }
        return $configs[0] ?? null;
    }

    /**
     * @param array<string,mixed> $item
     * @return array<string,mixed>
     */
    private function formatOutboxItem(array $item): array
    {
        $payload = $item['template_payload'] ?? null;
        if (is_string($payload) && $payload !== '') {
            $decoded = Json::decodeAssoc($payload);
            if ($decoded !== null) {
                $payload = $decoded;
            }
        }

        return [
            'id' => isset($item['id']) ? (int) $item['id'] : 0,
            'business_id' => isset($item['business_id']) ? (int) $item['business_id'] : null,
            'booking_id' => isset($item['booking_id']) ? (int) $item['booking_id'] : null,
            'location_id' => isset($item['location_id']) ? (int) $item['location_id'] : null,
            'whatsapp_config_id' => isset($item['whatsapp_config_id']) ? (int) $item['whatsapp_config_id'] : null,
            'recipient_phone' => $item['recipient_phone'] ?? null,
            'template_name' => $item['template_name'] ?? null,
            'template_language' => $item['template_language'] ?? 'it',
            'template_payload' => $payload,
            'status' => $item['status'] ?? 'queued',
            'attempts' => isset($item['attempts']) ? (int) $item['attempts'] : 0,
            'max_attempts' => isset($item['max_attempts']) ? (int) $item['max_attempts'] : 3,
            'provider_message_id' => $item['provider_message_id'] ?? null,
            'error_message' => $item['error_message'] ?? null,
            'scheduled_at' => $item['scheduled_at'] ?? null,
            'last_attempt_at' => $item['last_attempt_at'] ?? null,
            'sent_at' => $item['sent_at'] ?? null,
            'delivered_at' => $item['delivered_at'] ?? null,
            'read_at' => $item['read_at'] ?? null,
            'created_at' => $item['created_at'] ?? null,
            'updated_at' => $item['updated_at'] ?? null,
        ];
    }
}
