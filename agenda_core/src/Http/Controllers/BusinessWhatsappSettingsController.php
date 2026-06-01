<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BusinessWhatsappSettingsRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class BusinessWhatsappSettingsController
{
    public function __construct(
        private readonly BusinessRepository $businessRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly BusinessWhatsappSettingsRepository $settingsRepo,
    ) {}

    public function adminIndex(Request $request): Response
    {
        if (!$this->isSuperadmin($request)) {
            return Response::error('Solo superadmin', 'forbidden', 403, $request->traceId);
        }

        $limit = min(200, max(1, (int) ($request->queryParam('limit') ?? '100')));
        $offset = max(0, (int) ($request->queryParam('offset') ?? '0'));
        $items = $this->settingsRepo->listForAdmin([
            'business_id' => $request->queryParam('business_id'),
            'status' => $request->queryParam('status'),
            'enabled' => $request->queryParam('enabled'),
            'search' => $request->queryParam('search'),
        ], $limit, $offset);

        return Response::success([
            'items' => array_map([$this, 'formatAdminRow'], $items),
            'limit' => $limit,
            'offset' => $offset,
        ]);
    }

    public function show(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::error('Accesso non consentito', 'forbidden', 403, $request->traceId);
        }

        $settings = $this->settingsRepo->findByBusinessId($businessId);
        $isSuperadmin = $this->isSuperadmin($request);

        return Response::success([
            'settings' => $this->formatSettings($settings, $isSuperadmin),
        ]);
    }

    public function updateBusinessSettings(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::error('Accesso non consentito', 'forbidden', 403, $request->traceId);
        }

        $userId = (int) $request->getAttribute('user_id');
        if (!$this->isSuperadmin($request)) {
            $role = (string) $this->businessUserRepo->getRole($userId, $businessId);
            if (!in_array($role, ['owner', 'admin', 'manager'], true)) {
                return Response::error('Permessi WhatsApp insufficienti', 'forbidden', 403, $request->traceId);
            }
        }

        $body = $request->getBody() ?? [];
        if (!array_key_exists('business_messages_enabled', $body)) {
            return Response::validationError('business_messages_enabled obbligatorio', $request->traceId);
        }

        $settings = $this->settingsRepo->updateBusinessMessageSending(
            $businessId,
            (bool) $body['business_messages_enabled']
        );

        return Response::success(['settings' => $this->formatSettings($settings, $this->isSuperadmin($request))]);
    }

    public function adminUpsert(Request $request): Response
    {
        if (!$this->isSuperadmin($request)) {
            return Response::error('Solo superadmin', 'forbidden', 403, $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        if ($businessId <= 0 || $this->businessRepo->findById($businessId) === null) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $settings = $this->settingsRepo->upsertByAdmin(
            $businessId,
            (int) $request->getAttribute('user_id'),
            $request->getBody() ?? []
        );

        return Response::success(['settings' => $this->formatSettings($settings, true)]);
    }

    public function adminSuspend(Request $request): Response
    {
        return $this->adminStatusAction($request, 'suspended', [
            'messages_enabled' => false,
        ]);
    }

    public function adminResume(Request $request): Response
    {
        return $this->adminStatusAction($request, 'enabled', [
            'whatsapp_enabled' => true,
        ]);
    }

    public function adminDisable(Request $request): Response
    {
        return $this->adminStatusAction($request, 'not_enabled', [
            'whatsapp_enabled' => false,
        ]);
    }

    private function adminStatusAction(Request $request, string $status, array $overrides): Response
    {
        if (!$this->isSuperadmin($request)) {
            return Response::error('Solo superadmin', 'forbidden', 403, $request->traceId);
        }

        $businessId = (int) $request->getAttribute('business_id');
        $body = array_merge($request->getBody() ?? [], $overrides, ['status' => $status]);
        $settings = $this->settingsRepo->upsertByAdmin(
            $businessId,
            (int) $request->getAttribute('user_id'),
            $body
        );

        return Response::success(['settings' => $this->formatSettings($settings, true)]);
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

    private function isSuperadmin(Request $request): bool
    {
        $userId = $request->getAttribute('user_id');
        return $userId !== null && $this->userRepo->isSuperadmin((int) $userId);
    }

    private function formatAdminRow(array $row): array
    {
        $settings = $this->formatSettings($row, true);

        return [
            'business' => [
                'id' => (int) $row['business_id'],
                'name' => (string) ($row['business_name'] ?? ''),
                'slug' => (string) ($row['business_slug'] ?? ''),
            ],
            'settings' => $settings,
            'default_config' => isset($row['default_config_id']) && $row['default_config_id'] !== null
                ? [
                    'id' => (int) $row['default_config_id'],
                    'status' => $row['default_config_status'] ?? null,
                    'display_phone_number' => $this->mask((string) ($row['display_phone_number'] ?? '')),
                    'phone_number_id' => $this->mask((string) ($row['phone_number_id'] ?? '')),
                ]
                : null,
            'outbox_30d' => [
                'total' => (int) ($row['outbox_30d_count'] ?? 0),
                'failed' => (int) ($row['outbox_30d_failed_count'] ?? 0),
            ],
        ];
    }

    private function formatSettings(array $row, bool $includeInternal): array
    {
        $data = [
            'id' => isset($row['id']) && $row['id'] !== null ? (int) $row['id'] : null,
            'business_id' => (int) $row['business_id'],
            'provider_code' => (string) ($row['provider_code'] ?? 'meta'),
            'whatsapp_enabled' => ((int) ($row['whatsapp_enabled'] ?? 0)) === 1,
            'messages_enabled' => ((int) ($row['messages_enabled'] ?? 0)) === 1,
            'business_messages_enabled' => ((int) ($row['business_messages_enabled'] ?? 1)) === 1,
            'effective_messages_enabled' => ((int) ($row['whatsapp_enabled'] ?? 0)) === 1
                && ((int) ($row['messages_enabled'] ?? 0)) === 1
                && ((int) ($row['business_messages_enabled'] ?? 1)) === 1,
            'allow_location_mapping' => ((int) ($row['allow_location_mapping'] ?? 0)) === 1,
            'default_channel_mode' => (string) ($row['default_channel_mode'] ?? 'business_default'),
            'existing_clients_opt_in_policy' => (string) ($row['existing_clients_opt_in_policy'] ?? 'explicit_only'),
            'existing_clients_opt_in_assumed_at' => $row['existing_clients_opt_in_assumed_at'] ?? null,
            'status' => (string) ($row['status'] ?? 'not_enabled'),
            'last_go_live_check_at' => $row['last_go_live_check_at'] ?? null,
            'last_error_code' => $row['last_error_code'] ?? null,
            'last_error_message' => $row['last_error_message'] ?? null,
            'enabled_at' => $row['enabled_at'] ?? null,
            'disabled_at' => $row['disabled_at'] ?? null,
            'created_at' => $row['created_at'] ?? null,
            'updated_at' => $row['updated_at'] ?? null,
        ];

        if ($includeInternal) {
            $data['enabled_by_user_id'] = isset($row['enabled_by_user_id']) && $row['enabled_by_user_id'] !== null
                ? (int) $row['enabled_by_user_id']
                : null;
            $data['notes'] = $row['notes'] ?? null;
        }

        return $data;
    }

    private function mask(string $value): ?string
    {
        $value = trim($value);
        if ($value === '') {
            return null;
        }
        if (mb_strlen($value) <= 6) {
            return str_repeat('*', mb_strlen($value));
        }

        return mb_substr($value, 0, 3) . '...' . mb_substr($value, -3);
    }
}
