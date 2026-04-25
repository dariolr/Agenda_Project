<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

final class BillingConfig
{
    public function __construct(
        public readonly ?int $id,
        public readonly int $businessId,
        public readonly bool $billingEnabled,
        public readonly string $billingMode,
        public readonly ?string $billingIntervalUnit,
        public readonly ?int $billingIntervalCount,
        public readonly ?int $amountCents,
        public readonly string $currency,
        public readonly ?string $providerCode,
        public readonly ?string $providerPriceReference,
        public readonly ?string $notes,
        public readonly ?string $createdAt = null,
        public readonly ?string $updatedAt = null,
    ) {}

    public static function fromArray(array $row): self
    {
        return new self(
            id: isset($row['id']) ? (int) $row['id'] : null,
            businessId: (int) $row['business_id'],
            billingEnabled: (bool) ((int) ($row['billing_enabled'] ?? 0)),
            billingMode: (string) ($row['billing_mode'] ?? BillingMode::FREE),
            billingIntervalUnit: $row['billing_interval_unit'] !== null ? (string) $row['billing_interval_unit'] : null,
            billingIntervalCount: $row['billing_interval_count'] !== null ? (int) $row['billing_interval_count'] : null,
            amountCents: $row['amount_cents'] !== null ? (int) $row['amount_cents'] : null,
            currency: strtoupper((string) ($row['currency'] ?? 'EUR')),
            providerCode: $row['provider_code'] !== null ? (string) $row['provider_code'] : null,
            providerPriceReference: $row['provider_price_reference'] !== null ? (string) $row['provider_price_reference'] : null,
            notes: $row['notes'] !== null ? (string) $row['notes'] : null,
            createdAt: $row['created_at'] ?? null,
            updatedAt: $row['updated_at'] ?? null,
        );
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->businessId,
            'billing_enabled' => $this->billingEnabled,
            'billing_mode' => $this->billingMode,
            'billing_interval_unit' => $this->billingIntervalUnit,
            'billing_interval_count' => $this->billingIntervalCount,
            'amount_cents' => $this->amountCents,
            'currency' => $this->currency,
            'provider_code' => $this->providerCode,
            'provider_price_reference' => $this->providerPriceReference,
            'notes' => $this->notes,
            'created_at' => $this->createdAt,
            'updated_at' => $this->updatedAt,
        ];
    }
}
