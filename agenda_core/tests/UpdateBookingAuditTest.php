<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\UseCases\Booking\UpdateBooking;
use PDO;
use PHPUnit\Framework\TestCase;

final class UpdateBookingAuditTest extends TestCase
{
    private PDO $pdo;
    private UpdateBooking $useCase;

    protected function setUp(): void
    {
        $this->pdo = new PDO('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->sqliteCreateFunction('NOW', static fn(): string => '2026-06-03 12:00:00');
        $this->createSchema();
        $this->seedData();

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $this->pdo);

        $bookingRepo = new BookingRepository($connection);
        $auditRepo = new BookingAuditRepository($connection);
        $this->useCase = new UpdateBooking($bookingRepo, $connection, null, null, $auditRepo);
    }

    public function testStatusCancelledOnlyDoesNotCreateBookingUpdatedAudit(): void
    {
        $this->useCase->execute(100, 7, ['status' => 'cancelled'], true, false);

        $events = $this->pdo
            ->query('SELECT event_type FROM booking_events ORDER BY id')
            ->fetchAll(PDO::FETCH_COLUMN);

        $this->assertSame([], $events);
    }

    public function testNotesUpdateStillCreatesBookingUpdatedAudit(): void
    {
        $this->useCase->execute(100, 7, ['notes' => 'Nuova nota'], true, false);

        $event = $this->pdo
            ->query('SELECT event_type, payload_json FROM booking_events ORDER BY id DESC LIMIT 1')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame('booking_updated', $event['event_type']);
        $payload = json_decode((string) $event['payload_json'], true);
        $this->assertSame(['notes'], $payload['changed_fields']);
    }

    private function createSchema(): void
    {
        $this->pdo->exec(
            'CREATE TABLE bookings (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                location_id INTEGER NOT NULL,
                client_id INTEGER,
                user_id INTEGER,
                client_name TEXT,
                notes TEXT,
                status TEXT NOT NULL,
                source TEXT,
                replaces_booking_id INTEGER,
                replaced_by_booking_id INTEGER,
                idempotency_key TEXT,
                created_at TEXT,
                updated_at TEXT,
                recurrence_rule_id INTEGER,
                recurrence_index INTEGER,
                is_recurrence_parent INTEGER,
                has_conflict INTEGER,
                booking_direct_link_id INTEGER
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE booking_items (
                id INTEGER PRIMARY KEY,
                booking_id INTEGER NOT NULL,
                location_id INTEGER NOT NULL,
                service_id INTEGER NOT NULL,
                service_variant_id INTEGER,
                staff_id INTEGER NOT NULL,
                start_time TEXT,
                end_time TEXT,
                price REAL,
                list_price_cents INTEGER,
                applied_price_cents INTEGER,
                package_id INTEGER,
                pricing_source TEXT,
                extra_blocked_minutes INTEGER,
                extra_processing_minutes INTEGER,
                service_name_snapshot TEXT,
                client_name_snapshot TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE booking_events (
                id INTEGER PRIMARY KEY,
                booking_id INTEGER NOT NULL,
                event_type TEXT NOT NULL,
                actor_type TEXT NOT NULL,
                actor_id INTEGER,
                actor_name TEXT,
                payload_json TEXT NOT NULL,
                correlation_id TEXT,
                created_at TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE booking_direct_links (
                id INTEGER PRIMARY KEY,
                slug TEXT,
                is_active INTEGER
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE clients (
                id INTEGER PRIMARY KEY,
                first_name TEXT,
                last_name TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE businesses (
                id INTEGER PRIMARY KEY,
                name TEXT,
                slug TEXT,
                online_bookings_notification_email TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE locations (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                name TEXT,
                address TEXT,
                city TEXT,
                country TEXT,
                timezone TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE services (
                id INTEGER PRIMARY KEY,
                name TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE service_variants (
                id INTEGER PRIMARY KEY,
                parallel_capacity INTEGER,
                color_hex TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE staff (
                id INTEGER PRIMARY KEY,
                name TEXT,
                surname TEXT
            )'
        );
    }

    private function seedData(): void
    {
        $this->pdo->exec('INSERT INTO businesses (id, name, slug) VALUES (42, "Romeo Lab", "romeo")');
        $this->pdo->exec('INSERT INTO locations (id, business_id, name, timezone) VALUES (10, 42, "Studio", "Europe/Rome")');
        $this->pdo->exec('INSERT INTO clients (id, first_name, last_name) VALUES (30, "Ada", "Lovelace")');
        $this->pdo->exec('INSERT INTO services (id, name) VALUES (20, "Visita")');
        $this->pdo->exec('INSERT INTO service_variants (id, parallel_capacity, color_hex) VALUES (21, 1, "#2196F3")');
        $this->pdo->exec('INSERT INTO staff (id, name, surname) VALUES (40, "Mario", "Rossi")');
        $this->pdo->exec(
            'INSERT INTO bookings
             (id, business_id, location_id, client_id, user_id, client_name, notes, status, source, created_at, updated_at)
             VALUES
             (100, 42, 10, 30, 7, "Ada Lovelace", "Nota", "confirmed", "manual", "2026-06-03 09:00:00", "2026-06-03 09:00:00")'
        );
        $this->pdo->exec(
            'INSERT INTO booking_items
             (id, booking_id, location_id, service_id, service_variant_id, staff_id, start_time, end_time, price)
             VALUES
             (101, 100, 10, 20, 21, 40, "2026-06-04 10:00:00", "2026-06-04 11:00:00", 50.0)'
        );
    }
}
