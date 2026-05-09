<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentProviderCode
{
    public const STRIPE = 'stripe';
    public const PAYPAL = 'paypal';

    public static function isValid(string $value): bool
    {
        return in_array($value, [self::STRIPE, self::PAYPAL], true);
    }
}
