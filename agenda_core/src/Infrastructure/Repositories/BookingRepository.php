<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Domain\Helpers\Unicode;
use Agenda\Infrastructure\Database\Connection;
use DateTimeImmutable;

/**
 * Repository for bookings and booking_items.
 * 
 * SCHEMA NOTE:
 * - bookings: container (no staff_id - staff is per booking_item)
 * - booking_items: individual appointments with staff_id
 */
final class BookingRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findById(int $bookingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT b.id, b.business_id, b.location_id, b.client_id, b.user_id,
                    b.client_name, b.notes, b.status, b.source,
                    b.replaces_booking_id, b.replaced_by_booking_id,
                    b.idempotency_key, b.created_at, b.updated_at,
                    b.recurrence_rule_id, b.recurrence_index, 
                    b.is_recurrence_parent, b.has_conflict,
                    c.first_name AS client_first_name, c.last_name AS client_last_name,
                    bus.name AS business_name,
                    bus.slug AS business_slug,
                    bus.online_bookings_notification_email AS online_bookings_notification_email,
                    l.name AS location_name,
                    l.address AS location_address,
                    l.city AS location_city,
                    l.country AS location_country,
                    l.timezone AS location_timezone
             FROM bookings b
             LEFT JOIN clients c ON b.client_id = c.id
             LEFT JOIN businesses bus ON b.business_id = bus.id
             LEFT JOIN locations l ON b.location_id = l.id
             WHERE b.id = ?'
        );
        $stmt->execute([$bookingId]);
        $result = $stmt->fetch();

        if (!$result) {
            return null;
        }

        $result['items'] = $this->getBookingItems($bookingId);
        
        // Calculate totals from items
        $result['total_price'] = array_sum(array_column($result['items'], 'price'));
        $result['total_duration_minutes'] = $this->calculateTotalDuration($result['items']);

        return $result;
    }

    public function getCancellationPolicyForBooking(int $bookingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT MIN(bi.start_time) as earliest_start,
                    l.cancellation_hours as location_cancellation_hours,
                    b.cancellation_hours as business_cancellation_hours
             FROM booking_items bi
             JOIN bookings bk ON bi.booking_id = bk.id
             JOIN locations l ON bk.location_id = l.id
             JOIN businesses b ON l.business_id = b.id
             WHERE bk.id = ?
             GROUP BY l.cancellation_hours, b.cancellation_hours'
        );
        $stmt->execute([$bookingId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    public function findByIdempotencyKey(int $businessId, string $idempotencyKey): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id FROM bookings
             WHERE business_id = ? AND idempotency_key = ?
               AND (idempotency_expires_at IS NULL OR idempotency_expires_at > NOW())'
        );
        $stmt->execute([$businessId, $idempotencyKey]);
        $result = $stmt->fetch();

        if (!$result) {
            return null;
        }

        return $this->findById((int) $result['id']);
    }

    public function getBookingItems(int $bookingId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT bi.id, bi.booking_id, bi.location_id, bi.service_id, bi.service_variant_id,
                    bi.staff_id, bi.start_time, bi.end_time, bi.price,
                    bi.extra_blocked_minutes, bi.extra_processing_minutes,
                    bi.service_name_snapshot, bi.client_name_snapshot,
                    s.name AS service_name,
                    st.name AS staff_name, st.surname AS staff_surname,
                    b.business_id, b.client_name AS booking_client_name
             FROM booking_items bi
             JOIN services s ON bi.service_id = s.id
             JOIN staff st ON bi.staff_id = st.id
             JOIN bookings b ON bi.booking_id = b.id
             WHERE bi.booking_id = ?
             ORDER BY bi.start_time ASC'
        );
        $stmt->execute([$bookingId]);

        $items = $stmt->fetchAll();
        foreach ($items as &$item) {
            $item['staff_display_name'] = trim(
                $item['staff_name'] . ' ' . Unicode::firstCharacter((string) ($item['staff_surname'] ?? '')) . '.'
            );
            $item['duration_minutes'] = $this->calculateItemDuration($item);
            // Alias for client_name (uses snapshot or booking's client_name)
            $item['client_name'] = $item['client_name_snapshot'] ?? $item['booking_client_name'] ?? '';
        }

        return $items;
    }

    private function calculateItemDuration(array $item): int
    {
        $start = new DateTimeImmutable($item['start_time']);
        $end = new DateTimeImmutable($item['end_time']);
        return (int) (($end->getTimestamp() - $start->getTimestamp()) / 60);
    }

    private function calculateTotalDuration(array $items): int
    {
        if (empty($items)) {
            return 0;
        }

        $firstStart = new DateTimeImmutable($items[0]['start_time']);
        $lastEnd = new DateTimeImmutable($items[count($items) - 1]['end_time']);
        
        return (int) (($lastEnd->getTimestamp() - $firstStart->getTimestamp()) / 60);
    }

    /**
     * Check for conflicts using SELECT FOR UPDATE.
     * MUST be called inside a transaction.
     * Staff is on booking_items, not bookings.
     */
    public function checkConflicts(
        int $staffId,
        int $locationId,
        DateTimeImmutable $startTime,
        DateTimeImmutable $endTime,
        ?int $excludeBookingId = null
    ): array {
        $sql = "SELECT bi.id, bi.booking_id, bi.start_time, bi.end_time, b.status
                FROM booking_items bi
                JOIN bookings b ON bi.booking_id = b.id
                WHERE bi.staff_id = ?
                  AND bi.location_id = ?
                  AND b.status IN ('pending', 'confirmed')
                  AND bi.start_time < ?
                  AND bi.end_time > ?";
        
        $params = [
            $staffId,
            $locationId,
            $endTime->format('Y-m-d H:i:s'),
            $startTime->format('Y-m-d H:i:s'),
        ];

        if ($excludeBookingId !== null) {
            $sql .= ' AND b.id != ?';
            $params[] = $excludeBookingId;
        }

        $sql .= ' FOR UPDATE';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    public function create(array $data): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO bookings (business_id, location_id, client_id, user_id, 
                                   client_name, notes, status, source,
                                   idempotency_key, idempotency_expires_at,
                                   recurrence_rule_id, recurrence_index, 
                                   is_recurrence_parent, has_conflict)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        
        $idempotencyExpires = null;
        if (!empty($data['idempotency_key'])) {
            $idempotencyExpires = (new DateTimeImmutable('+24 hours'))->format('Y-m-d H:i:s');
        }

        $stmt->execute([
            $data['business_id'],
            $data['location_id'],
            $data['client_id'] ?? null,
            $data['user_id'] ?? null,
            $data['client_name'] ?? null,
            $data['notes'] ?? null,
            $data['status'] ?? 'pending',
            $data['source'] ?? 'online',
            $data['idempotency_key'] ?? null,
            $idempotencyExpires,
            $data['recurrence_rule_id'] ?? null,
            $data['recurrence_index'] ?? null,
            (int) ($data['is_recurrence_parent'] ?? 0),
            (int) ($data['has_conflict'] ?? 0),
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function addBookingItem(int $bookingId, array $item): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO booking_items (booking_id, location_id, service_id, service_variant_id,
                                        staff_id, start_time, end_time, price,
                                        extra_blocked_minutes, extra_processing_minutes,
                                        service_name_snapshot, client_name_snapshot)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $bookingId,
            $item['location_id'],
            $item['service_id'],
            $item['service_variant_id'],
            $item['staff_id'],
            $item['start_time'],
            $item['end_time'],
            $item['price'] ?? 0,
            $item['extra_blocked_minutes'] ?? 0,
            $item['extra_processing_minutes'] ?? 0,
            $item['service_name_snapshot'] ?? null,
            $item['client_name_snapshot'] ?? null,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Delete a single booking item (appointment) from a booking.
     * Returns true if deleted, false if not found.
     */
    public function deleteBookingItem(int $itemId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM booking_items WHERE id = ?'
        );
        $stmt->execute([$itemId]);

        return $stmt->rowCount() > 0;
    }

    /**
     * Count remaining items in a booking.
     */
    public function countBookingItems(int $bookingId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM booking_items WHERE booking_id = ?'
        );
        $stmt->execute([$bookingId]);

        return (int) $stmt->fetchColumn();
    }

    public function updateStatus(int $bookingId, string $status): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE bookings SET status = ?, updated_at = NOW() WHERE id = ?'
        );

        return $stmt->execute([$status, $bookingId]);
    }

    /**
     * @param bool $clearClient Se true, imposta client_id a NULL (rimuovi cliente)
     */
    public function updateBooking(
        int $bookingId,
        ?string $status = null,
        ?string $notes = null,
        ?int $clientId = null,
        ?string $customerName = null,
        bool $clearClient = false
    ): bool {
        $fields = [];
        $params = [];

        if ($status !== null) {
            $fields[] = 'status = ?';
            $params[] = $status;
        }

        if ($notes !== null) {
            $fields[] = 'notes = ?';
            $params[] = $notes;
        }

        // clearClient ha priorità: se true, imposta NULL
        // altrimenti se clientId è specificato, usa quello
        if ($clearClient) {
            $fields[] = 'client_id = NULL';
            // Nessun parametro da aggiungere per NULL
        } elseif ($clientId !== null) {
            $fields[] = 'client_id = ?';
            $params[] = $clientId;
        }

        if ($customerName !== null) {
            $fields[] = 'client_name = ?';
            $params[] = $customerName;
        }

        if (empty($fields)) {
            return false;
        }

        $fields[] = 'updated_at = NOW()';
        $params[] = $bookingId;

        $sql = 'UPDATE bookings SET ' . implode(', ', $fields) . ' WHERE id = ?';
        $stmt = $this->db->getPdo()->prepare($sql);

        return $stmt->execute($params);
    }

    /**
     * Reschedule booking: aggiorna start_time di tutti i booking_items
     * mantenendo le durate e gli intervalli relativi.
     * 
     * @param int $bookingId
     * @param DateTimeImmutable $newStartTime Nuovo orario di inizio
     * @param string|null $notes Note opzionali
     * @return bool
     */
    public function rescheduleBooking(
        int $bookingId,
        DateTimeImmutable $newStartTime,
        ?string $notes = null
    ): bool {
        // Get current booking items
        $items = $this->getBookingItems($bookingId);
        if (empty($items)) {
            return false;
        }

        // Calculate time offset from first item
        $firstItem = $items[0];
        $oldStartTime = new DateTimeImmutable($firstItem['start_time']);
        $offsetSeconds = $newStartTime->getTimestamp() - $oldStartTime->getTimestamp();

        // Update each booking_item with new times
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_items 
             SET start_time = ?, end_time = ? 
             WHERE id = ?'
        );

        foreach ($items as $item) {
            $oldStart = new DateTimeImmutable($item['start_time']);
            $oldEnd = new DateTimeImmutable($item['end_time']);

            $newStart = $oldStart->modify("+{$offsetSeconds} seconds");
            $newEnd = $oldEnd->modify("+{$offsetSeconds} seconds");

            $stmt->execute([
                $newStart->format('Y-m-d H:i:s'),
                $newEnd->format('Y-m-d H:i:s'),
                $item['id'],
            ]);
        }

        // Update booking notes if provided
        if ($notes !== null) {
            $this->updateBooking($bookingId, null, $notes);
        }

        return true;
    }

    /**
     * Soft delete a booking by setting status to 'cancelled'.
     * The booking and its items remain in the database for audit purposes.
     */
    public function deleteBooking(int $bookingId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE bookings SET status = 'cancelled', updated_at = NOW() WHERE id = ?"
        );
        return $stmt->execute([$bookingId]);
    }

    /**
     * Get occupied slots for a staff member in a date range.
     * Used by ComputeAvailability.
     * 
     * @param int $staffId
     * @param int $locationId
     * @param DateTimeImmutable $startDate
     * @param DateTimeImmutable $endDate
     * @param int|null $excludeBookingId Exclude this booking from conflicts (for edit mode)
     * @return array
     */
    public function getOccupiedSlots(
        int $staffId,
        int $locationId,
        DateTimeImmutable $startDate,
        DateTimeImmutable $endDate,
        ?int $excludeBookingId = null
    ): array {
        $sql = "SELECT bi.start_time, bi.end_time
                FROM booking_items bi
                JOIN bookings b ON bi.booking_id = b.id
                WHERE bi.staff_id = ?
                  AND bi.location_id = ?
                  AND b.status IN ('pending', 'confirmed')
                  AND bi.start_time >= ?
                  AND bi.end_time <= ?";
        
        $params = [
            $staffId,
            $locationId,
            $startDate->format('Y-m-d H:i:s'),
            $endDate->format('Y-m-d H:i:s'),
        ];
        
        if ($excludeBookingId !== null) {
            $sql .= " AND b.id != ?";
            $params[] = $excludeBookingId;
        }
        
        $sql .= " ORDER BY bi.start_time ASC";

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /**
     * Get all occupied time slots for a location on a given date range (all staff).
     * Used for min_gap filtering in smart slot display.
     *
     * @param int $locationId Location ID
     * @param DateTimeImmutable $startDate Start of date range
     * @param DateTimeImmutable $endDate End of date range
     * @param int|null $excludeBookingId Exclude this booking from conflicts (for edit mode)
     * @return array
     */
    public function getOccupiedSlotsForLocation(
        int $locationId,
        DateTimeImmutable $startDate,
        DateTimeImmutable $endDate,
        ?int $excludeBookingId = null
    ): array {
        $sql = "SELECT bi.start_time, bi.end_time, bi.staff_id
                FROM booking_items bi
                JOIN bookings b ON bi.booking_id = b.id
                WHERE bi.location_id = ?
                  AND b.status IN ('pending', 'confirmed')
                  AND bi.start_time >= ?
                  AND bi.end_time <= ?";
        
        $params = [
            $locationId,
            $startDate->format('Y-m-d H:i:s'),
            $endDate->format('Y-m-d H:i:s'),
        ];
        
        if ($excludeBookingId !== null) {
            $sql .= " AND b.id != ?";
            $params[] = $excludeBookingId;
        }
        
        $sql .= " ORDER BY bi.start_time ASC";

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /**
     * Find booking items that conflict with the given time range.
     *
     * @param int $locationId Location ID
     * @param int $staffId Staff ID
     * @param string $startTime Start time (Y-m-d H:i:s)
     * @param string $endTime End time (Y-m-d H:i:s)
     * @param int|null $excludeBookingId Exclude this booking from conflicts
     * @return array Conflicting booking items
     */
    public function findConflictingBookings(
        int $locationId,
        int $staffId,
        string $startTime,
        string $endTime,
        ?int $excludeBookingId = null
    ): array {
        $sql = "SELECT bi.id, bi.booking_id, bi.start_time, bi.end_time
                FROM booking_items bi
                JOIN bookings b ON bi.booking_id = b.id
                WHERE bi.staff_id = ?
                  AND bi.location_id = ?
                  AND b.status IN ('pending', 'confirmed')
                  AND (
                      (bi.start_time < ? AND bi.end_time > ?)
                      OR (bi.start_time >= ? AND bi.start_time < ?)
                      OR (bi.end_time > ? AND bi.end_time <= ?)
                  )";
        
        $params = [
            $staffId,
            $locationId,
            $endTime, $startTime,       // Overlaps completely
            $startTime, $endTime,       // Starts during
            $startTime, $endTime,       // Ends during
        ];
        
        if ($excludeBookingId !== null) {
            $sql .= " AND b.id != ?";
            $params[] = $excludeBookingId;
        }

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    public function findByClientId(int $clientId, int $limit = 50, int $offset = 0): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id FROM bookings
             WHERE client_id = ?
               AND status != "replaced"
             ORDER BY created_at DESC
             LIMIT ? OFFSET ?'
        );
        $stmt->execute([$clientId, $limit, $offset]);

        $bookings = [];
        while ($row = $stmt->fetch()) {
            $bookings[] = $this->findById((int) $row['id']);
        }

        return $bookings;
    }

    /**
     * Get bookings for a location on a specific date.
     * Optionally filter by staff_id (via booking_items).
     */
    public function findByLocationAndDate(
        int $locationId,
        string $date,
        ?int $staffId = null,
        int $limit = 100,
        bool $includeReplaced = false
    ): array {
        $startOfDay = $date . ' 00:00:00';
        $endOfDay = $date . ' 23:59:59';

        $sql = "SELECT DISTINCT b.id 
                FROM bookings b
                JOIN booking_items bi ON b.id = bi.booking_id
                WHERE b.location_id = ?
                  AND bi.start_time >= ?
                  AND bi.start_time <= ?";
        
        $params = [$locationId, $startOfDay, $endOfDay];

        if (!$includeReplaced) {
            $sql .= " AND b.status != 'replaced'";
        }

        if ($staffId !== null) {
            $sql .= ' AND bi.staff_id = ?';
            $params[] = $staffId;
        }

        $sql .= ' ORDER BY b.id DESC LIMIT ?';
        $params[] = $limit;

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);

        $bookings = [];
        while ($row = $stmt->fetch()) {
            $bookings[] = $this->findById((int) $row['id']);
        }

        return $bookings;
    }

    /**
     * Get all appointments (booking_items) for a specific location and date.
     * Returns booking_items with joined booking and service info.
     * 
     * @param bool $includeReplaced Include bookings with status 'replaced'
     * @param bool $includeCancelled Include bookings with status 'cancelled' (default false - cancelled appointments are hidden from calendar)
     */
    public function getAppointmentsByLocationAndDate(int $locationId, string $date, bool $includeReplaced = false, bool $includeCancelled = false): array
    {
        $startOfDay = $date . ' 00:00:00';
        $endOfDay = $date . ' 23:59:59';

        $excludedStatuses = [];
        if (!$includeReplaced) {
            $excludedStatuses[] = 'replaced';
        }
        if (!$includeCancelled) {
            $excludedStatuses[] = 'cancelled';
        }
        
        $statusFilter = '';
        if (!empty($excludedStatuses)) {
            $placeholders = implode(', ', array_fill(0, count($excludedStatuses), '?'));
            $statusFilter = "AND b.status NOT IN ($placeholders)";
        }

        $stmt = $this->db->getPdo()->prepare(
            "SELECT bi.id, bi.booking_id, bi.location_id, bi.staff_id, bi.service_id, bi.service_variant_id,
                    bi.start_time, bi.end_time, bi.price, bi.extra_blocked_minutes, bi.extra_processing_minutes,
                    bi.created_at, bi.updated_at,
                    b.status AS booking_status, b.client_name, b.notes AS booking_notes, b.client_id, b.business_id, b.source,
                    b.replaces_booking_id, b.replaced_by_booking_id,
                    b.recurrence_rule_id, b.recurrence_index,
                    (SELECT COUNT(*) FROM bookings b2 WHERE b2.recurrence_rule_id = b.recurrence_rule_id AND b2.status != 'cancelled') AS recurrence_total,
                    c.first_name AS client_first_name, c.last_name AS client_last_name,
                    NULLIF(TRIM(CONCAT(COALESCE(c.first_name, ''), ' ', COALESCE(c.last_name, ''))), '') AS client_full_name,
                    s.name AS service_name,
                    st.name AS staff_name, st.surname AS staff_surname,
                    CONCAT(st.name, ' ', st.surname) AS staff_full_name
             FROM booking_items bi
             JOIN bookings b ON bi.booking_id = b.id
             LEFT JOIN clients c ON b.client_id = c.id
             LEFT JOIN service_variants sv ON bi.service_variant_id = sv.id
             LEFT JOIN services s ON sv.service_id = s.id
             LEFT JOIN staff st ON bi.staff_id = st.id
             WHERE bi.location_id = ?
               AND bi.start_time >= ?
               AND bi.start_time <= ?
               $statusFilter
             ORDER BY bi.start_time ASC, bi.id ASC"
        );
        
        $params = [$locationId, $startOfDay, $endOfDay];
        if (!empty($excludedStatuses)) {
            $params = array_merge($params, $excludedStatuses);
        }
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /**
     * Get a single appointment (booking_item) by ID.
     */
    public function getAppointmentById(int $appointmentId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            "SELECT bi.id, bi.booking_id, bi.location_id, bi.staff_id, bi.service_id, bi.service_variant_id,
                    bi.start_time, bi.end_time, bi.price, bi.extra_blocked_minutes, bi.extra_processing_minutes,
                    bi.created_at, bi.updated_at,
                    b.status AS booking_status, b.client_name, b.notes AS booking_notes, b.client_id, b.business_id, b.source,
                    b.recurrence_rule_id, b.recurrence_index,
                    (SELECT COUNT(*) FROM bookings b2 WHERE b2.recurrence_rule_id = b.recurrence_rule_id AND b2.status != 'cancelled') AS recurrence_total,
                    c.first_name AS client_first_name, c.last_name AS client_last_name,
                    NULLIF(TRIM(CONCAT(COALESCE(c.first_name, ''), ' ', COALESCE(c.last_name, ''))), '') AS client_full_name,
                    s.name AS service_name,
                    CONCAT(st.name, ' ', st.surname) AS staff_name
             FROM booking_items bi
             JOIN bookings b ON bi.booking_id = b.id
             LEFT JOIN clients c ON b.client_id = c.id
             LEFT JOIN service_variants sv ON bi.service_variant_id = sv.id
             LEFT JOIN services s ON sv.service_id = s.id
             LEFT JOIN staff st ON bi.staff_id = st.id
             WHERE bi.id = ?"
        );
        $stmt->execute([$appointmentId]);
        $result = $stmt->fetch();

        return $result ?: null;
    }

    /**
     * Update an appointment (booking_item).
     */
    public function updateAppointment(int $appointmentId, array $data): void
    {
        $fields = [];
        $params = [];

        foreach (['start_time', 'end_time', 'staff_id', 'service_id', 'service_variant_id', 'service_name_snapshot', 'client_name_snapshot', 'extra_blocked_minutes', 'extra_processing_minutes', 'price'] as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = ?";
                $params[] = $data[$field];
            }
        }

        if (empty($fields)) {
            return;
        }

        $fields[] = 'updated_at = NOW()';
        $params[] = $appointmentId;

        $sql = 'UPDATE booking_items SET ' . implode(', ', $fields) . ' WHERE id = ?';
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
    }

    /**
     * Lock a booking row for update (SELECT ... FOR UPDATE).
     * MUST be called inside a transaction.
     */
    public function lockForUpdate(int $bookingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT b.*, 
                    b.replaces_booking_id, b.replaced_by_booking_id
             FROM bookings b
             WHERE b.id = ?
             FOR UPDATE'
        );
        $stmt->execute([$bookingId]);
        return $stmt->fetch() ?: null;
    }

    /**
     * Mark a booking as replaced.
     */
    public function markAsReplaced(int $bookingId, int $replacedByBookingId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE bookings 
             SET status = ?, replaced_by_booking_id = ?, updated_at = NOW()
             WHERE id = ?'
        );
        $stmt->execute(['replaced', $replacedByBookingId, $bookingId]);
    }

    /**
     * Set the replaces_booking_id on a new booking.
     */
    public function setReplacesBookingId(int $newBookingId, int $originalBookingId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE bookings 
             SET replaces_booking_id = ?, updated_at = NOW()
             WHERE id = ?'
        );
        $stmt->execute([$originalBookingId, $newBookingId]);
    }

    /**
     * Get booking with replace info.
     */
    public function findByIdWithReplaceInfo(int $bookingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT b.id, b.business_id, b.location_id, b.client_id, b.user_id,
                    b.client_name, b.notes, b.status, b.source,
                    b.idempotency_key, b.created_at, b.updated_at,
                    b.replaces_booking_id, b.replaced_by_booking_id,
                    c.first_name AS client_first_name, c.last_name AS client_last_name
             FROM bookings b
             LEFT JOIN clients c ON b.client_id = c.id
             WHERE b.id = ?'
        );
        $stmt->execute([$bookingId]);
        $result = $stmt->fetch();

        if (!$result) {
            return null;
        }

        $result['items'] = $this->getBookingItems($bookingId);
        $result['total_price'] = array_sum(array_column($result['items'], 'price'));
        $result['total_duration_minutes'] = $this->calculateTotalDuration($result['items']);

        return $result;
    }

    public function db(): Connection
    {
        return $this->db;
    }

    // ========================================
    // RECURRING BOOKING METHODS
    // ========================================

    /**
     * Trova tutte le booking di una serie ricorrente.
     *
     * @return array[] Lista di booking appartenenti alla stessa serie
     */
    public function findByRecurrenceRuleId(int $ruleId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT b.id, b.business_id, b.location_id, b.client_id, b.user_id,
                    b.client_name, b.notes, b.status, b.source,
                    b.recurrence_rule_id, b.recurrence_index, 
                    b.is_recurrence_parent, b.has_conflict,
                    b.created_at, b.updated_at,
                    c.first_name AS client_first_name, c.last_name AS client_last_name
             FROM bookings b
             LEFT JOIN clients c ON b.client_id = c.id
             WHERE b.recurrence_rule_id = ?
             ORDER BY b.recurrence_index ASC'
        );
        $stmt->execute([$ruleId]);

        $bookings = [];
        while ($row = $stmt->fetch()) {
            $row['items'] = $this->getBookingItems((int) $row['id']);
            $row['total_price'] = array_sum(array_column($row['items'], 'price'));
            $row['total_duration_minutes'] = $this->calculateTotalDuration($row['items']);
            $bookings[] = $row;
        }

        return $bookings;
    }

    /**
     * Trova la booking "parent" di una serie ricorrente.
     */
    public function findRecurrenceParent(int $ruleId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT b.id, b.business_id, b.location_id, b.client_id, b.user_id,
                    b.client_name, b.notes, b.status, b.source,
                    b.recurrence_rule_id, b.recurrence_index, 
                    b.is_recurrence_parent, b.has_conflict,
                    b.created_at, b.updated_at,
                    c.first_name AS client_first_name, c.last_name AS client_last_name
             FROM bookings b
             LEFT JOIN clients c ON b.client_id = c.id
             WHERE b.recurrence_rule_id = ? AND b.is_recurrence_parent = 1
             LIMIT 1'
        );
        $stmt->execute([$ruleId]);
        $result = $stmt->fetch();

        if (!$result) {
            return null;
        }

        $result['items'] = $this->getBookingItems((int) $result['id']);
        $result['total_price'] = array_sum(array_column($result['items'], 'price'));
        $result['total_duration_minutes'] = $this->calculateTotalDuration($result['items']);

        return $result;
    }

    /**
     * Conta le booking di una serie ricorrente.
     */
    public function countByRecurrenceRuleId(int $ruleId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM bookings WHERE recurrence_rule_id = ?'
        );
        $stmt->execute([$ruleId]);
        return (int) $stmt->fetchColumn();
    }

    /**
     * Conta le booking con conflitto in una serie.
     */
    public function countConflictsByRecurrenceRuleId(int $ruleId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM bookings WHERE recurrence_rule_id = ? AND has_conflict = 1'
        );
        $stmt->execute([$ruleId]);
        return (int) $stmt->fetchColumn();
    }

    /**
     * Cancella tutte le booking future di una serie (da un certo index in poi).
     *
     * @return int Numero di booking cancellate
     */
    public function cancelFutureRecurrences(int $ruleId, int $fromIndex): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE bookings 
             SET status = \'cancelled\', updated_at = NOW()
             WHERE recurrence_rule_id = ? AND recurrence_index >= ?'
        );
        $stmt->execute([$ruleId, $fromIndex]);
        return $stmt->rowCount();
    }

    /**
     * Cancella tutte le booking di una serie.
     *
     * @return int Numero di booking cancellate
     */
    public function cancelAllRecurrences(int $ruleId): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE bookings 
             SET status = \'cancelled\', updated_at = NOW()
             WHERE recurrence_rule_id = ?'
        );
        $stmt->execute([$ruleId]);
        return $stmt->rowCount();
    }

    /**
     * Aggiorna il flag has_conflict per una booking.
     */
    public function setHasConflict(int $bookingId, bool $hasConflict): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE bookings 
             SET has_conflict = ?, updated_at = NOW()
             WHERE id = ?'
        );
        $stmt->execute([$hasConflict ? 1 : 0, $bookingId]);
    }

    /**
     * Trova booking ricorrenti future per un client.
     *
     * @return array[] Lista di serie ricorrenti con booking future
     */
    public function findFutureRecurrencesByClientId(int $clientId, string $afterDate): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT DISTINCT b.recurrence_rule_id, 
                    MIN(bi.start_time) as next_occurrence,
                    COUNT(*) as remaining_occurrences
             FROM bookings b
             JOIN booking_items bi ON b.id = bi.booking_id
             WHERE b.client_id = ? 
               AND b.recurrence_rule_id IS NOT NULL
               AND b.status != \'cancelled\'
               AND bi.start_time > ?
             GROUP BY b.recurrence_rule_id
             ORDER BY next_occurrence ASC'
        );
        $stmt->execute([$clientId, $afterDate]);
        return $stmt->fetchAll();
    }

    /**
     * Find bookings with advanced filters for the bookings list view.
     * 
     * @param int $businessId Business ID
     * @param array $filters Filters: location_id, staff_id, service_id, client_search,
     *                       status, source, start_date, end_date, include_past, sort_by, sort_order
     * @param int $limit Max results
     * @param int $offset Pagination offset
     * @return array{bookings: array, total: int}
     */
    public function findWithFilters(int $businessId, array $filters = [], int $limit = 50, int $offset = 0): array
    {
        $now = (new DateTimeImmutable())->format('Y-m-d H:i:s');
        
        // Base query - join booking_items to get first appointment time
        $baseSelect = "
            SELECT b.id, b.business_id, b.location_id, b.client_id, b.user_id,
                   b.client_name, b.notes, b.status, b.source,
                   b.created_at, b.updated_at,
                   b.recurrence_rule_id, b.recurrence_index,
                   c.first_name AS client_first_name, c.last_name AS client_last_name,
                   c.email AS client_email, c.phone AS client_phone,
                   l.name AS location_name,
                   MIN(bi.start_time) AS first_start_time,
                   MAX(bi.end_time) AS last_end_time,
                   SUM(bi.price) AS total_price,
                   GROUP_CONCAT(DISTINCT s.name ORDER BY bi.start_time SEPARATOR ', ') AS service_names,
                   GROUP_CONCAT(DISTINCT CONCAT(st.name, ' ', LEFT(st.surname, 1), '.') ORDER BY bi.start_time SEPARATOR ', ') AS staff_names,
                   creator.first_name AS creator_first_name, creator.last_name AS creator_last_name
            FROM bookings b
            LEFT JOIN clients c ON b.client_id = c.id
            LEFT JOIN locations l ON b.location_id = l.id
            LEFT JOIN users creator ON b.user_id = creator.id
            JOIN booking_items bi ON b.id = bi.booking_id
            JOIN services s ON bi.service_id = s.id
            JOIN staff st ON bi.staff_id = st.id
        ";
        
        $countSelect = "SELECT COUNT(DISTINCT b.id) FROM bookings b
            LEFT JOIN clients c ON b.client_id = c.id
            JOIN booking_items bi ON b.id = bi.booking_id";
        
        $where = ['b.business_id = ?'];
        $params = [$businessId];
        
        // Location filter - support both single and multi-select
        if (!empty($filters['location_ids']) && is_array($filters['location_ids'])) {
            $placeholders = implode(',', array_fill(0, count($filters['location_ids']), '?'));
            $where[] = "b.location_id IN ($placeholders)";
            $params = array_merge($params, $filters['location_ids']);
        } elseif (!empty($filters['location_id'])) {
            $where[] = 'b.location_id = ?';
            $params[] = (int) $filters['location_id'];
        }
        
        // Staff filter - support both single and multi-select
        if (!empty($filters['staff_ids']) && is_array($filters['staff_ids'])) {
            $placeholders = implode(',', array_fill(0, count($filters['staff_ids']), '?'));
            $where[] = "bi.staff_id IN ($placeholders)";
            $params = array_merge($params, $filters['staff_ids']);
        } elseif (!empty($filters['staff_id'])) {
            $where[] = 'bi.staff_id = ?';
            $params[] = (int) $filters['staff_id'];
        }
        
        // Service filter - support both single and multi-select
        if (!empty($filters['service_ids']) && is_array($filters['service_ids'])) {
            $placeholders = implode(',', array_fill(0, count($filters['service_ids']), '?'));
            $where[] = "bi.service_id IN ($placeholders)";
            $params = array_merge($params, $filters['service_ids']);
        } elseif (!empty($filters['service_id'])) {
            $where[] = 'bi.service_id = ?';
            $params[] = (int) $filters['service_id'];
        }
        
        // Client search (name, email, phone)
        if (!empty($filters['client_search'])) {
            $search = '%' . $filters['client_search'] . '%';
            $where[] = '(c.first_name LIKE ? OR c.last_name LIKE ? OR c.email LIKE ? OR c.phone LIKE ? OR b.client_name LIKE ?)';
            $params[] = $search;
            $params[] = $search;
            $params[] = $search;
            $params[] = $search;
            $params[] = $search;
        }
        
        // Status filter
        if (!empty($filters['status'])) {
            if (is_array($filters['status'])) {
                $placeholders = implode(',', array_fill(0, count($filters['status']), '?'));
                $where[] = "b.status IN ($placeholders)";
                $params = array_merge($params, $filters['status']);
            } else {
                $where[] = 'b.status = ?';
                $params[] = $filters['status'];
            }
        }

        // Source filter
        if (!empty($filters['source'])) {
            if (is_array($filters['source'])) {
                $placeholders = implode(',', array_fill(0, count($filters['source']), '?'));
                $where[] = "b.source IN ($placeholders)";
                $params = array_merge($params, $filters['source']);
            } else {
                $where[] = 'b.source = ?';
                $params[] = $filters['source'];
            }
        }
        
        // Date range filter
        if (!empty($filters['start_date'])) {
            $where[] = 'bi.start_time >= ?';
            $params[] = $filters['start_date'] . ' 00:00:00';
        }
        
        if (!empty($filters['end_date'])) {
            $where[] = 'bi.start_time <= ?';
            $params[] = $filters['end_date'] . ' 23:59:59';
        }
        
        // Include past or only future
        $includePast = $filters['include_past'] ?? false;
        if (!$includePast) {
            $where[] = 'bi.start_time >= ?';
            $params[] = $now;
        }
        
        $whereClause = ' WHERE ' . implode(' AND ', $where);
        $groupBy = ' GROUP BY b.id';
        
        // Sorting
        $sortBy = $filters['sort_by'] ?? 'appointment'; // 'appointment' or 'created'
        $sortOrder = strtoupper($filters['sort_order'] ?? 'DESC');
        if (!in_array($sortOrder, ['ASC', 'DESC'])) {
            $sortOrder = 'DESC';
        }
        
        $orderBy = match($sortBy) {
            'created' => " ORDER BY b.created_at $sortOrder",
            default => " ORDER BY first_start_time $sortOrder",
        };
        
        // Count total
        $countParams = $params;
        $countStmt = $this->db->getPdo()->prepare($countSelect . $whereClause);
        $countStmt->execute($countParams);
        $total = (int) $countStmt->fetchColumn();
        
        // Get bookings with pagination
        $sql = $baseSelect . $whereClause . $groupBy . $orderBy . " LIMIT $limit OFFSET $offset";
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $bookings = $stmt->fetchAll();
        
        // Enrich each booking with items
        foreach ($bookings as &$booking) {
            $booking['items'] = $this->getBookingItems((int) $booking['id']);
        }
        
        return [
            'bookings' => $bookings,
            'total' => $total,
        ];
    }

}
