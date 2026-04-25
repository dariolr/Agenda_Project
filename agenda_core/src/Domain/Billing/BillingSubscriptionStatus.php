<?php

declare(strict_types=1);

namespace Agenda\Domain\Billing;

final class BillingSubscriptionStatus
{
    public const NOT_REQUIRED = 'not_required';
    public const INACTIVE = 'inactive';
    public const PENDING_CHECKOUT = 'pending_checkout';
    public const ACTIVE = 'active';
    public const PAST_DUE = 'past_due';
    public const UNPAID = 'unpaid';
    public const CANCELED = 'canceled';
    public const ERROR = 'error';
}
