<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers\Billing;

use Agenda\Domain\Billing\BillingMode;
use Agenda\Domain\Billing\BillingProviderCode;
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
    private readonly BusinessRepository $businessRepository;
    private readonly BusinessUserRepository $businessUserRepository;
    private readonly UserRepository $userRepository;
    private readonly BusinessBillingConfigRepository $configRepository;
    private readonly BusinessBillingSubscriptionRepository $subscriptionRepository;
    private readonly BillingProviderFactory $providerFactory;

    public function __construct(
        BusinessRepository $businessRepository,
        BusinessUserRepository $businessUserRepository,
        UserRepository $userRepository,
        BusinessBillingConfigRepository $configRepository,
        BusinessBillingSubscriptionRepository $subscriptionRepository,
        BillingProviderFactory $providerFactory,
    ) {
        $this->businessRepository = $businessRepository;
        $this->businessUserRepository = $businessUserRepository;
        $this->userRepository = $userRepository;
        $this->configRepository = $configRepository;
        $this->subscriptionRepository = $subscriptionRepository;
        $this->providerFactory = $providerFactory;
    }

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

        $provider = $this->providerFactory->get($config->providerCode);
        $checkoutReserved = false;
        try {
            $this->subscriptionRepository->beginTransaction();
            $subscription = $this->subscriptionRepository->findOrCreateByBusinessIdForUpdate($businessId);
            if ($subscription->status === BillingSubscriptionStatus::ACTIVE) {
                $this->subscriptionRepository->rollback();
                return $this->portalSession($request);
            }
            if ($this->hasManageableSubscription($subscription)) {
                $this->subscriptionRepository->rollback();
                return $this->portalSession($request);
            }

            if ($subscription->status === BillingSubscriptionStatus::PENDING_CHECKOUT && $subscription->lastCheckoutSessionId === null) {
                if ($this->isRecentPendingCheckout($subscription)) {
                    $this->subscriptionRepository->rollback();
                    return Response::conflict(
                        'checkout_already_started',
                        'Checkout has already been started for this business',
                        $request->traceId
                    );
                }

                $this->subscriptionRepository->clearCheckoutReservation($businessId);
            }

            if ($subscription->status === BillingSubscriptionStatus::PENDING_CHECKOUT && $subscription->lastCheckoutSessionId !== null) {
                $existingSession = $provider->retrieveCheckoutSession($subscription->lastCheckoutSessionId);
                if ($existingSession === null) {
                    $this->subscriptionRepository->clearAbandonedCheckout($businessId);
                    $subscription = $this->subscriptionRepository->findOrCreateByBusinessIdForUpdate($businessId);
                } else {
                    $sessionStatus = (string) ($existingSession['status'] ?? '');
                    $paymentStatus = (string) ($existingSession['payment_status'] ?? '');
                    if ($sessionStatus === 'open' && ($existingSession['url'] ?? null) !== null) {
                        $this->subscriptionRepository->rollback();
                        return Response::success([
                            'provider' => $config->providerCode,
                            'purpose' => 'checkout',
                            'url' => (string) $existingSession['url'],
                            'session_id' => $subscription->lastCheckoutSessionId,
                            'expires_at' => null,
                        ]);
                    }
                    if (
                        $sessionStatus === 'expired'
                        || $sessionStatus === 'canceled'
                        || (in_array($sessionStatus, ['complete', 'completed'], true) && $paymentStatus !== 'paid')
                    ) {
                        $this->subscriptionRepository->clearAbandonedCheckout($businessId);
                    } elseif (in_array($sessionStatus, ['complete', 'completed'], true) && $paymentStatus === 'paid') {
                        $existingSubscription = $provider->findManageableSubscription($config, $subscription);
                        if ($existingSubscription !== null) {
                            $this->subscriptionRepository->syncManageableProviderSubscription(
                                $businessId,
                                $config->providerCode,
                                $existingSubscription,
                            );
                        }
                        $this->subscriptionRepository->commit();
                        return $this->portalSession($request);
                    } else {
                        $this->subscriptionRepository->rollback();
                        return Response::conflict(
                            'checkout_already_started',
                            'Checkout has already been started for this business',
                            $request->traceId
                        );
                    }
                }
            }

            if (!$this->subscriptionRepository->reserveCheckoutCreation(
                $businessId,
                $config->providerCode,
                $config->providerPriceReference,
            )) {
                $this->subscriptionRepository->rollback();
                return Response::conflict(
                    'checkout_already_started',
                    'Checkout has already been started for this business',
                    $request->traceId
                );
            }
            $this->subscriptionRepository->commit();
            $checkoutReserved = true;

            if ($subscription->providerCustomerId === null || $subscription->providerCustomerId === '') {
                $customer = $provider->createCustomer($config, [
                    'business_name' => $business['name'] ?? null,
                    'business_email' => $business['email'] ?? null,
                ]);
                $this->subscriptionRepository->updateProviderCustomerId(
                    $businessId,
                    $config->providerCode,
                    (string) $customer['provider_customer_id'],
                );
                $subscription = $this->subscriptionRepository->findByBusinessId($businessId)
                    ?? throw new \RuntimeException('Unable to load billing subscription');
            }

            $existingSubscription = $provider->findManageableSubscription($config, $subscription);
            if ($existingSubscription !== null) {
                $this->subscriptionRepository->syncManageableProviderSubscription(
                    $businessId,
                    $config->providerCode,
                    $existingSubscription,
                );
                $checkoutReserved = false;
                return $this->portalSession($request);
            }

            $result = $provider->createSubscriptionCheckout($config, $subscription, [
                'business_name' => $business['name'] ?? null,
                'business_email' => $business['email'] ?? null,
                'success_url' => $this->frontendUrl('/altro/abbonamento?billing=success'),
                'cancel_url' => $this->frontendUrl('/altro/abbonamento?billing=cancel'),
            ]);
            $this->subscriptionRepository->updateAfterCheckoutCreation(
                $businessId,
                $config->providerCode,
                $result['provider_customer_id'] ?? null,
                $result['provider_subscription_id'] ?? null,
                $result['provider_price_reference'] ?? $config->providerPriceReference,
                $result['checkout_session_id'] ?? null,
            );
            $checkoutReserved = false;
        } catch (\InvalidArgumentException $e) {
            $this->subscriptionRepository->rollback();
            if ($checkoutReserved) {
                $this->subscriptionRepository->clearCheckoutReservation($businessId);
            }
            return Response::validationError($e->getMessage(), $request->traceId);
        } catch (\Throwable $e) {
            $this->subscriptionRepository->rollback();
            if ($checkoutReserved) {
                $this->subscriptionRepository->clearCheckoutReservation($businessId);
            }
            throw $e;
        }

        return Response::success([
            'provider' => BillingProviderCode::STRIPE,
            'purpose' => 'checkout',
            'url' => (string) $result['url'],
            'session_id' => $result['checkout_session_id'] ?? null,
            'expires_at' => null,
        ]);
    }

    public function resumeCheckoutSession(Request $request): Response
    {
        $context = $this->pendingCheckoutContext($request);
        if ($context instanceof Response) {
            return $context;
        }

        [$businessId, $config, $subscription, $provider] = $context;
        $session = $provider->retrieveCheckoutSession((string) $subscription->lastCheckoutSessionId);
        if ($session === null) {
            return Response::conflict('checkout_already_started', 'Checkout has already been started for this business', $request->traceId);
        }

        $sessionStatus = (string) ($session['status'] ?? '');
        $paymentStatus = (string) ($session['payment_status'] ?? '');
        if ($sessionStatus === 'open' && ($session['url'] ?? null) !== null) {
            return Response::success([
                'provider' => (string) $config->providerCode,
                'purpose' => 'checkout',
                'url' => (string) $session['url'],
                'session_id' => $subscription->lastCheckoutSessionId,
                'expires_at' => null,
            ]);
        }
        if ($sessionStatus === 'expired' || $sessionStatus === 'canceled' || (in_array($sessionStatus, ['complete', 'completed'], true) && $paymentStatus !== 'paid')) {
            $this->subscriptionRepository->clearAbandonedCheckout($businessId);
            return Response::conflict('checkout_retryable', 'Checkout can be retried', $request->traceId);
        }
        if (in_array($sessionStatus, ['complete', 'completed'], true) && $paymentStatus === 'paid') {
            $this->syncExistingManageableSubscription($businessId, (string) $config->providerCode, $provider, $config, $subscription);
            return Response::conflict('subscription_already_exists', 'Subscription already exists for this business', $request->traceId);
        }

        return Response::conflict('checkout_already_started', 'Checkout has already been started for this business', $request->traceId);
    }

    public function cancelCheckoutSession(Request $request): Response
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
        if ($subscription === null || $subscription->status !== BillingSubscriptionStatus::PENDING_CHECKOUT) {
            return Response::success([
                'status' => $subscription?->status ?? BillingSubscriptionStatus::INACTIVE,
                'canceled_pending_checkout' => false,
            ]);
        }
        if (
            $subscription->lastPaymentAt !== null ||
            ($subscription->providerSubscriptionId !== null && $subscription->providerSubscriptionId !== '')
        ) {
            return Response::success([
                'status' => $subscription->status,
                'canceled_pending_checkout' => false,
            ]);
        }

        if ($subscription->lastCheckoutSessionId !== null && $subscription->lastCheckoutSessionId !== '') {
            $provider = $this->providerFactory->get((string) $config->providerCode);
            $session = $provider->retrieveCheckoutSession((string) $subscription->lastCheckoutSessionId);
            if ($session !== null) {
                $sessionStatus = (string) ($session['status'] ?? '');
                $paymentStatus = (string) ($session['payment_status'] ?? '');
                if (in_array($sessionStatus, ['complete', 'completed'], true) && $paymentStatus === 'paid') {
                    $this->syncExistingManageableSubscription($businessId, (string) $config->providerCode, $provider, $config, $subscription);
                    $updated = $this->subscriptionRepository->findByBusinessId($businessId);
                    return Response::success([
                        'status' => $updated?->status ?? $subscription->status,
                        'canceled_pending_checkout' => false,
                    ]);
                }
                if ($sessionStatus === 'open' && $provider->expireCheckoutSession((string) $subscription->lastCheckoutSessionId) === null) {
                    return Response::conflict('checkout_already_started', 'Checkout has already been started for this business', $request->traceId);
                }
            }
        }

        $this->subscriptionRepository->clearAbandonedCheckout($businessId);

        return Response::success([
            'status' => BillingSubscriptionStatus::INACTIVE,
            'canceled_pending_checkout' => true,
        ]);
    }

    /**
     * @return array{0:int,1:mixed,2:BillingSubscription,3:mixed}|Response
     */
    private function pendingCheckoutContext(Request $request): array|Response
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
        if (!$config->billingEnabled || $config->providerCode === null || $subscription === null) {
            return Response::conflict('billing_not_available', 'Billing is not available', $request->traceId);
        }
        if ($subscription->status !== BillingSubscriptionStatus::PENDING_CHECKOUT || $subscription->lastCheckoutSessionId === null || $subscription->lastCheckoutSessionId === '') {
            return Response::conflict('checkout_not_started', 'Checkout has not been started for this business', $request->traceId);
        }

        return [$businessId, $config, $subscription, $this->providerFactory->get((string) $config->providerCode)];
    }

    private function syncExistingManageableSubscription(int $businessId, string $providerCode, mixed $provider, mixed $config, BillingSubscription $subscription): void
    {
        $existingSubscription = $provider->findManageableSubscription($config, $subscription);
        if ($existingSubscription !== null) {
            $this->subscriptionRepository->syncManageableProviderSubscription($businessId, $providerCode, $existingSubscription);
        }
    }

    private function isRecentPendingCheckout(BillingSubscription $subscription): bool
    {
        if ($subscription->updatedAt === null || $subscription->updatedAt === '') {
            return true;
        }

        try {
            $updatedAt = new \DateTimeImmutable($subscription->updatedAt);
        } catch (\Throwable) {
            return true;
        }

        return $updatedAt > (new \DateTimeImmutable('-5 minutes'));
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

        if (
            in_array($subscription->status, [
                BillingSubscriptionStatus::PAST_DUE,
                BillingSubscriptionStatus::UNPAID,
            ], true)
            && $subscription->lastPaymentAt === null
        ) {
            return false;
        }

        return in_array($subscription->status, [
            BillingSubscriptionStatus::ACTIVE,
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

        return Response::success([
            'provider' => (string) $config->providerCode,
            'purpose' => 'portal',
            'url' => (string) $result['url'],
            'session_id' => $result['portal_session_id'] ?? null,
            'expires_at' => null,
        ]);
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
        $checkoutRetryable = $subscription !== null
            && $subscription->status === BillingSubscriptionStatus::PENDING_CHECKOUT
            && $subscription->lastPaymentAt === null
            && ($subscription->lastCheckoutSessionId === null || $subscription->lastCheckoutSessionId === '');
        $checkoutState = null;
        if ($subscription !== null && $subscription->status === BillingSubscriptionStatus::PENDING_CHECKOUT) {
            $checkoutState = $checkoutRetryable ? 'retryable' : 'prepared';
        }

        $activationDeadline = $config->activationDeadlineAt;
        $now = new \DateTimeImmutable('now', new \DateTimeZone('UTC'));
        $accessBlocked = false;
        if (
            $config->billingEnabled &&
            $config->billingMode === BillingMode::RECURRING &&
            !in_array($status, [BillingSubscriptionStatus::ACTIVE], true)
        ) {
            // Caso 1: attivazione iniziale mai completata e scadenza di attivazione superata.
            if ($activationDeadline !== null && $activationDeadline < $now) {
                $accessBlocked = true;
            }

            // Caso 2: periodo pagato terminato senza rinnovo attivo
            // (moroso past_due/unpaid, oppure cancellato dopo la fine del periodo).
            // Durante la finestra di retry di Stripe (periodo non ancora scaduto)
            // l'accesso resta consentito.
            if (!$accessBlocked && $subscription?->currentPeriodEnd !== null) {
                try {
                    $periodEnd = new \DateTimeImmutable(
                        (string) $subscription->currentPeriodEnd,
                        new \DateTimeZone('UTC')
                    );
                    if ($periodEnd < $now) {
                        $accessBlocked = true;
                    }
                } catch (\Throwable) {
                    // Data non parsabile: non blocchiamo per evitare falsi positivi.
                }
            }
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
            'last_checkout_session_id' => $subscription?->lastCheckoutSessionId,
            'checkout_retryable' => $checkoutRetryable,
            'checkout_state' => $checkoutState,
            'can_start_checkout' => $config->billingEnabled && $this->canStartCheckout($status, $subscription),
            'can_open_portal' => $config->billingEnabled && ($subscription?->providerCustomerId !== null),
            'access_blocked' => $accessBlocked,
            'activation_deadline_at' => $activationDeadline !== null
                ? $activationDeadline->setTimezone(new \DateTimeZone('UTC'))->format('Y-m-d\TH:i:s\Z')
                : null,
        ];
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
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            BillingSubscriptionStatus::CANCELED,
            BillingSubscriptionStatus::ERROR,
        ], true)) {
            return true;
        }

        if (
            in_array($status, [
                BillingSubscriptionStatus::PAST_DUE,
                BillingSubscriptionStatus::UNPAID,
            ], true)
            && $subscription->lastPaymentAt === null
        ) {
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
