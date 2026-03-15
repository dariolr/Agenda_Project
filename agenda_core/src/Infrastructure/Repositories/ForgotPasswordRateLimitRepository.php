<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

final class ForgotPasswordRateLimitRepository
{
    private const SHORT_WINDOW_SECONDS = 60;
    private const SHORT_WINDOW_MAX_REQUESTS = 1;
    private const HOUR_WINDOW_HOURS = 1;
    private const HOUR_WINDOW_MAX_REQUESTS = 5;

    public function __construct(
        private readonly Connection $db,
    ) {}

    public function isRateLimited(
        string $scope,
        ?int $businessId,
        string $email,
        ?string $ipAddress
    ): bool {
        $emailHash = $this->hashEmail($email);
        $ipHash = $this->hashIp($ipAddress);

        if ($this->countInWindow($scope, $businessId, $emailHash, $ipHash, self::SHORT_WINDOW_SECONDS, 'SECOND') >= self::SHORT_WINDOW_MAX_REQUESTS) {
            return true;
        }

        if ($this->countInWindow($scope, $businessId, $emailHash, $ipHash, self::HOUR_WINDOW_HOURS, 'HOUR') >= self::HOUR_WINDOW_MAX_REQUESTS) {
            return true;
        }

        return false;
    }

    public function recordAttempt(
        string $scope,
        ?int $businessId,
        string $email,
        ?string $ipAddress
    ): void {
        $emailHash = $this->hashEmail($email);
        $ipHash = $this->hashIp($ipAddress);

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO forgot_password_rate_limits (scope, business_id, email_hash, ip_hash) 
             VALUES (:scope, :business_id, :email_hash, :ip_hash)'
        );
        $stmt->execute([
            'scope' => $scope,
            'business_id' => $businessId,
            'email_hash' => $emailHash,
            'ip_hash' => $ipHash,
        ]);

        // Keep table small without requiring a dedicated cleanup cron.
        $cleanup = $this->db->getPdo()->prepare(
            'DELETE FROM forgot_password_rate_limits
             WHERE created_at < DATE_SUB(NOW(), INTERVAL 2 DAY)'
        );
        $cleanup->execute();
    }

    private function countInWindow(
        string $scope,
        ?int $businessId,
        string $emailHash,
        string $ipHash,
        int $windowValue,
        string $windowUnit
    ): int {
        $businessFilterSql = $businessId === null
            ? 'business_id IS NULL'
            : 'business_id = :business_id';

        $sql = sprintf(
            'SELECT COUNT(*)
             FROM forgot_password_rate_limits
             WHERE scope = :scope
               AND %s
               AND email_hash = :email_hash
               AND ip_hash = :ip_hash
               AND created_at > DATE_SUB(NOW(), INTERVAL %d %s)',
            $businessFilterSql,
            $windowValue,
            $windowUnit
        );

        $stmt = $this->db->getPdo()->prepare($sql);
        $params = [
            'scope' => $scope,
            'email_hash' => $emailHash,
            'ip_hash' => $ipHash,
        ];
        if ($businessId !== null) {
            $params['business_id'] = $businessId;
        }

        $stmt->execute($params);

        return (int) $stmt->fetchColumn();
    }

    private function hashEmail(string $email): string
    {
        $normalized = strtolower(trim($email));
        return hash('sha256', $normalized);
    }

    private function hashIp(?string $ipAddress): string
    {
        $normalizedIp = trim((string) $ipAddress);
        if ($normalizedIp === '') {
            $normalizedIp = 'unknown';
        }

        return hash('sha256', $normalizedIp);
    }
}
