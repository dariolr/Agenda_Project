<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class BookingRepositoryPricingTest extends TestCase
{
    private PDO $pdo;
    private BookingRepository $repository;

    protected function setUp(): void
    {
        $this->pdo = new PDO('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $this->pdo->sqliteCreateFunction('NOW', static fn (): string => '2026-06-03 10:30:00');

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $this->pdo);

        $this->repository = new BookingRepository($connection);
        $this->createSchema();
    }

    public function testUpdateAppointmentKeepsFreeListPriceAndAppliesPaidOverride(): void
    {
        $this->pdo->exec(
            "INSERT INTO booking_items
                (id, price, list_price_cents, applied_price_cents, pricing_source, updated_at)
             VALUES
                (10, 0, 0, 0, 'service', '2026-06-03 10:00:00')"
        );

        $this->repository->updateAppointment(10, [
            'price' => 150.0,
            'applied_price_cents' => 15000,
        ]);

        $row = $this->pdo
            ->query('SELECT price, list_price_cents, applied_price_cents, pricing_source FROM booking_items WHERE id = 10')
            ->fetch();

        $this->assertSame(150.0, (float) $row['price']);
        $this->assertSame(0, (int) $row['list_price_cents']);
        $this->assertSame(15000, (int) $row['applied_price_cents']);
    }

    private function createSchema(): void
    {
        $this->pdo->exec(
            'CREATE TABLE booking_items (
                id INTEGER PRIMARY KEY,
                start_time TEXT,
                end_time TEXT,
                staff_id INTEGER,
                service_id INTEGER,
                service_variant_id INTEGER,
                service_name_snapshot TEXT,
                client_name_snapshot TEXT,
                extra_blocked_minutes INTEGER,
                extra_processing_minutes INTEGER,
                price REAL,
                list_price_cents INTEGER,
                applied_price_cents INTEGER,
                package_id INTEGER,
                pricing_source TEXT,
                updated_at TEXT
            )'
        );
    }
}
