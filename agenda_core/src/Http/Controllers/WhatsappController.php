<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BusinessWhatsappSettingsRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Repositories\WhatsappRepository;
use Agenda\Infrastructure\Security\TokenCipher;
use Agenda\Infrastructure\Support\Json;
use Agenda\Infrastructure\Whatsapp\MetaWhatsAppEmbeddedSignupService;

final class WhatsappController
{
    /** @var string[] */
    private const ALLOWED_CONFIG_STATUS = ['active', 'inactive', 'pending', 'error', 'draft', 'suspended'];
    /** @var string[] */
    private const ALLOWED_OUTBOX_STATUS = ['queued', 'processing', 'sent', 'delivered', 'read', 'failed', 'cancelled', 'skipped'];

    public function __construct(
        private readonly WhatsappRepository $whatsappRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly LocationRepository $locationRepo,
        private readonly BusinessWhatsappSettingsRepository $settingsRepo,
        private readonly TokenCipher $tokenCipher,
        private readonly MetaWhatsAppEmbeddedSignupService $metaEmbeddedSignupService,
    ) {}

    public function configsIndex(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'view', $request);
        if ($availability !== null) {
            return $availability;
        }

        $configs = $this->whatsappRepo->getConfigsByBusinessId($businessId);
        return Response::success(['configs' => array_map([$this, 'formatConfig'], $configs)]);
    }

    public function configsStore(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'manage_config', $request);
        if ($availability !== null) {
            return $availability;
        }

        $body = $request->getBody() ?? [];
        $wabaId = trim((string) ($body['waba_id'] ?? ''));
        $phoneNumberId = trim((string) ($body['phone_number_id'] ?? ''));
        $tokenInput = trim((string) ($body['access_token_encrypted'] ?? ''));
        $status = strtolower(trim((string) ($body['status'] ?? 'pending')));
        $isDefault = (bool) ($body['is_default'] ?? false);

        if ($wabaId === '' || $phoneNumberId === '' || $tokenInput === '') {
            return Response::validationError('waba_id, phone_number_id e access_token_encrypted sono obbligatori', $request->traceId);
        }
        if (!in_array($status, self::ALLOWED_CONFIG_STATUS, true)) {
            return Response::validationError('status non valido', $request->traceId);
        }

        $token = $this->encryptTokenIfNeeded($tokenInput);

        $id = $this->whatsappRepo->createConfig(
            $businessId,
            $wabaId,
            $phoneNumberId,
            $token,
            $status,
            $isDefault
        );
        $config = $this->whatsappRepo->findConfigById($businessId, $id);

        return Response::created(['config' => $this->formatConfig($config ?? ['id' => $id])]);
    }

    public function configsUpdate(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $configId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'manage_config', $request);
        if ($availability !== null) {
            return $availability;
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
            $data['access_token_encrypted'] = $this->encryptTokenIfNeeded(
                trim((string) $body['access_token_encrypted'])
            );
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

        return Response::success(['config' => $this->formatConfig($updated ?? $current)]);
    }

    public function configsDestroy(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $configId = (int) $request->getAttribute('id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'manage_config', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'view', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'manage_mapping', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'manage_mapping', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'view', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'send_test', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'manage_config', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'send_test', $request);
        if ($availability !== null) {
            return $availability;
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
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'view', $request);
        if ($availability !== null) {
            return $availability;
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

        $settings = $this->settingsRepo->findByBusinessId($businessId);
        $checks = $this->buildGoLiveResponse(
            $businessId,
            $settings,
            $config,
            $phoneActive,
            $webhookVerified,
            $templateApproved,
            $optInActive
        );
        $blocking = $checks['blocking_reasons'] ?? [];
        $this->settingsRepo->markGoLiveChecked(
            $businessId,
            $blocking === [] ? null : (string) $blocking[0],
            $blocking === [] ? null : implode(', ', $blocking)
        );

        return Response::success(['checks' => $checks]);
    }

    public function optInStore(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'manage_optin', $request);
        if ($availability !== null) {
            return $availability;
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

    public function embeddedSignupState(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'onboard', $request);
        if ($availability !== null) {
            return $availability;
        }

        $redirectUri = trim((string) ($_ENV['META_EMBEDDED_SIGNUP_REDIRECT_URI'] ?? getenv('META_EMBEDDED_SIGNUP_REDIRECT_URI') ?? ''));
        $state = $this->createEmbeddedSignupStateToken(
            $businessId,
            (int) $request->getAttribute('user_id'),
            $redirectUri
        );

        return Response::success([
            'state' => $state,
            'app_id' => trim((string) ($_ENV['META_APP_ID'] ?? getenv('META_APP_ID') ?? '')),
            'graph_version' => trim((string) ($_ENV['META_GRAPH_VERSION'] ?? getenv('META_GRAPH_VERSION') ?? 'v22.0')),
            'redirect_uri' => $redirectUri,
            'expires_in' => 900,
        ]);
    }

    public function embeddedSignupComplete(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }
        $availability = $this->assertWhatsappFeatureAvailableForBusiness($businessId, 'onboard', $request);
        if ($availability !== null) {
            return $availability;
        }

        $body = $request->getBody() ?? [];
        $code = trim((string) ($body['code'] ?? ''));
        $state = trim((string) ($body['state'] ?? ''));
        $wabaId = trim((string) ($body['waba_id'] ?? ''));
        $phoneNumberId = trim((string) ($body['phone_number_id'] ?? ''));
        $displayPhoneNumber = isset($body['display_phone_number'])
            ? trim((string) $body['display_phone_number'])
            : null;
        $sessionInfoVersion = isset($body['session_info_version'])
            ? (int) $body['session_info_version']
            : null;

        if ($code === '') {
            return Response::validationError('code obbligatorio', $request->traceId);
        }
        if (array_key_exists('state', $body) && $state === '') {
            return Response::validationError('state non valido', $request->traceId);
        }
        if ($state === '' || !$this->validateEmbeddedSignupStateToken($state, $businessId, (int) $request->getAttribute('user_id'))) {
            return Response::error('State Embedded Signup non valido o scaduto', 'whatsapp_embedded_signup_state_invalid', 409, $request->traceId);
        }

        try {
            $meta = $this->metaEmbeddedSignupService->completeSignup(
                $code,
                $wabaId !== '' ? $wabaId : null,
                $phoneNumberId !== '' ? $phoneNumberId : null,
                $displayPhoneNumber
            );
        } catch (\RuntimeException $e) {
            return Response::error(
                'Impossibile completare la connessione Meta. Verifica permessi o riprova.',
                'meta_embedded_signup_failed',
                422,
                $request->traceId,
                ['reason' => $e->getMessage()]
            );
        }

        $encryptedToken = $this->tokenCipher->encrypt((string) $meta['access_token']);
        $existing = $this->whatsappRepo->findConfigByPhoneNumberId($businessId, (string) $meta['phone_number_id']);
        $configs = $this->whatsappRepo->getConfigsByBusinessId($businessId);
        $isDefault = $existing !== null
            ? ((int) ($existing['is_default'] ?? 0) === 1)
            : count($configs) === 0;

        $goLiveBeforeStatus = $this->computeGoLiveCheck($businessId, null);
        $id = $this->whatsappRepo->upsertConfigByPhoneNumberId(
            $businessId,
            (string) $meta['waba_id'],
            (string) $meta['phone_number_id'],
            $encryptedToken,
            ($goLiveBeforeStatus['webhook'] && $goLiveBeforeStatus['template']) ? 'active' : 'pending',
            $isDefault,
            $meta['display_phone_number'] ?? null
        );
        $config = $this->whatsappRepo->findConfigById($businessId, $id);
        $this->settingsRepo->updateStatus($businessId, ($config['status'] ?? '') === 'active' ? 'active' : 'pending_review');

        $autoMappedLocationIds = [];
        $activeLocations = $this->locationRepo->findByBusinessId($businessId);
        if (count($activeLocations) === 1) {
            $locationId = (int) ($activeLocations[0]['id'] ?? 0);
            if ($locationId > 0) {
                $existingMapping = $this->whatsappRepo->findMappingByLocation($businessId, $locationId);
                if ($existingMapping === null) {
                    $this->whatsappRepo->upsertMapping($businessId, $locationId, $id);
                    $autoMappedLocationIds[] = $locationId;
                }
            }
        }

        $goLive = $this->computeGoLiveCheck($businessId, null);
        $nextSteps = [];
        if (!$goLive['webhook']) {
            $nextSteps[] = 'verify_webhook';
        }
        if (!$goLive['template']) {
            $nextSteps[] = 'create_utility_template';
        }
        if (!$goLive['optin']) {
            $nextSteps[] = 'collect_opt_in';
        }
        if (count($activeLocations) > 1) {
            $nextSteps[] = 'complete_location_mapping';
        }

        return Response::success([
            'config' => $this->formatConfig($config ?? ['id' => $id]),
            'auto_mapped_location_ids' => $autoMappedLocationIds,
            'go_live_check' => $goLive,
            'next_steps' => $nextSteps,
            'session_info_version' => $sessionInfoVersion,
        ]);
    }

    public function webhookPublicVerify(Request $request): Response
    {
        $mode = (string) ($request->queryParam('hub.mode') ?? '');
        $verifyToken = (string) ($request->queryParam('hub.verify_token') ?? '');
        $challenge = (string) ($request->queryParam('hub.challenge') ?? '');
        $expected = trim((string) ($_ENV['WHATSAPP_WEBHOOK_VERIFY_TOKEN'] ?? getenv('WHATSAPP_WEBHOOK_VERIFY_TOKEN') ?? ''));
        if ($expected === '') {
            $expected = trim((string) ($_ENV['META_WHATSAPP_WEBHOOK_VERIFY_TOKEN'] ?? getenv('META_WHATSAPP_WEBHOOK_VERIFY_TOKEN') ?? ''));
        }

        if ($mode === 'subscribe' && $expected !== '' && hash_equals($expected, $verifyToken)) {
            return new Response(
                200,
                [],
                null,
                $challenge !== '' ? $challenge : 'ok',
                'text/plain; charset=UTF-8'
            );
        }

        return Response::error('Webhook verify failed', 'webhook_verify_failed', 403, $request->traceId);
    }

    public function webhookPublicIngest(Request $request): Response
    {
        $payload = $request->getBody() ?? [];
        if (!is_array($payload) || $payload === []) {
            return Response::validationError('payload obbligatorio', $request->traceId);
        }
        if (!$this->verifyWebhookSignature($request)) {
            return Response::error('Webhook signature invalid', 'webhook_signature_invalid', 403, $request->traceId);
        }

        $phoneNumberId = $this->extractPhoneNumberIdFromWebhook($payload);
        if ($phoneNumberId === null) {
            return Response::success(['processed' => false, 'reason' => 'phone_number_id_not_found']);
        }

        $config = $this->whatsappRepo->findConfigByPhoneNumberIdGlobal($phoneNumberId);
        if ($config === null) {
            return Response::success(['processed' => false, 'reason' => 'unmapped_phone_number_id']);
        }

        $businessId = (int) ($config['business_id'] ?? 0);
        if ($businessId <= 0) {
            return Response::success(['processed' => false, 'reason' => 'invalid_business']);
        }

        $eventId = trim((string) ($this->extractWebhookEventId($payload) ?? ''));
        if ($eventId === '') {
            $eventId = 'wh_' . md5(Json::encode($payload));
        }
        if ($this->whatsappRepo->isWebhookEventProcessed($eventId)) {
            return Response::success(['processed' => false, 'duplicate' => true, 'event_id' => $eventId]);
        }

        $this->whatsappRepo->storeWebhookEvent($eventId, $businessId, $payload);
        $updated = $this->applyWebhookStatuses($businessId, $payload);
        $optOuts = $this->applyWebhookOptOutKeywords($businessId, $payload);

        return Response::success([
            'processed' => true,
            'duplicate' => false,
            'event_id' => $eventId,
            'updated_count' => $updated,
            'opt_out_updates' => $optOuts,
        ]);
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

    private function assertWhatsappFeatureAvailableForBusiness(int $businessId, string $action, Request $request): ?Response
    {
        $settings = $this->settingsRepo->findByBusinessId($businessId);
        $isSuperadmin = $this->userRepo->isSuperadmin((int) $request->getAttribute('user_id'));
        $enabled = ((int) ($settings['whatsapp_enabled'] ?? 0)) === 1;
        $activationAllowed = ((int) ($settings['activation_allowed'] ?? 0)) === 1;
        $messagesEnabled = ((int) ($settings['messages_enabled'] ?? 0)) === 1;
        $selfOnboarding = ((int) ($settings['allow_business_self_onboarding'] ?? 1)) === 1;
        $mappingAllowed = ((int) ($settings['allow_location_mapping'] ?? 0)) === 1;
        $role = $isSuperadmin
            ? 'superadmin'
            : $this->businessUserRepo->getRole((int) $request->getAttribute('user_id'), $businessId);

        if ($action === 'view') {
            return null;
        }
        if (!$isSuperadmin && !in_array((string) $role, ['owner', 'admin', 'manager'], true)) {
            return Response::error('Permessi WhatsApp insufficienti', 'forbidden', 403, $request->traceId);
        }
        if (!$enabled && !$isSuperadmin) {
            return Response::error('WhatsApp non abilitato per questo business', 'whatsapp_not_enabled', 403, $request->traceId);
        }
        if ($action === 'onboard' && (!$enabled || !$activationAllowed || !$selfOnboarding)) {
            return Response::error('Attivazione WhatsApp non consentita', 'whatsapp_activation_not_allowed', 403, $request->traceId);
        }
        if ($action === 'send_real' && (!$enabled || !$messagesEnabled)) {
            return Response::error('Invio messaggi WhatsApp disabilitato', 'whatsapp_messages_disabled', 403, $request->traceId);
        }
        if ($action === 'send_test' && !$messagesEnabled && !$isSuperadmin) {
            return Response::error('Invio messaggi WhatsApp disabilitato', 'whatsapp_messages_disabled', 403, $request->traceId);
        }
        if ($action === 'manage_mapping' && !$mappingAllowed && !$isSuperadmin) {
            return Response::error('Mapping sedi WhatsApp non consentito', 'whatsapp_mapping_not_allowed', 403, $request->traceId);
        }

        return null;
    }

    private function buildProviderMessageId(int $outboxId): string
    {
        return 'wa_' . $outboxId . '_' . bin2hex(random_bytes(6));
    }

    private function createEmbeddedSignupStateToken(int $businessId, int $userId, string $redirectUri): string
    {
        $payload = [
            'business_id' => $businessId,
            'user_id' => $userId,
            'nonce' => bin2hex(random_bytes(16)),
            'redirect_uri' => $redirectUri,
            'expires_at' => time() + 900,
        ];
        $encoded = $this->base64UrlEncode(Json::encode($payload));
        $signature = hash_hmac('sha256', $encoded, $this->embeddedSignupStateSecret());

        return $encoded . '.' . $signature;
    }

    private function validateEmbeddedSignupStateToken(string $state, int $businessId, int $userId): bool
    {
        $parts = explode('.', $state, 2);
        if (count($parts) !== 2) {
            return false;
        }
        [$encoded, $signature] = $parts;
        $expected = hash_hmac('sha256', $encoded, $this->embeddedSignupStateSecret());
        if (!hash_equals($expected, $signature)) {
            return false;
        }

        $decoded = Json::decodeAssoc($this->base64UrlDecode($encoded));
        if ($decoded === null) {
            return false;
        }

        return (int) ($decoded['business_id'] ?? 0) === $businessId
            && (int) ($decoded['user_id'] ?? 0) === $userId
            && (int) ($decoded['expires_at'] ?? 0) >= time();
    }

    private function embeddedSignupStateSecret(): string
    {
        $secret = trim((string) ($_ENV['META_APP_SECRET'] ?? getenv('META_APP_SECRET') ?? ''));
        if ($secret === '') {
            $secret = trim((string) ($_ENV['APP_KEY'] ?? getenv('APP_KEY') ?? ''));
        }
        if ($secret === '') {
            $secret = 'agenda-whatsapp-embedded-signup-state';
        }

        return $secret;
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function base64UrlDecode(string $value): string
    {
        $padding = strlen($value) % 4;
        if ($padding > 0) {
            $value .= str_repeat('=', 4 - $padding);
        }

        $decoded = base64_decode(strtr($value, '-_', '+/'), true);
        return is_string($decoded) ? $decoded : '';
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
     * @return array{phone:bool,webhook:bool,template:bool,optin:bool}
     */
    private function computeGoLiveCheck(int $businessId, ?int $locationId): array
    {
        $config = $locationId !== null && $locationId > 0
            ? $this->whatsappRepo->findConfigForLocation($businessId, $locationId)
            : $this->findDefaultOrActiveConfig($businessId);

        return [
            'phone' => $config !== null && ($config['status'] ?? '') === 'active',
            'webhook' => $this->whatsappRepo->hasWebhookEventForBusiness($businessId),
            'template' => $this->whatsappRepo->hasApprovedUtilityTemplate($businessId),
            'optin' => $this->whatsappRepo->hasActiveOptIn($businessId),
        ];
    }

    private function buildGoLiveResponse(
        int $businessId,
        array $settings,
        ?array $config,
        bool $phoneActive,
        bool $webhookVerified,
        bool $templateApproved,
        bool $optInActive
    ): array {
        $featureEnabled = ((int) ($settings['whatsapp_enabled'] ?? 0)) === 1;
        $activationAllowed = ((int) ($settings['activation_allowed'] ?? 0)) === 1;
        $messagesEnabled = ((int) ($settings['messages_enabled'] ?? 0)) === 1;
        $mappingAllowed = ((int) ($settings['allow_location_mapping'] ?? 0)) === 1;
        $blocking = [];
        $warnings = [];
        $nextSteps = [];

        if (!$featureEnabled) {
            $blocking[] = 'whatsapp_not_enabled';
            $nextSteps[] = 'superadmin_enable_whatsapp';
        }
        if (!$activationAllowed) {
            $blocking[] = 'whatsapp_activation_not_allowed';
            $nextSteps[] = 'allow_business_onboarding';
        }
        if ($config === null) {
            $blocking[] = 'whatsapp_config_missing';
            $nextSteps[] = 'connect_whatsapp_number';
        }
        if (!$phoneActive) {
            $blocking[] = 'whatsapp_phone_number_not_active';
            $nextSteps[] = 'complete_meta_review';
        }
        if (!$webhookVerified) {
            $blocking[] = 'whatsapp_webhook_not_verified';
            $nextSteps[] = 'configure_meta_webhook';
        }
        if (!$templateApproved) {
            $blocking[] = 'whatsapp_template_not_approved';
            $nextSteps[] = 'approve_utility_templates';
        }
        if (!$optInActive) {
            $blocking[] = 'whatsapp_optin_required';
            $nextSteps[] = 'collect_customer_opt_in';
        }
        if (!$messagesEnabled) {
            $blocking[] = 'whatsapp_messages_disabled';
            $nextSteps[] = 'enable_real_message_sending';
        }
        if (!$mappingAllowed && ($settings['default_channel_mode'] ?? '') === 'location_mapping') {
            $warnings[] = 'location_mapping_mode_without_permission';
        }

        return [
            'feature_enabled' => $featureEnabled,
            'activation_allowed' => $activationAllowed,
            'messages_enabled' => $messagesEnabled,
            'business_config_present' => $config !== null,
            'phone_number_present' => $config !== null && trim((string) ($config['phone_number_id'] ?? '')) !== '',
            'phone_number_active' => $phoneActive,
            'webhook_verified' => $webhookVerified,
            'template_approved' => $templateApproved,
            'templates_approved' => $templateApproved,
            'opt_in_active' => $optInActive,
            'opt_in_available' => $optInActive,
            'location_mapping_valid' => $mappingAllowed || ($settings['default_channel_mode'] ?? '') !== 'location_mapping',
            'can_send_real_messages' => $blocking === [] && $this->realSendEnabled(),
            'blocking_reasons' => array_values(array_unique($blocking)),
            'warnings' => array_values(array_unique($warnings)),
            'next_steps' => array_values(array_unique($nextSteps)),
            'business_id' => $businessId,
        ];
    }

    private function realSendEnabled(): bool
    {
        $env = strtolower(trim((string) ($_ENV['APP_ENV'] ?? getenv('APP_ENV') ?? 'local')));
        if ($env === 'demo') {
            return false;
        }
        return in_array(
            strtolower(trim((string) ($_ENV['WHATSAPP_REAL_SEND_ENABLED'] ?? getenv('WHATSAPP_REAL_SEND_ENABLED') ?? 'false'))),
            ['1', 'true', 'yes', 'on'],
            true
        );
    }

    private function verifyWebhookSignature(Request $request): bool
    {
        $secret = trim((string) ($_ENV['META_WHATSAPP_WEBHOOK_APP_SECRET'] ?? getenv('META_WHATSAPP_WEBHOOK_APP_SECRET') ?? ''));
        if ($secret === '') {
            return true;
        }
        $header = (string) ($request->getHeader('x-hub-signature-256') ?? '');
        if (!str_starts_with($header, 'sha256=')) {
            return false;
        }
        $expected = 'sha256=' . hash_hmac('sha256', $request->rawBody, $secret);

        return hash_equals($expected, $header);
    }

    /**
     * @param array<string,mixed> $config
     * @return array<string,mixed>
     */
    private function formatConfig(array $config): array
    {
        return [
            'id' => isset($config['id']) ? (int) $config['id'] : 0,
            'business_id' => isset($config['business_id']) ? (int) $config['business_id'] : null,
            'waba_id' => $config['waba_id'] ?? null,
            'phone_number_id' => $config['phone_number_id'] ?? null,
            'display_phone_number' => $config['display_phone_number'] ?? null,
            'status' => $config['status'] ?? 'pending',
            'is_default' => ((int) ($config['is_default'] ?? 0)) === 1,
            'created_at' => $config['created_at'] ?? null,
            'updated_at' => $config['updated_at'] ?? null,
        ];
    }

    private function isEmbeddedSignupEnabled(int $businessId): bool
    {
        $defaultEnabled = in_array(
            strtolower(trim((string) ($_ENV['WHATSAPP_EMBEDDED_SIGNUP_DEFAULT_ENABLED'] ?? getenv('WHATSAPP_EMBEDDED_SIGNUP_DEFAULT_ENABLED') ?? 'false'))),
            ['1', 'true', 'yes', 'on'],
            true
        );
        return $this->whatsappRepo->isEmbeddedSignupEnabled($businessId, $defaultEnabled);
    }

    private function encryptTokenIfNeeded(string $input): string
    {
        $trimmed = trim($input);
        if ($trimmed === '') {
            return $trimmed;
        }
        if (str_starts_with($trimmed, 'v1:')) {
            return $trimmed;
        }
        return $this->tokenCipher->encrypt($trimmed);
    }

    private function extractPhoneNumberIdFromWebhook(array $payload): ?string
    {
        $entry = $payload['entry'] ?? null;
        if (!is_array($entry)) {
            return null;
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
                $metadata = $value['metadata'] ?? null;
                if (is_array($metadata)) {
                    $candidate = trim((string) ($metadata['phone_number_id'] ?? ''));
                    if ($candidate !== '') {
                        return $candidate;
                    }
                }
                $candidate = trim((string) ($value['phone_number_id'] ?? ''));
                if ($candidate !== '') {
                    return $candidate;
                }
            }
        }

        return null;
    }

    private function applyWebhookOptOutKeywords(int $businessId, array $payload): int
    {
        $optOutCount = 0;
        $entry = $payload['entry'] ?? null;
        if (!is_array($entry)) {
            return 0;
        }

        $keywords = ['STOP', 'STOPPA', 'ANNULLA', 'DISISCRIVI'];
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
                $messages = $value['messages'] ?? null;
                if (!is_array($messages)) {
                    continue;
                }
                foreach ($messages as $message) {
                    if (!is_array($message)) {
                        continue;
                    }
                    $from = trim((string) ($message['from'] ?? ''));
                    $textBody = trim((string) (($message['text']['body'] ?? null) ?? ''));
                    if ($from === '' || $textBody === '') {
                        continue;
                    }
                    $normalized = strtoupper(trim($textBody));
                    if (!in_array($normalized, $keywords, true)) {
                        continue;
                    }
                    if ($this->whatsappRepo->optOutByPhone($businessId, $from, 'whatsapp_stop')) {
                        $optOutCount++;
                    }
                }
            }
        }

        return $optOutCount;
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
