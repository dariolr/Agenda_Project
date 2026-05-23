<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Http\Controllers\Billing\AdminBusinessBillingController;
use Agenda\Http\Request;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingConfigRepository;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingSubscriptionRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class AdminBusinessBillingControllerTest extends TestCase
{
    private PDO $pdo;
    private AdminBusinessBillingController $controller;

    protected function setUp(): void
    {
        $this->pdo = new PDO('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->sqliteCreateFunction('UTC_TIMESTAMP', static fn(): string => gmdate('Y-m-d H:i:s'));
        $this->createSchema();
        $this->seedData();

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $this->pdo);

        $this->controller = new AdminBusinessBillingController(
            new BusinessRepository($connection),
            new UserRepository($connection),
            new BusinessBillingConfigRepository($connection),
            new BusinessBillingSubscriptionRepository($connection),
        );
    }

    // ── GET ────────────────────────────────────────────────────────────────────

    public function testShowReturnsBillingConfigForSuperadmin(): void
    {
        $response = $this->controller->show($this->makeRequest(1, 42));

        $this->assertSame(200, $response->status);
        $this->assertTrue($response->data['success']);
        $this->assertArrayHasKey('billing_cycle_anchor_at', $response->data['data']);
        $this->assertNull($response->data['data']['billing_cycle_anchor_at']);
    }

    public function testShowReturnsForbiddenForNonSuperadmin(): void
    {
        $response = $this->controller->show($this->makeRequest(99, 42));

        $this->assertSame(403, $response->status);
        $this->assertFalse($response->data['success']);
    }

    public function testShowReturnsNotFoundForUnknownBusiness(): void
    {
        $response = $this->controller->show($this->makeRequest(1, 9999));

        $this->assertSame(404, $response->status);
    }

    // ── PUT without billing_cycle_anchor_at ───────────────────────────────────

    public function testUpdateEnablesBillingWithoutAnchorDate(): void
    {
        $response = $this->controller->update($this->makeRequest(1, 42, [
            'billing_enabled' => true,
            'amount_cents' => 2900,
        ]));

        $this->assertSame(200, $response->status);
        $this->assertTrue($response->data['success']);
        $this->assertNull($response->data['data']['billing_cycle_anchor_at']);
    }

    public function testUpdateDisablesBillingAndClearsAnchorDate(): void
    {
        $future = gmdate('Y-m-d H:i:s', strtotime('+30 days'));
        $this->pdo->exec(
            "UPDATE business_billing_config
             SET billing_enabled = 1, billing_mode = 'recurring',
                 billing_interval_unit = 'month', billing_interval_count = 1,
                 amount_cents = 2900, provider_code = 'stripe',
                 billing_cycle_anchor_at = '{$future}'
             WHERE business_id = 42"
        );

        $response = $this->controller->update($this->makeRequest(1, 42, [
            'billing_enabled' => false,
        ]));

        $this->assertSame(200, $response->status);
        $row = $this->pdo
            ->query('SELECT billing_cycle_anchor_at FROM business_billing_config WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);
        $this->assertNull($row['billing_cycle_anchor_at']);
    }

    // ── PUT with billing_cycle_anchor_at ──────────────────────────────────────

    public function testUpdateSavesAndReturnsFutureBillingCycleAnchorAt(): void
    {
        $futureIso = gmdate('Y-m-d\TH:i:s\Z', strtotime('+15 days'));

        $response = $this->controller->update($this->makeRequest(1, 42, [
            'billing_enabled' => true,
            'amount_cents' => 4900,
            'billing_cycle_anchor_at' => $futureIso,
        ]));

        $this->assertSame(200, $response->status);
        $this->assertNotNull($response->data['data']['billing_cycle_anchor_at']);

        $row = $this->pdo
            ->query('SELECT billing_cycle_anchor_at FROM business_billing_config WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);
        $this->assertNotNull($row['billing_cycle_anchor_at']);
    }

    public function testUpdateReturnsBadRequestForPastBillingCycleAnchorAt(): void
    {
        $pastIso = gmdate('Y-m-d\TH:i:s\Z', strtotime('-1 day'));

        $response = $this->controller->update($this->makeRequest(1, 42, [
            'billing_enabled' => true,
            'amount_cents' => 2900,
            'billing_cycle_anchor_at' => $pastIso,
        ]));

        $this->assertSame(422, $response->status);
        $this->assertFalse($response->data['success']);
        $this->assertSame('billing_cycle_anchor_in_past', $response->data['error']['message']);
    }

    public function testUpdateReturnsBadRequestWhenAmountMissingWithBillingEnabled(): void
    {
        $response = $this->controller->update($this->makeRequest(1, 42, [
            'billing_enabled' => true,
            'amount_cents' => 0,
        ]));

        $this->assertSame(422, $response->status);
        $this->assertFalse($response->data['success']);
    }

    public function testUpdateReturnsForbiddenForNonSuperadmin(): void
    {
        $response = $this->controller->update($this->makeRequest(99, 42, [
            'billing_enabled' => false,
        ]));

        $this->assertSame(403, $response->status);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function makeRequest(int $userId, int $businessId, array $body = []): Request
    {
        $request = new Request(
            method: 'PUT',
            path: '/v1/admin/businesses/' . $businessId . '/billing',
            query: [],
            headers: [],
            body: $body,
            traceId: 'test-trace',
        );
        $request->setAttribute('user_id', $userId);
        $request->setAttribute('businessId', $businessId);

        return $request;
    }

    private function createSchema(): void
    {
        $this->pdo->exec(
            'CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                email TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                first_name TEXT NOT NULL,
                last_name TEXT NOT NULL,
                phone TEXT NULL,
                email_verified_at TEXT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                is_superadmin INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NULL,
                updated_at TEXT NULL
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE businesses (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                slug TEXT NOT NULL,
                email TEXT NULL,
                phone TEXT NULL,
                timezone TEXT NOT NULL DEFAULT "Europe/Rome",
                currency TEXT NOT NULL DEFAULT "EUR",
                cancellation_hours INTEGER NOT NULL DEFAULT 24,
                show_appointment_price_in_card INTEGER NOT NULL DEFAULT 0,
                online_bookings_notification_email TEXT NULL,
                service_color_palette TEXT NOT NULL DEFAULT "legacy",
                is_active INTEGER NOT NULL DEFAULT 1,
                is_suspended INTEGER NOT NULL DEFAULT 0,
                suspension_message TEXT NULL,
                created_at TEXT NULL,
                updated_at TEXT NULL
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE business_billing_config (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                business_id INTEGER NOT NULL UNIQUE,
                billing_enabled INTEGER NOT NULL DEFAULT 0,
                billing_mode TEXT NOT NULL DEFAULT "free",
                billing_interval_unit TEXT NULL,
                billing_interval_count INTEGER NULL,
                amount_cents INTEGER NULL,
                currency TEXT NOT NULL DEFAULT "EUR",
                provider_code TEXT NULL,
                provider_price_reference TEXT NULL,
                billing_cycle_anchor_at TEXT NULL,
                notes TEXT NULL,
                created_at TEXT NULL,
                updated_at TEXT NULL
            )'
        );
        $this->pdo->exec(
            'CREATE TABLE business_billing_subscription (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                business_id INTEGER NOT NULL UNIQUE,
                provider_code TEXT NULL,
                provider_customer_id TEXT NULL,
                provider_subscription_id TEXT NULL,
                provider_price_reference TEXT NULL,
                status TEXT NOT NULL DEFAULT "not_required",
                current_period_start TEXT NULL,
                current_period_end TEXT NULL,
                cancel_at_period_end INTEGER NOT NULL DEFAULT 0,
                canceled_at TEXT NULL,
                last_payment_at TEXT NULL,
                last_payment_failed_at TEXT NULL,
                last_checkout_session_id TEXT NULL,
                created_at TEXT NULL,
                updated_at TEXT NULL
            )'
        );
    }

    private function seedData(): void
    {
        $this->pdo->exec(
            "INSERT INTO users (id, email, password_hash, first_name, last_name, is_active, is_superadmin)
             VALUES (1, 'superadmin@example.test', 'hash', 'Super', 'Admin', 1, 1)"
        );
        $this->pdo->exec(
            "INSERT INTO users (id, email, password_hash, first_name, last_name, is_active, is_superadmin)
             VALUES (99, 'user@example.test', 'hash', 'Normal', 'User', 1, 0)"
        );
        $this->pdo->exec(
            "INSERT INTO businesses (id, name, slug, email, is_active)
             VALUES (42, 'Romeo Lab', 'romeo-lab', 'billing@example.test', 1)"
        );
        $this->pdo->exec(
            'INSERT INTO business_billing_config
                (business_id, billing_enabled, billing_mode, currency)
             VALUES (42, 0, "free", "EUR")'
        );
    }
}
