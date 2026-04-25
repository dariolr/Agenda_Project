<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

final class BillingWebhookResult
{
    public function __construct(
        public readonly string $providerEventId,
        public readonly string $eventType,
        public readonly ?int $businessId,
        public readonly string $providerCode,
        public readonly ?string $providerCustomerId,
        public readonly ?string $providerSubscriptionId,
        public readonly ?string $providerPriceReference,
        public readonly ?string $targetStatus,
        public readonly ?string $currentPeriodStart,
        public readonly ?string $currentPeriodEnd,
        public readonly ?bool $cancelAtPeriodEnd,
        public readonly ?string $lastPaymentAt,
        public readonly ?string $lastPaymentFailedAt,
        public readonly array $rawPayload,
    ) {}
}
