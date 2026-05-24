<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers\Billing;

use Agenda\Domain\Billing\BillingProviderCode;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingConfigRepository;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingSubscriptionRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class AdminBusinessBillingController
{
    public function __construct(
        private readonly BusinessRepository $businessRepository,
        private readonly UserRepository $userRepository,
        private readonly BusinessBillingConfigRepository $configRepository,
        private readonly BusinessBillingSubscriptionRepository $subscriptionRepository,
    ) {}

    public function show(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('businessId');
        if (!$this->isSuperadmin($request)) {
            return Response::forbidden('Superadmin access required', $request->traceId);
        }
        if ($this->businessRepository->findById($businessId) === null) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $config = $this->configRepository->findOrCreateByBusinessId($businessId);
        $subscription = $this->subscriptionRepository->findByBusinessId($businessId);

        return Response::success($this->formatConfig($config->toArray(), $subscription));
    }

    public function update(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('businessId');
        if (!$this->isSuperadmin($request)) {
            return Response::forbidden('Superadmin access required', $request->traceId);
        }
        if ($this->businessRepository->findById($businessId) === null) {
            return Response::notFound('Business not found', $request->traceId);
        }

        $body = $request->getBody() ?? [];
        $enabled = $this->parseBool($body['billing_enabled'] ?? false);

        // Validate activation_deadline_at if provided
        $activationDeadlineAt = null;
        if (isset($body['activation_deadline_at']) && $body['activation_deadline_at'] !== null && $body['activation_deadline_at'] !== '') {
            try {
                $deadlineDt = new \DateTimeImmutable((string) $body['activation_deadline_at'], new \DateTimeZone('UTC'));
                $activationDeadlineAt = $deadlineDt->format(\DateTimeInterface::ATOM);
            } catch (\Throwable) {
                return Response::validationError('activation_deadline_at is not a valid date', $request->traceId);
            }
        }

        $payload = [
            'billing_enabled' => $enabled,
            'amount_cents' => isset($body['amount_cents']) ? (int) $body['amount_cents'] : null,
            'currency' => 'EUR',
            'provider_code' => $enabled ? BillingProviderCode::STRIPE : null,
            'activation_deadline_at' => $activationDeadlineAt,
            'notes' => $body['notes'] ?? null,
        ];

        try {
            $config = $this->configRepository->upsertConfig($businessId, $payload);
        } catch (\InvalidArgumentException $e) {
            return Response::validationError($e->getMessage(), $request->traceId);
        }

        if (!$config->billingEnabled) {
            $this->subscriptionRepository->markNotRequired($businessId);
        } else {
            $this->subscriptionRepository->findOrCreateByBusinessId($businessId);
        }

        $subscription = $this->subscriptionRepository->findByBusinessId($businessId);

        return Response::success($this->formatConfig($config->toArray(), $subscription));
    }

    private function isSuperadmin(Request $request): bool
    {
        $userId = $request->userId();
        return $userId !== null && $this->userRepository->isSuperadmin($userId);
    }

    private function parseBool(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }
        if (is_numeric($value)) {
            return (int) $value === 1;
        }

        return in_array(strtolower(trim((string) $value)), ['1', 'true', 'yes', 'on'], true);
    }

    private function formatConfig(array $config, mixed $subscription): array
    {
        return [
            'business_id' => $config['business_id'],
            'billing_enabled' => $config['billing_enabled'],
            'billing_mode' => $config['billing_mode'],
            'billing_interval_unit' => $config['billing_interval_unit'],
            'billing_interval_count' => $config['billing_interval_count'],
            'amount_cents' => $config['amount_cents'],
            'currency' => $config['currency'],
            'provider_code' => $config['provider_code'],
            'provider_price_reference' => $config['provider_price_reference'],
            'activation_deadline_at' => $config['activation_deadline_at'],
            'notes' => $config['notes'],
            'subscription_status' => $subscription?->status,
            'current_period_end' => $subscription?->currentPeriodEnd,
        ];
    }
}
