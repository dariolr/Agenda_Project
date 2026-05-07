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

    public function __construct(
        private readonly StripeClientFactory $clientFactory,
        private readonly BusinessBillingConfigRepository $configRepository,
    ) {}

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

        $customerId = $subscription->providerCustomerId;
        if ($customerId === null || $customerId === '') {
            $customer = $client->customers->create([
                'email' => $context['business_email'] ?? null,
                'name' => $context['business_name'] ?? ('Business #' . $config->businessId),
                'metadata' => ['business_id' => (string) $config->businessId],
            ]);
            $customerId = $customer->id;
        }

        $session = $client->checkout->sessions->create([
            'mode' => 'subscription',
            'customer' => $customerId,
            'line_items' => [
                ['price' => $priceReference, 'quantity' => 1],
            ],
            'success_url' => $this->env('STRIPE_SUCCESS_URL', $context['success_url'] ?? ''),
            'cancel_url' => $this->env('STRIPE_CANCEL_URL', $context['cancel_url'] ?? ''),
            'client_reference_id' => (string) $config->businessId,
            'metadata' => ['business_id' => (string) $config->businessId],
            'subscription_data' => [
                'metadata' => ['business_id' => (string) $config->businessId],
            ],
        ]);

        return [
            'url' => $session->url,
            'checkout_session_id' => $session->id,
            'provider_customer_id' => $customerId,
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

        $status = $this->targetStatus($type, $object);
        $periodStart = $this->timestampOrNull($object['current_period_start'] ?? null);
        $periodEnd = $this->timestampOrNull($object['current_period_end'] ?? null);
        $lastPaymentAt = $this->isPaymentSucceededEvent($type)
            ? $this->timestampOrNull($object['status_transitions']['paid_at'] ?? $object['created'] ?? null)
            : null;
        $lastPaymentFailedAt = $type === 'invoice.payment_failed' ? $this->timestampOrNull($object['created'] ?? null) : null;

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
            cancelAtPeriodEnd: isset($object['cancel_at_period_end']) ? (bool) $object['cancel_at_period_end'] : null,
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

    private function targetStatus(string $type, array $object): ?string
    {
        if ($type === 'checkout.session.completed') {
            return BillingSubscriptionStatus::ACTIVE;
        }
        if ($this->isPaymentSucceededEvent($type)) {
            return BillingSubscriptionStatus::ACTIVE;
        }
        if ($type === 'invoice.payment_failed') {
            return BillingSubscriptionStatus::PAST_DUE;
        }
        if ($type === 'customer.subscription.deleted') {
            return BillingSubscriptionStatus::CANCELED;
        }
        if ($type === 'customer.subscription.created' || $type === 'customer.subscription.updated') {
            return match ((string) ($object['status'] ?? '')) {
                'active', 'trialing' => BillingSubscriptionStatus::ACTIVE,
                'past_due' => BillingSubscriptionStatus::PAST_DUE,
                'unpaid' => BillingSubscriptionStatus::UNPAID,
                'canceled', 'incomplete_expired' => BillingSubscriptionStatus::CANCELED,
                default => null,
            };
        }

        return null;
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
        if ($type === 'customer.subscription.created' || $type === 'customer.subscription.updated' || $type === 'customer.subscription.deleted') {
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

    private function isPaymentSucceededEvent(string $type): bool
    {
        return in_array($type, self::PAYMENT_SUCCEEDED_EVENTS, true);
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
