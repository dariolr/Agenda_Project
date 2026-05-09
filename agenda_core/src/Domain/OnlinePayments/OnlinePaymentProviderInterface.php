<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

use Agenda\Http\Request;

interface OnlinePaymentProviderInterface
{
    public function providerCode(): string;

    public function createOnboardingLink(int $businessId, string $mode): OnlinePaymentOnboardingResult;

    public function refreshAccountStatus(OnlinePaymentAccount $account): OnlinePaymentAccountStatusResult;

    public function createCheckout(OnlinePaymentCheckoutRequest $request): OnlinePaymentCheckoutResult;

    public function handleWebhook(Request $request): OnlinePaymentWebhookResult;

    public function retrievePaymentStatus(OnlineBookingPayment $payment): OnlinePaymentStatusResult;
}
