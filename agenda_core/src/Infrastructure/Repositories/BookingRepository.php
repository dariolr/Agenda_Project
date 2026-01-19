<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

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
                    st.name AS staff_name, st.surname AS staff_surname
             FROM booking_items bi
             JOIN services s ON bi.service_id = s.id
             JOIN staff st ON bi.staff_id = st.id
             WHERE bi.booking_id = ?
             ORDER BY bi.start_time ASC'
        );
        $stmt->execute([$bookingId]);

        $items = $stmt->fetchAll();
        foreach ($items as &$item) {
            $item['staff_display_name'] = trim($item['staff_name'] . ' ' . substr($item['staff_surname'] ?? '', 0, 1) . '.');
            $item['duration_minutes'] = $this->calculateItemDuration($item);
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
                                   idempotency_key, idempotency_expires_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
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

    public function findByClientId(int $clientId, int $limit = 50, int $offset = 0): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id FROM bookings
             WHERE client_id = ?
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
}
