<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Billing\Stripe;

use Agenda\Domain\Billing\BillingConfig;
use Agenda\Domain\Billing\BillingIntervalUnit;
use Agenda\Domain\Billing\BillingMode;
use Agenda\Domain\Billing\BillingProviderCode;
use Agenda\Domain\Billing\BillingProviderInterface;
use Agenda\Domain\Billing\BillingSubscription;
use Agenda\Domain\Billing\BillingSubscriptionStatus;
use Agenda\Domain\Billing\BillingWebhookResult;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingConfigRepository;
use Stripe\Webhook;

final class StripeBillingProvider implements BillingProviderInterface
{
    private const PAYMENT_SUCCEEDED_EVENTS = [
        'invoice.paid',
        'invoice_payment.paid',
    ];

    private const PAYMENT_FAILED_EVENTS = [
        'invoice.payment_failed',
        'invoice_payment.failed',
        'checkout.session.async_payment_failed',
    ];

    private const SUBSCRIPTION_EVENTS = [
        'customer.subscription.created',
        'customer.subscription.updated',
        'customer.subscription.deleted',
    ];

    public function __construct(
        private readonly StripeClientFactory $clientFactory,
        private readonly BusinessBillingConfigRepository $configRepository,
    ) {}

    public function createCustomer(BillingConfig $config, array $context): array
    {
        $customer = $this->clientFactory->create()->customers->create([
            'email' => $context['business_email'] ?? null,
            'name' => $context['business_name'] ?? ('Business #' . $config->businessId),
            'metadata' => ['business_id' => (string) $config->businessId],
        ]);

        return ['provider_customer_id' => $customer->id];
    }

    public function retrieveCheckoutSession(string $checkoutSessionId): ?array
    {
        try {
            $session = $this->clientFactory->create()->checkout->sessions->retrieve($checkoutSessionId, []);
            $sessionArray = $session->toArray();
            return is_array($sessionArray) ? $this->formatCheckoutSession($sessionArray) : null;
        } catch (\Throwable) {
            return null;
        }
    }

    public function expireCheckoutSession(string $checkoutSessionId): ?array
    {
        try {
            $session = $this->clientFactory->create()->checkout->sessions->expire($checkoutSessionId, []);
            $sessionArray = $session->toArray();
            return is_array($sessionArray) ? $this->formatCheckoutSession($sessionArray) : null;
        } catch (\Throwable) {
            return null;
        }
    }

    public function findManageableSubscription(BillingConfig $config, BillingSubscription $subscription): ?array
    {
        if ($subscription->providerCustomerId === null || $subscription->providerCustomerId === '') {
            return null;
        }

        try {
            $subscriptions = $this->clientFactory->create()->subscriptions->all([
                'customer' => $subscription->providerCustomerId,
                'status' => 'all',
                'limit' => 100,
            ]);
            $subscriptionsArray = $subscriptions->toArray();
        } catch (\Throwable) {
            return null;
        }

        foreach (($subscriptionsArray['data'] ?? []) as $candidate) {
            if (!is_array($candidate)) {
                continue;
            }
            $status = (string) ($candidate['status'] ?? '');
            if (!in_array($status, ['active', 'trialing', 'past_due', 'unpaid'], true)) {
                continue;
            }

            return $this->formatSubscription($candidate);
        }

        return null;
    }

    public function createSubscriptionCheckout(BillingConfig $config, BillingSubscription $subscription, array $context): array
    {
        if (
            $config->billingMode !== BillingMode::RECURRING ||
            $config->billingIntervalUnit !== BillingIntervalUnit::MONTH ||
            $config->billingIntervalCount !== 1
        ) {
            throw new \InvalidArgumentException('Billing mode is not active yet');
        }

        if (!$config->billingEnabled || $config->amountCents === null || $config->amountCents <= 0) {
            throw new \InvalidArgumentException('Billing config is not valid');
        }

        $client = $this->clientFactory->create();
        $priceReference = $config->providerPriceReference ?: $this->createMonthlyPrice($config, $context);
        if ($config->providerPriceReference === null) {
            $this->configRepository->updateProviderPriceReference($config->businessId, $priceReference);
        }

        if ($subscription->providerCustomerId === null || $subscription->providerCustomerId === '') {
            throw new \InvalidArgumentException('Provider customer is missing');
        }

        $subscriptionData = [
            'metadata' => ['business_id' => (string) $config->businessId],
        ];

        if ($config->billingCycleAnchorAt !== null) {
            $now = new \DateTimeImmutable('now', new \DateTimeZone('UTC'));
            if ($config->billingCycleAnchorAt <= $now) {
                throw new \InvalidArgumentException('billing_cycle_anchor_in_past');
            }
            $subscriptionData['billing_cycle_anchor'] = $config->billingCycleAnchorAt->getTimestamp();
            $subscriptionData['proration_behavior'] = 'none';
        }

        $session = $client->checkout->sessions->create([
            'mode' => 'subscription',
            'customer' => $subscription->providerCustomerId,
            'line_items' => [
                ['price' => $priceReference, 'quantity' => 1],
            ],
            'success_url' => $this->env('STRIPE_SUCCESS_URL', $context['success_url'] ?? ''),
            'cancel_url' => $this->env('STRIPE_CANCEL_URL', $context['cancel_url'] ?? ''),
            'client_reference_id' => (string) $config->businessId,
            'metadata' => ['business_id' => (string) $config->businessId],
            'subscription_data' => $subscriptionData,
        ]);

        return [
            'url' => $session->url,
            'checkout_session_id' => $session->id,
            'provider_customer_id' => $subscription->providerCustomerId,
            'provider_price_reference' => $priceReference,
        ];
    }

    public function createCustomerPortal(BillingConfig $config, BillingSubscription $subscription, array $context): array
    {
        if ($subscription->providerCustomerId === null || $subscription->providerCustomerId === '') {
            throw new \InvalidArgumentException('Provider customer is missing');
        }

        $session = $this->clientFactory->create()->billingPortal->sessions->create([
            'customer' => $subscription->providerCustomerId,
            'return_url' => $this->env('STRIPE_PORTAL_RETURN_URL', $context['return_url'] ?? ''),
        ]);

        return ['url' => $session->url];
    }

    public function cancelSubscription(BillingConfig $config, BillingSubscription $subscription, array $context): void
    {
        if ($subscription->providerSubscriptionId === null || $subscription->providerSubscriptionId === '') {
            return;
        }

        $this->clientFactory->create()->subscriptions->cancel($subscription->providerSubscriptionId);
    }

    public function handleWebhook(string $payload, array $headers): BillingWebhookResult
    {
        $secret = $this->env('STRIPE_WEBHOOK_SECRET', '');
        if ($secret === '') {
            throw new \RuntimeException('STRIPE_WEBHOOK_SECRET is not configured');
        }

        $signature = $headers['stripe-signature'] ?? $headers['Stripe-Signature'] ?? '';
        $event = Webhook::constructEvent($payload, $signature, $secret);
        $eventArray = $event->toArray();
        $object = $eventArray['data']['object'] ?? [];
        $type = (string) $eventArray['type'];

        $businessId = $this->extractBusinessId($object);
        $customerId = $this->extractCustomerId($object);
        $subscriptionId = $this->extractSubscriptionId($type, $object);
        if ($this->shouldResolveSubscriptionSnapshot($type, $object, $subscriptionId)) {
            $object = $this->resolveSubscriptionSnapshot(
                $object,
                $subscriptionId,
            );
            $businessId = $this->extractBusinessId($object);
            $customerId = $this->extractCustomerId($object);
            $subscriptionId = $this->extractSubscriptionId($type, $object);
        }

        $status = $this->targetStatus($type, $object);
        $periodStart = $this->extractCurrentPeriodStart($object);
        $periodEnd = $this->extractCurrentPeriodEnd($object);
        $cancelAtPeriodEnd = $this->extractCancelAtPeriodEnd($object);
        if ($status === BillingSubscriptionStatus::CANCELED) {
            $cancelAtPeriodEnd = false;
        }
        if ($cancelAtPeriodEnd === true && $periodEnd === null) {
            $this->logMissingCurrentPeriodEnd((string) $eventArray['id'], $subscriptionId, $businessId);
        }
        $lastPaymentAt = $this->isPaymentSucceededEvent($type)
            ? $this->timestampOrNull($object['status_transitions']['paid_at'] ?? $object['created'] ?? null)
            : null;
        $lastPaymentFailedAt = $this->isPaymentFailedEvent($type) ? $this->timestampOrNull($object['created'] ?? null) : null;
        $canceledAt = $status === BillingSubscriptionStatus::CANCELED
            ? $this->timestampOrNull($this->firstValue([
                $object['canceled_at'] ?? null,
                $object['ended_at'] ?? null,
                $eventArray['created'] ?? null,
            ]))
            : null;

        return new BillingWebhookResult(
            providerEventId: (string) $eventArray['id'],
            eventType: $type,
            businessId: $businessId,
            providerCode: BillingProviderCode::STRIPE,
            providerCustomerId: $customerId,
            providerSubscriptionId: $subscriptionId,
            providerPriceReference: $this->extractPriceReference($object),
            targetStatus: $status,
            currentPeriodStart: $periodStart,
            currentPeriodEnd: $periodEnd,
            cancelAtPeriodEnd: $cancelAtPeriodEnd,
            canceledAt: $canceledAt,
            lastPaymentAt: $lastPaymentAt,
            lastPaymentFailedAt: $lastPaymentFailedAt,
            rawPayload: $eventArray,
        );
    }

    private function createMonthlyPrice(BillingConfig $config, array $context): string
    {
        $client = $this->clientFactory->create();
        $product = $client->products->create([
            'name' => 'Agenda gestionale - ' . ($context['business_name'] ?? ('Business #' . $config->businessId)),
            'metadata' => ['business_id' => (string) $config->businessId],
        ]);

        $price = $client->prices->create([
            'unit_amount' => $config->amountCents,
            'currency' => strtolower($config->currency),
            'recurring' => ['interval' => 'month', 'interval_count' => 1],
            'product' => $product->id,
            'metadata' => ['business_id' => (string) $config->businessId],
        ]);

        return $price->id;
    }

    private function formatCheckoutSession(array $session): array
    {
        return [
            'checkout_session_id' => $this->stringOrNull($session['id'] ?? null),
            'url' => $this->stringOrNull($session['url'] ?? null),
            'status' => $this->stringOrNull($session['status'] ?? null),
            'payment_status' => $this->stringOrNull($session['payment_status'] ?? null),
            'provider_customer_id' => $this->stringOrNull($session['customer'] ?? null),
            'provider_subscription_id' => $this->stringOrNull($session['subscription'] ?? null),
        ];
    }

    private function formatSubscription(array $subscription): array
    {
        return [
            'provider_subscription_id' => $this->stringOrNull($subscription['id'] ?? null),
            'provider_customer_id' => $this->stringOrNull($subscription['customer'] ?? null),
            'provider_price_reference' => $this->extractPriceReference($subscription),
            'status' => $this->statusFromStripeSubscriptionStatus((string) ($subscription['status'] ?? '')),
            'current_period_start' => $this->extractCurrentPeriodStart($subscription),
            'current_period_end' => $this->extractCurrentPeriodEnd($subscription),
            'cancel_at_period_end' => $this->extractCancelAtPeriodEnd($subscription) ?? false,
        ];
    }

    private function targetStatus(string $type, array $object): ?string
    {
        if ($type === 'checkout.session.completed') {
            if (($object['payment_status'] ?? null) === 'paid') {
                return BillingSubscriptionStatus::ACTIVE;
            }

            return $this->statusFromStripeSubscriptionStatus((string) ($object['status'] ?? ''));
        }
        if ($this->isPaymentSucceededEvent($type)) {
            return BillingSubscriptionStatus::ACTIVE;
        }
        if ($this->isPaymentFailedEvent($type)) {
            return BillingSubscriptionStatus::PAST_DUE;
        }
        if ($type === 'customer.subscription.deleted') {
            return BillingSubscriptionStatus::CANCELED;
        }
        if ($this->isSubscriptionEvent($type)) {
            return $this->statusFromStripeSubscriptionStatus((string) ($object['status'] ?? ''));
        }

        return null;
    }

    private function statusFromStripeSubscriptionStatus(string $status): ?string
    {
        return match ($status) {
            'active', 'trialing' => BillingSubscriptionStatus::ACTIVE,
            'past_due', 'incomplete' => BillingSubscriptionStatus::PAST_DUE,
            'unpaid' => BillingSubscriptionStatus::UNPAID,
            'canceled', 'incomplete_expired' => BillingSubscriptionStatus::CANCELED,
            default => null,
        };
    }

    private function extractBusinessId(array $object): ?int
    {
        $value = $this->firstValue([
            $object['metadata']['business_id'] ?? null,
            $object['client_reference_id'] ?? null,
            $object['subscription_details']['metadata']['business_id'] ?? null,
            $object['parent']['subscription_details']['metadata']['business_id'] ?? null,
            $object['invoice']['metadata']['business_id'] ?? null,
            $object['invoice']['client_reference_id'] ?? null,
            $object['invoice']['subscription_details']['metadata']['business_id'] ?? null,
            $object['invoice']['parent']['subscription_details']['metadata']['business_id'] ?? null,
        ]);
        if (is_numeric($value) && (int) $value > 0) {
            return (int) $value;
        }

        return null;
    }

    private function extractCustomerId(array $object): ?string
    {
        return $this->stringOrNull($this->firstValue([
            $object['customer'] ?? null,
            $object['invoice']['customer'] ?? null,
        ]));
    }

    private function extractSubscriptionId(string $type, array $object): ?string
    {
        if ($this->isSubscriptionEvent($type)) {
            return $this->stringOrNull($object['id'] ?? null);
        }

        return $this->stringOrNull($this->firstValue([
            $object['subscription'] ?? null,
            $object['invoice']['subscription'] ?? null,
            $object['parent']['subscription_details']['subscription'] ?? null,
            $object['invoice']['parent']['subscription_details']['subscription'] ?? null,
        ]));
    }

    private function extractPriceReference(array $object): ?string
    {
        foreach ([
            $object['items']['data'] ?? null,
            $object['lines']['data'] ?? null,
            $object['invoice']['items']['data'] ?? null,
            $object['invoice']['lines']['data'] ?? null,
        ] as $lines) {
            if (isset($lines[0]['price']['id'])) {
                return (string) $lines[0]['price']['id'];
            }
        }

        return null;
    }

    private function extractCurrentPeriodStart(array $object): ?string
    {
        return $this->timestampOrNull($this->firstValue([
            $object['current_period_start'] ?? null,
            $object['items']['data'][0]['current_period_start'] ?? null,
        ]));
    }

    private function extractCurrentPeriodEnd(array $object): ?string
    {
        return $this->timestampOrNull($this->firstValue([
            $object['current_period_end'] ?? null,
            $object['items']['data'][0]['current_period_end'] ?? null,
        ]));
    }

    private function extractCancelAtPeriodEnd(array $object): ?bool
    {
        return array_key_exists('cancel_at_period_end', $object)
            ? (bool) $object['cancel_at_period_end']
            : null;
    }

    private function isPaymentSucceededEvent(string $type): bool
    {
        return in_array($type, self::PAYMENT_SUCCEEDED_EVENTS, true);
    }

    private function isPaymentFailedEvent(string $type): bool
    {
        return in_array($type, self::PAYMENT_FAILED_EVENTS, true);
    }

    private function isSubscriptionEvent(string $type): bool
    {
        return in_array($type, self::SUBSCRIPTION_EVENTS, true);
    }

    private function shouldResolveSubscriptionSnapshot(string $type, array $object, ?string $subscriptionId): bool
    {
        if ($subscriptionId === null) {
            return false;
        }
        if ($this->isSubscriptionEvent($type)) {
            return true;
        }

        return $this->targetStatus($type, $object) === BillingSubscriptionStatus::ACTIVE
            && $this->extractCurrentPeriodEnd($object) === null;
    }

    private function resolveSubscriptionSnapshot(
        array $object,
        ?string $subscriptionId,
    ): array {
        if ($this->extractCurrentPeriodEnd($object) !== null || $subscriptionId === null) {
            return $object;
        }

        try {
            $subscription = $this->clientFactory->create()->subscriptions->retrieve($subscriptionId, []);
            $subscriptionArray = $subscription->toArray();
            if (is_array($subscriptionArray)) {
                return array_replace_recursive($object, $subscriptionArray);
            }
        } catch (\Throwable) {}

        return $object;
    }

    private function logMissingCurrentPeriodEnd(string $eventId, ?string $subscriptionId, ?int $businessId): void
    {
        error_log(sprintf(
            '[StripeBillingProvider] WARNING missing current_period_end for cancel_at_period_end event_id=%s subscription_id=%s business_id=%s',
            $eventId,
            $subscriptionId ?? 'null',
            $businessId === null ? 'null' : (string) $businessId,
        ));
    }

    private function firstValue(array $values): mixed
    {
        foreach ($values as $value) {
            if ($value !== null && $value !== '') {
                return $value;
            }
        }

        return null;
    }

    private function stringOrNull(mixed $value): ?string
    {
        return is_string($value) && $value !== '' ? $value : null;
    }

    private function timestampOrNull(mixed $value): ?string
    {
        return is_numeric($value) ? gmdate('Y-m-d H:i:s', (int) $value) : null;
    }

    private function env(string $key, string $default): string
    {
        $value = $_ENV[$key] ?? getenv($key);
        $resolved = $value === false || $value === null || trim((string) $value) === ''
            ? $default
            : trim((string) $value);
        if ($resolved === '') {
            throw new \RuntimeException($key . ' is not configured');
        }

        return $resolved;
    }
}
