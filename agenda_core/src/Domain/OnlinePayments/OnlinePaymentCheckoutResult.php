<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentCheckoutResult
{
    public function __construct(
        public readonly string $providerCode,
        public readonly ?string $providerCheckoutId,
        public readonly ?string $providerPaymentId,
        public readonly ?string $providerOrderId,
        public readonly string $checkoutUrl,
        public readonly ?string $expiresAt,
        public readonly array $rawPayload = [],
    ) {}
}
