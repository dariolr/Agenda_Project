<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\OnlinePayments\Stripe;

use Stripe\StripeClient;

final class StripeConnectClientFactory
{
    public function create(): StripeClient
    {
        $secretKey = trim((string) ($_ENV['STRIPE_SECRET_KEY'] ?? getenv('STRIPE_SECRET_KEY') ?: ''));
        if ($secretKey === '') {
            throw new \RuntimeException('STRIPE_SECRET_KEY is not configured');
        }

        return new StripeClient($secretKey);
    }
}
