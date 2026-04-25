<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

final class BillingIntervalUnit
{
    public const MONTH = 'month';
    public const YEAR = 'year';

    public static function all(): array
    {
        return [self::MONTH, self::YEAR];
    }
}
