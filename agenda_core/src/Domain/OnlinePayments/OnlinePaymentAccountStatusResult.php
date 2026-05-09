<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentAccountStatusResult
{
    public function __construct(
        public readonly string $status,
        public readonly bool $chargesEnabled,
        public readonly bool $payoutsEnabled,
        public readonly bool $detailsSubmitted,
        public readonly ?array $capabilities = null,
        public readonly ?array $requirements = null,
        public readonly ?string $providerAccountId = null,
        public readonly ?string $providerMerchantId = null,
        public readonly ?string $errorCode = null,
        public readonly ?string $errorMessage = null,
    ) {}
}
