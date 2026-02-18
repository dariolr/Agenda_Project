<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;

/**
 * Repository for class_events and class_bookings.
 */
final class ClassEventRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findClassTypes(int $businessId, bool $includeInactive = false): array
    {
        $sql = 'SELECT * FROM class_types WHERE business_id = :business_id';
        if (!$includeInactive) {
            $sql .= ' AND is_active = 1';
        }
        $sql .= ' ORDER BY name ASC, id ASC';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(['business_id' => $businessId]);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function findClassTypeById(int $businessId, int $classTypeId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM class_types
             WHERE business_id = :business_id AND id = :id
             LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'id' => $classTypeId,
        ]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    public function findClassTypeLocationsMap(int $businessId, array $classTypeIds): array
    {
        $classTypeIds = array_values(array_unique(array_map(static fn ($id): int => (int) $id, $classTypeIds)));
        $classTypeIds = array_values(array_filter($classTypeIds, static fn ($id): bool => $id > 0));
        if (empty($classTypeIds)) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($classTypeIds), '?'));
        $sql = "
            SELECT ctl.class_type_id, ctl.location_id
            FROM class_type_locations ctl
            INNER JOIN class_types ct ON ct.id = ctl.class_type_id
            WHERE ct.business_id = ?
              AND ctl.class_type_id IN ({$placeholders})
            ORDER BY ctl.class_type_id ASC, ctl.location_id ASC";

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(array_merge([$businessId], $classTypeIds));
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        $result = [];
        foreach ($rows as $row) {
            $classTypeId = (int) $row['class_type_id'];
            $result[$classTypeId] ??= [];
            $result[$classTypeId][] = (int) $row['location_id'];
        }
        return $result;
    }

    public function classTypeExists(int $businessId, int $classTypeId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM class_types
             WHERE business_id = :business_id
               AND id = :id
             LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'id' => $classTypeId,
        ]);
        return $stmt->fetchColumn() !== false;
    }

    public function classTypeAllowsLocation(int $businessId, int $classTypeId, int $locationId): bool
    {
        $countStmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*)
             FROM class_type_locations ctl
             INNER JOIN class_types ct ON ct.id = ctl.class_type_id
             WHERE ct.business_id = :business_id
               AND ctl.class_type_id = :class_type_id'
        );
        $countStmt->execute([
            'business_id' => $businessId,
            'class_type_id' => $classTypeId,
        ]);
        $bindingsCount = (int) ($countStmt->fetchColumn() ?: 0);
        if ($bindingsCount === 0) {
            return true;
        }

        $matchStmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM class_type_locations ctl
             INNER JOIN class_types ct ON ct.id = ctl.class_type_id
             WHERE ct.business_id = :business_id
               AND ctl.class_type_id = :class_type_id
               AND ctl.location_id = :location_id
             LIMIT 1'
        );
        $matchStmt->execute([
            'business_id' => $businessId,
            'class_type_id' => $classTypeId,
            'location_id' => $locationId,
        ]);
        return $matchStmt->fetchColumn() !== false;
    }

    public function locationExistsInBusiness(int $businessId, int $locationId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM locations
             WHERE id = :location_id
               AND business_id = :business_id
             LIMIT 1'
        );
        $stmt->execute([
            'location_id' => $locationId,
            'business_id' => $businessId,
        ]);
        return $stmt->fetchColumn() !== false;
    }

    public function locationsBelongToBusiness(int $businessId, array $locationIds): bool
    {
        $locationIds = array_values(array_unique(array_map(static fn ($id): int => (int) $id, $locationIds)));
        $locationIds = array_values(array_filter($locationIds, static fn ($id): bool => $id > 0));
        if (empty($locationIds)) {
            return true;
        }

        $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
        $sql = "
            SELECT COUNT(*)
            FROM locations
            WHERE business_id = ?
              AND id IN ({$placeholders})";

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(array_merge([$businessId], $locationIds));
        $count = (int) ($stmt->fetchColumn() ?: 0);
        return $count === count($locationIds);
    }

    public function staffExistsInBusiness(int $businessId, int $staffId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM staff
             WHERE id = :staff_id
               AND business_id = :business_id
             LIMIT 1'
        );
        $stmt->execute([
            'staff_id' => $staffId,
            'business_id' => $businessId,
        ]);
        return $stmt->fetchColumn() !== false;
    }

    public function resourcesBelongToLocation(int $businessId, int $locationId, array $resourceIds): bool
    {
        if (empty($resourceIds)) {
            return true;
        }

        $resourceIds = array_values(array_unique(array_map(static fn ($id): int => (int) $id, $resourceIds)));
        $resourceIds = array_values(array_filter($resourceIds, static fn ($id): bool => $id > 0));
        if (empty($resourceIds)) {
            return true;
        }

        $placeholders = implode(',', array_fill(0, count($resourceIds), '?'));
        $sql = "
            SELECT COUNT(*) AS cnt
            FROM resources r
            INNER JOIN locations l ON l.id = r.location_id
            WHERE l.business_id = ?
              AND r.location_id = ?
              AND r.id IN ({$placeholders})";

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(array_merge([$businessId, $locationId], $resourceIds));
        $count = (int) ($stmt->fetchColumn() ?: 0);
        return $count === count($resourceIds);
    }

    public function createClassType(int $businessId, array $data): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO class_types (
                business_id, name, description, is_active
             ) VALUES (
                :business_id, :name, :description, :is_active
             )'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'is_active' => !empty($data['is_active']) ? 1 : 0,
        ]);
        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function updateClassType(int $businessId, int $classTypeId, array $data): bool
    {
        $allowed = ['name', 'description', 'is_active'];
        $fields = [];
        $params = [
            'business_id' => $businessId,
            'id' => $classTypeId,
        ];

        foreach ($allowed as $field) {
            if (!array_key_exists($field, $data)) {
                continue;
            }
            $fields[] = "{$field} = :{$field}";
            $params[$field] = $field === 'is_active'
                ? (!empty($data[$field]) ? 1 : 0)
                : $data[$field];
        }

        if (empty($fields)) {
            return false;
        }

        $sql = 'UPDATE class_types SET ' . implode(', ', $fields) . '
                WHERE business_id = :business_id AND id = :id';
        $stmt = $this->db->getPdo()->prepare($sql);
        return $stmt->execute($params);
    }

    public function deleteClassType(int $businessId, int $classTypeId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM class_types
             WHERE business_id = :business_id
               AND id = :id
             LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'id' => $classTypeId,
        ]);
        return $stmt->rowCount() > 0;
    }

    public function setClassTypeLocations(int $businessId, int $classTypeId, array $locationIds): void
    {
        $pdo = $this->db->getPdo();
        $locationIds = array_values(array_unique(array_map(static fn ($id): int => (int) $id, $locationIds)));
        $locationIds = array_values(array_filter($locationIds, static fn ($id): bool => $id > 0));

        $pdo->beginTransaction();
        try {
            $deleteStmt = $pdo->prepare(
                'DELETE ctl
                 FROM class_type_locations ctl
                 INNER JOIN class_types ct ON ct.id = ctl.class_type_id
                 WHERE ctl.class_type_id = :class_type_id
                   AND ct.business_id = :business_id'
            );
            $deleteStmt->execute([
                'class_type_id' => $classTypeId,
                'business_id' => $businessId,
            ]);

            if (!empty($locationIds)) {
                $insertStmt = $pdo->prepare(
                    'INSERT INTO class_type_locations (class_type_id, location_id)
                     VALUES (:class_type_id, :location_id)'
                );
                foreach ($locationIds as $locationId) {
                    $insertStmt->execute([
                        'class_type_id' => $classTypeId,
                        'location_id' => $locationId,
                    ]);
                }
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    public function hasClassEventsForType(int $businessId, int $classTypeId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1
             FROM class_events
             WHERE business_id = :business_id
               AND class_type_id = :class_type_id
             LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'class_type_id' => $classTypeId,
        ]);
        return $stmt->fetchColumn() !== false;
    }

    public function findByBusinessAndRange(
        int $businessId,
        string $fromUtc,
        string $toUtc,
        ?int $locationId = null,
        ?int $classTypeId = null,
        ?int $customerId = null
    ): array {
        $sql = '
            SELECT
                ce.*,
                ct.name AS class_type_name,
                COALESCE(l.timezone, "Europe/Rome") AS location_timezone,
                cb.status AS my_booking_status
            FROM class_events ce
            LEFT JOIN class_types ct
              ON ct.id = ce.class_type_id
             AND ct.business_id = ce.business_id
            LEFT JOIN locations l
              ON l.id = ce.location_id
            LEFT JOIN class_bookings cb
                ON cb.business_id = ce.business_id
               AND cb.class_event_id = ce.id
               AND cb.customer_id = :customer_id
            WHERE ce.business_id = :business_id
              AND ce.starts_at >= :from_utc
              AND ce.starts_at < :to_utc';

        $params = [
            'business_id' => $businessId,
            'from_utc' => $fromUtc,
            'to_utc' => $toUtc,
            'customer_id' => $customerId ?? 0,
        ];

        if ($locationId !== null) {
            $sql .= ' AND ce.location_id = :location_id';
            $params['location_id'] = $locationId;
        }
        if ($classTypeId !== null) {
            $sql .= ' AND ce.class_type_id = :class_type_id';
            $params['class_type_id'] = $classTypeId;
        }

        $sql .= ' ORDER BY ce.starts_at ASC, ce.id ASC';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function findById(int $businessId, int $classEventId, ?int $customerId = null): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            '
            SELECT
                ce.*,
                ct.name AS class_type_name,
                COALESCE(l.timezone, "Europe/Rome") AS location_timezone,
                cb.status AS my_booking_status
            FROM class_events ce
            LEFT JOIN class_types ct
              ON ct.id = ce.class_type_id
             AND ct.business_id = ce.business_id
            LEFT JOIN locations l
              ON l.id = ce.location_id
            LEFT JOIN class_bookings cb
                ON cb.business_id = ce.business_id
               AND cb.class_event_id = ce.id
               AND cb.customer_id = :customer_id
            WHERE ce.business_id = :business_id
              AND ce.id = :class_event_id
            LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
            'customer_id' => $customerId ?? 0,
        ]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    public function findParticipants(int $businessId, int $classEventId, ?string $status = null): array
    {
        $sql = '
            SELECT
                cb.*,
                c.first_name AS customer_first_name,
                c.last_name AS customer_last_name
            FROM class_bookings cb
            LEFT JOIN clients c ON c.id = cb.customer_id
            WHERE cb.business_id = :business_id
              AND cb.class_event_id = :class_event_id';

        $params = [
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
        ];

        if ($status !== null && $status !== '') {
            $sql .= ' AND cb.status = :status';
            $params['status'] = strtoupper($status);
        }

        $sql .= ' ORDER BY
            CASE WHEN cb.waitlist_position IS NULL THEN 0 ELSE 1 END ASC,
            cb.waitlist_position ASC,
            cb.booked_at ASC,
            cb.id ASC';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function create(array $data): int
    {
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare(
                '
                INSERT INTO class_events (
                    business_id, class_type_id,
                    starts_at, ends_at,
                    location_id, staff_id,
                    capacity_total, capacity_reserved, confirmed_count, waitlist_count,
                    waitlist_enabled, booking_open_at, booking_close_at,
                    cancel_cutoff_minutes, status, visibility, price_cents, currency
                ) VALUES (
                    :business_id, :class_type_id,
                    :starts_at, :ends_at,
                    :location_id, :staff_id,
                    :capacity_total, :capacity_reserved, :confirmed_count, :waitlist_count,
                    :waitlist_enabled, :booking_open_at, :booking_close_at,
                    :cancel_cutoff_minutes, :status, :visibility, :price_cents, :currency
                )'
            );
            $stmt->execute([
                'business_id' => $data['business_id'],
                'class_type_id' => $data['class_type_id'],
                'starts_at' => $data['starts_at'],
                'ends_at' => $data['ends_at'],
                'location_id' => $data['location_id'],
                'staff_id' => $data['staff_id'],
                'capacity_total' => $data['capacity_total'] ?? 1,
                'capacity_reserved' => $data['capacity_reserved'] ?? 0,
                'confirmed_count' => $data['confirmed_count'] ?? 0,
                'waitlist_count' => $data['waitlist_count'] ?? 0,
                'waitlist_enabled' => !empty($data['waitlist_enabled']) ? 1 : 0,
                'booking_open_at' => $data['booking_open_at'] ?? null,
                'booking_close_at' => $data['booking_close_at'] ?? null,
                'cancel_cutoff_minutes' => $data['cancel_cutoff_minutes'] ?? 0,
                'status' => $data['status'] ?? 'SCHEDULED',
                'visibility' => $data['visibility'] ?? 'PUBLIC',
                'price_cents' => $data['price_cents'] ?? null,
                'currency' => $data['currency'] ?? null,
            ]);
            $classEventId = (int) $pdo->lastInsertId();

            if (array_key_exists('resource_requirements', $data)) {
                $this->replaceResourceRequirements(
                    $pdo,
                    $classEventId,
                    is_array($data['resource_requirements']) ? $data['resource_requirements'] : []
                );
            }

            $pdo->commit();
            return $classEventId;
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    public function update(int $businessId, int $classEventId, array $data): bool
    {
        $allowed = [
            'class_type_id',
            'starts_at',
            'ends_at',
            'location_id',
            'staff_id',
            'capacity_total',
            'capacity_reserved',
            'waitlist_enabled',
            'booking_open_at',
            'booking_close_at',
            'cancel_cutoff_minutes',
            'status',
            'visibility',
            'price_cents',
            'currency',
        ];

        $fields = [];
        $params = [
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
        ];

        foreach ($allowed as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "{$field} = :{$field}";
                $params[$field] = $field === 'waitlist_enabled'
                    ? (!empty($data[$field]) ? 1 : 0)
                    : $data[$field];
            }
        }

        $hasResourceRequirements = array_key_exists('resource_requirements', $data);
        if (empty($fields) && !$hasResourceRequirements) {
            return false;
        }

        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();
        try {
            if (!empty($fields)) {
                $sql = 'UPDATE class_events SET ' . implode(', ', $fields) . '
                        WHERE business_id = :business_id AND id = :class_event_id';
                $stmt = $pdo->prepare($sql);
                $stmt->execute($params);
            }

            if ($hasResourceRequirements) {
                $this->replaceResourceRequirements(
                    $pdo,
                    $classEventId,
                    is_array($data['resource_requirements']) ? $data['resource_requirements'] : []
                );
            }

            $pdo->commit();
            return true;
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    public function findResourceRequirementsForEvents(int $businessId, array $classEventIds): array
    {
        if (empty($classEventIds)) {
            return [];
        }

        $ids = array_values(array_unique(array_map(static fn ($id): int => (int) $id, $classEventIds)));
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $sql = "
            SELECT
                cerr.class_event_id,
                cerr.resource_id,
                cerr.quantity
            FROM class_event_resource_requirements cerr
            INNER JOIN class_events ce ON ce.id = cerr.class_event_id
            WHERE ce.business_id = ?
              AND cerr.class_event_id IN ({$placeholders})
            ORDER BY cerr.class_event_id ASC, cerr.id ASC";

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(array_merge([$businessId], $ids));
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        $grouped = [];
        foreach ($rows as $row) {
            $eventId = (int) $row['class_event_id'];
            $grouped[$eventId] ??= [];
            $grouped[$eventId][] = [
                'resource_id' => (int) $row['resource_id'],
                'quantity' => (int) $row['quantity'],
            ];
        }

        return $grouped;
    }

    public function findResourceRequirementsForEvent(int $businessId, int $classEventId): array
    {
        return $this->findResourceRequirementsForEvents($businessId, [$classEventId])[$classEventId] ?? [];
    }

    public function cancelEvent(int $businessId, int $classEventId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE class_events
             SET status = "CANCELLED"
             WHERE business_id = :business_id AND id = :class_event_id'
        );
        return $stmt->execute([
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
        ]);
    }

    public function deleteEvent(int $businessId, int $classEventId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM class_events
             WHERE business_id = :business_id AND id = :class_event_id
             LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
        ]);
        return $stmt->rowCount() > 0;
    }

    public function book(int $businessId, int $classEventId, int $customerId): array
    {
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();
        try {
            $eventStmt = $pdo->prepare(
                'SELECT * FROM class_events
                 WHERE business_id = :business_id AND id = :class_event_id
                 FOR UPDATE'
            );
            $eventStmt->execute([
                'business_id' => $businessId,
                'class_event_id' => $classEventId,
            ]);
            $event = $eventStmt->fetch(\PDO::FETCH_ASSOC);
            if (!$event) {
                $pdo->rollBack();
                throw new \RuntimeException('class_event_not_found');
            }
            if (($event['status'] ?? 'SCHEDULED') !== 'SCHEDULED') {
                $pdo->rollBack();
                throw new \RuntimeException('class_event_not_bookable');
            }

            $bookingStmt = $pdo->prepare(
                'SELECT * FROM class_bookings
                 WHERE business_id = :business_id
                   AND class_event_id = :class_event_id
                   AND customer_id = :customer_id
                 FOR UPDATE'
            );
            $bookingStmt->execute([
                'business_id' => $businessId,
                'class_event_id' => $classEventId,
                'customer_id' => $customerId,
            ]);
            $existing = $bookingStmt->fetch(\PDO::FETCH_ASSOC);

            if ($existing && in_array($existing['status'], ['CONFIRMED', 'WAITLISTED'], true)) {
                $pdo->commit();
                return $existing;
            }

            $spotsLeft = (int) $event['capacity_total'] - (int) $event['capacity_reserved'] - (int) $event['confirmed_count'];
            if ($spotsLeft > 0) {
                $this->upsertBooking(
                    $pdo,
                    $existing,
                    $businessId,
                    $classEventId,
                    $customerId,
                    'CONFIRMED',
                    null
                );
                $pdo->prepare(
                    'UPDATE class_events
                     SET confirmed_count = confirmed_count + 1
                     WHERE business_id = :business_id AND id = :class_event_id'
                )->execute([
                    'business_id' => $businessId,
                    'class_event_id' => $classEventId,
                ]);
            } elseif ((int) ($event['waitlist_enabled'] ?? 0) === 1) {
                $waitlistPos = (int) $event['waitlist_count'] + 1;
                $this->upsertBooking(
                    $pdo,
                    $existing,
                    $businessId,
                    $classEventId,
                    $customerId,
                    'WAITLISTED',
                    $waitlistPos
                );
                $pdo->prepare(
                    'UPDATE class_events
                     SET waitlist_count = waitlist_count + 1
                     WHERE business_id = :business_id AND id = :class_event_id'
                )->execute([
                    'business_id' => $businessId,
                    'class_event_id' => $classEventId,
                ]);
            } else {
                $pdo->rollBack();
                throw new \RuntimeException('class_event_full');
            }

            $pdo->commit();
            return $this->findBookingByCustomer($businessId, $classEventId, $customerId) ?? [];
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    public function cancelBooking(int $businessId, int $classEventId, int $customerId): bool
    {
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();
        try {
            $eventStmt = $pdo->prepare(
                'SELECT * FROM class_events
                 WHERE business_id = :business_id AND id = :class_event_id
                 FOR UPDATE'
            );
            $eventStmt->execute([
                'business_id' => $businessId,
                'class_event_id' => $classEventId,
            ]);
            $event = $eventStmt->fetch(\PDO::FETCH_ASSOC);
            if (!$event) {
                $pdo->rollBack();
                return false;
            }

            $bookingStmt = $pdo->prepare(
                'SELECT * FROM class_bookings
                 WHERE business_id = :business_id
                   AND class_event_id = :class_event_id
                   AND customer_id = :customer_id
                 FOR UPDATE'
            );
            $bookingStmt->execute([
                'business_id' => $businessId,
                'class_event_id' => $classEventId,
                'customer_id' => $customerId,
            ]);
            $booking = $bookingStmt->fetch(\PDO::FETCH_ASSOC);
            if (!$booking) {
                $pdo->rollBack();
                return false;
            }

            if ($booking['status'] === 'CONFIRMED') {
                $pdo->prepare(
                    'UPDATE class_bookings
                     SET status = "CANCELLED_BY_CUSTOMER",
                         cancelled_at = UTC_TIMESTAMP(),
                         waitlist_position = NULL
                     WHERE id = :id'
                )->execute(['id' => $booking['id']]);

                $pdo->prepare(
                    'UPDATE class_events
                     SET confirmed_count = GREATEST(0, confirmed_count - 1)
                     WHERE business_id = :business_id AND id = :class_event_id'
                )->execute([
                    'business_id' => $businessId,
                    'class_event_id' => $classEventId,
                ]);

                $nextStmt = $pdo->prepare(
                    'SELECT id
                     FROM class_bookings
                     WHERE business_id = :business_id
                       AND class_event_id = :class_event_id
                       AND status = "WAITLISTED"
                     ORDER BY waitlist_position ASC, booked_at ASC, id ASC
                     LIMIT 1
                     FOR UPDATE'
                );
                $nextStmt->execute([
                    'business_id' => $businessId,
                    'class_event_id' => $classEventId,
                ]);
                $next = $nextStmt->fetch(\PDO::FETCH_ASSOC);
                if ($next) {
                    $pdo->prepare(
                        'UPDATE class_bookings
                         SET status = "CONFIRMED", waitlist_position = NULL
                         WHERE id = :id'
                    )->execute(['id' => $next['id']]);

                    $pdo->prepare(
                        'UPDATE class_events
                         SET waitlist_count = GREATEST(0, waitlist_count - 1),
                             confirmed_count = confirmed_count + 1
                         WHERE business_id = :business_id AND id = :class_event_id'
                    )->execute([
                        'business_id' => $businessId,
                        'class_event_id' => $classEventId,
                    ]);
                    $this->repackWaitlist($pdo, $businessId, $classEventId);
                }
            } elseif ($booking['status'] === 'WAITLISTED') {
                $pdo->prepare(
                    'UPDATE class_bookings
                     SET status = "CANCELLED_BY_CUSTOMER",
                         cancelled_at = UTC_TIMESTAMP(),
                         waitlist_position = NULL
                     WHERE id = :id'
                )->execute(['id' => $booking['id']]);

                $pdo->prepare(
                    'UPDATE class_events
                     SET waitlist_count = GREATEST(0, waitlist_count - 1)
                     WHERE business_id = :business_id AND id = :class_event_id'
                )->execute([
                    'business_id' => $businessId,
                    'class_event_id' => $classEventId,
                ]);
                $this->repackWaitlist($pdo, $businessId, $classEventId);
            }

            $pdo->commit();
            return true;
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    public function findClientIdByUser(int $businessId, int $userId): ?int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id
             FROM clients
             WHERE business_id = :business_id
               AND user_id = :user_id
             LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'user_id' => $userId,
        ]);
        $value = $stmt->fetchColumn();
        return $value !== false ? (int) $value : null;
    }

    public function findBookingByCustomer(int $businessId, int $classEventId, int $customerId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT *
             FROM class_bookings
             WHERE business_id = :business_id
               AND class_event_id = :class_event_id
               AND customer_id = :customer_id
             LIMIT 1'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
            'customer_id' => $customerId,
        ]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    private function upsertBooking(
        \PDO $pdo,
        ?array $existing,
        int $businessId,
        int $classEventId,
        int $customerId,
        string $status,
        ?int $waitlistPosition
    ): void {
        if ($existing) {
            $stmt = $pdo->prepare(
                'UPDATE class_bookings
                 SET status = :status,
                     waitlist_position = :waitlist_position,
                     booked_at = UTC_TIMESTAMP(),
                     cancelled_at = NULL,
                     updated_at = UTC_TIMESTAMP()
                 WHERE id = :id'
            );
            $stmt->execute([
                'status' => $status,
                'waitlist_position' => $waitlistPosition,
                'id' => $existing['id'],
            ]);
            return;
        }

        $stmt = $pdo->prepare(
            'INSERT INTO class_bookings (
                business_id, class_event_id, customer_id, status, waitlist_position, booked_at
             ) VALUES (
                :business_id, :class_event_id, :customer_id, :status, :waitlist_position, UTC_TIMESTAMP()
             )'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
            'customer_id' => $customerId,
            'status' => $status,
            'waitlist_position' => $waitlistPosition,
        ]);
    }

    private function repackWaitlist(\PDO $pdo, int $businessId, int $classEventId): void
    {
        $stmt = $pdo->prepare(
            'SELECT id
             FROM class_bookings
             WHERE business_id = :business_id
               AND class_event_id = :class_event_id
               AND status = "WAITLISTED"
             ORDER BY waitlist_position ASC, booked_at ASC, id ASC'
        );
        $stmt->execute([
            'business_id' => $businessId,
            'class_event_id' => $classEventId,
        ]);
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        $position = 1;
        $update = $pdo->prepare('UPDATE class_bookings SET waitlist_position = :pos WHERE id = :id');
        foreach ($rows as $row) {
            $update->execute([
                'pos' => $position,
                'id' => $row['id'],
            ]);
            $position++;
        }
    }

    private function replaceResourceRequirements(\PDO $pdo, int $classEventId, array $requirements): void
    {
        $delete = $pdo->prepare('DELETE FROM class_event_resource_requirements WHERE class_event_id = :class_event_id');
        $delete->execute(['class_event_id' => $classEventId]);

        if (empty($requirements)) {
            return;
        }

        $insert = $pdo->prepare(
            'INSERT INTO class_event_resource_requirements (
                class_event_id, resource_id, quantity
             ) VALUES (
                :class_event_id, :resource_id, :quantity
             )'
        );

        foreach ($requirements as $item) {
            $resourceId = isset($item['resource_id']) ? (int) $item['resource_id'] : 0;
            $quantity = isset($item['quantity']) ? max(1, (int) $item['quantity']) : 1;
            if ($resourceId <= 0) {
                continue;
            }
            $insert->execute([
                'class_event_id' => $classEventId,
                'resource_id' => $resourceId,
                'quantity' => $quantity,
            ]);
        }
    }
}
