<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;
use DateTimeImmutable;

/**
 * Repository for booking audit tables: booking_replacements and booking_events
 */
final class BookingAuditRepository
{
    public function __construct(
        private readonly Connection $db,
        private readonly ?UserRepository $userRepo = null,
        private readonly ?ClientRepository $clientRepo = null,
    ) {}

    /**
     * Resolve actor name from actor_id and actor_type.
     * Returns name at current time (for denormalization).
     */
    public function resolveActorName(string $actorType, ?int $actorId): ?string
    {
        if ($actorId === null) {
            return null;
        }

        if ($actorType === 'staff' && $this->userRepo !== null) {
            $user = $this->userRepo->findByIdUnfiltered($actorId);
            if ($user !== null) {
                $name = trim(($user['first_name'] ?? '') . ' ' . ($user['last_name'] ?? ''));
                return !empty($name) ? $name : ($user['email'] ?? null);
            }
        } elseif ($actorType === 'customer' && $this->clientRepo !== null) {
            $client = $this->clientRepo->findByIdUnfiltered($actorId);
            if ($client !== null) {
                $name = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));
                return !empty($name) ? $name : ($client['email'] ?? null);
            }
        }

        return null;
    }

    // ========================================================================
    // booking_replacements
    // ========================================================================

    /**
     * Create a booking replacement record.
     * 
     * @param int $originalBookingId The booking that was replaced
     * @param int $newBookingId The booking that replaced it
     * @param string $actorType 'customer', 'staff', or 'system'
     * @param int|null $actorId Client ID for customer, User ID for staff
     * @param string|null $reason Optional reason for the replacement
     * @return int The created record ID
     */
    public function createReplacement(
        int $originalBookingId,
        int $newBookingId,
        string $actorType,
        ?int $actorId,
        ?string $reason = null
    ): int {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO booking_replacements 
             (original_booking_id, new_booking_id, actor_type, actor_id, reason, created_at)
             VALUES (?, ?, ?, ?, ?, NOW())'
        );
        $stmt->execute([
            $originalBookingId,
            $newBookingId,
            $actorType,
            $actorId,
            $reason,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Find replacement record by original booking ID.
     */
    public function findByOriginalBookingId(int $originalBookingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_replacements WHERE original_booking_id = ?'
        );
        $stmt->execute([$originalBookingId]);
        $result = $stmt->fetch();
        return $result ?: null;
    }

    /**
     * Find replacement record by new booking ID.
     */
    public function findByNewBookingId(int $newBookingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_replacements WHERE new_booking_id = ?'
        );
        $stmt->execute([$newBookingId]);
        $result = $stmt->fetch();
        return $result ?: null;
    }

    // ========================================================================
    // booking_events
    // ========================================================================

    /**
     * Create an immutable booking event.
     * 
     * @param int $bookingId The booking this event relates to
     * @param string $eventType Event type (booking_created, booking_replaced, etc.)
     * @param string $actorType 'customer', 'staff', or 'system'
     * @param int|null $actorId Client ID for customer, User ID for staff
     * @param array $payload Event-specific data (will be JSON encoded)
     * @param string|null $correlationId Optional UUID to correlate related events
     * @param string|null $actorName Denormalized actor name (preserved even if actor deleted)
     * @return int The created event ID
     */
    public function createEvent(
        int $bookingId,
        string $eventType,
        string $actorType,
        ?int $actorId,
        array $payload,
        ?string $correlationId = null,
        ?string $actorName = null
    ): int {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO booking_events 
             (booking_id, event_type, actor_type, actor_id, actor_name, payload_json, correlation_id, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, NOW())'
        );
        $stmt->execute([
            $bookingId,
            $eventType,
            $actorType,
            $actorId,
            $actorName,
            Json::encode($payload),
            $correlationId,
        ]);

        $eventId = (int) $this->db->getPdo()->lastInsertId();
        $this->writeClientEventFromBookingEvent($bookingId, $eventType, $actorId, $payload);

        return $eventId;
    }

    /**
     * Get all events for a booking.
     */
    public function getEventsByBookingId(int $bookingId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_events 
             WHERE booking_id = ? 
             ORDER BY created_at ASC'
        );
        $stmt->execute([$bookingId]);
        
        $events = $stmt->fetchAll();
        foreach ($events as &$event) {
            $event['payload'] = Json::decodeAssoc((string) $event['payload_json']) ?? [];
        }
        return $events;
    }

    /**
     * Get events by correlation ID.
     */
    public function getEventsByCorrelationId(string $correlationId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_events 
             WHERE correlation_id = ? 
             ORDER BY created_at ASC'
        );
        $stmt->execute([$correlationId]);
        
        $events = $stmt->fetchAll();
        foreach ($events as &$event) {
            $event['payload'] = Json::decodeAssoc((string) $event['payload_json']) ?? [];
        }
        return $events;
    }

    /**
     * Get events by type for a booking.
     */
    public function getEventsByType(int $bookingId, string $eventType): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_events 
             WHERE booking_id = ? AND event_type = ?
             ORDER BY created_at ASC'
        );
        $stmt->execute([$bookingId, $eventType]);
        
        $events = $stmt->fetchAll();
        foreach ($events as &$event) {
            $event['payload'] = Json::decodeAssoc((string) $event['payload_json']) ?? [];
        }
        return $events;
    }

    /**
     * Mirror selected booking events into CRM timeline (client_events).
     * Fails open to preserve booking flow even if CRM tables are not migrated yet.
     */
    private function writeClientEventFromBookingEvent(int $bookingId, string $eventType, ?int $actorId, array $payload): void
    {
        $mappedType = match ($eventType) {
            'booking_created', 'booking_cancelled', 'booking_no_show', 'payment' => $eventType,
            default => null,
        };

        if ($mappedType === null) {
            return;
        }

        try {
            $bookingStmt = $this->db->getPdo()->prepare(
                'SELECT business_id, client_id FROM bookings WHERE id = ? LIMIT 1'
            );
            $bookingStmt->execute([$bookingId]);
            $booking = $bookingStmt->fetch();
            if (!$booking || empty($booking['client_id'])) {
                return;
            }

            $insertStmt = $this->db->getPdo()->prepare(
                'INSERT INTO client_events (business_id, client_id, event_type, payload, occurred_at, created_by_user_id)
                 VALUES (?, ?, ?, ?, NOW(), ?)'
            );
            $insertStmt->execute([
                (int) $booking['business_id'],
                (int) $booking['client_id'],
                $mappedType,
                Json::encode([
                    'booking_id' => $bookingId,
                    'source' => 'booking_events',
                    'payload' => $payload,
                ]),
                $actorId,
            ]);
        } catch (\PDOException $e) {
            // Ignore when CRM tables are not available yet or on non-critical CRM persistence errors.
            return;
        }
    }
}
