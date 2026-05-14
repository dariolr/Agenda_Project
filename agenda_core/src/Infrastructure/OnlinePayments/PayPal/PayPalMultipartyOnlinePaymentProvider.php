<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\OnlinePayments\PayPal;

use Agenda\Domain\OnlinePayments\OnlineBookingPayment;
use Agenda\Domain\OnlinePayments\OnlinePaymentAccount;
use Agenda\Domain\OnlinePayments\OnlinePaymentAccountStatusResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentCheckoutRequest;
use Agenda\Domain\OnlinePayments\OnlinePaymentCheckoutResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentOnboardingResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentProviderCode;
use Agenda\Domain\OnlinePayments\OnlinePaymentProviderInterface;
use Agenda\Domain\OnlinePayments\OnlinePaymentStatusResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentWebhookResult;
use Agenda\Http\Request;

final class PayPalMultipartyOnlinePaymentProvider implements OnlinePaymentProviderInterface
{
    public function providerCode(): string
    {
        return OnlinePaymentProviderCode::PAYPAL;
    }

    public function createOnboardingLink(int $businessId, string $mode, ?string $existingAccountId = null): OnlinePaymentOnboardingResult
    {
        throw new \RuntimeException('PayPal seller onboarding is not implemented yet');
    }

    public function refreshAccountStatus(OnlinePaymentAccount $account): OnlinePaymentAccountStatusResult
    {
        return new OnlinePaymentAccountStatusResult(
            status: $account->onboardingStatus,
            chargesEnabled: $account->chargesEnabled,
            payoutsEnabled: $account->payoutsEnabled,
            detailsSubmitted: $account->detailsSubmitted,
            capabilities: $account->capabilities,
            requirements: $account->requirements,
            providerAccountId: $account->providerAccountId,
            providerMerchantId: $account->providerMerchantId,
        );
    }

    public function createCheckout(OnlinePaymentCheckoutRequest $request): OnlinePaymentCheckoutResult
    {
        throw new \RuntimeException('PayPal Orders API is not implemented yet');
    }

    public function handleWebhook(Request $request): OnlinePaymentWebhookResult
    {
        throw new \RuntimeException('PayPal webhook handling is not implemented yet');
    }

    public function retrievePaymentStatus(OnlineBookingPayment $payment): OnlinePaymentStatusResult
    {
        return new OnlinePaymentStatusResult($payment->status, $payment->providerPaymentId);
    }
}
