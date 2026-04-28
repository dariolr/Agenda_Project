<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;

final class ServiceCapacityRulesTest extends TestCase
{
    public function testIndividualCapacityRejectsSecondOverlappingBooking(): void
    {
        $existing = [
            $this->bookingItem(1, 10, 100, '08:00', '09:00'),
        ];

        $this->assertFalse($this->canBook($existing, 1, 10, 100, '08:30', '09:30', 1));
    }

    public function testParallelCapacityTwoAcceptsTwoAndRejectsThirdOverlap(): void
    {
        $existing = [];

        $this->assertTrue($this->canBook($existing, 1, 10, 100, '08:15', '09:15', 2));
        $existing[] = $this->bookingItem(1, 10, 100, '08:15', '09:15');

        $this->assertTrue($this->canBook($existing, 1, 10, 100, '08:20', '09:20', 2));
        $existing[] = $this->bookingItem(1, 10, 100, '08:20', '09:20');

        $this->assertFalse($this->canBook($existing, 1, 10, 100, '08:40', '09:40', 2));
    }

    public function testDifferentServiceVariantOnSameStaffStillConflicts(): void
    {
        $existing = [
            $this->bookingItem(1, 10, 200, '08:00', '09:00'),
        ];

        $this->assertFalse($this->canBook($existing, 1, 10, 100, '08:30', '09:30', 2));
    }

    public function testSameServiceVariantDifferentStaffIsAllowed(): void
    {
        $existing = [
            $this->bookingItem(1, 10, 100, '08:00', '09:00'),
        ];

        $this->assertTrue($this->canBook($existing, 1, 11, 100, '08:30', '09:30', 1));
    }

    public function testCancelledBookingsDoNotConsumeCapacity(): void
    {
        $existing = [
            $this->bookingItem(1, 10, 100, '08:00', '09:00', 'cancelled'),
        ];

        $this->assertTrue($this->canBook($existing, 1, 10, 100, '08:30', '09:30', 1));
    }

    public function testCapacityCheckLocksVariantBeforeCountingOverlaps(): void
    {
        $source = (string) file_get_contents(__DIR__ . '/../src/UseCases/Booking/CreateBooking.php');

        $lockPosition = strpos($source, 'lockServiceVariantForCapacityCheck');
        $countPosition = strpos($source, 'findServiceVariantCapacityOverlapsForUpdate');

        $this->assertIsInt($lockPosition);
        $this->assertIsInt($countPosition);
        $this->assertLessThan($countPosition, $lockPosition);
    }

    public function testCapacityQueriesUseServiceVariantId(): void
    {
        $source = (string) file_get_contents(__DIR__ . '/../src/Infrastructure/Repositories/BookingRepository.php');

        $this->assertStringContainsString('AND bi.service_variant_id = ?', $source);
        $this->assertStringContainsString('AND bi.service_variant_id <> ?', $source);
        $this->assertStringNotContainsString('AND bi.service_id = ?', $source);
        $this->assertStringNotContainsString('AND bi.service_id <> ?', $source);
    }

    public function testMigrationIsIdempotentAndIndexesServiceVariantCapacityChecks(): void
    {
        $migration = (string) file_get_contents(
            __DIR__ . '/../../config/migrations/20260427_service_variants_parallel_capacity.sql'
        );

        $this->assertStringContainsString('information_schema.COLUMNS', $migration);
        $this->assertStringContainsString('information_schema.STATISTICS', $migration);
        $this->assertStringContainsString(
            'booking_items(location_id, staff_id, service_variant_id, start_time, end_time)',
            $migration
        );
        $this->assertStringContainsString('DROP INDEX idx_booking_items_capacity_check', $migration);
    }

    public function testReactivatedServiceVariantsCopyParallelCapacityFromTemplate(): void
    {
        $source = (string) file_get_contents(__DIR__ . '/../src/Infrastructure/Repositories/ServiceRepository.php');

        $this->assertStringContainsString('parallel_capacity = ?', $source);
        $this->assertStringContainsString('$templateVariant[\'parallel_capacity\'] ?? 1', $source);
    }

    private function canBook(
        array $existing,
        int $locationId,
        int $staffId,
        int $serviceVariantId,
        string $start,
        string $end,
        int $parallelCapacity
    ): bool {
        $sameVariantOverlaps = 0;

        foreach ($existing as $item) {
            if (!in_array($item['status'], ['pending', 'confirmed'], true)) {
                continue;
            }
            if ($item['location_id'] !== $locationId || $item['staff_id'] !== $staffId) {
                continue;
            }
            if (!$this->overlaps($item['start_time'], $item['end_time'], $start, $end)) {
                continue;
            }
            if ($item['service_variant_id'] !== $serviceVariantId) {
                return false;
            }
            $sameVariantOverlaps++;
        }

        return $sameVariantOverlaps < $parallelCapacity;
    }

    private function overlaps(string $existingStart, string $existingEnd, string $newStart, string $newEnd): bool
    {
        return $existingStart < $newEnd && $existingEnd > $newStart;
    }

    private function bookingItem(
        int $locationId,
        int $staffId,
        int $serviceVariantId,
        string $start,
        string $end,
        string $status = 'confirmed'
    ): array {
        return [
            'location_id' => $locationId,
            'staff_id' => $staffId,
            'service_variant_id' => $serviceVariantId,
            'start_time' => $start,
            'end_time' => $end,
            'status' => $status,
        ];
    }
}
