<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentCheckoutRequest
{
    public function __construct(
        public readonly int $businessId,
        public readonly int $locationId,
        public readonly ?int $bookingId,
        public readonly ?int $classBookingId,
        public readonly int $onlineBookingPaymentId,
        public readonly int $amountCents,
        public readonly string $currency,
        public readonly string $mode,
        public readonly string $providerAccountId,
        public readonly string $returnUrl,
        public readonly string $cancelUrl,
        public readonly ?string $idempotencyKey = null,
        public readonly string $businessSlug = '',
    ) {}
}
