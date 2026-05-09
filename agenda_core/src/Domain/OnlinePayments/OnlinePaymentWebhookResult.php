<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentWebhookResult
{
    public function __construct(
        public readonly string $providerCode,
        public readonly string $providerEventId,
        public readonly string $eventType,
        public readonly ?int $businessId,
        public readonly ?int $onlineBookingPaymentId,
        public readonly ?string $providerCheckoutId,
        public readonly ?string $providerPaymentId,
        public readonly string $targetStatus,
        public readonly array $rawPayload,
    ) {}
}
