<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

use InvalidArgumentException;

final class BillingProviderFactory
{
    /** @param array<string,BillingProviderInterface> $providers */
    public function __construct(
        private readonly array $providers,
    ) {}

    public function get(string $providerCode): BillingProviderInterface
    {
        $provider = $this->providers[$providerCode] ?? null;
        if ($provider === null) {
            throw new InvalidArgumentException('Unsupported billing provider: ' . $providerCode);
        }

        return $provider;
    }
}
