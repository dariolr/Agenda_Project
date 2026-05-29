<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class BookingNotificationsRepositoryTest extends TestCase
{
    private PDO $pdo;
    private NotificationRepository $repository;

    protected function setUp(): void
    {
        $this->pdo = new PDO('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->createSchema();
        $this->seedData();

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $this->pdo);

        $this->repository = new NotificationRepository($connection);
    }

    public function testFindBookingNotificationsReturnsServiceAndClassKinds(): void
    {
        $result = $this->repository->findBookingNotificationsWithFilters(42, [
            'sort_order' => 'asc',
        ]);

        $this->assertSame(2, $result['total']);
        $this->assertSame(['service', 'class'], $result['available_booking_kinds']);
        $this->assertSame(['service', 'class'], array_column($result['notifications'], 'booking_kind'));
        $this->assertSame(100, (int) $result['notifications'][0]['booking_id']);
        $this->assertSame(200, (int) $result['notifications'][1]['class_booking_id']);
    }

    public function testFindBookingNotificationsFiltersClassKind(): void
    {
        $result = $this->repository->findBookingNotificationsWithFilters(42, [
            'booking_kind' => 'class',
        ]);

        $this->assertSame(1, $result['total']);
        $this->assertSame('class', $result['notifications'][0]['booking_kind']);
        $this->assertNull($result['notifications'][0]['booking_id']);
        $this->assertSame(200, (int) $result['notifications'][0]['class_booking_id']);
    }

    public function testFindBookingNotificationsDoesNotLeakServiceRowsForClassChannelFilter(): void
    {
        $result = $this->repository->findBookingNotificationsWithFilters(42, [
            'channel' => 'class_booking_confirmed',
        ]);

        $this->assertSame(1, $result['total']);
        $this->assertSame('class_booking_confirmed', $result['notifications'][0]['channel']);
        $this->assertSame('class', $result['notifications'][0]['booking_kind']);
    }

    private function createSchema(): void
    {
        $this->pdo->exec(
            'CREATE TABLE business_whatsapp_settings (
                business_id INTEGER NOT NULL,
                whatsapp_enabled INTEGER NOT NULL DEFAULT 0,
                messages_enabled INTEGER NOT NULL DEFAULT 0
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE services (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE service_variants (
                id INTEGER PRIMARY KEY,
                service_id INTEGER NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE class_types (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1
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
            'CREATE TABLE locations (
                id INTEGER PRIMARY KEY,
                name TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE bookings (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                client_id INTEGER,
                location_id INTEGER,
                client_name TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE booking_items (
                id INTEGER PRIMARY KEY,
                booking_id INTEGER NOT NULL,
                start_time TEXT,
                end_time TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE class_events (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                class_type_id INTEGER NOT NULL,
                location_id INTEGER,
                starts_at TEXT,
                ends_at TEXT
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE class_bookings (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                class_event_id INTEGER NOT NULL,
                customer_id INTEGER NOT NULL
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE notification_queue (
                id INTEGER PRIMARY KEY,
                type TEXT NOT NULL,
                channel TEXT NOT NULL,
                recipient_type TEXT NOT NULL,
                recipient_id INTEGER NOT NULL,
                recipient_email TEXT,
                recipient_name TEXT,
                subject TEXT,
                payload TEXT NOT NULL,
                status TEXT NOT NULL,
                priority INTEGER NOT NULL DEFAULT 5,
                attempts INTEGER NOT NULL DEFAULT 0,
                max_attempts INTEGER NOT NULL DEFAULT 3,
                scheduled_at TEXT,
                last_attempt_at TEXT,
                sent_at TEXT,
                failed_at TEXT,
                error_message TEXT,
                provider_used TEXT,
                business_id INTEGER,
                booking_id INTEGER,
                class_booking_id INTEGER,
                created_at TEXT,
                updated_at TEXT
            )'
        );
    }

    private function seedData(): void
    {
        $this->pdo->exec('INSERT INTO services (id, business_id, is_active) VALUES (10, 42, 1)');
        $this->pdo->exec('INSERT INTO service_variants (id, service_id, is_active) VALUES (11, 10, 1)');
        $this->pdo->exec('INSERT INTO class_types (id, business_id, name, is_active) VALUES (20, 42, "Pilates", 1)');
        $this->pdo->exec('INSERT INTO clients (id, first_name, last_name) VALUES (30, "Ada", "Lovelace")');
        $this->pdo->exec('INSERT INTO locations (id, name) VALUES (40, "Studio")');
        $this->pdo->exec('INSERT INTO bookings (id, business_id, client_id, location_id, client_name) VALUES (100, 42, 30, 40, "Ada Lovelace")');
        $this->pdo->exec('INSERT INTO booking_items (id, booking_id, start_time, end_time) VALUES (101, 100, "2026-05-28 10:00:00", "2026-05-28 11:00:00")');
        $this->pdo->exec('INSERT INTO class_events (id, business_id, class_type_id, location_id, starts_at, ends_at) VALUES (150, 42, 20, 40, "2026-05-28 12:00:00", "2026-05-28 13:00:00")');
        $this->pdo->exec('INSERT INTO class_bookings (id, business_id, class_event_id, customer_id) VALUES (200, 42, 150, 30)');
        $this->pdo->exec(
            'INSERT INTO notification_queue
             (id, type, channel, recipient_type, recipient_id, recipient_email, recipient_name, subject, payload, status, business_id, booking_id, class_booking_id, created_at, updated_at)
             VALUES
             (1, "email", "booking_confirmed", "client", 30, "ada@example.test", "Ada Lovelace", "Booking", "{}", "sent", 42, 100, NULL, "2026-05-28 08:00:00", "2026-05-28 08:00:00"),
             (2, "email", "class_booking_confirmed", "client", 30, "ada@example.test", "Ada Lovelace", "Class", "{}", "sent", 42, NULL, 200, "2026-05-28 09:00:00", "2026-05-28 09:00:00")'
        );
    }
}
