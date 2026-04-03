<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessPaymentMethodRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class PaymentMethodsController
{
    private const RESERVED_CODES = ['discount'];

    public function __construct(
        private readonly BusinessPaymentMethodRepository $paymentMethodRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    public function index(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if ($businessId <= 0) {
            return Response::badRequest(['error' => 'business_id is required'], $request->traceId);
        }

        if (!$this->hasReadAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $includeInactiveRaw = (string) ($request->query['include_inactive'] ?? '0');
        $includeInactive = in_array(strtolower($includeInactiveRaw), ['1', 'true', 'yes'], true);

        $methods = $this->paymentMethodRepo->listByBusinessId($businessId, $includeInactive);

        return Response::success([
            'methods' => array_map([$this, 'formatMethod'], $methods),
        ]);
    }

    public function store(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        if ($businessId <= 0) {
            return Response::badRequest(['error' => 'business_id is required'], $request->traceId);
        }

        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            return Response::validationError('name is required', $request->traceId);
        }

        $rawCode = trim((string) ($body['code'] ?? ''));
        $baseCode = $rawCode !== '' ? $this->normalizeCode($rawCode) : $this->normalizeCode($name);
        if ($baseCode === '') {
            return Response::validationError('code is invalid', $request->traceId);
        }

        if (in_array($baseCode, self::RESERVED_CODES, true)) {
            return Response::validationError('code is reserved', $request->traceId);
        }

        $code = $this->nextAvailableCode($businessId, $baseCode);
        $sortOrder = isset($body['sort_order']) && is_int($body['sort_order'])
            ? (int) $body['sort_order']
            : ($this->paymentMethodRepo->countActiveByBusinessId($businessId) + 1) * 10;

        $created = $this->paymentMethodRepo->create([
            'business_id' => $businessId,
            'code' => $code,
            'name' => $name,
            'sort_order' => $sortOrder,
            'icon_key' => isset($body['icon_key']) ? trim((string) $body['icon_key']) : null,
            'updated_by_user_id' => $request->userId(),
        ]);

        return Response::success(['method' => $this->formatMethod($created)], 201);
    }

    public function update(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $methodId = (int) $request->getAttribute('id');

        if ($businessId <= 0 || $methodId <= 0) {
            return Response::badRequest(['error' => 'business_id and id are required'], $request->traceId);
        }

        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $existing = $this->paymentMethodRepo->findByIdInBusiness($businessId, $methodId);
        if ($existing === null) {
            return Response::notFound('Payment method not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            return Response::validationError('name is required', $request->traceId);
        }

        $sortOrder = isset($body['sort_order']) && is_int($body['sort_order'])
            ? (int) $body['sort_order']
            : (int) ($existing['sort_order'] ?? 0);

        $updated = $this->paymentMethodRepo->updateInBusiness($businessId, $methodId, [
            'name' => $name,
            'sort_order' => $sortOrder,
            'icon_key' => isset($body['icon_key']) ? trim((string) $body['icon_key']) : ($existing['icon_key'] ?? null),
            'updated_by_user_id' => $request->userId(),
        ]);

        if ($updated === null) {
            return Response::notFound('Payment method not found', $request->traceId);
        }

        return Response::success(['method' => $this->formatMethod($updated)]);
    }

    public function destroy(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');
        $methodId = (int) $request->getAttribute('id');

        if ($businessId <= 0 || $methodId <= 0) {
            return Response::badRequest(['error' => 'business_id and id are required'], $request->traceId);
        }

        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $existing = $this->paymentMethodRepo->findByIdInBusiness($businessId, $methodId);
        if ($existing === null) {
            return Response::notFound('Payment method not found', $request->traceId);
        }

        if (!(bool) ($existing['is_active'] ?? false)) {
            return Response::success(['deleted' => true]);
        }

        $activeCount = $this->paymentMethodRepo->countActiveByBusinessId($businessId);
        if ($activeCount <= 1) {
            return Response::validationError('At least one active payment method is required', $request->traceId);
        }

        $deleted = $this->paymentMethodRepo->deactivateInBusiness($businessId, $methodId, $request->userId());

        return Response::success(['deleted' => $deleted]);
    }

    private function hasReadAccess(Request $request, int $businessId): bool
    {
        $userId = $request->userId();
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    private function hasManageAccess(Request $request, int $businessId): bool
    {
        $userId = $request->userId();
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_services', false);
    }

    private function normalizeCode(string $value): string
    {
        $normalized = strtolower($value);
        $normalized = preg_replace('/[^a-z0-9]+/', '_', $normalized) ?? '';
        $normalized = trim($normalized, '_');

        if ($normalized === '') {
            return '';
        }

        return substr($normalized, 0, 40);
    }

    private function nextAvailableCode(int $businessId, string $baseCode): string
    {
        $candidate = $baseCode;
        $suffix = 2;

        while ($this->paymentMethodRepo->codeExistsInBusiness($businessId, $candidate)) {
            $candidate = substr($baseCode, 0, 35) . '_' . $suffix;
            $suffix++;
        }

        return $candidate;
    }

    /**
     * @param array<string,mixed> $method
     * @return array<string,mixed>
     */
    private function formatMethod(array $method): array
    {
        return [
            'id' => (int) ($method['id'] ?? 0),
            'business_id' => (int) ($method['business_id'] ?? 0),
            'code' => (string) ($method['code'] ?? ''),
            'name' => (string) ($method['name'] ?? ''),
            'sort_order' => (int) ($method['sort_order'] ?? 0),
            'icon_key' => $method['icon_key'] ?? null,
            'is_active' => (bool) ($method['is_active'] ?? false),
        ];
    }
}
