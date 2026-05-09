<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\OnlinePayments\Stripe;

use Agenda\Domain\OnlinePayments\OnlineBookingPayment;
use Agenda\Domain\OnlinePayments\OnlinePaymentAccount;
use Agenda\Domain\OnlinePayments\OnlinePaymentAccountStatusResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentCheckoutRequest;
use Agenda\Domain\OnlinePayments\OnlinePaymentCheckoutResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentOnboardingResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentProviderCode;
use Agenda\Domain\OnlinePayments\OnlinePaymentProviderInterface;
use Agenda\Domain\OnlinePayments\OnlinePaymentStatus;
use Agenda\Domain\OnlinePayments\OnlinePaymentStatusResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentWebhookResult;
use Agenda\Http\Request;
use Stripe\Webhook;

final class StripeConnectOnlinePaymentProvider implements OnlinePaymentProviderInterface
{
    public function __construct(private readonly StripeConnectClientFactory $clientFactory) {}

    public function providerCode(): string
    {
        return OnlinePaymentProviderCode::STRIPE;
    }

    public function createOnboardingLink(int $businessId, string $mode): OnlinePaymentOnboardingResult
    {
        $client = $this->clientFactory->create();
        $account = $client->accounts->create([
            'type' => 'express',
            'metadata' => [
                'business_id' => (string) $businessId,
                'mode' => $mode,
                'feature' => 'online_booking_payments',
            ],
        ]);

        $returnUrl = $this->env('STRIPE_CONNECT_RETURN_URL', '');
        $refreshUrl = $this->env('STRIPE_CONNECT_REFRESH_URL', '');
        if ($returnUrl === '' || $refreshUrl === '') {
            throw new \RuntimeException('Stripe Connect return/refresh URLs are not configured');
        }

        $link = $client->accountLinks->create([
            'account' => $account->id,
            'refresh_url' => $refreshUrl,
            'return_url' => $returnUrl,
            'type' => 'account_onboarding',
        ]);

        return new OnlinePaymentOnboardingResult(
            providerCode: $this->providerCode(),
            onboardingUrl: (string) $link->url,
            expiresAt: isset($link->expires_at) ? gmdate('Y-m-d H:i:s', (int) $link->expires_at) : null,
            status: 'pending',
            providerAccountId: (string) $account->id,
        );
    }

    public function refreshAccountStatus(OnlinePaymentAccount $account): OnlinePaymentAccountStatusResult
    {
        if ($account->providerAccountId === null || $account->providerAccountId === '') {
            return new OnlinePaymentAccountStatusResult(
                status: 'not_configured',
                chargesEnabled: false,
                payoutsEnabled: false,
                detailsSubmitted: false,
                errorCode: 'online_payment_provider_not_configured',
                errorMessage: 'Stripe account is not configured',
            );
        }

        $stripeAccount = $this->clientFactory->create()->accounts->retrieve($account->providerAccountId, []);
        $raw = $stripeAccount->toArray();
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

        return new OnlinePaymentAccountStatusResult(
            status: $status,
            chargesEnabled: $chargesEnabled,
            payoutsEnabled: $payoutsEnabled,
            detailsSubmitted: $detailsSubmitted,
            capabilities: is_array($raw['capabilities'] ?? null) ? $raw['capabilities'] : null,
            requirements: $requirements,
            providerAccountId: (string) ($raw['id'] ?? $account->providerAccountId),
            errorCode: $disabledReason !== null ? 'stripe_requirements_due' : null,
            errorMessage: is_string($disabledReason) ? $disabledReason : null,
        );
    }

    public function createCheckout(OnlinePaymentCheckoutRequest $request): OnlinePaymentCheckoutResult
    {
        $successUrl = $this->withPaymentContext(
            $this->injectSlug($this->env('STRIPE_ONLINE_PAYMENT_SUCCESS_URL', $request->returnUrl), $request->businessSlug),
            $request->onlineBookingPaymentId,
            $request->bookingId,
        );
        $cancelUrl = $this->withPaymentContext(
            $this->injectSlug($this->env('STRIPE_ONLINE_PAYMENT_CANCEL_URL', $request->cancelUrl), $request->businessSlug),
            $request->onlineBookingPaymentId,
            $request->bookingId,
        );
        $metadata = [
            'business_id' => (string) $request->businessId,
            'location_id' => (string) $request->locationId,
            'online_booking_payment_id' => (string) $request->onlineBookingPaymentId,
            'provider_code' => $this->providerCode(),
            'mode' => $request->mode,
        ];
        if ($request->bookingId !== null) {
            $metadata['booking_id'] = (string) $request->bookingId;
        }
        if ($request->classBookingId !== null) {
            $metadata['class_booking_id'] = (string) $request->classBookingId;
        }

        $params = [
            'mode' => 'payment',
            'success_url' => $successUrl,
            'cancel_url' => $cancelUrl,
            'client_reference_id' => (string) $request->onlineBookingPaymentId,
            'line_items' => [[
                'quantity' => 1,
                'price_data' => [
                    'currency' => strtolower($request->currency),
                    'unit_amount' => $request->amountCents,
                    'product_data' => [
                        'name' => 'Prenotazione online',
                        'metadata' => $metadata,
                    ],
                ],
            ]],
            'payment_intent_data' => [
                'metadata' => $metadata,
            ],
            'metadata' => $metadata,
        ];

        $options = ['stripe_account' => $request->providerAccountId];
        if ($request->idempotencyKey !== null && $request->idempotencyKey !== '') {
            $options['idempotency_key'] = $request->idempotencyKey;
        }

        $session = $this->clientFactory->create()->checkout->sessions->create($params, $options);
        $raw = $session->toArray();

        return new OnlinePaymentCheckoutResult(
            providerCode: $this->providerCode(),
            providerCheckoutId: (string) ($raw['id'] ?? ''),
            providerPaymentId: isset($raw['payment_intent']) ? (string) $raw['payment_intent'] : null,
            providerOrderId: null,
            checkoutUrl: (string) ($raw['url'] ?? ''),
            expiresAt: isset($raw['expires_at']) ? gmdate('Y-m-d H:i:s', (int) $raw['expires_at']) : null,
            rawPayload: $raw,
        );
    }

    public function handleWebhook(Request $request): OnlinePaymentWebhookResult
    {
        $secret = $this->env('STRIPE_CONNECT_WEBHOOK_SECRET', '');
        if ($secret === '') {
            throw new \RuntimeException('STRIPE_CONNECT_WEBHOOK_SECRET is not configured');
        }

        $signature = $request->getHeader('stripe-signature') ?? '';
        $event = Webhook::constructEvent($request->rawBody, $signature, $secret);
        $eventArray = $event->toArray();
        $object = is_array($eventArray['data']['object'] ?? null) ? $eventArray['data']['object'] : [];
        $metadata = is_array($object['metadata'] ?? null) ? $object['metadata'] : [];
        $type = (string) ($eventArray['type'] ?? '');

        $targetStatus = match ($type) {
            'checkout.session.completed', 'payment_intent.succeeded', 'charge.succeeded' => OnlinePaymentStatus::PAID,
            'checkout.session.expired' => OnlinePaymentStatus::EXPIRED,
            'payment_intent.payment_failed', 'charge.failed' => OnlinePaymentStatus::FAILED,
            'charge.refunded' => OnlinePaymentStatus::REFUNDED,
            default => OnlinePaymentStatus::PENDING,
        };

        return new OnlinePaymentWebhookResult(
            providerCode: $this->providerCode(),
            providerEventId: (string) ($eventArray['id'] ?? ''),
            eventType: $type,
            businessId: isset($metadata['business_id']) ? (int) $metadata['business_id'] : null,
            onlineBookingPaymentId: isset($metadata['online_booking_payment_id']) ? (int) $metadata['online_booking_payment_id'] : null,
            providerCheckoutId: isset($object['id']) && ($object['object'] ?? '') === 'checkout.session' ? (string) $object['id'] : null,
            providerPaymentId: isset($object['payment_intent']) ? (string) $object['payment_intent'] : (isset($object['id']) ? (string) $object['id'] : null),
            targetStatus: $targetStatus,
            rawPayload: $eventArray,
        );
    }

    public function retrievePaymentStatus(OnlineBookingPayment $payment): OnlinePaymentStatusResult
    {
        if ($payment->providerCheckoutId === null || $payment->providerAccountId === null) {
            return new OnlinePaymentStatusResult(OnlinePaymentStatus::PENDING);
        }

        $session = $this->clientFactory->create()->checkout->sessions->retrieve(
            $payment->providerCheckoutId,
            [],
            ['stripe_account' => $payment->providerAccountId],
        );
        $raw = $session->toArray();
        $status = ($raw['payment_status'] ?? null) === 'paid'
            ? OnlinePaymentStatus::PAID
            : (($raw['status'] ?? null) === 'expired' ? OnlinePaymentStatus::EXPIRED : OnlinePaymentStatus::PENDING);

        return new OnlinePaymentStatusResult(
            status: $status,
            providerPaymentId: isset($raw['payment_intent']) ? (string) $raw['payment_intent'] : null,
            rawPayload: $raw,
        );
    }

    private function env(string $key, string $default): string
    {
        $value = $_ENV[$key] ?? getenv($key);
        if ($value === false || $value === null || trim((string) $value) === '') {
            return $default;
        }

        return trim((string) $value);
    }

    private function injectSlug(string $url, string $slug): string
    {
        if ($url === '' || $slug === '') {
            return $url;
        }

        if (str_contains($url, '{slug}')) {
            return str_replace('{slug}', rawurlencode($slug), $url);
        }

        // URL senza placeholder: inserisci lo slug nel path se la route è /payment-result
        // e il path non contiene già lo slug.
        $parsed = parse_url($url);
        $path = $parsed['path'] ?? '';
        // Se il path ha già lo slug, non modificare.
        $segments = explode('/', trim($path, '/'));
        if (in_array($slug, $segments, true)) {
            return $url;
        }

        // Ricostruisci l'URL inserendo lo slug prima del segmento terminale.
        $lastSegment = array_pop($segments);
        $newPath = '/' . implode('/', array_filter($segments)) . '/' . rawurlencode($slug) . '/' . $lastSegment;
        $scheme = isset($parsed['scheme']) ? $parsed['scheme'] . '://' : '';
        $host = $parsed['host'] ?? '';
        $port = isset($parsed['port']) ? ':' . $parsed['port'] : '';
        $query = isset($parsed['query']) ? '?' . $parsed['query'] : '';
        $fragment = isset($parsed['fragment']) ? '#' . $parsed['fragment'] : '';

        return $scheme . $host . $port . $newPath . $query . $fragment;
    }

    private function withPaymentContext(string $url, int $paymentId, ?int $bookingId): string
    {
        if ($url === '') {
            return $url;
        }

        $params = [];
        if (!str_contains($url, 'payment_id=')) {
            $params['payment_id'] = (string) $paymentId;
        }
        if ($bookingId !== null && !str_contains($url, 'booking_id=')) {
            $params['booking_id'] = (string) $bookingId;
        }
        if ($params === []) {
            return $url;
        }

        $separator = str_contains($url, '?') ? '&' : '?';
        return $url . $separator . http_build_query($params);
    }
}
