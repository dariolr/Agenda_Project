<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

final class BillingMode
{
    public const FREE = 'free';
    public const RECURRING = 'recurring';
    public const ONE_TIME = 'one_time';
    public const MANUAL = 'manual';

    public static function all(): array
    {
        return [self::FREE, self::RECURRING, self::ONE_TIME, self::MANUAL];
    }
}
