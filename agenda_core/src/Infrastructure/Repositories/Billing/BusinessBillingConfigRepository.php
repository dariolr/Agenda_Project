<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories\Billing;

use Agenda\Domain\Billing\BillingConfig;
use Agenda\Domain\Billing\BillingIntervalUnit;
use Agenda\Domain\Billing\BillingMode;
use Agenda\Infrastructure\Database\Connection;
use PDO;

final class BusinessBillingConfigRepository
{
    public function __construct(private readonly Connection $db) {}

    public function findByBusinessId(int $businessId): ?BillingConfig
    {
        $stmt = $this->db->getPdo()->prepare('SELECT * FROM business_billing_config WHERE business_id = ? LIMIT 1');
        $stmt->execute([$businessId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? BillingConfig::fromArray($row) : null;
    }

    public function createDefaultForBusiness(int $businessId): BillingConfig
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_billing_config
                (business_id, billing_enabled, billing_mode, currency)
             VALUES (?, 0, ?, "EUR")
             ON DUPLICATE KEY UPDATE business_id = VALUES(business_id)'
        );
        $stmt->execute([$businessId, BillingMode::FREE]);

        return $this->findByBusinessId($businessId) ?? throw new \RuntimeException('Unable to create billing config');
    }

    public function findOrCreateByBusinessId(int $businessId): BillingConfig
    {
        return $this->findByBusinessId($businessId) ?? $this->createDefaultForBusiness($businessId);
    }

    public function upsertConfig(int $businessId, array $payload): BillingConfig
    {
        $enabled = !empty($payload['billing_enabled']);
        $currency = strtoupper(substr(trim((string) ($payload['currency'] ?? 'EUR')), 0, 3));
        $notes = isset($payload['notes']) && trim((string) $payload['notes']) !== ''
            ? substr(trim((string) $payload['notes']), 0, 255)
            : null;

        $activationDeadlineAt = null;
        if (!empty($payload['activation_deadline_at'])) {
            try {
                $dt = new \DateTimeImmutable((string) $payload['activation_deadline_at'], new \DateTimeZone('UTC'));
                $activationDeadlineAt = $dt->format('Y-m-d H:i:s');
            } catch (\Throwable) {
                throw new \InvalidArgumentException('activation_deadline_at is not a valid date');
            }
        }

        if (!$enabled) {
            $data = [
                0,
                BillingMode::FREE,
                null,
                null,
                null,
                $currency !== '' ? $currency : 'EUR',
                null,
                null,
                null,
                $notes,
            ];
        } else {
            $amountCents = (int) ($payload['amount_cents'] ?? 0);
            $providerCode = trim((string) ($payload['provider_code'] ?? ''));
            if ($amountCents <= 0) {
                throw new \InvalidArgumentException('amount_cents must be greater than zero');
            }
            if ($providerCode === '') {
                throw new \InvalidArgumentException('provider_code is required');
            }

            $data = [
                1,
                BillingMode::RECURRING,
                BillingIntervalUnit::MONTH,
                1,
                $amountCents,
                $currency !== '' ? $currency : 'EUR',
                $providerCode,
                $payload['provider_price_reference'] ?? null,
                $activationDeadlineAt,
                $notes,
            ];
        }

        $existing = $this->findByBusinessId($businessId);

        if ($existing === null) {
            $stmt = $this->db->getPdo()->prepare(
                'INSERT INTO business_billing_config
                    (business_id, billing_enabled, billing_mode, billing_interval_unit, billing_interval_count,
                     amount_cents, currency, provider_code, provider_price_reference, activation_deadline_at, notes)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute(array_merge([$businessId], $data));
        } else {
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE business_billing_config SET
                    billing_enabled = ?,
                    billing_mode = ?,
                    billing_interval_unit = ?,
                    billing_interval_count = ?,
                    amount_cents = ?,
                    currency = ?,
                    provider_code = ?,
                    provider_price_reference = ?,
                    activation_deadline_at = ?,
                    notes = ?
                 WHERE business_id = ?'
            );
            $stmt->execute(array_merge($data, [$businessId]));
        }

        return $this->findByBusinessId($businessId) ?? throw new \RuntimeException('Unable to load billing config');
    }

    public function updateProviderPriceReference(int $businessId, string $providerPriceReference): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_billing_config SET provider_price_reference = ? WHERE business_id = ?'
        );
        $stmt->execute([$providerPriceReference, $businessId]);
    }
}
