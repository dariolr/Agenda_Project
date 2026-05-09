<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories\OnlinePayments;

use Agenda\Domain\OnlinePayments\OnlineBookingPayment;
use Agenda\Domain\OnlinePayments\OnlinePaymentCheckoutResult;
use Agenda\Domain\OnlinePayments\OnlinePaymentStatus;
use Agenda\Infrastructure\Database\Connection;

final class OnlineBookingPaymentRepository
{
    public function __construct(private readonly Connection $db) {}

    public function createPending(array $data): OnlineBookingPayment
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO online_booking_payments
                (business_id, location_id, booking_id, class_booking_id, provider_code, provider_account_id, amount_cents, currency, return_url, cancel_url, idempotency_key, expires_at, status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $data['business_id'],
            $data['location_id'],
            $data['booking_id'] ?? null,
            $data['class_booking_id'] ?? null,
            $data['provider_code'],
            $data['provider_account_id'] ?? null,
            $data['amount_cents'],
            strtoupper((string) ($data['currency'] ?? 'EUR')),
            $data['return_url'] ?? null,
            $data['cancel_url'] ?? null,
            $data['idempotency_key'] ?? null,
            $data['expires_at'] ?? null,
            OnlinePaymentStatus::PENDING,
        ]);

        return $this->findById((int) $this->db->getPdo()->lastInsertId())
            ?? throw new \RuntimeException('Unable to load online booking payment');
    }

    public function findById(int $id): ?OnlineBookingPayment
    {
        $stmt = $this->db->getPdo()->prepare('SELECT * FROM online_booking_payments WHERE id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        return $row ? OnlineBookingPayment::fromArray($row) : null;
    }

    public function findByProviderCheckoutId(string $providerCode, string $checkoutId): ?OnlineBookingPayment
    {
        return $this->findOneByProviderField('provider_checkout_id', $providerCode, $checkoutId);
    }

    public function findByProviderPaymentId(string $providerCode, string $paymentId): ?OnlineBookingPayment
    {
        return $this->findOneByProviderField('provider_payment_id', $providerCode, $paymentId);
    }

    public function findActivePendingForBooking(int $bookingId): ?OnlineBookingPayment
    {
        $stmt = $this->db->getPdo()->prepare(
            "SELECT * FROM online_booking_payments
             WHERE booking_id = ? AND status IN ('pending','requires_action')
             ORDER BY id DESC
             LIMIT 1"
        );
        $stmt->execute([$bookingId]);
        $row = $stmt->fetch();

        return $row ? OnlineBookingPayment::fromArray($row) : null;
    }

    /**
     * @return OnlineBookingPayment[]
     */
    public function findExpiredPending(int $limit = 100): array
    {
        $stmt = $this->db->getPdo()->prepare(
            "SELECT * FROM online_booking_payments
             WHERE status IN ('pending','requires_action')
               AND expires_at IS NOT NULL
               AND expires_at <= NOW()
             ORDER BY expires_at ASC
             LIMIT ?"
        );
        $stmt->bindValue(1, $limit, \PDO::PARAM_INT);
        $stmt->execute();

        return array_map(
            static fn (array $row): OnlineBookingPayment => OnlineBookingPayment::fromArray($row),
            $stmt->fetchAll()
        );
    }

    public function attachCheckout(int $paymentId, OnlinePaymentCheckoutResult $result): void
    {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE online_booking_payments
             SET provider_checkout_id = ?, provider_payment_id = ?, provider_order_id = ?,
                 checkout_url = ?, expires_at = COALESCE(?, expires_at), payload_json = ?, status = 'pending', updated_at = NOW()
             WHERE id = ? AND status IN ('pending','requires_action','failed')"
        );
        $stmt->execute([
            $result->providerCheckoutId,
            $result->providerPaymentId,
            $result->providerOrderId,
            $result->checkoutUrl,
            $result->expiresAt,
            json_encode($result->rawPayload, JSON_THROW_ON_ERROR),
            $paymentId,
        ]);
    }

    public function markPaid(int $paymentId, ?string $providerPaymentId = null, ?array $payload = null): void
    {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE online_booking_payments
             SET status = 'paid',
                 provider_payment_id = COALESCE(?, provider_payment_id),
                 paid_at = COALESCE(paid_at, NOW()),
                 payload_json = COALESCE(?, payload_json),
                 updated_at = NOW()
             WHERE id = ? AND status <> 'paid'"
        );
        $stmt->execute([
            $providerPaymentId,
            $payload !== null ? json_encode($payload, JSON_THROW_ON_ERROR) : null,
            $paymentId,
        ]);
    }

    public function markFailed(int $paymentId, ?array $payload = null): void
    {
        $this->markTerminal($paymentId, OnlinePaymentStatus::FAILED, 'failed_at', $payload);
    }

    public function markCancelled(int $paymentId, ?array $payload = null): void
    {
        $this->markTerminal($paymentId, OnlinePaymentStatus::CANCELLED, 'cancelled_at', $payload);
    }

    public function markExpired(int $paymentId, ?array $payload = null): void
    {
        $this->markTerminal($paymentId, OnlinePaymentStatus::EXPIRED, null, $payload);
    }

    private function markTerminal(int $paymentId, string $status, ?string $timestampColumn, ?array $payload): void
    {
        $timestampSql = $timestampColumn !== null ? ", {$timestampColumn} = COALESCE({$timestampColumn}, NOW())" : '';
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE online_booking_payments
             SET status = ?{$timestampSql}, payload_json = COALESCE(?, payload_json), updated_at = NOW()
             WHERE id = ? AND status <> 'paid'"
        );
        $stmt->execute([
            $status,
            $payload !== null ? json_encode($payload, JSON_THROW_ON_ERROR) : null,
            $paymentId,
        ]);
    }

    private function findOneByProviderField(string $field, string $providerCode, string $value): ?OnlineBookingPayment
    {
        $stmt = $this->db->getPdo()->prepare(
            "SELECT * FROM online_booking_payments WHERE provider_code = ? AND {$field} = ? LIMIT 1"
        );
        $stmt->execute([$providerCode, $value]);
        $row = $stmt->fetch();

        return $row ? OnlineBookingPayment::fromArray($row) : null;
    }
}
