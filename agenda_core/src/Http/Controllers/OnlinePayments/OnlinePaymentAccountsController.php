<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers\OnlinePayments;

use Agenda\Domain\OnlinePayments\OnlinePaymentProviderCode;
use Agenda\Domain\OnlinePayments\OnlinePaymentProviderInterface;
use Agenda\Domain\OnlinePayments\OnlinePaymentWebhookResult;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Environment\EnvironmentPolicy;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\OnlinePayments\BusinessOnlinePaymentAccountRepository;
use Agenda\Infrastructure\Repositories\OnlinePayments\OnlineBookingPaymentRepository;
use Agenda\Infrastructure\Repositories\OnlinePayments\OnlinePaymentProviderEventRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\UseCases\Notifications\QueueBookingConfirmation;
use Agenda\UseCases\Notifications\QueueBookingReminder;
use Agenda\UseCases\Notifications\QueueClassBookingNotification;

final class OnlinePaymentAccountsController
{
    /**
     * @param array<string, OnlinePaymentProviderInterface> $providers
     */
    public function __construct(
        private readonly Connection $db,
        private readonly BusinessOnlinePaymentAccountRepository $accounts,
        private readonly OnlineBookingPaymentRepository $payments,
        private readonly OnlinePaymentProviderEventRepository $events,
        private readonly BusinessUserRepository $businessUsers,
        private readonly UserRepository $users,
        private readonly array $providers,
        private readonly ?BookingRepository $bookingRepo = null,
        private readonly ?LocationRepository $locationRepo = null,
        private readonly ?ClientRepository $clientRepo = null,
        private readonly ?NotificationRepository $notificationRepo = null,
        private readonly ?QueueClassBookingNotification $queueClassBookingNotification = null,
    ) {}

    public function stripeWebhook(Request $request): Response
    {
        $provider = $this->providers[OnlinePaymentProviderCode::STRIPE] ?? null;
        if (!$provider instanceof OnlinePaymentProviderInterface) {
            return Response::error('Stripe online payment provider is not available', 'online_payment_provider_not_configured', 400, $request->traceId);
        }

        try {
            $result = $provider->handleWebhook($request);
        } catch (\Throwable) {
            return Response::error('Invalid online payment webhook signature', 'online_payment_webhook_invalid_signature', 400, $request->traceId);
        }

        $isNew = $this->events->storeProcessedEvent($result);
        if (!$isNew) {
            return Response::success(['duplicate' => true]);
        }

        return match ($result->eventType) {
            'account.updated' => $this->handleAccountUpdated($result),
            'capability.updated' => $this->handleCapabilityUpdated($result, $provider),
            'account.application.deauthorized' => $this->handleAccountDeauthorized($result),
            default => $this->handlePaymentEvent($result),
        };
    }

    private function handleAccountUpdated(OnlinePaymentWebhookResult $result): Response
    {
        $providerAccountId = (string) ($result->rawPayload['account'] ?? '');
        if ($providerAccountId === '') {
            return Response::success(['processed' => true, 'account_found' => false]);
        }

        $mode = $this->mode();
        $account = $this->accounts->findByProviderAccountId($providerAccountId, $mode);
        if ($account === null) {
            return Response::success(['processed' => true, 'account_found' => false]);
        }

        $raw = is_array($result->rawPayload['data']['object'] ?? null) ? $result->rawPayload['data']['object'] : [];
        $requirements = is_array($raw['requirements'] ?? null) ? $raw['requirements'] : [];
        $currentlyDue = $requirements['currently_due'] ?? [];
        $pastDue = $requirements['past_due'] ?? [];
        $disabledReason = $requirements['disabled_reason'] ?? null;
        $chargesEnabled = (bool) ($raw['charges_enabled'] ?? false);
        $payoutsEnabled = (bool) ($raw['payouts_enabled'] ?? false);
        $detailsSubmitted = (bool) ($raw['details_submitted'] ?? false);
        $status = $chargesEnabled && empty($currentlyDue) && empty($pastDue) && $disabledReason === null
            ? 'active'
            : ($detailsSubmitted ? 'restricted' : 'pending');

        $this->accounts->syncCapabilities(
            $account->businessId,
            $account->providerCode,
            $mode,
            $chargesEnabled,
            $payoutsEnabled,
            $detailsSubmitted,
            is_array($raw['capabilities'] ?? null) ? $raw['capabilities'] : null,
            $requirements,
            $status,
            $providerAccountId,
            null,
            $disabledReason !== null ? 'stripe_requirements_due' : null,
            is_string($disabledReason) ? $disabledReason : null,
        );

        return Response::success(['processed' => true]);
    }

    private function handleCapabilityUpdated(OnlinePaymentWebhookResult $result, OnlinePaymentProviderInterface $provider): Response
    {
        $providerAccountId = (string) ($result->rawPayload['account'] ?? '');
        if ($providerAccountId === '') {
            return Response::success(['processed' => true, 'account_found' => false]);
        }

        $mode = $this->mode();
        $account = $this->accounts->findByProviderAccountId($providerAccountId, $mode);
        if ($account === null) {
            return Response::success(['processed' => true, 'account_found' => false]);
        }

        $statusResult = $provider->refreshAccountStatus($account);
        $this->accounts->syncCapabilities(
            $account->businessId,
            $account->providerCode,
            $mode,
            $statusResult->chargesEnabled,
            $statusResult->payoutsEnabled,
            $statusResult->detailsSubmitted,
            $statusResult->capabilities,
            $statusResult->requirements,
            $statusResult->status,
            $statusResult->providerAccountId,
            $statusResult->providerMerchantId,
            $statusResult->errorCode,
            $statusResult->errorMessage,
        );

        return Response::success(['processed' => true]);
    }

    private function handleAccountDeauthorized(OnlinePaymentWebhookResult $result): Response
    {
        $providerAccountId = (string) ($result->rawPayload['account'] ?? '');
        if ($providerAccountId === '') {
            return Response::success(['processed' => true, 'account_found' => false]);
        }

        $mode = $this->mode();
        $account = $this->accounts->findByProviderAccountId($providerAccountId, $mode);
        if ($account === null) {
            return Response::success(['processed' => true, 'account_found' => false]);
        }

        $this->accounts->disable($account->businessId, $account->providerCode, $mode);

        return Response::success(['processed' => true]);
    }

    private function handlePaymentEvent(OnlinePaymentWebhookResult $result): Response
    {
        $payment = $result->onlineBookingPaymentId !== null
            ? $this->payments->findById($result->onlineBookingPaymentId)
            : ($result->providerCheckoutId !== null
                ? $this->payments->findByProviderCheckoutId($result->providerCode, $result->providerCheckoutId)
                : null);
        if ($payment === null) {
            return Response::success(['processed' => true, 'payment_found' => false]);
        }

        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();
        try {
            match ($result->targetStatus) {
                'paid' => $this->payments->markPaid($payment->id, $result->providerPaymentId, $result->rawPayload),
                'failed' => $this->payments->markFailed($payment->id, $result->rawPayload),
                'expired' => $this->payments->markExpired($payment->id, $result->rawPayload),
                'cancelled' => $this->payments->markCancelled($payment->id, $result->rawPayload),
                default => null,
            };

            $shouldQueueBookingNotifications = false;
            $shouldQueueClassNotification = false;

            if ($result->targetStatus === 'paid') {
                if ($payment->bookingId !== null) {
                    $stmt = $pdo->prepare("UPDATE bookings SET status = 'confirmed', updated_at = NOW() WHERE id = ? AND status = 'pending_payment'");
                    $stmt->execute([$payment->bookingId]);
                    $shouldQueueBookingNotifications = $stmt->rowCount() > 0;
                }
                if ($payment->classBookingId !== null) {
                    $stmt = $pdo->prepare("UPDATE class_bookings SET status = 'CONFIRMED', updated_at = NOW() WHERE id = ? AND status = 'PENDING_PAYMENT'");
                    $stmt->execute([$payment->classBookingId]);
                    $shouldQueueClassNotification = $stmt->rowCount() > 0;
                }
            }

            if (in_array($result->targetStatus, ['failed', 'expired', 'cancelled'], true)) {
                if ($payment->bookingId !== null) {
                    $pdo->prepare("UPDATE bookings SET status = 'cancelled', updated_at = NOW() WHERE id = ? AND status = 'pending_payment'")->execute([$payment->bookingId]);
                }
                if ($payment->classBookingId !== null) {
                    $this->cancelPendingClassBooking($pdo, (int) $payment->classBookingId);
                }
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        if ($shouldQueueBookingNotifications && $payment->bookingId !== null) {
            $this->queueBookingNotifications((int) $payment->bookingId);
        }
        if ($shouldQueueClassNotification && $payment->classBookingId !== null) {
            $this->queueClassBookingNotification((int) $payment->classBookingId, (int) $payment->businessId);
        }

        return Response::success(['processed' => true]);
    }

    public function status(Request $request): Response
    {
        $paymentId = (int) $request->getRouteParam('payment_id');
        $payment = $this->payments->findById($paymentId);
        if ($payment === null) {
            return Response::notFound('Online booking payment not found', $request->traceId);
        }
        if (!$this->customerOwnsPayment($request, $payment->bookingId, $payment->classBookingId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        // Riconcilia con Stripe se il webhook non è ancora arrivato.
        if (
            in_array($payment->status, ['pending', 'requires_action'], true)
            && $payment->providerCheckoutId !== null
            && $payment->providerAccountId !== null
        ) {
            $provider = $this->providers[$payment->providerCode] ?? null;
            if ($provider instanceof OnlinePaymentProviderInterface) {
                try {
                    $stripeResult = $provider->retrievePaymentStatus($payment);
                    if ($stripeResult->status === 'paid') {
                        $pdo = $this->db->getPdo();
                        $pdo->beginTransaction();
                        try {
                            $this->payments->markPaid($payment->id, $stripeResult->providerPaymentId);
                            $shouldQueueNotifications = false;
                            if ($payment->bookingId !== null) {
                                $stmt = $pdo->prepare("UPDATE bookings SET status = 'confirmed', updated_at = NOW() WHERE id = ? AND status = 'pending_payment'");
                                $stmt->execute([$payment->bookingId]);
                                $shouldQueueNotifications = $stmt->rowCount() > 0;
                            }
                            if ($payment->classBookingId !== null) {
                                $pdo->prepare("UPDATE class_bookings SET status = 'CONFIRMED', updated_at = NOW() WHERE id = ? AND status = 'PENDING_PAYMENT'")->execute([$payment->classBookingId]);
                            }
                            $pdo->commit();
                        } catch (\Throwable $e) {
                            $pdo->rollBack();
                            throw $e;
                        }
                        if ($shouldQueueNotifications && $payment->bookingId !== null) {
                            $this->queueBookingNotifications((int) $payment->bookingId);
                        }
                        if ($payment->classBookingId !== null) {
                            $this->queueClassBookingNotification((int) $payment->classBookingId, (int) $payment->businessId);
                        }
                        $payment = $this->payments->findById($paymentId) ?? $payment;
                    } elseif ($stripeResult->status === 'expired') {
                        $pdo = $this->db->getPdo();
                        $pdo->beginTransaction();
                        try {
                            $this->payments->markExpired($payment->id);
                            if ($payment->bookingId !== null) {
                                $pdo->prepare("UPDATE bookings SET status = 'cancelled', updated_at = NOW() WHERE id = ? AND status = 'pending_payment'")->execute([$payment->bookingId]);
                            }
                            if ($payment->classBookingId !== null) {
                                $this->cancelPendingClassBooking($pdo, (int) $payment->classBookingId);
                            }
                            $pdo->commit();
                        } catch (\Throwable $e) {
                            $pdo->rollBack();
                        }
                        $payment = $this->payments->findById($paymentId) ?? $payment;
                    }
                } catch (\Throwable) {
                    // Riconciliazione fallita: restituisci stato DB, l'utente può riprovare.
                }
            }
        }

        $bookingStatus = null;
        if ($payment->bookingId !== null) {
            $stmt = $this->db->getPdo()->prepare('SELECT status FROM bookings WHERE id = ?');
            $stmt->execute([$payment->bookingId]);
            $bookingStatus = $stmt->fetchColumn() ?: null;
        }
        $classBookingStatus = null;
        if ($payment->classBookingId !== null) {
            $stmt = $this->db->getPdo()->prepare('SELECT status FROM class_bookings WHERE id = ?');
            $stmt->execute([$payment->classBookingId]);
            $classBookingStatus = $stmt->fetchColumn() ?: null;
        }

        $effectiveBookingStatus = $bookingStatus ?? $classBookingStatus;
        $canRetry = in_array($payment->status, ['pending', 'failed', 'cancelled'], true)
            && ($bookingStatus === 'pending_payment' || $classBookingStatus === 'PENDING_PAYMENT');

        return Response::success([
            'status' => $payment->status,
            'booking_status' => $effectiveBookingStatus,
            'amount_cents' => $payment->amountCents,
            'currency' => $payment->currency,
            'can_retry' => $canRetry,
            'checkout_url' => $payment->checkoutUrl,
            'booking_id' => $payment->bookingId,
            'class_booking_id' => $payment->classBookingId,
        ]);
    }

    public function retry(Request $request): Response
    {
        $paymentId = (int) $request->getRouteParam('payment_id');
        $payment = $this->payments->findById($paymentId);
        if ($payment === null) {
            return Response::notFound('Online booking payment not found', $request->traceId);
        }
        if (!$this->customerOwnsPayment($request, $payment->bookingId, $payment->classBookingId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }
        if ($payment->status === 'paid') {
            return Response::error('Online payment is already paid', 'online_payment_already_paid', 409, $request->traceId);
        }
        if ($payment->providerAccountId === null) {
            return Response::error('Online payment cannot be retried', 'online_payment_status_unknown', 409, $request->traceId);
        }

        // Verifica che il booking/class booking sia ancora in attesa di pagamento.
        $canRetry = false;
        if ($payment->bookingId !== null) {
            $stmt = $this->db->getPdo()->prepare('SELECT status FROM bookings WHERE id = ?');
            $stmt->execute([$payment->bookingId]);
            $canRetry = ($stmt->fetchColumn() ?: null) === 'pending_payment';
        } elseif ($payment->classBookingId !== null) {
            $stmt = $this->db->getPdo()->prepare('SELECT status FROM class_bookings WHERE id = ?');
            $stmt->execute([$payment->classBookingId]);
            $canRetry = ($stmt->fetchColumn() ?: null) === 'PENDING_PAYMENT';
        }
        if (!$canRetry) {
            return Response::error('Online payment cannot be retried', 'online_payment_expired', 409, $request->traceId);
        }

        $provider = $this->providers[$payment->providerCode] ?? null;
        if (!$provider instanceof OnlinePaymentProviderInterface) {
            return Response::error('Online payment provider is not available', 'online_payment_provider_not_configured', 400, $request->traceId);
        }
        if (!EnvironmentPolicy::current()->canUseRealPayments()) {
            return Response::error('Real payments are disabled in this environment', 'demo_blocked', 403, $request->traceId);
        }

        $checkout = $provider->createCheckout(new \Agenda\Domain\OnlinePayments\OnlinePaymentCheckoutRequest(
            businessId: $payment->businessId,
            locationId: $payment->locationId,
            bookingId: $payment->bookingId,
            classBookingId: $payment->classBookingId,
            onlineBookingPaymentId: $payment->id,
            amountCents: $payment->amountCents,
            currency: $payment->currency,
            mode: $this->mode(),
            providerAccountId: $payment->providerAccountId,
            returnUrl: $payment->returnUrl ?? '',
            cancelUrl: $payment->cancelUrl ?? '',
            idempotencyKey: $request->getHeader('x-idempotency-key'),
        ));
        $this->payments->attachCheckout($payment->id, $checkout);

        return Response::success([
            'requires_payment' => true,
            'payment_id' => $payment->id,
            'provider_code' => $payment->providerCode,
            'checkout_url' => $checkout->checkoutUrl,
            'amount_cents' => $payment->amountCents,
            'currency' => $payment->currency,
            'booking_id' => $payment->bookingId,
            'status' => 'pending',
        ]);
    }

    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->canRead($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $mode = $this->mode();
        $items = [];
        foreach ([OnlinePaymentProviderCode::STRIPE] as $providerCode) {
            $account = $this->accounts->findByBusinessAndProvider($businessId, $providerCode, $mode);
            $items[] = [
                'provider_code' => $providerCode,
                'mode' => $mode,
                'is_enabled' => $account?->isEnabled ?? false,
                'onboarding_status' => $account?->onboardingStatus ?? 'not_configured',
                'charges_enabled' => $account?->chargesEnabled ?? false,
                'payouts_enabled' => $account?->payoutsEnabled ?? false,
                'details_submitted' => $account?->detailsSubmitted ?? false,
                'last_error_code' => $account?->lastErrorCode,
                'last_error_message' => $account?->lastErrorMessage,
            ];
        }

        return Response::success(['accounts' => $items]);
    }

    public function onboardingLink(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $providerCode = strtolower((string) $request->getRouteParam('provider_code'));
        if (!$this->canManage($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }
        if (!OnlinePaymentProviderCode::isValid($providerCode)) {
            return Response::error('Invalid online payment provider', 'online_payment_provider_invalid', 400, $request->traceId);
        }
        if ($providerCode !== OnlinePaymentProviderCode::STRIPE) {
            return Response::error('Online payment provider is not available', 'online_payment_provider_not_available', 409, $request->traceId);
        }
        if (!EnvironmentPolicy::current()->canUseRealPayments()) {
            return Response::error('Real payments are disabled in this environment', 'demo_blocked', 403, $request->traceId);
        }

        $provider = $this->providers[$providerCode] ?? null;
        if (!$provider instanceof OnlinePaymentProviderInterface) {
            return Response::error('Online payment provider is not available', 'online_payment_provider_not_configured', 400, $request->traceId);
        }

        try {
            $mode = $this->mode();
            $existingAccount = $this->accounts->findByBusinessAndProvider($businessId, $providerCode, $mode);
            $result = $provider->createOnboardingLink($businessId, $mode, $existingAccount?->providerAccountId);
            $this->accounts->upsertProviderAccount(
                $businessId,
                $providerCode,
                $mode,
                $result->providerAccountId,
                $result->providerMerchantId,
                $result->status,
            );
            // Imposta "pending" solo per account nuovi: per account esistenti
            // (active, restricted, disabled…) generare un nuovo link non deve
            // sovrascrivere lo stato reale — quello viene aggiornato solo da sync.
            // Aggiorna però sempre last_onboarding_url_created_at (dentro setOnboardingPending)
            // tramite la query separata qui sotto.
            if ($existingAccount === null) {
                $this->accounts->setOnboardingPending($businessId, $providerCode, $mode, $result->providerAccountId);
            } else {
                $this->accounts->markOnboardingStarted(
                    $businessId,
                    $providerCode,
                    $mode,
                    $result->providerAccountId,
                    $result->providerMerchantId,
                    $result->status,
                );
            }

            return Response::success([
                'provider_code' => $providerCode,
                'onboarding_url' => $result->onboardingUrl,
                'expires_at' => $result->expiresAt,
                'status' => $result->status,
            ], 201);
        } catch (\RuntimeException $e) {
            return Response::error($e->getMessage(), 'online_payment_provider_not_configured', 400, $request->traceId);
        }
    }

    public function sync(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $providerCode = strtolower((string) $request->getRouteParam('provider_code'));
        if (!$this->canManage($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }
        if (!OnlinePaymentProviderCode::isValid($providerCode)) {
            return Response::error('Invalid online payment provider', 'online_payment_provider_invalid', 400, $request->traceId);
        }
        if ($providerCode !== OnlinePaymentProviderCode::STRIPE) {
            return Response::error('Online payment provider is not available', 'online_payment_provider_not_available', 409, $request->traceId);
        }

        $mode = $this->mode();
        $account = $this->accounts->findByBusinessAndProvider($businessId, $providerCode, $mode);
        if ($account === null) {
            return Response::success([
                'provider_code' => $providerCode,
                'status' => 'not_configured',
                'charges_enabled' => false,
                'payouts_enabled' => false,
                'details_submitted' => false,
            ]);
        }

        $provider = $this->providers[$providerCode] ?? null;
        if (!$provider instanceof OnlinePaymentProviderInterface) {
            return Response::error('Online payment provider is not available', 'online_payment_provider_not_configured', 400, $request->traceId);
        }

        $result = $provider->refreshAccountStatus($account);
        $this->accounts->syncCapabilities(
            $businessId,
            $providerCode,
            $mode,
            $result->chargesEnabled,
            $result->payoutsEnabled,
            $result->detailsSubmitted,
            $result->capabilities,
            $result->requirements,
            $result->status,
            $result->providerAccountId,
            $result->providerMerchantId,
            $result->errorCode,
            $result->errorMessage,
        );

        return Response::success([
            'provider_code' => $providerCode,
            'status' => $result->status,
            'charges_enabled' => $result->chargesEnabled,
            'payouts_enabled' => $result->payoutsEnabled,
            'details_submitted' => $result->detailsSubmitted,
        ]);
    }

    public function update(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $providerCode = strtolower((string) $request->getRouteParam('provider_code'));
        if (!$this->canManage($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }
        if (!OnlinePaymentProviderCode::isValid($providerCode)) {
            return Response::error('Invalid online payment provider', 'online_payment_provider_invalid', 400, $request->traceId);
        }
        if ($providerCode !== OnlinePaymentProviderCode::STRIPE) {
            return Response::error('Online payment provider is not available', 'online_payment_provider_not_available', 409, $request->traceId);
        }
        $body = $request->getBody() ?? [];
        if (!array_key_exists('is_enabled', $body)) {
            return Response::error('is_enabled is required', 'validation_error', 400, $request->traceId);
        }

        $updated = $this->accounts->setEnabled($businessId, $providerCode, $this->mode(), (bool) $body['is_enabled']);
        if (!$updated) {
            return Response::error('Provider must be active before enabling', 'online_payment_provider_not_active', 409, $request->traceId);
        }

        return Response::success(['updated' => true]);
    }

    public function destroy(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $providerCode = strtolower((string) $request->getRouteParam('provider_code'));
        if (!$this->canManage($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }
        if (!OnlinePaymentProviderCode::isValid($providerCode)) {
            return Response::error('Invalid online payment provider', 'online_payment_provider_invalid', 400, $request->traceId);
        }
        if ($providerCode !== OnlinePaymentProviderCode::STRIPE) {
            return Response::error('Online payment provider is not available', 'online_payment_provider_not_available', 409, $request->traceId);
        }

        $this->accounts->disable($businessId, $providerCode, $this->mode());

        return Response::success(['disabled' => true]);
    }

    public function updateServiceVariant(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $variantId = (int) $request->getRouteParam('id');
        $body = $request->getBody() ?? [];
        return $this->updateTarget(
            $request,
            'service_variants',
            'id = ? AND location_id = ?',
            [$variantId, $locationId],
            'price',
            "SELECT sv.*, l.business_id FROM service_variants sv JOIN locations l ON l.id = sv.location_id WHERE sv.id = ? AND sv.location_id = ?",
            [$variantId, $locationId],
            (bool) ($body['online_payment_required'] ?? false),
        );
    }

    public function updateServicePackage(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('location_id');
        $packageId = (int) $request->getRouteParam('id');
        $body = $request->getBody() ?? [];
        return $this->updateTarget(
            $request,
            'service_packages',
            'id = ? AND location_id = ?',
            [$packageId, $locationId],
            'override_price',
            'SELECT * FROM service_packages WHERE id = ? AND location_id = ?',
            [$packageId, $locationId],
            (bool) ($body['online_payment_required'] ?? false),
        );
    }

    public function updateClassEvent(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $eventId = (int) $request->getRouteParam('id');
        $body = $request->getBody() ?? [];
        return $this->updateTarget(
            $request,
            'class_events',
            'id = ? AND business_id = ?',
            [$eventId, $businessId],
            'price_cents',
            'SELECT * FROM class_events WHERE id = ? AND business_id = ?',
            [$eventId, $businessId],
            (bool) ($body['online_payment_required'] ?? false),
            true,
        );
    }

    private function updateTarget(
        Request $request,
        string $table,
        string $where,
        array $whereParams,
        string $priceField,
        string $selectSql,
        array $selectParams,
        bool $required,
        bool $priceIsCents = false,
    ): Response {
        $stmt = $this->db->getPdo()->prepare($selectSql);
        $stmt->execute($selectParams);
        $target = $stmt->fetch();
        if (!$target) {
            return Response::notFound('Online payment target not found', $request->traceId);
        }

        $businessId = (int) ($target['business_id'] ?? 0);
        if (!$this->canManage($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        if ($required) {
            if (empty($this->accounts->findEnabledByBusiness($businessId, $this->mode()))) {
                return Response::error('Enable at least one active online payment provider first', 'online_payment_provider_not_active', 409, $request->traceId);
            }
            $rawPrice = $target[$priceField] ?? null;
            $amountCents = $priceIsCents ? (int) ($rawPrice ?? 0) : (int) round(((float) ($rawPrice ?? 0)) * 100);
            if ($amountCents <= 0) {
                return Response::error('Online payment requires a positive amount', 'online_payment_requires_positive_amount', 409, $request->traceId);
            }
        }

        $stmt = $this->db->getPdo()->prepare(
            "UPDATE {$table} SET online_payment_required = ?, updated_at = NOW() WHERE {$where}"
        );
        $stmt->execute(array_merge([$required ? 1 : 0], $whereParams));

        return Response::success(['online_payment_required' => $required]);
    }

    private function customerOwnsPayment(Request $request, ?int $bookingId, ?int $classBookingId = null): bool
    {
        $clientId = $request->getAttribute('client_id');
        if ($clientId === null) {
            return false;
        }
        if ($bookingId !== null) {
            $stmt = $this->db->getPdo()->prepare('SELECT 1 FROM bookings WHERE id = ? AND client_id = ? LIMIT 1');
            $stmt->execute([$bookingId, (int) $clientId]);
            if ((bool) $stmt->fetchColumn()) {
                return true;
            }
        }
        if ($classBookingId !== null) {
            $stmt = $this->db->getPdo()->prepare('SELECT 1 FROM class_bookings WHERE id = ? AND customer_id = ? LIMIT 1');
            $stmt->execute([$classBookingId, (int) $clientId]);
            if ((bool) $stmt->fetchColumn()) {
                return true;
            }
        }

        return false;
    }

    private function queueClassBookingNotification(int $classBookingId, int $businessId): void
    {
        if ($this->queueClassBookingNotification === null) {
            return;
        }
        try {
            $this->queueClassBookingNotification->execute($classBookingId, $businessId, 'class_booking_confirmed');
        } catch (\Throwable) {
            // Webhook processing must stay idempotent; notification retries are handled by the queue.
        }
    }

    private function cancelPendingClassBooking(\PDO $pdo, int $classBookingId): void
    {
        $row = $pdo->query("SELECT class_event_id, business_id FROM class_bookings WHERE id = {$classBookingId} LIMIT 1")->fetch(\PDO::FETCH_ASSOC);
        if (!$row) {
            return;
        }
        $stmt = $pdo->prepare("UPDATE class_bookings SET status = 'CANCELLED_BY_CUSTOMER', cancelled_at = NOW(), updated_at = NOW() WHERE id = ? AND status = 'PENDING_PAYMENT'");
        $stmt->execute([$classBookingId]);
        if ($stmt->rowCount() > 0) {
            // Libera il posto decrementing confirmed_count
            $pdo->prepare("UPDATE class_events SET confirmed_count = GREATEST(0, confirmed_count - 1), updated_at = NOW() WHERE id = ? AND business_id = ?")->execute([$row['class_event_id'], $row['business_id']]);
        }
    }

    private function queueBookingNotifications(int $bookingId): void
    {
        if ($this->bookingRepo === null || $this->locationRepo === null || $this->clientRepo === null || $this->notificationRepo === null) {
            return;
        }

        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null || empty($booking['client_id'])) {
            return;
        }
        $location = $this->locationRepo->findById((int) $booking['location_id']);
        $client = $this->clientRepo->findById((int) $booking['client_id']);
        if ($location === null || $client === null || empty($client['email'])) {
            return;
        }

        try {
            $clientName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));
            $locationEmail = trim((string) ($location['email'] ?? ''));
            $businessEmail = trim((string) ($location['business_email'] ?? ''));
            $businessName = trim((string) ($location['business_name'] ?? ''));
            $bookingItems = $booking['items'] ?? [];
            $lastItem = $bookingItems !== [] ? $bookingItems[count($bookingItems) - 1] : null;
            $notificationData = [
                'booking_id' => $bookingId,
                'client_id' => (int) $booking['client_id'],
                'client_email' => $client['email'],
                'client_name' => $clientName,
                'business_id' => (int) $booking['business_id'],
                'business_name' => $location['business_name'] ?? '',
                'business_email' => $location['business_email'] ?? '',
                'location_name' => $location['name'] ?? '',
                'location_email' => $location['email'] ?? '',
                'location_address' => $location['address'] ?? '',
                'location_city' => $location['city'] ?? '',
                'location_phone' => $location['phone'] ?? '',
                'location_timezone' => $location['timezone'] ?? 'Europe/Rome',
                'sender_email' => $locationEmail !== '' ? $locationEmail : ($businessEmail !== '' ? $businessEmail : null),
                'sender_name' => $businessName !== '' ? $businessName : null,
                'start_time' => $bookingItems[0]['start_time'] ?? $booking['created_at'],
                'end_time' => $lastItem['end_time'] ?? null,
                'services' => implode(', ', array_column($bookingItems, 'service_name')),
                'total_price' => $booking['total_price'] ?? 0,
                'location_show_price_to_customer' => (bool) ($location['show_price_to_customer'] ?? true),
                'cancellation_hours' => $location['cancellation_hours'] ?? 24,
                'manage_url' => ($_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it') . '/' . ($location['business_slug'] ?? '') . '/my-bookings',
                'booking_url' => ($_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it') . '/' . ($location['business_slug'] ?? '') . '/booking' . (!empty($location['id']) ? '?location=' . (int) $location['id'] : ''),
                'locale' => EmailTemplateRenderer::resolvePreferredLocale(null, $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? null, $_ENV['DEFAULT_LOCALE'] ?? 'it'),
            ];

            (new QueueBookingConfirmation($this->db, $this->notificationRepo))->execute($notificationData);
            (new QueueBookingReminder($this->db, $this->notificationRepo))->execute($notificationData);
        } catch (\Throwable) {
            // Webhook processing must stay idempotent; notification retries are handled by the queue.
        }
    }

    private function canRead(Request $request, int $businessId): bool
    {
        $userId = $request->userId();
        if ($userId === null) {
            return false;
        }
        return $this->users->isSuperadmin($userId)
            || $this->businessUsers->hasAccess($userId, $businessId, false);
    }

    private function canManage(Request $request, int $businessId): bool
    {
        $userId = $request->userId();
        if ($userId === null) {
            return false;
        }
        if ($this->users->isSuperadmin($userId)) {
            return true;
        }
        $role = $this->businessUsers->getRole($userId, $businessId);
        return in_array($role, ['owner', 'admin'], true);
    }

    private function mode(): string
    {
        return (($_ENV['APP_ENV'] ?? getenv('APP_ENV') ?: 'production') === 'production') ? 'live' : 'test';
    }
}
