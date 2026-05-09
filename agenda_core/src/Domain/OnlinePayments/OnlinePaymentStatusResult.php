<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentStatusResult
{
    public function __construct(
        public readonly string $status,
        public readonly ?string $providerPaymentId = null,
        public readonly ?array $rawPayload = null,
    ) {}
}
