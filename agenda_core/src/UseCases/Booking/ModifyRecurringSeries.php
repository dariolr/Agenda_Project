<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\RecurrenceRuleRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Domain\Exceptions\BookingException;
use DateTimeImmutable;

/**
 * Modify multiple bookings in a recurring series.
 * 
 * Supports modifying:
 * - staff_id: Change the assigned staff for all/future bookings
 * - notes: Update notes for all/future bookings
 * - time: Change the time (hour:minute) for all/future bookings (date stays the same)
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
    ) {}

    /**
     * Modify bookings in a recurring series.
     *
     * @param int $userId The authenticated user ID (operator)
     * @param int $ruleId The recurrence rule ID
     * @param array $changes {
     *   staff_id?: int,
     *   notes?: string|null,
     *   time?: string (HH:MM format)
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

            foreach ($bookingsToModify as $booking) {
                $bookingId = (int) $booking['id'];
                $bookingChanges = [];
                $itemChanges = [];

                // Apply staff change
                if (isset($changes['staff_id'])) {
                    $itemChanges['staff_id'] = (int) $changes['staff_id'];
                    $changesApplied['staff_id'] = (int) $changes['staff_id'];
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

                // Log audit event
                if ($this->auditRepository !== null && (!empty($bookingChanges) || !empty($itemChanges) || $newTime !== null)) {
                    try {
                        $this->auditRepository->createEvent(
                            bookingId: $bookingId,
                            eventType: 'booking_updated',
                            actorType: 'staff',
                            actorId: $userId,
                            payload: [
                                'action' => 'recurring_series_modification',
                                'scope' => $scope,
                                'changes' => array_merge($bookingChanges, $itemChanges, $newTime ? ['time' => $newTime] : []),
                            ],
                            correlationId: "recurring_modify_{$ruleId}"
                        );
                    } catch (\Exception $e) {
                        error_log("Failed to log recurring modification audit: " . $e->getMessage());
                    }
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
}
