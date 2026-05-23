<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Domain\Billing\BillingConfig;
use Agenda\Domain\Billing\BillingProviderCode;
use Agenda\Domain\Billing\BillingProviderFactory;
use Agenda\Domain\Billing\BillingProviderInterface;
use Agenda\Domain\Billing\BillingSubscription;
use Agenda\Domain\Billing\BillingSubscriptionStatus;
use Agenda\Domain\Billing\BillingWebhookResult;
use Agenda\Http\Controllers\Billing\BusinessBillingController;
use Agenda\Http\Request;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingConfigRepository;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingSubscriptionRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class BusinessBillingControllerCheckoutTest extends TestCase
{
    private PDO $pdo;
    private FakeBillingProvider $provider;
    private BusinessBillingController $controller;

    protected function setUp(): void
    {
        $this->pdo = new PDO('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->createSchema();
        $this->seedAccess();

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $this->pdo);

        $this->provider = new FakeBillingProvider();
        $this->controller = new BusinessBillingController(
            new BusinessRepository($connection),
            new BusinessUserRepository($connection),
            new UserRepository($connection),
            new BusinessBillingConfigRepository($connection),
            new BusinessBillingSubscriptionRepository($connection),
            new BillingProviderFactory([BillingProviderCode::STRIPE => $this->provider]),
        );
    }

    public function testActiveWithProviderSubscriptionReturnsPortal(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::ACTIVE,
            providerSubscriptionId: 'sub_active',
        );

        $response = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $response->status);
        $this->assertTrue($response->data['success']);
        $this->assertSame('portal', $response->data['data']['purpose']);
        $this->assertSame('https://billing.stripe.test/portal', $response->data['data']['url']);
        $this->assertSame(0, $this->provider->checkoutCalls);
    }

    public function testActiveCancelAtPeriodEndReturnsPortal(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::ACTIVE,
            providerSubscriptionId: 'sub_canceling',
            cancelAtPeriodEnd: true,
        );

        $response = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $response->status);
        $this->assertSame('portal', $response->data['data']['purpose']);
        $this->assertSame('https://billing.stripe.test/portal', $response->data['data']['url']);
        $this->assertSame(0, $this->provider->checkoutCalls);
    }

    public function testCanceledAllowsCheckout(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::CANCELED,
            providerSubscriptionId: 'sub_canceled',
        );

        $response = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $response->status);
        $this->assertTrue($response->data['success']);
        $this->assertSame('https://checkout.stripe.test/session', $response->data['data']['url']);
        $this->assertSame(1, $this->provider->checkoutCalls);
    }

    public function testInactiveWithoutProviderSubscriptionAllowsCheckout(): void
    {
        $this->seedBillingSubscription(BillingSubscriptionStatus::INACTIVE);

        $response = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $response->status);
        $this->assertTrue($response->data['success']);
        $this->assertSame('https://checkout.stripe.test/session', $response->data['data']['url']);
        $this->assertSame(1, $this->provider->checkoutCalls);
    }

    public function testSecondCheckoutRequestReturnsOpenPendingCheckoutSession(): void
    {
        $this->provider->checkoutSessionId = 'cs_open';
        $this->provider->checkoutUrl = 'https://checkout.stripe.test/open';
        $firstResponse = $this->controller->checkoutSession($this->request());
        $this->provider->checkoutUrl = 'https://checkout.stripe.test/second';

        $secondResponse = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $firstResponse->status);
        $this->assertSame(200, $secondResponse->status);
        $this->assertSame('https://checkout.stripe.test/open', $secondResponse->data['data']['url']);
        $this->assertSame('cs_open', $secondResponse->data['data']['session_id']);
        $this->assertSame(1, $this->provider->checkoutCalls);
    }

    public function testPendingSessionCannotBeRetrievedCreatesNewCheckout(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_missing',
        );

        $response = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $response->status);
        $this->assertSame('https://checkout.stripe.test/session', $response->data['data']['url']);
        $this->assertSame(1, $this->provider->checkoutCalls);
    }

    public function testPendingCheckoutReservationWithoutSessionBlocksNewCheckout(): void
    {
        $this->seedBillingSubscription(BillingSubscriptionStatus::PENDING_CHECKOUT);

        $response = $this->controller->checkoutSession($this->request());

        $this->assertSame(409, $response->status);
        $this->assertSame('checkout_already_started', $response->data['error']['code']);
        $this->assertSame(0, $this->provider->checkoutCalls);
    }

    public function testStalePendingCheckoutReservationWithoutSessionAllowsNewCheckout(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            updatedAt: '2000-01-01 00:00:00',
        );

        $response = $this->controller->checkoutSession($this->request());
        $row = $this->pdo
            ->query('SELECT last_checkout_session_id FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(200, $response->status);
        $this->assertSame(1, $this->provider->checkoutCalls);
        $this->assertNotSame('cs_expired', $row['last_checkout_session_id']);
    }

    public function testImmediateSecondCheckoutDuringReservationDoesNotCreateSecondStripeSession(): void
    {
        $this->seedBillingSubscription(BillingSubscriptionStatus::INACTIVE);
        $secondResponse = null;
        $this->provider->beforeCreateCheckout = function () use (&$secondResponse): void {
            $row = $this->pdo
                ->query('SELECT status, last_checkout_session_id FROM business_billing_subscription WHERE business_id = 42')
                ->fetch(PDO::FETCH_ASSOC);

            $this->assertSame(BillingSubscriptionStatus::PENDING_CHECKOUT, $row['status']);
            $this->assertNull($row['last_checkout_session_id']);

            $secondResponse = $this->controller->checkoutSession($this->request());
            $this->assertSame(0, $this->provider->checkoutCalls);
        };

        $firstResponse = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $firstResponse->status);
        $this->assertNotNull($secondResponse);
        $this->assertSame(409, $secondResponse->status);
        $this->assertSame('checkout_already_started', $secondResponse->data['error']['code']);
        $this->assertSame(1, $this->provider->checkoutCalls);
    }

    public function testExistingStripeSubscriptionReturnsPortalAndSyncsLocalState(): void
    {
        $this->provider->manageableSubscription = [
            'provider_customer_id' => 'cus_test',
            'provider_subscription_id' => 'sub_existing_stripe',
            'provider_price_reference' => 'price_existing',
            'status' => BillingSubscriptionStatus::ACTIVE,
            'current_period_start' => '2026-05-01 00:00:00',
            'current_period_end' => '2026-06-01 00:00:00',
            'cancel_at_period_end' => false,
        ];

        $response = $this->controller->checkoutSession($this->request());
        $row = $this->pdo
            ->query('SELECT * FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(200, $response->status);
        $this->assertSame('portal', $response->data['data']['purpose']);
        $this->assertSame('https://billing.stripe.test/portal', $response->data['data']['url']);
        $this->assertSame(0, $this->provider->checkoutCalls);
        $this->assertSame('sub_existing_stripe', $row['provider_subscription_id']);
        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $row['status']);
    }

    public function testExpiredPendingCheckoutAllowsNewCheckout(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_expired',
        );
        $this->provider->checkoutSessions['cs_expired'] = [
            'checkout_session_id' => 'cs_expired',
            'status' => 'expired',
        ];

        $response = $this->controller->checkoutSession($this->request());
        $row = $this->pdo
            ->query('SELECT last_checkout_session_id FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(200, $response->status);
        $this->assertSame(1, $this->provider->checkoutCalls);
        $this->assertNotSame('cs_unpaid', $row['last_checkout_session_id']);
    }

    public function testCompletedUnpaidPendingCheckoutAllowsNewCheckout(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_unpaid',
        );
        $this->provider->checkoutSessions['cs_unpaid'] = [
            'checkout_session_id' => 'cs_unpaid',
            'status' => 'complete',
            'payment_status' => 'unpaid',
            'provider_subscription_id' => 'sub_unpaid_checkout',
        ];

        $response = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $response->status);
        $this->assertSame(1, $this->provider->checkoutCalls);
    }

    public function testCompletedPaidPendingCheckoutSyncsSubscriptionAndReturnsPortal(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_paid',
        );
        $this->provider->checkoutSessions['cs_paid'] = [
            'checkout_session_id' => 'cs_paid',
            'status' => 'completed',
            'payment_status' => 'paid',
            'provider_subscription_id' => 'sub_paid_checkout',
        ];
        $this->provider->manageableSubscription = [
            'provider_customer_id' => 'cus_test',
            'provider_subscription_id' => 'sub_paid_checkout',
            'provider_price_reference' => 'price_test',
            'status' => BillingSubscriptionStatus::ACTIVE,
            'current_period_start' => '2026-05-01 00:00:00',
            'current_period_end' => '2026-06-01 00:00:00',
            'cancel_at_period_end' => false,
        ];

        $response = $this->controller->checkoutSession($this->request());
        $row = $this->pdo
            ->query('SELECT status, provider_subscription_id FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(200, $response->status);
        $this->assertSame('portal', $response->data['data']['purpose']);
        $this->assertSame('https://billing.stripe.test/portal', $response->data['data']['url']);
        $this->assertSame(0, $this->provider->checkoutCalls);
        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $row['status']);
        $this->assertSame('sub_paid_checkout', $row['provider_subscription_id']);
    }

    public function testResumeOpenCheckoutReturnsExistingUrl(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_open',
        );
        $this->provider->checkoutSessions['cs_open'] = [
            'checkout_session_id' => 'cs_open',
            'url' => 'https://checkout.stripe.test/open',
            'status' => 'open',
            'payment_status' => 'unpaid',
        ];

        $response = $this->controller->resumeCheckoutSession($this->request());

        $this->assertSame(200, $response->status);
        $this->assertSame('https://checkout.stripe.test/open', $response->data['data']['url']);
        $this->assertSame(0, $this->provider->checkoutCalls);
    }

    public function testCancelOpenCheckoutExpiresSessionAndClearsPendingCheckout(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_open',
        );
        $this->provider->checkoutSessions['cs_open'] = [
            'checkout_session_id' => 'cs_open',
            'url' => 'https://checkout.stripe.test/open',
            'status' => 'open',
            'payment_status' => 'unpaid',
        ];

        $response = $this->controller->cancelCheckoutSession($this->request());
        $row = $this->pdo
            ->query('SELECT status, last_checkout_session_id, last_payment_at FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(200, $response->status);
        $this->assertSame(BillingSubscriptionStatus::INACTIVE, $response->data['data']['status']);
        $this->assertTrue($response->data['data']['canceled_pending_checkout']);
        $this->assertSame(BillingSubscriptionStatus::INACTIVE, $row['status']);
        $this->assertNull($row['last_checkout_session_id']);
        $this->assertNull($row['last_payment_at']);
        $this->assertSame('expired', $this->provider->checkoutSessions['cs_open']['status']);
    }

    public function testInitialPastDueWithoutSuccessfulPaymentAllowsRetryCheckout(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PAST_DUE,
            providerSubscriptionId: 'sub_failed_initial',
        );

        $subscriptionResponse = $this->controller->subscription($this->request());
        $checkoutResponse = $this->controller->checkoutSession($this->request());

        $this->assertSame(200, $subscriptionResponse->status);
        $this->assertTrue($subscriptionResponse->data['data']['can_start_checkout']);
        $this->assertSame(200, $checkoutResponse->status);
        $this->assertTrue($checkoutResponse->data['success']);
        $this->assertSame(1, $this->provider->checkoutCalls);
    }

    public function testPendingCheckoutWithSessionIsExposedAsPrepared(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_open',
        );

        $response = $this->controller->subscription($this->request());

        $this->assertSame(200, $response->status);
        $this->assertSame(BillingSubscriptionStatus::PENDING_CHECKOUT, $response->data['data']['status']);
        $this->assertFalse($response->data['data']['checkout_retryable']);
        $this->assertSame('prepared', $response->data['data']['checkout_state']);
        $this->assertSame('cs_open', $response->data['data']['last_checkout_session_id']);
        $this->assertNull($response->data['data']['last_payment_at']);
        $this->assertNull($response->data['data']['current_period_end']);
    }

    public function testCheckoutCancelReturnKeepsPendingCheckoutWhenSessionExists(): void
    {
        $this->seedBillingSubscription(
            BillingSubscriptionStatus::PENDING_CHECKOUT,
            checkoutSessionId: 'cs_cancelled',
        );

        $response = $this->controller->subscription($this->request(['checkout_cancelled' => '1']));
        $storedStatus = $this->pdo
            ->query('SELECT status, last_checkout_session_id FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(200, $response->status);
        $this->assertSame(BillingSubscriptionStatus::PENDING_CHECKOUT, $response->data['data']['status']);
        $this->assertFalse($response->data['data']['checkout_retryable']);
        $this->assertSame('prepared', $response->data['data']['checkout_state']);
        $this->assertSame(BillingSubscriptionStatus::PENDING_CHECKOUT, $storedStatus['status']);
        $this->assertSame('cs_cancelled', $storedStatus['last_checkout_session_id']);
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
            'CREATE TABLE business_users (
                id INTEGER PRIMARY KEY,
                business_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                role TEXT NOT NULL DEFAULT "owner",
                scope_type TEXT NOT NULL DEFAULT "business",
                staff_id INTEGER NULL,
                can_manage_bookings INTEGER NOT NULL DEFAULT 1,
                can_manage_clients INTEGER NOT NULL DEFAULT 1,
                can_manage_services INTEGER NOT NULL DEFAULT 1,
                can_manage_staff INTEGER NOT NULL DEFAULT 1,
                can_view_reports INTEGER NOT NULL DEFAULT 1,
                is_active INTEGER NOT NULL DEFAULT 1,
                invited_by INTEGER NULL,
                invited_at TEXT NULL,
                accepted_at TEXT NULL,
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

    private function seedAccess(): void
    {
        $this->pdo->exec(
            "INSERT INTO users (id, email, password_hash, first_name, last_name, is_active)
             VALUES (9, 'owner@example.test', 'hash', 'Owner', 'Test', 1)"
        );
        $this->pdo->exec(
            "INSERT INTO businesses (id, name, slug, email, is_active)
             VALUES (42, 'Romeo Lab', 'romeo-lab', 'billing@example.test', 1)"
        );
        $this->pdo->exec(
            'INSERT INTO business_users (id, business_id, user_id, role, is_active)
             VALUES (1, 42, 9, "owner", 1)'
        );
        $this->pdo->exec(
            'INSERT INTO business_billing_config
                (business_id, billing_enabled, billing_mode, billing_interval_unit,
                 billing_interval_count, amount_cents, currency, provider_code,
                 provider_price_reference)
             VALUES (42, 1, "recurring", "month", 1, 2900, "EUR", "stripe", "price_test")'
        );
    }

    private function seedBillingSubscription(
        string $status,
        ?string $providerSubscriptionId = null,
        bool $cancelAtPeriodEnd = false,
        ?string $checkoutSessionId = null,
        ?string $updatedAt = null,
    ): void {
        $stmt = $this->pdo->prepare(
            'INSERT INTO business_billing_subscription
                (business_id, provider_code, provider_customer_id, provider_subscription_id,
                 provider_price_reference, status, cancel_at_period_end, last_checkout_session_id, updated_at)
             VALUES (42, "stripe", "cus_test", ?, "price_test", ?, ?, ?, ?)'
        );
        $stmt->execute([
            $providerSubscriptionId,
            $status,
            $cancelAtPeriodEnd ? 1 : 0,
            $checkoutSessionId,
            $updatedAt,
        ]);
    }

    /**
     * @param array<string, string> $query
     */
    private function request(array $query = []): Request
    {
        $request = new Request(
            'POST',
            '/v1/billing/checkout-session',
            array_merge(['business_id' => '42'], $query),
            [],
            null,
            'trace-test',
        );
        $request->setAttribute('user_id', 9);

        return $request;
    }
}

final class FakeBillingProvider implements BillingProviderInterface
{
    public int $checkoutCalls = 0;
    public int $customerCalls = 0;
    public string $checkoutSessionId = 'cs_test';
    public string $checkoutUrl = 'https://checkout.stripe.test/session';
    /** @var array<string, array<string, mixed>> */
    public array $checkoutSessions = [];
    /** @var array<string, mixed>|null */
    public ?array $manageableSubscription = null;
    public ?\Closure $beforeCreateCheckout = null;

    public function createCustomer(BillingConfig $config, array $context): array
    {
        $this->customerCalls++;

        return ['provider_customer_id' => 'cus_test'];
    }

    public function retrieveCheckoutSession(string $checkoutSessionId): ?array
    {
        return $this->checkoutSessions[$checkoutSessionId] ?? null;
    }

    public function expireCheckoutSession(string $checkoutSessionId): ?array
    {
        if (!isset($this->checkoutSessions[$checkoutSessionId])) {
            return null;
        }
        $this->checkoutSessions[$checkoutSessionId]['status'] = 'expired';

        return $this->checkoutSessions[$checkoutSessionId];
    }

    public function findManageableSubscription(BillingConfig $config, BillingSubscription $subscription): ?array
    {
        return $subscription->providerCustomerId === null ? null : $this->manageableSubscription;
    }

    public function createSubscriptionCheckout(BillingConfig $config, BillingSubscription $subscription, array $context): array
    {
        if ($this->beforeCreateCheckout !== null) {
            ($this->beforeCreateCheckout)();
            $this->beforeCreateCheckout = null;
        }
        $this->checkoutCalls++;
        $this->checkoutSessions[$this->checkoutSessionId] = [
            'checkout_session_id' => $this->checkoutSessionId,
            'url' => $this->checkoutUrl,
            'status' => 'open',
            'payment_status' => 'unpaid',
        ];

        return [
            'url' => $this->checkoutUrl,
            'checkout_session_id' => $this->checkoutSessionId,
            'provider_customer_id' => $subscription->providerCustomerId ?? 'cus_test',
            'provider_price_reference' => $config->providerPriceReference,
        ];
    }

    public function createCustomerPortal(BillingConfig $config, BillingSubscription $subscription, array $context): array
    {
        return ['url' => 'https://billing.stripe.test/portal'];
    }

    public function cancelSubscription(BillingConfig $config, BillingSubscription $subscription, array $context): void {}

    public function handleWebhook(string $payload, array $headers): BillingWebhookResult
    {
        throw new \RuntimeException('Not used by this test');
    }
}
