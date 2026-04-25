<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories\Billing;

use Agenda\Domain\Billing\BillingWebhookResult;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;

final class BillingProviderEventRepository
{
    public function __construct(private readonly Connection $db) {}

    public function exists(string $providerCode, string $providerEventId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM billing_provider_events WHERE provider_code = ? AND provider_event_id = ? LIMIT 1'
        );
        $stmt->execute([$providerCode, $providerEventId]);

        return $stmt->fetchColumn() !== false;
    }

    public function storeProcessedEvent(BillingWebhookResult $result): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO billing_provider_events
                (provider_code, provider_event_id, event_type, business_id, payload_json, processed_at)
             VALUES (?, ?, ?, ?, ?, UTC_TIMESTAMP())'
        );
        $stmt->execute([
            $result->providerCode,
            $result->providerEventId,
            $result->eventType,
            $result->businessId,
            Json::encode($result->rawPayload),
        ]);
    }
}
