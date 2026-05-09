<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlineBookingPayment
{
    public function __construct(
        public readonly int $id,
        public readonly int $businessId,
        public readonly int $locationId,
        public readonly ?int $bookingId,
        public readonly ?int $classBookingId,
        public readonly string $providerCode,
        public readonly ?string $providerAccountId,
        public readonly ?string $providerCheckoutId,
        public readonly ?string $providerPaymentId,
        public readonly ?string $providerOrderId,
        public readonly string $status,
        public readonly int $amountCents,
        public readonly string $currency,
        public readonly ?string $checkoutUrl,
        public readonly ?string $returnUrl,
        public readonly ?string $cancelUrl,
        public readonly ?string $idempotencyKey,
        public readonly ?string $expiresAt,
    ) {}

    public static function fromArray(array $row): self
    {
        return new self(
            id: (int) $row['id'],
            businessId: (int) $row['business_id'],
            locationId: (int) $row['location_id'],
            bookingId: isset($row['booking_id']) ? (int) $row['booking_id'] : null,
            classBookingId: isset($row['class_booking_id']) ? (int) $row['class_booking_id'] : null,
            providerCode: (string) $row['provider_code'],
            providerAccountId: self::stringOrNull($row['provider_account_id'] ?? null),
            providerCheckoutId: self::stringOrNull($row['provider_checkout_id'] ?? null),
            providerPaymentId: self::stringOrNull($row['provider_payment_id'] ?? null),
            providerOrderId: self::stringOrNull($row['provider_order_id'] ?? null),
            status: (string) $row['status'],
            amountCents: (int) $row['amount_cents'],
            currency: (string) $row['currency'],
            checkoutUrl: self::stringOrNull($row['checkout_url'] ?? null),
            returnUrl: self::stringOrNull($row['return_url'] ?? null),
            cancelUrl: self::stringOrNull($row['cancel_url'] ?? null),
            idempotencyKey: self::stringOrNull($row['idempotency_key'] ?? null),
            expiresAt: self::stringOrNull($row['expires_at'] ?? null),
        );
    }

    private static function stringOrNull(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $string = trim((string) $value);
        return $string === '' ? null : $string;
    }
}
