<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories\Billing;

use Agenda\Domain\Billing\BillingSubscription;
use Agenda\Domain\Billing\BillingSubscriptionStatus;
use Agenda\Domain\Billing\BillingWebhookResult;
use Agenda\Infrastructure\Database\Connection;
use PDO;
use PDOException;

final class BusinessBillingSubscriptionRepository
{
    public function __construct(private readonly Connection $db) {}

    public function beginTransaction(): void
    {
        $this->db->beginTransaction();
    }

    public function commit(): void
    {
        $this->db->commit();
    }

    public function rollback(): void
    {
        $this->db->rollback();
    }

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

    // Usato quando il superadmin riabilita billing: crea il record se assente,
    // oppure lo porta a inactive se era not_required (reset dopo disattivazione).
    // Non tocca stati runtime come active, past_due, pending_checkout.
    public function activateOrCreate(int $businessId): BillingSubscription
    {
        $existing = $this->findByBusinessId($businessId);
        if ($existing === null) {
            $stmt = $this->db->getPdo()->prepare(
                'INSERT INTO business_billing_subscription (business_id, status) VALUES (?, ?)'
            );
            $stmt->execute([$businessId, BillingSubscriptionStatus::INACTIVE]);
        } elseif ($existing->status === BillingSubscriptionStatus::NOT_REQUIRED) {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE business_billing_subscription SET status = ? WHERE business_id = ?'
            );
            $stmt->execute([BillingSubscriptionStatus::INACTIVE, $businessId]);
        }

        return $this->findByBusinessId($businessId) ?? throw new \RuntimeException('Unable to load billing subscription');
    }

    public function findOrCreateByBusinessIdForUpdate(int $businessId): BillingSubscription
    {
        $driver = $this->db->getPdo()->getAttribute(PDO::ATTR_DRIVER_NAME);
        if ($driver === 'sqlite') {
            $stmt = $this->db->getPdo()->prepare(
                'INSERT OR IGNORE INTO business_billing_subscription (business_id, status) VALUES (?, ?)'
            );
        } else {
            $stmt = $this->db->getPdo()->prepare(
                'INSERT INTO business_billing_subscription (business_id, status)
                 VALUES (?, ?)
                 ON DUPLICATE KEY UPDATE business_id = business_id'
            );
        }
        $stmt->execute([$businessId, BillingSubscriptionStatus::INACTIVE]);

        $sql = 'SELECT * FROM business_billing_subscription WHERE business_id = ? LIMIT 1';
        if ($driver !== 'sqlite') {
            $sql .= ' FOR UPDATE';
        }

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute([$businessId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? BillingSubscription::fromArray($row) : throw new \RuntimeException('Unable to lock billing subscription');
    }

    public function markNotRequired(int $businessId): void
    {
        $exists = $this->db->getPdo()
            ->prepare('SELECT 1 FROM business_billing_subscription WHERE business_id = ? LIMIT 1');
        $exists->execute([$businessId]);

        if ($exists->fetchColumn() === false) {
            $stmt = $this->db->getPdo()->prepare(
                'INSERT INTO business_billing_subscription (business_id, status) VALUES (?, ?)'
            );
            $stmt->execute([$businessId, BillingSubscriptionStatus::NOT_REQUIRED]);
        } else {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE business_billing_subscription
                 SET provider_code = NULL,
                     provider_price_reference = NULL,
                     status = ?,
                     cancel_at_period_end = 0
                 WHERE business_id = ?'
            );
            $stmt->execute([BillingSubscriptionStatus::NOT_REQUIRED, $businessId]);
        }
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
                 last_checkout_session_id = ?,
                 updated_at = CURRENT_TIMESTAMP
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

    public function reserveCheckoutCreation(
        int $businessId,
        string $providerCode,
        ?string $providerPriceReference,
    ): bool {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET provider_code = ?,
                 provider_price_reference = COALESCE(?, provider_price_reference),
                 status = ?,
                 last_checkout_session_id = NULL,
                 updated_at = CURRENT_TIMESTAMP
             WHERE business_id = ?
               AND (
                    status <> ?
                    OR last_checkout_session_id IS NOT NULL
               )'
        );
        $stmt->execute([
            $providerCode,
            $providerPriceReference,
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            $businessId,
            BillingSubscriptionStatus::PENDING_CHECKOUT,
        ]);

        return $stmt->rowCount() > 0;
    }

    public function clearCheckoutReservation(int $businessId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET status = ?,
                 last_checkout_session_id = NULL,
                 updated_at = CURRENT_TIMESTAMP
             WHERE business_id = ?
               AND status = ?
               AND last_checkout_session_id IS NULL'
        );
        $stmt->execute([
            BillingSubscriptionStatus::INACTIVE,
            $businessId,
            BillingSubscriptionStatus::PENDING_CHECKOUT,
        ]);
    }

    public function clearAbandonedCheckout(int $businessId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET status = ?,
                 last_checkout_session_id = NULL,
                 updated_at = CURRENT_TIMESTAMP
             WHERE business_id = ?
               AND status = ?'
        );
        $stmt->execute([
            BillingSubscriptionStatus::INACTIVE,
            $businessId,
            BillingSubscriptionStatus::PENDING_CHECKOUT,
        ]);
    }

    public function updateProviderCustomerId(int $businessId, string $providerCode, string $providerCustomerId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET provider_code = ?,
                 provider_customer_id = ?
             WHERE business_id = ?'
        );
        $stmt->execute([$providerCode, $providerCustomerId, $businessId]);
    }

    public function syncManageableProviderSubscription(
        int $businessId,
        string $providerCode,
        array $subscription,
    ): void {
        $cancelAtPeriodEnd = array_key_exists('cancel_at_period_end', $subscription)
            ? (!empty($subscription['cancel_at_period_end']) ? 1 : 0)
            : 0;
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET provider_code = ?,
                 provider_customer_id = COALESCE(?, provider_customer_id),
                 provider_subscription_id = COALESCE(?, provider_subscription_id),
                 provider_price_reference = COALESCE(?, provider_price_reference),
                 status = COALESCE(?, status),
                 current_period_start = COALESCE(?, current_period_start),
                 current_period_end = COALESCE(?, current_period_end),
                 cancel_at_period_end = ?
             WHERE business_id = ?'
        );
        $stmt->execute([
            $providerCode,
            $subscription['provider_customer_id'] ?? null,
            $subscription['provider_subscription_id'] ?? null,
            $subscription['provider_price_reference'] ?? null,
            $subscription['status'] ?? null,
            $subscription['current_period_start'] ?? null,
            $subscription['current_period_end'] ?? null,
            $cancelAtPeriodEnd,
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

        if ($this->findByBusinessId($result->businessId) !== null) {
            $this->updateExistingFromWebhookResult($result);
            return;
        }

        try {
            $this->insertFromWebhookResult($result);
        } catch (PDOException $e) {
            if ($e->getCode() !== '23000') {
                throw $e;
            }
            $this->updateExistingFromWebhookResult($result);
        }
    }

    private function insertFromWebhookResult(BillingWebhookResult $result): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_billing_subscription
                (business_id, provider_code, provider_customer_id, provider_subscription_id,
                 provider_price_reference, status, current_period_start, current_period_end,
                 cancel_at_period_end, canceled_at, last_payment_at, last_payment_failed_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
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
        ]);
    }

    private function updateExistingFromWebhookResult(BillingWebhookResult $result): void
    {
        $existing = $this->findByBusinessId($result->businessId ?? 0);
        if ($existing === null) {
            return;
        }
        if ($this->isConflictingActiveSubscription($existing, $result)) {
            error_log(sprintf(
                '[BusinessBillingSubscriptionRepository] conflicting active billing subscription business_id=%d canonical_subscription_id=%s incoming_subscription_id=%s event_id=%s',
                $existing->businessId,
                $existing->providerSubscriptionId ?? 'null',
                $result->providerSubscriptionId ?? 'null',
                $result->providerEventId,
            ));
            return;
        }

        $providerSubscriptionId = $result->providerSubscriptionId ?? $existing->providerSubscriptionId;
        $targetStatus = $result->targetStatus ?? $existing->status;
        $subscriptionChanged = $result->providerSubscriptionId !== null
            && $result->providerSubscriptionId !== $existing->providerSubscriptionId;
        $isFailedInitialPayment = $subscriptionChanged
            && in_array($targetStatus, [
                BillingSubscriptionStatus::PAST_DUE,
                BillingSubscriptionStatus::UNPAID,
                BillingSubscriptionStatus::ERROR,
            ], true);
        $lastPaymentAt = $result->lastPaymentAt ?? ($isFailedInitialPayment ? null : $existing->lastPaymentAt);
        $canceledAt = $targetStatus === BillingSubscriptionStatus::ACTIVE
            ? null
            : ($result->canceledAt ?? $existing->canceledAt);
        $cancelAtPeriodEnd = $result->cancelAtPeriodEnd === null
            ? ($existing->cancelAtPeriodEnd ? 1 : 0)
            : ($result->cancelAtPeriodEnd ? 1 : 0);

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_subscription
             SET provider_code = ?,
                 provider_customer_id = ?,
                 provider_subscription_id = ?,
                 provider_price_reference = ?,
                 status = ?,
                 current_period_start = ?,
                 current_period_end = ?,
                 cancel_at_period_end = ?,
                 canceled_at = ?,
                 last_payment_at = ?,
                 last_payment_failed_at = ?
             WHERE business_id = ?'
        );
        $stmt->execute([
            $result->providerCode ?? $existing->providerCode,
            $result->providerCustomerId ?? $existing->providerCustomerId,
            $providerSubscriptionId,
            $result->providerPriceReference ?? $existing->providerPriceReference,
            $targetStatus,
            $result->currentPeriodStart ?? $existing->currentPeriodStart,
            $result->currentPeriodEnd ?? $existing->currentPeriodEnd,
            $cancelAtPeriodEnd,
            $canceledAt,
            $lastPaymentAt,
            $result->lastPaymentFailedAt ?? $existing->lastPaymentFailedAt,
            $result->businessId,
        ]);
    }

    private function isConflictingActiveSubscription(BillingSubscription $existing, BillingWebhookResult $result): bool
    {
        if ($existing->providerSubscriptionId === null || $result->providerSubscriptionId === null) {
            return false;
        }
        if ($existing->providerSubscriptionId === $result->providerSubscriptionId) {
            return false;
        }
        if (!in_array($existing->status, [
            BillingSubscriptionStatus::ACTIVE,
            BillingSubscriptionStatus::PAST_DUE,
            BillingSubscriptionStatus::UNPAID,
        ], true)) {
            return false;
        }

        return in_array($result->targetStatus, [
            BillingSubscriptionStatus::ACTIVE,
            BillingSubscriptionStatus::PAST_DUE,
            BillingSubscriptionStatus::UNPAID,
        ], true);
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
