<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories\OnlinePayments;

use Agenda\Domain\OnlinePayments\OnlinePaymentAccount;
use Agenda\Infrastructure\Database\Connection;

final class BusinessOnlinePaymentAccountRepository
{
    public function __construct(private readonly Connection $db) {}

    public function findByBusinessAndProvider(int $businessId, string $providerCode, string $mode = 'test'): ?OnlinePaymentAccount
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM business_online_payment_accounts
             WHERE business_id = ? AND provider_code = ? AND mode = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $providerCode, $mode]);
        $row = $stmt->fetch();

        return $row ? OnlinePaymentAccount::fromArray($row) : null;
    }

    public function findByProviderAccountId(string $providerAccountId, string $mode = 'test'): ?OnlinePaymentAccount
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM business_online_payment_accounts
             WHERE provider_account_id = ? AND mode = ?
             LIMIT 1'
        );
        $stmt->execute([$providerAccountId, $mode]);
        $row = $stmt->fetch();

        return $row ? OnlinePaymentAccount::fromArray($row) : null;
    }

    /**
     * @return OnlinePaymentAccount[]
     */
    public function findEnabledByBusiness(int $businessId, string $mode = 'test'): array
    {
        $stmt = $this->db->getPdo()->prepare(
            "SELECT * FROM business_online_payment_accounts
             WHERE business_id = ? AND mode = ? AND is_enabled = 1 AND onboarding_status = 'active'
               AND charges_enabled = 1 AND details_submitted = 1
             ORDER BY provider_code ASC"
        );
        $stmt->execute([$businessId, $mode]);

        return array_map(
            static fn (array $row): OnlinePaymentAccount => OnlinePaymentAccount::fromArray($row),
            $stmt->fetchAll()
        );
    }

    public function upsertProviderAccount(
        int $businessId,
        string $providerCode,
        string $mode,
        ?string $providerAccountId,
        ?string $providerMerchantId = null,
        string $onboardingStatus = 'pending',
    ): OnlinePaymentAccount {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_online_payment_accounts
                (business_id, provider_code, mode, provider_account_id, provider_merchant_id, onboarding_status)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                provider_account_id = COALESCE(VALUES(provider_account_id), provider_account_id),
                provider_merchant_id = COALESCE(VALUES(provider_merchant_id), provider_merchant_id),
                onboarding_status = IF(
                    onboarding_status = "disabled" AND is_enabled = 0,
                    onboarding_status,
                    VALUES(onboarding_status)
                ),
                last_error_code = NULL,
                last_error_message = NULL,
                updated_at = NOW()'
        );
        $stmt->execute([$businessId, $providerCode, $mode, $providerAccountId, $providerMerchantId, $onboardingStatus]);

        return $this->findByBusinessAndProvider($businessId, $providerCode, $mode)
            ?? throw new \RuntimeException('Unable to load online payment account');
    }

    public function setOnboardingPending(int $businessId, string $providerCode, string $mode, ?string $providerAccountId = null): void
    {
        $this->upsertProviderAccount($businessId, $providerCode, $mode, $providerAccountId, null, 'pending');
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_online_payment_accounts
             SET last_onboarding_url_created_at = NOW(), updated_at = NOW()
             WHERE business_id = ? AND provider_code = ? AND mode = ?'
        );
        $stmt->execute([$businessId, $providerCode, $mode]);
    }

    public function touchOnboardingLinkCreatedAt(int $businessId, string $providerCode, string $mode): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_online_payment_accounts
             SET last_onboarding_url_created_at = NOW(), updated_at = NOW()
             WHERE business_id = ? AND provider_code = ? AND mode = ?'
        );
        $stmt->execute([$businessId, $providerCode, $mode]);
    }

    public function markOnboardingStarted(
        int $businessId,
        string $providerCode,
        string $mode,
        ?string $providerAccountId,
        ?string $providerMerchantId = null,
        string $status = 'pending',
    ): void {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_online_payment_accounts
             SET provider_account_id = COALESCE(?, provider_account_id),
                 provider_merchant_id = COALESCE(?, provider_merchant_id),
                 onboarding_status = ?,
                 is_enabled = 0,
                 last_onboarding_url_created_at = NOW(),
                 last_error_code = NULL,
                 last_error_message = NULL,
                 updated_at = NOW()
             WHERE business_id = ? AND provider_code = ? AND mode = ?'
        );
        $stmt->execute([
            $providerAccountId,
            $providerMerchantId,
            $status,
            $businessId,
            $providerCode,
            $mode,
        ]);
    }

    public function markActive(int $businessId, string $providerCode, string $mode): void
    {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE business_online_payment_accounts
             SET onboarding_status = 'active', last_error_code = NULL, last_error_message = NULL, updated_at = NOW()
             WHERE business_id = ? AND provider_code = ? AND mode = ?"
        );
        $stmt->execute([$businessId, $providerCode, $mode]);
    }

    public function markRestricted(int $businessId, string $providerCode, string $mode, ?string $errorCode = null, ?string $errorMessage = null): void
    {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE business_online_payment_accounts
             SET onboarding_status = 'restricted', is_enabled = 0, last_error_code = ?, last_error_message = ?, updated_at = NOW()
             WHERE business_id = ? AND provider_code = ? AND mode = ?"
        );
        $stmt->execute([$errorCode, $errorMessage, $businessId, $providerCode, $mode]);
    }

    public function disable(int $businessId, string $providerCode, string $mode): void
    {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE business_online_payment_accounts
             SET is_enabled = 0, onboarding_status = IF(onboarding_status = 'not_configured', 'not_configured', 'disabled'), updated_at = NOW()
             WHERE business_id = ? AND provider_code = ? AND mode = ?"
        );
        $stmt->execute([$businessId, $providerCode, $mode]);
    }

    public function setEnabled(int $businessId, string $providerCode, string $mode, bool $enabled): bool
    {
        if ($enabled) {
            $account = $this->findByBusinessAndProvider($businessId, $providerCode, $mode);
            if (
                $account === null
                || $account->onboardingStatus !== 'active'
                || !$account->chargesEnabled
                || !$account->detailsSubmitted
            ) {
                return false;
            }
        }

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE business_online_payment_accounts
             SET is_enabled = ?, updated_at = NOW()
             WHERE business_id = ? AND provider_code = ? AND mode = ?'
        );
        $stmt->execute([$enabled ? 1 : 0, $businessId, $providerCode, $mode]);

        return true;
    }

    public function syncCapabilities(
        int $businessId,
        string $providerCode,
        string $mode,
        bool $chargesEnabled,
        bool $payoutsEnabled,
        bool $detailsSubmitted,
        ?array $capabilities,
        ?array $requirements,
        string $status,
        ?string $providerAccountId = null,
        ?string $providerMerchantId = null,
        ?string $errorCode = null,
        ?string $errorMessage = null,
    ): void {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO business_online_payment_accounts
                (business_id, provider_code, mode, provider_account_id, provider_merchant_id, onboarding_status, charges_enabled, payouts_enabled, details_submitted, capabilities_json, requirements_json, last_sync_at, last_error_code, last_error_message)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?)
             ON DUPLICATE KEY UPDATE
                provider_account_id = COALESCE(VALUES(provider_account_id), provider_account_id),
                provider_merchant_id = COALESCE(VALUES(provider_merchant_id), provider_merchant_id),
                onboarding_status = IF(
                    onboarding_status = "disabled" AND is_enabled = 0,
                    onboarding_status,
                    VALUES(onboarding_status)
                ),
                charges_enabled = VALUES(charges_enabled),
                payouts_enabled = VALUES(payouts_enabled),
                details_submitted = VALUES(details_submitted),
                capabilities_json = VALUES(capabilities_json),
                requirements_json = VALUES(requirements_json),
                last_sync_at = NOW(),
                last_error_code = VALUES(last_error_code),
                last_error_message = VALUES(last_error_message),
                is_enabled = IF(
                    onboarding_status = "disabled" AND is_enabled = 0,
                    0,
                    IF(VALUES(onboarding_status) = "active", is_enabled, 0)
                ),
                updated_at = NOW()'
        );
        $stmt->execute([
            $businessId,
            $providerCode,
            $mode,
            $providerAccountId,
            $providerMerchantId,
            $status,
            $chargesEnabled ? 1 : 0,
            $payoutsEnabled ? 1 : 0,
            $detailsSubmitted ? 1 : 0,
            $capabilities !== null ? json_encode($capabilities, JSON_THROW_ON_ERROR) : null,
            $requirements !== null ? json_encode($requirements, JSON_THROW_ON_ERROR) : null,
            $errorCode,
            $errorMessage,
        ]);
    }
}
