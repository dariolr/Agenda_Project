<?php

declare(strict_types=1);

namespace Agenda\Domain\OnlinePayments;

final class OnlinePaymentAccount
{
    public function __construct(
        public readonly int $id,
        public readonly int $businessId,
        public readonly string $providerCode,
        public readonly string $mode,
        public readonly ?string $providerAccountId,
        public readonly ?string $providerMerchantId,
        public readonly bool $isEnabled,
        public readonly string $onboardingStatus,
        public readonly bool $chargesEnabled,
        public readonly bool $payoutsEnabled,
        public readonly bool $detailsSubmitted,
        public readonly ?array $capabilities,
        public readonly ?array $requirements,
        public readonly ?string $lastErrorCode,
        public readonly ?string $lastErrorMessage,
    ) {}

    public static function fromArray(array $row): self
    {
        return new self(
            id: (int) $row['id'],
            businessId: (int) $row['business_id'],
            providerCode: (string) $row['provider_code'],
            mode: (string) $row['mode'],
            providerAccountId: self::stringOrNull($row['provider_account_id'] ?? null),
            providerMerchantId: self::stringOrNull($row['provider_merchant_id'] ?? null),
            isEnabled: (bool) $row['is_enabled'],
            onboardingStatus: (string) $row['onboarding_status'],
            chargesEnabled: (bool) $row['charges_enabled'],
            payoutsEnabled: (bool) $row['payouts_enabled'],
            detailsSubmitted: (bool) $row['details_submitted'],
            capabilities: self::jsonOrNull($row['capabilities_json'] ?? null),
            requirements: self::jsonOrNull($row['requirements_json'] ?? null),
            lastErrorCode: self::stringOrNull($row['last_error_code'] ?? null),
            lastErrorMessage: self::stringOrNull($row['last_error_message'] ?? null),
        );
    }

    private static function jsonOrNull(mixed $value): ?array
    {
        if ($value === null || $value === '') {
            return null;
        }
        if (is_array($value)) {
            return $value;
        }
        $decoded = json_decode((string) $value, true);
        return is_array($decoded) ? $decoded : null;
    }

    private static function stringOrNull(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $string = trim((string) $value);
        return $string === '' ? null : $string;
    }
}
