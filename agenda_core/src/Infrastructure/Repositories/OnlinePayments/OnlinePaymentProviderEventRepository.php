<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories\OnlinePayments;

use Agenda\Domain\OnlinePayments\OnlinePaymentWebhookResult;
use Agenda\Infrastructure\Database\Connection;

final class OnlinePaymentProviderEventRepository
{
    public function __construct(private readonly Connection $db) {}

    public function storeProcessedEvent(OnlinePaymentWebhookResult $result): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT IGNORE INTO online_payment_provider_events
                (provider_code, provider_event_id, event_type, business_id, online_booking_payment_id, payload_json, processed_at)
             VALUES (?, ?, ?, ?, ?, ?, NOW())'
        );
        $stmt->execute([
            $result->providerCode,
            $result->providerEventId,
            $result->eventType,
            $result->businessId,
            $result->onlineBookingPaymentId,
            json_encode($result->rawPayload, JSON_THROW_ON_ERROR),
        ]);

        return $stmt->rowCount() > 0;
    }
}
