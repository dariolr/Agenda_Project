<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories\Billing;

use Agenda\Domain\Billing\BillingSubscription;
use Agenda\Domain\Billing\BillingSubscriptionStatus;
use Agenda\Domain\Billing\BillingWebhookResult;
use Agenda\Infrastructure\Database\Connection;
use PDO;

final class BusinessBillingSubscriptionRepository
{
    public function __construct(private readonly Connection $db) {}

    public function findByBusinessId(int $businessId): ?BillingSubscription
    {
        $stmt = $this->db->getPdo()->prepare('SELECT * FROM business_billing_subscription WHERE business_id = ? LIMIT 1');
        $stmt->execute([$businessId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? BillingSubscription::fromArray($row) : null;
    }

    public function findOrCreateByBusinessId(int $businessId): BillingSubscription
    {
        $existing = $this->findByBusinessId($businessId);
        if ($existing !== null) {
            return $existing;
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_billing_subscription (business_id, status) VALUES (?, ?)'
        );
        $stmt->execute([$businessId, BillingSubscriptionStatus::INACTIVE]);

        return $this->findByBusinessId($businessId) ?? throw new \RuntimeException('Unable to create billing subscription');
    }

    public function markNotRequired(int $businessId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_billing_subscription (business_id, status)
             VALUES (?, ?)
             ON DUPLICATE KEY UPDATE
                provider_code = NULL,
                provider_price_reference = NULL,
                status = VALUES(status),
                cancel_at_period_end = 0'
        );
        $stmt->execute([$businessId, BillingSubscriptionStatus::NOT_REQUIRED]);
    }

    public function updateAfterCheckoutCreation(
        int $businessId,
        string $providerCode,
        ?string $providerCustomerId,
        ?string $providerSubscriptionId,
        ?string $providerPriceReference,
        ?string $checkoutSessionId,
    ): void {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET provider_code = ?,
                 provider_customer_id = COALESCE(?, provider_customer_id),
                 provider_subscription_id = COALESCE(?, provider_subscription_id),
                 provider_price_reference = COALESCE(?, provider_price_reference),
                 status = ?,
                 last_checkout_session_id = ?
             WHERE business_id = ?'
        );
        $stmt->execute([
            $providerCode,
            $providerCustomerId,
            $providerSubscriptionId,
            $providerPriceReference,
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            $checkoutSessionId,
            $businessId,
        ]);
    }

    public function markAbandonedPendingCheckoutInactive(int $businessId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET status = ?
             WHERE business_id = ?
               AND status = ?
               AND provider_subscription_id IS NULL
               AND last_checkout_session_id IS NOT NULL'
        );
        $stmt->execute([
            BillingSubscriptionStatus::INACTIVE,
            $businessId,
            BillingSubscriptionStatus::PENDING_CHECKOUT,
        ]);
    }

    public function updateFromWebhookResult(BillingWebhookResult $result): void
    {
        if ($result->businessId === null) {
            return;
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_billing_subscription
                (business_id, provider_code, provider_customer_id, provider_subscription_id,
                 provider_price_reference, status, current_period_start, current_period_end,
                 cancel_at_period_end, canceled_at, last_payment_at, last_payment_failed_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                provider_code = COALESCE(VALUES(provider_code), provider_code),
                provider_customer_id = COALESCE(VALUES(provider_customer_id), provider_customer_id),
                provider_subscription_id = COALESCE(VALUES(provider_subscription_id), provider_subscription_id),
                provider_price_reference = COALESCE(VALUES(provider_price_reference), provider_price_reference),
                status = COALESCE(VALUES(status), status),
                current_period_start = COALESCE(VALUES(current_period_start), current_period_start),
                current_period_end = COALESCE(VALUES(current_period_end), current_period_end),
                cancel_at_period_end = IF(? IS NULL, cancel_at_period_end, ?),
                canceled_at = COALESCE(VALUES(canceled_at), canceled_at),
                last_payment_at = COALESCE(VALUES(last_payment_at), last_payment_at),
                last_payment_failed_at = COALESCE(VALUES(last_payment_failed_at), last_payment_failed_at)'
        );
        $cancelAtPeriodEnd = $result->cancelAtPeriodEnd === null ? null : ($result->cancelAtPeriodEnd ? 1 : 0);
        $stmt->execute([
            $result->businessId,
            $result->providerCode,
            $result->providerCustomerId,
            $result->providerSubscriptionId,
            $result->providerPriceReference,
            $result->targetStatus,
            $result->currentPeriodStart,
            $result->currentPeriodEnd,
            $cancelAtPeriodEnd ?? 0,
            $result->canceledAt,
            $result->lastPaymentAt,
            $result->lastPaymentFailedAt,
            $cancelAtPeriodEnd,
            $cancelAtPeriodEnd,
        ]);
    }

    public function findBusinessIdByProviderSubscriptionId(string $providerCode, string $providerSubscriptionId): ?int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT business_id FROM business_billing_subscription
             WHERE provider_code = ? AND provider_subscription_id = ?
             LIMIT 1'
        );
        $stmt->execute([$providerCode, $providerSubscriptionId]);
        $value = $stmt->fetchColumn();

        return $value === false ? null : (int) $value;
    }
}
