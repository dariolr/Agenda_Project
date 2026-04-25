<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

final class BillingSubscription
{
    public function __construct(
        public readonly ?int $id,
        public readonly int $businessId,
        public readonly ?string $providerCode,
        public readonly ?string $providerCustomerId,
        public readonly ?string $providerSubscriptionId,
        public readonly ?string $providerPriceReference,
        public readonly string $status,
        public readonly ?string $currentPeriodStart,
        public readonly ?string $currentPeriodEnd,
        public readonly bool $cancelAtPeriodEnd,
        public readonly ?string $canceledAt,
        public readonly ?string $lastPaymentAt,
        public readonly ?string $lastPaymentFailedAt,
        public readonly ?string $lastCheckoutSessionId,
        public readonly ?string $createdAt = null,
        public readonly ?string $updatedAt = null,
    ) {}

    public static function fromArray(array $row): self
    {
        return new self(
            id: isset($row['id']) ? (int) $row['id'] : null,
            businessId: (int) $row['business_id'],
            providerCode: $row['provider_code'] !== null ? (string) $row['provider_code'] : null,
            providerCustomerId: $row['provider_customer_id'] !== null ? (string) $row['provider_customer_id'] : null,
            providerSubscriptionId: $row['provider_subscription_id'] !== null ? (string) $row['provider_subscription_id'] : null,
            providerPriceReference: $row['provider_price_reference'] !== null ? (string) $row['provider_price_reference'] : null,
            status: (string) ($row['status'] ?? BillingSubscriptionStatus::NOT_REQUIRED),
            currentPeriodStart: $row['current_period_start'] ?? null,
            currentPeriodEnd: $row['current_period_end'] ?? null,
            cancelAtPeriodEnd: (bool) ((int) ($row['cancel_at_period_end'] ?? 0)),
            canceledAt: $row['canceled_at'] ?? null,
            lastPaymentAt: $row['last_payment_at'] ?? null,
            lastPaymentFailedAt: $row['last_payment_failed_at'] ?? null,
            lastCheckoutSessionId: $row['last_checkout_session_id'] !== null ? (string) $row['last_checkout_session_id'] : null,
            createdAt: $row['created_at'] ?? null,
            updatedAt: $row['updated_at'] ?? null,
        );
    }
}
