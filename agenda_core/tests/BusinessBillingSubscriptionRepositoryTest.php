<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Domain\Billing\BillingProviderCode;
use Agenda\Domain\Billing\BillingSubscriptionStatus;
use Agenda\Domain\Billing\BillingWebhookResult;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingSubscriptionRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class BusinessBillingSubscriptionRepositoryTest extends TestCase
{
    private PDO $pdo;
    private BusinessBillingSubscriptionRepository $repository;

    protected function setUp(): void
    {
        $this->pdo = new PDO('sqlite::memory:');
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->createSchema();

        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $this->pdo);

        $this->repository = new BusinessBillingSubscriptionRepository($connection);
    }

    public function testActiveWebhookClearsPreviousCanceledAtAndUpdatesSubscription(): void
    {
        $this->pdo->exec(
            "INSERT INTO business_billing_subscription
                (business_id, provider_code, provider_customer_id, provider_subscription_id,
                 provider_price_reference, status, current_period_start, current_period_end,
                 cancel_at_period_end, canceled_at)
             VALUES
                (42, 'stripe', 'cus_old', 'sub_old', 'price_old', 'canceled',
                 '2024-04-01 00:00:00', '2024-05-01 00:00:00', 1, '2024-05-02 10:00:00')"
        );

        $this->repository->updateFromWebhookResult(new BillingWebhookResult(
            providerEventId: 'evt_new_checkout_paid',
            eventType: 'checkout.session.completed',
            businessId: 42,
            providerCode: BillingProviderCode::STRIPE,
            providerCustomerId: 'cus_new',
            providerSubscriptionId: 'sub_new',
            providerPriceReference: 'price_new',
            targetStatus: BillingSubscriptionStatus::ACTIVE,
            currentPeriodStart: '2024-06-01 00:00:00',
            currentPeriodEnd: '2024-07-01 00:00:00',
            cancelAtPeriodEnd: false,
            canceledAt: null,
            lastPaymentAt: '2024-06-01 09:30:00',
            lastPaymentFailedAt: null,
            rawPayload: [],
        ));

        $row = $this->pdo
            ->query('SELECT * FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $row['status']);
        $this->assertSame('cus_new', $row['provider_customer_id']);
        $this->assertSame('sub_new', $row['provider_subscription_id']);
        $this->assertSame('price_new', $row['provider_price_reference']);
        $this->assertSame('2024-06-01 00:00:00', $row['current_period_start']);
        $this->assertSame('2024-07-01 00:00:00', $row['current_period_end']);
        $this->assertSame(0, (int) $row['cancel_at_period_end']);
        $this->assertNull($row['canceled_at']);
        $this->assertSame('2024-06-01 09:30:00', $row['last_payment_at']);
    }

    public function testFailedInitialPaymentClearsPreviousLastPaymentAtForNewSubscription(): void
    {
        $this->pdo->exec(
            "INSERT INTO business_billing_subscription
                (business_id, provider_code, provider_customer_id, provider_subscription_id,
                 provider_price_reference, status, last_payment_at)
             VALUES
                (42, 'stripe', 'cus_old', 'sub_old', 'price_old', 'canceled',
                 '2024-05-01 09:30:00')"
        );

        $this->repository->updateFromWebhookResult(new BillingWebhookResult(
            providerEventId: 'evt_initial_payment_failed',
            eventType: 'invoice.payment_failed',
            businessId: 42,
            providerCode: BillingProviderCode::STRIPE,
            providerCustomerId: 'cus_new',
            providerSubscriptionId: 'sub_new',
            providerPriceReference: 'price_new',
            targetStatus: BillingSubscriptionStatus::PAST_DUE,
            currentPeriodStart: null,
            currentPeriodEnd: null,
            cancelAtPeriodEnd: false,
            canceledAt: null,
            lastPaymentAt: null,
            lastPaymentFailedAt: '2024-06-01 09:30:00',
            rawPayload: [],
        ));

        $row = $this->pdo
            ->query('SELECT * FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame(BillingSubscriptionStatus::PAST_DUE, $row['status']);
        $this->assertSame('sub_new', $row['provider_subscription_id']);
        $this->assertNull($row['last_payment_at']);
        $this->assertSame('2024-06-01 09:30:00', $row['last_payment_failed_at']);
    }

    public function testSecondActiveSubscriptionWebhookDoesNotOverwriteCanonicalSubscription(): void
    {
        $this->pdo->exec(
            "INSERT INTO business_billing_subscription
                (business_id, provider_code, provider_customer_id, provider_subscription_id,
                 provider_price_reference, status, last_payment_at)
             VALUES
                (42, 'stripe', 'cus_test', 'sub_canonical', 'price_canonical', 'active',
                 '2024-05-01 09:30:00')"
        );

        $this->repository->updateFromWebhookResult(new BillingWebhookResult(
            providerEventId: 'evt_second_active',
            eventType: 'customer.subscription.created',
            businessId: 42,
            providerCode: BillingProviderCode::STRIPE,
            providerCustomerId: 'cus_test',
            providerSubscriptionId: 'sub_duplicate',
            providerPriceReference: 'price_duplicate',
            targetStatus: BillingSubscriptionStatus::ACTIVE,
            currentPeriodStart: '2024-06-01 00:00:00',
            currentPeriodEnd: '2024-07-01 00:00:00',
            cancelAtPeriodEnd: false,
            canceledAt: null,
            lastPaymentAt: '2024-06-01 09:30:00',
            lastPaymentFailedAt: null,
            rawPayload: [],
        ));

        $row = $this->pdo
            ->query('SELECT * FROM business_billing_subscription WHERE business_id = 42')
            ->fetch(PDO::FETCH_ASSOC);

        $this->assertSame('sub_canonical', $row['provider_subscription_id']);
        $this->assertSame('price_canonical', $row['provider_price_reference']);
        $this->assertSame('2024-05-01 09:30:00', $row['last_payment_at']);
    }

    private function createSchema(): void
    {
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
}
