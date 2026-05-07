<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers\Billing;

use Agenda\Domain\Billing\BillingMode;
use Agenda\Domain\Billing\BillingProviderFactory;
use Agenda\Domain\Billing\BillingSubscription;
use Agenda\Domain\Billing\BillingSubscriptionStatus;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingConfigRepository;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingSubscriptionRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class BusinessBillingController
{
    public function __construct(
        private readonly BusinessRepository $businessRepository,
        private readonly BusinessUserRepository $businessUserRepository,
        private readonly UserRepository $userRepository,
        private readonly BusinessBillingConfigRepository $configRepository,
        private readonly BusinessBillingSubscriptionRepository $subscriptionRepository,
        private readonly BillingProviderFactory $providerFactory,
    ) {}

    public function subscription(Request $request): Response
    {
        $businessId = $this->businessId($request);
        if ($businessId === null) {
            return Response::badRequest('business_id is required', $request->traceId);
        }
        if (!$this->hasAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $config = $this->configRepository->findOrCreateByBusinessId($businessId);
        $subscription = $this->subscriptionRepository->findByBusinessId($businessId);
        if (!$config->billingEnabled) {
            return Response::success($this->formatState($config, null));
        }

        $subscription ??= $this->subscriptionRepository->findOrCreateByBusinessId($businessId);
        if ($this->isCheckoutCancelReturn($request) && $this->isPendingCheckoutWithoutSubscription($subscription)) {
            $this->subscriptionRepository->markAbandonedPendingCheckoutInactive($businessId);
            $subscription = $this->subscriptionRepository->findOrCreateByBusinessId($businessId);
        }

        return Response::success($this->formatState($config, $subscription));
    }

    public function checkoutSession(Request $request): Response
    {
        $businessId = $this->businessId($request);
        if ($businessId === null) {
            return Response::badRequest('business_id is required', $request->traceId);
        }
        if (!$this->hasAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $business = $this->businessRepository->findById($businessId);
        $config = $this->configRepository->findOrCreateByBusinessId($businessId);
        if (!$config->billingEnabled) {
            return Response::conflict('billing_not_required', 'Billing is not required for this business', $request->traceId);
        }
        if ($config->billingMode !== BillingMode::RECURRING || $config->amountCents === null || $config->providerCode === null) {
            return Response::validationError('Billing configuration is not valid', $request->traceId);
        }

        $subscription = $this->subscriptionRepository->findOrCreateByBusinessId($businessId);
        if ($this->hasManageableSubscription($subscription)) {
            return Response::conflict(
                'subscription_already_exists',
                'Subscription already exists for this business',
                $request->traceId
            );
        }

        try {
            $provider = $this->providerFactory->get($config->providerCode);
            $result = $provider->createSubscriptionCheckout($config, $subscription, [
                'business_name' => $business['name'] ?? null,
                'business_email' => $business['email'] ?? null,
                'success_url' => $this->frontendUrl('/altro/abbonamento?billing=success'),
                'cancel_url' => $this->frontendUrl('/altro/abbonamento?billing=cancel'),
            ]);
        } catch (\InvalidArgumentException $e) {
            return Response::validationError($e->getMessage(), $request->traceId);
        }

        $this->subscriptionRepository->updateAfterCheckoutCreation(
            $businessId,
            $config->providerCode,
            $result['provider_customer_id'] ?? null,
            $result['provider_subscription_id'] ?? null,
            $result['provider_price_reference'] ?? $config->providerPriceReference,
            $result['checkout_session_id'] ?? null,
        );

        return Response::success(['url' => (string) $result['url']]);
    }

    private function hasManageableSubscription(BillingSubscription $subscription): bool
    {
        if (
            $subscription->status === BillingSubscriptionStatus::ACTIVE
            && $subscription->cancelAtPeriodEnd
        ) {
            return true;
        }

        if ($subscription->providerSubscriptionId === null || $subscription->providerSubscriptionId === '') {
            return false;
        }

        return in_array($subscription->status, [
            BillingSubscriptionStatus::ACTIVE,
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            BillingSubscriptionStatus::PAST_DUE,
            BillingSubscriptionStatus::UNPAID,
        ], true);
    }

    public function portalSession(Request $request): Response
    {
        $businessId = $this->businessId($request);
        if ($businessId === null) {
            return Response::badRequest('business_id is required', $request->traceId);
        }
        if (!$this->hasAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $config = $this->configRepository->findOrCreateByBusinessId($businessId);
        $subscription = $this->subscriptionRepository->findByBusinessId($businessId);
        if (!$config->billingEnabled || $subscription === null) {
            return Response::conflict('billing_not_available', 'Billing portal is not available', $request->traceId);
        }

        try {
            $result = $this->providerFactory->get((string) $config->providerCode)->createCustomerPortal($config, $subscription, [
                'return_url' => $this->frontendUrl('/altro/abbonamento'),
            ]);
        } catch (\InvalidArgumentException $e) {
            return Response::validationError($e->getMessage(), $request->traceId);
        }

        return Response::success(['url' => (string) $result['url']]);
    }

    private function businessId(Request $request): ?int
    {
        $value = $request->queryParam('business_id') ?? $request->getHeader('x-business-id');
        return is_numeric($value) && (int) $value > 0 ? (int) $value : null;
    }

    private function hasAccess(Request $request, int $businessId): bool
    {
        $userId = $request->userId();
        if ($userId === null) {
            return false;
        }
        if ($this->userRepository->isSuperadmin($userId)) {
            return true;
        }

        return $this->businessUserRepository->hasAccess($userId, $businessId, false);
    }

    private function formatState(mixed $config, mixed $subscription): array
    {
        $status = $config->billingEnabled
            ? ($subscription?->status ?? BillingSubscriptionStatus::INACTIVE)
            : BillingSubscriptionStatus::NOT_REQUIRED;
        if ($subscription !== null && $this->isPendingCheckoutWithoutSubscription($subscription)) {
            $status = BillingSubscriptionStatus::INACTIVE;
        }

        return [
            'billing_enabled' => $config->billingEnabled,
            'billing_mode' => $config->billingMode,
            'billing_interval_unit' => $config->billingIntervalUnit,
            'billing_interval_count' => $config->billingIntervalCount,
            'amount_cents' => $config->amountCents,
            'currency' => $config->currency,
            'provider_code' => $config->providerCode,
            'provider_price_reference' => $config->providerPriceReference,
            'provider_customer_id' => $subscription?->providerCustomerId,
            'provider_subscription_id' => $subscription?->providerSubscriptionId,
            'status' => $status,
            'current_period_start' => $subscription?->currentPeriodStart,
            'current_period_end' => $subscription?->currentPeriodEnd,
            'cancel_at_period_end' => $subscription?->cancelAtPeriodEnd ?? false,
            'canceled_at' => $subscription?->canceledAt,
            'last_payment_at' => $subscription?->lastPaymentAt,
            'last_payment_failed_at' => $subscription?->lastPaymentFailedAt,
            'can_start_checkout' => $config->billingEnabled && $this->canStartCheckout($status, $subscription),
            'can_open_portal' => $config->billingEnabled && ($subscription?->providerCustomerId !== null),
        ];
    }

    private function isCheckoutCancelReturn(Request $request): bool
    {
        return in_array((string) $request->queryParam('checkout_cancelled'), ['1', 'true'], true);
    }

    private function isPendingCheckoutWithoutSubscription(BillingSubscription $subscription): bool
    {
        return $subscription->status === BillingSubscriptionStatus::PENDING_CHECKOUT
            && ($subscription->providerSubscriptionId === null || $subscription->providerSubscriptionId === '')
            && $subscription->lastCheckoutSessionId !== null
            && $subscription->lastCheckoutSessionId !== '';
    }

    private function canStartCheckout(string $status, ?BillingSubscription $subscription): bool
    {
        if ($subscription === null) {
            return true;
        }

        if ($this->hasManageableSubscription($subscription)) {
            return false;
        }

        if (in_array($status, [
            BillingSubscriptionStatus::INACTIVE,
            BillingSubscriptionStatus::CANCELED,
            BillingSubscriptionStatus::ERROR,
        ], true)) {
            return true;
        }

        return $subscription?->providerSubscriptionId === null || $subscription?->providerSubscriptionId === '';
    }

    private function frontendUrl(string $path): string
    {
        $base = rtrim((string) ($_ENV['BACKEND_URL'] ?? getenv('BACKEND_URL') ?: 'https://gestionale.romeolab.it'), '/');
        return $base . $path;
    }
}
