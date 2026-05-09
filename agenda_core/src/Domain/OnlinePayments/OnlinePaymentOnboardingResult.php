<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentOnboardingResult
{
    public function __construct(
        public readonly string $providerCode,
        public readonly string $onboardingUrl,
        public readonly ?string $expiresAt,
        public readonly string $status,
        public readonly ?string $providerAccountId = null,
        public readonly ?string $providerMerchantId = null,
    ) {}
}
