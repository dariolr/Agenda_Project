<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\RecurrenceRuleRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Domain\Exceptions\BookingException;
use Agenda\UseCases\Notifications\QueueBookingReminder;
use DateTimeImmutable;

/**
 * Modify multiple bookings in a recurring series.
 * 
 * Supports modifying:
 * - staff_id: Change the assigned staff for all/future bookings
 * - service_id: Change service for all/future bookings
 * - service_variant_id: Change service variant for all/future bookings
 * - package_id: Change package (or clear it with null) for all/future bookings
 * - price: Change applied price (or clear it with null) for all/future bookings
 * - notes: Update notes for all/future bookings
 * - time: Change the time (hour:minute) for all/future bookings (date stays the same)
 * - duration_minutes: Change appointment duration (in minutes) for all/future bookings
 * 
 * Scope options:
 * - 'all': Modify all bookings in the series
 * - 'future': Modify only bookings from a given index onwards
 */
final class ModifyRecurringSeries
{
    public function __construct(
        private readonly Connection $db,
        private readonly BookingRepository $bookingRepository,
        private readonly RecurrenceRuleRepository $recurrenceRuleRepository,
        private readonly StaffRepository $staffRepository,
        private readonly ?BookingAuditRepository $auditRepository = null,
        private readonly ?NotificationRepository $notificationRepository = null,
    ) {}

    /**
     * Modify bookings in a recurring series.
     *
     * @param int $userId The authenticated user ID (operator)
     * @param int $ruleId The recurrence rule ID
     * @param array $changes {
     *   staff_id?: int,
     *   service_id?: int,
     *   service_variant_id?: int,
     *   package_id?: int|null,
     *   price?: float|null,
     *   notes?: string|null,
     *   time?: string (HH:MM format),
     *   duration_minutes?: int
     * }
     * @param string $scope 'all' or 'future'
     * @param int $fromIndex For scope='future', start from this index (default 0)
     * @return array {
     *   modified_count: int,
     *   scope: string,
     *   from_index: int|null,
     *   changes_applied: array
     * }
     * @throws BookingException
     */
    public function execute(
        int $userId,
        int $ruleId,
        array $changes,
        string $scope = 'all',
        int $fromIndex = 0
    ): array {
        // Validate scope
        if (!in_array($scope, ['all', 'future'], true)) {
            throw new \InvalidArgumentException("Invalid scope: {$scope}. Must be 'all' or 'future'");
        }

        // Get recurrence rule
        $rule = $this->recurrenceRuleRepository->findById($ruleId);
        if ($rule === null) {
            throw BookingException::notFound($ruleId);
        }

        // Validate staff if provided
        if (isset($changes['staff_id'])) {
            $staff = $this->staffRepository->findById((int) $changes['staff_id']);
            if (!$staff) {
                throw BookingException::invalidStaff((int) $changes['staff_id']);
            }
        }

        // Validate time format if provided
        $newTime = null;
        if (isset($changes['time'])) {
            if (!preg_match('/^\d{2}:\d{2}$/', $changes['time'])) {
                throw BookingException::invalidTime("Time must be in HH:MM format");
            }
            $newTime = $changes['time'];
        }

        if (isset($changes['duration_minutes'])) {
            $durationMinutes = (int) $changes['duration_minutes'];
            if ($durationMinutes <= 0) {
                throw BookingException::validationError('duration_minutes must be greater than 0');
            }
        }

        // Get bookings to modify
        $allBookings = $this->bookingRepository->findByRecurrenceRuleId($ruleId);
        
        // Filter by scope
        $bookingsToModify = [];
        foreach ($allBookings as $booking) {
            // Skip cancelled bookings
            if ($booking['status'] === 'cancelled') {
                continue;
            }
            
            if ($scope === 'all') {
                $bookingsToModify[] = $booking;
            } elseif ($scope === 'future' && ($booking['recurrence_index'] ?? 0) >= $fromIndex) {
                $bookingsToModify[] = $booking;
            }
        }

        if (empty($bookingsToModify)) {
            return [
                'modified_count' => 0,
                'scope' => $scope,
                'from_index' => $scope === 'future' ? $fromIndex : null,
                'changes_applied' => [],
            ];
        }

        // Start transaction
        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();

        try {
            $modifiedCount = 0;
            $changesApplied = [];
            $actorName = $this->auditRepository?->resolveActorName('staff', $userId);

            foreach ($bookingsToModify as $booking) {
                $bookingId = (int) $booking['id'];
                $bookingChanges = [];
                $itemChanges = [];

                // Apply staff change
                if (isset($changes['staff_id'])) {
                    $itemChanges['staff_id'] = (int) $changes['staff_id'];
                    $changesApplied['staff_id'] = (int) $changes['staff_id'];
                }
                if (isset($changes['service_id'])) {
                    $itemChanges['service_id'] = (int) $changes['service_id'];
                    $changesApplied['service_id'] = (int) $changes['service_id'];
                }
                if (isset($changes['service_variant_id'])) {
                    $itemChanges['service_variant_id'] = (int) $changes['service_variant_id'];
                    $changesApplied['service_variant_id'] = (int) $changes['service_variant_id'];
                }
                if (array_key_exists('package_id', $changes)) {
                    $itemChanges['package_id'] = $changes['package_id'] !== null
                        ? (int) $changes['package_id']
                        : null;
                    $changesApplied['package_id'] = $changes['package_id'];
                }
                if (array_key_exists('price', $changes)) {
                    $itemChanges['price'] = $changes['price'] !== null
                        ? (float) $changes['price']
                        : null;
                    $changesApplied['price'] = $changes['price'];
                }
                if (isset($changes['duration_minutes'])) {
                    $changesApplied['duration_minutes'] = (int) $changes['duration_minutes'];
                }

                $hasItemMutation = !empty($itemChanges) ||
                    $newTime !== null ||
                    isset($changes['duration_minutes']);
                $beforeItemsById = [];
                if ($hasItemMutation) {
                    $beforeItemsById = $this->fetchBookingItemsForAudit($bookingId);
                }

                // Apply notes change
                if (array_key_exists('notes', $changes)) {
                    $bookingChanges['notes'] = $changes['notes'];
                    $changesApplied['notes'] = $changes['notes'];
                }

                // Apply time change to booking items
                if ($newTime !== null) {
                    $this->updateBookingItemsTime($bookingId, $newTime);
                    $changesApplied['time'] = $newTime;
                }

                // Update booking if there are booking-level changes
                if (isset($bookingChanges['notes'])) {
                    $this->bookingRepository->updateBooking(
                        bookingId: $bookingId,
                        notes: $bookingChanges['notes']
                    );
                }

                // Update booking items if there are item-level changes
                if (!empty($itemChanges)) {
                    $this->updateBookingItems($bookingId, $itemChanges);
                }

                // Apply duration change to booking items
                if (isset($changes['duration_minutes'])) {
                    $this->updateBookingItemsDuration($bookingId, (int) $changes['duration_minutes']);
                }

                // Log booking-level audit event (notes only)
                if ($this->auditRepository !== null && !empty($bookingChanges)) {
                    try {
                        $this->auditRepository->createEvent(
                            bookingId: $bookingId,
                            eventType: 'booking_updated',
                            actorType: 'staff',
                            actorId: $userId,
                            payload: [
                                'action' => 'recurring_series_modification',
                                'scope' => $scope,
                                'changes' => $bookingChanges,
                            ],
                            correlationId: "recurring_modify_{$ruleId}",
                            actorName: $actorName
                        );
                    } catch (\Exception $e) {
                        error_log("Failed to log recurring modification audit: " . $e->getMessage());
                    }
                }

                // Log appointment-level audit events for propagated appointment changes
                if ($this->auditRepository !== null && $hasItemMutation) {
                    try {
                        $afterItemsById = $this->fetchBookingItemsForAudit($bookingId);
                        foreach ($afterItemsById as $appointmentId => $afterItem) {
                            if (!isset($beforeItemsById[$appointmentId])) {
                                continue;
                            }
                            $beforeItem = $beforeItemsById[$appointmentId];
                            $changedFields = $this->getActuallyChangedAppointmentFields(
                                $beforeItem,
                                $afterItem
                            );
                            if (empty($changedFields)) {
                                continue;
                            }

                            $this->auditRepository->createEvent(
                                bookingId: $bookingId,
                                eventType: 'appointment_updated',
                                actorType: 'staff',
                                actorId: $userId,
                                payload: [
                                    'appointment_id' => $appointmentId,
                                    'before' => $beforeItem,
                                    'after' => $afterItem,
                                    'changed_fields' => array_keys($changedFields),
                                    'action' => 'recurring_series_modification',
                                    'scope' => $scope,
                                ],
                                correlationId: "recurring_modify_{$ruleId}",
                                actorName: $actorName
                            );
                        }
                    } catch (\Throwable $e) {
                        error_log("Failed to log recurring appointment audit: " . $e->getMessage());
                    }
                }

                // If schedule/service changed, refresh reminder payload/schedule.
                $shouldRefreshReminder = $newTime !== null ||
                    isset($changes['duration_minutes']) ||
                    isset($changes['service_id']) ||
                    isset($changes['service_variant_id']);
                if ($shouldRefreshReminder) {
                    $this->refreshBookingReminder($bookingId);
                }

                $modifiedCount++;
            }

            $pdo->commit();

            return [
                'modified_count' => $modifiedCount,
                'scope' => $scope,
                'from_index' => $scope === 'future' ? $fromIndex : null,
                'changes_applied' => array_unique(array_keys($changesApplied)),
            ];

        } catch (\Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Update all items of a booking with the given changes.
     */
    private function updateBookingItems(int $bookingId, array $changes): void
    {
        $setClauses = [];
        $params = [];

        if (isset($changes['staff_id'])) {
            $setClauses[] = 'staff_id = ?';
            $params[] = $changes['staff_id'];
        }
        if (isset($changes['service_id'])) {
            $setClauses[] = 'service_id = ?';
            $params[] = $changes['service_id'];
        }
        if (isset($changes['service_variant_id'])) {
            $setClauses[] = 'service_variant_id = ?';
            $params[] = $changes['service_variant_id'];
        }
        if (array_key_exists('package_id', $changes)) {
            $setClauses[] = 'package_id = ?';
            $params[] = $changes['package_id'];
            $setClauses[] = 'pricing_source = ?';
            $params[] = $changes['package_id'] !== null ? 'package' : 'custom';
        }
        if (array_key_exists('price', $changes)) {
            $price = $changes['price'];
            $setClauses[] = 'price = ?';
            $params[] = $price;
            $setClauses[] = 'list_price_cents = ?';
            $params[] = $price !== null ? (int) round(((float) $price) * 100) : null;
            $setClauses[] = 'applied_price_cents = ?';
            $params[] = $price !== null ? (int) round(((float) $price) * 100) : null;
            if (!array_key_exists('package_id', $changes)) {
                $setClauses[] = 'pricing_source = ?';
                $params[] = $price !== null ? 'custom' : null;
            }
        }

        if (empty($setClauses)) {
            return;
        }

        $params[] = $bookingId;

        $sql = "UPDATE booking_items SET " . implode(', ', $setClauses) . " WHERE booking_id = ?";
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
    }

    /**
     * Update the time (hour:minute) for all items of a booking.
     * The date remains the same, only the time portion changes.
     */
    private function updateBookingItemsTime(int $bookingId, string $newTime): void
    {
        [$newHour, $newMinute] = explode(':', $newTime);

        // Get current items to calculate time shift
        $stmt = $this->db->getPdo()->prepare(
            "SELECT id, start_time, end_time FROM booking_items WHERE booking_id = ? ORDER BY start_time"
        );
        $stmt->execute([$bookingId]);
        $items = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        if (empty($items)) {
            return;
        }

        // Calculate the time shift based on the first item
        $firstStart = new DateTimeImmutable($items[0]['start_time']);
        $newFirstStart = $firstStart->setTime((int) $newHour, (int) $newMinute, 0);
        $shift = $firstStart->getTimestamp() - $newFirstStart->getTimestamp();

        // Update each item with the time shift
        $updateStmt = $this->db->getPdo()->prepare(
            "UPDATE booking_items SET start_time = ?, end_time = ? WHERE id = ?"
        );

        foreach ($items as $item) {
            $oldStart = new DateTimeImmutable($item['start_time']);
            $oldEnd = new DateTimeImmutable($item['end_time']);

            $newStart = $oldStart->modify("-{$shift} seconds");
            $newEnd = $oldEnd->modify("-{$shift} seconds");

            $updateStmt->execute([
                $newStart->format('Y-m-d H:i:s'),
                $newEnd->format('Y-m-d H:i:s'),
                $item['id'],
            ]);
        }
    }

    /**
     * Update duration for all items of a booking.
     * Keeps each item's start_time unchanged and recomputes end_time = start_time + duration.
     */
    private function updateBookingItemsDuration(int $bookingId, int $durationMinutes): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, start_time FROM booking_items WHERE booking_id = ?'
        );
        $stmt->execute([$bookingId]);
        $items = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        if (empty($items)) {
            return;
        }

        $updateStmt = $this->db->getPdo()->prepare(
            'UPDATE booking_items SET end_time = ? WHERE id = ?'
        );

        foreach ($items as $item) {
            $start = new DateTimeImmutable((string) $item['start_time']);
            $end = $start->modify("+{$durationMinutes} minutes");
            $updateStmt->execute([
                $end->format('Y-m-d H:i:s'),
                (int) $item['id'],
            ]);
        }
    }

    private function refreshBookingReminder(int $bookingId): void
    {
        if ($this->notificationRepository === null) {
            return;
        }

        try {
            $reminderUseCase = new QueueBookingReminder($this->db, $this->notificationRepository);
            $reminderUseCase->refreshReminder($bookingId);
        } catch (\Throwable $e) {
            // Keep series modification non-blocking on reminder errors.
            error_log("Failed to refresh reminder for recurring booking {$bookingId}: " . $e->getMessage());
        }
    }

    /**
     * Load appointment states for audit, indexed by appointment (booking_item) id.
     *
     * @return array<int, array{
     *   id:int,
     *   staff_id:int,
     *   service_id:int,
     *   service_variant_id:int,
     *   package_id:int|null,
     *   start_time:string,
     *   end_time:string,
     *   price:float|null,
     *   extra_blocked_minutes:int,
     *   extra_processing_minutes:int
     * }>
     */
    private function fetchBookingItemsForAudit(int $bookingId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT
                id,
                staff_id,
                service_id,
                service_variant_id,
                package_id,
                start_time,
                end_time,
                price,
                extra_blocked_minutes,
                extra_processing_minutes
             FROM booking_items
             WHERE booking_id = ?'
        );
        $stmt->execute([$bookingId]);
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        $itemsById = [];
        foreach ($rows as $row) {
            $id = (int) $row['id'];
            $itemsById[$id] = [
                'id' => $id,
                'staff_id' => (int) $row['staff_id'],
                'service_id' => (int) $row['service_id'],
                'service_variant_id' => (int) $row['service_variant_id'],
                'package_id' => $row['package_id'] !== null ? (int) $row['package_id'] : null,
                'start_time' => (string) $row['start_time'],
                'end_time' => (string) $row['end_time'],
                'price' => $row['price'] !== null ? (float) $row['price'] : null,
                'extra_blocked_minutes' => (int) ($row['extra_blocked_minutes'] ?? 0),
                'extra_processing_minutes' => (int) ($row['extra_processing_minutes'] ?? 0),
            ];
        }

        return $itemsById;
    }

    /**
     * Compare appointment states and return changed fields.
     */
    private function getActuallyChangedAppointmentFields(array $before, array $after): array
    {
        $changed = [];
        $fieldsToCompare = [
            'staff_id',
            'service_id',
            'service_variant_id',
            'package_id',
            'start_time',
            'end_time',
            'price',
            'extra_blocked_minutes',
            'extra_processing_minutes',
        ];

        foreach ($fieldsToCompare as $field) {
            $beforeVal = $before[$field] ?? null;
            $afterVal = $after[$field] ?? null;
            if ($beforeVal !== $afterVal) {
                $changed[$field] = $afterVal;
            }
        }

        return $changed;
    }
}
