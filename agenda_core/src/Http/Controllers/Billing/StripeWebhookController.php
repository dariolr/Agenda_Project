<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers\Billing;

use Agenda\Domain\Billing\BillingProviderCode;
use Agenda\Domain\Billing\BillingProviderFactory;
use Agenda\Domain\Billing\BillingWebhookResult;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\Billing\BillingProviderEventRepository;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingSubscriptionRepository;

final class StripeWebhookController
{
    public function __construct(
        private readonly BillingProviderFactory $providerFactory,
        private readonly BusinessBillingSubscriptionRepository $subscriptionRepository,
        private readonly BillingProviderEventRepository $eventRepository,
    ) {}

    public function handle(Request $request): Response
    {
        try {
            $result = $this->providerFactory
                ->get(BillingProviderCode::STRIPE)
                ->handleWebhook($request->rawBody, $request->headers);
        } catch (\Throwable $e) {
            return Response::badRequest('Invalid Stripe webhook: ' . $e->getMessage(), $request->traceId);
        }

        if ($this->eventRepository->exists($result->providerCode, $result->providerEventId)) {
            return Response::success(['processed' => false, 'duplicate' => true]);
        }

        if ($result->businessId === null && $result->providerSubscriptionId !== null) {
            $businessId = $this->subscriptionRepository->findBusinessIdByProviderSubscriptionId(
                $result->providerCode,
                $result->providerSubscriptionId,
            );
            if ($businessId !== null) {
                $result = new BillingWebhookResult(
                    providerEventId: $result->providerEventId,
                    eventType: $result->eventType,
                    businessId: $businessId,
                    providerCode: $result->providerCode,
                    providerCustomerId: $result->providerCustomerId,
                    providerSubscriptionId: $result->providerSubscriptionId,
                    providerPriceReference: $result->providerPriceReference,
                    targetStatus: $result->targetStatus,
                    currentPeriodStart: $result->currentPeriodStart,
                    currentPeriodEnd: $result->currentPeriodEnd,
                    cancelAtPeriodEnd: $result->cancelAtPeriodEnd,
                    lastPaymentAt: $result->lastPaymentAt,
                    lastPaymentFailedAt: $result->lastPaymentFailedAt,
                    rawPayload: $result->rawPayload,
                );
            }
        }

        $this->subscriptionRepository->updateFromWebhookResult($result);
        $this->eventRepository->storeProcessedEvent($result);

        return Response::success(['processed' => true]);
    }
}
