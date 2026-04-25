<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

interface BillingProviderInterface
{
    public function createSubscriptionCheckout(BillingConfig $config, BillingSubscription $subscription, array $context): array;

    public function createCustomerPortal(BillingConfig $config, BillingSubscription $subscription, array $context): array;

    public function cancelSubscription(BillingConfig $config, BillingSubscription $subscription, array $context): void;

    public function handleWebhook(string $payload, array $headers): BillingWebhookResult;
}
