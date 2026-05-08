<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Domain\Billing\BillingProviderCode;
use Agenda\Domain\Billing\BillingSubscriptionStatus;
use Agenda\Infrastructure\Billing\Stripe\StripeBillingProvider;
use Agenda\Infrastructure\Billing\Stripe\StripeClientFactory;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\Billing\BillingProviderEventRepository;
use Agenda\Infrastructure\Repositories\Billing\BusinessBillingConfigRepository;
use PDO;
use PHPUnit\Framework\TestCase;

final class StripeBillingProviderTest extends TestCase
{
    private const WEBHOOK_SECRET = 'whsec_test_secret';

    protected function setUp(): void
    {
        $_ENV['STRIPE_WEBHOOK_SECRET'] = self::WEBHOOK_SECRET;
    }

    protected function tearDown(): void
    {
        unset($_ENV['STRIPE_WEBHOOK_SECRET']);
    }

    public function testInvoicePaymentPaidIsHandledAsSuccessfulPayment(): void
    {
        $created = 1_714_569_600;
        $paidAt = 1_714_569_660;
        $event = [
            'id' => 'evt_invoice_payment_paid',
            'object' => 'event',
            'type' => 'invoice_payment.paid',
            'data' => [
                'object' => [
                    'id' => 'inpay_test',
                    'object' => 'invoice_payment',
                    'created' => $created,
                    'status' => 'paid',
                    'status_transitions' => [
                        'paid_at' => $paidAt,
                    ],
                    'metadata' => [
                        'business_id' => '42',
                    ],
                    'invoice' => [
                        'id' => 'in_test',
                        'object' => 'invoice',
                        'customer' => 'cus_test',
                        'subscription' => 'sub_test',
                        'lines' => [
                            'data' => [
                                [
                                    'price' => [
                                        'id' => 'price_test',
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertSame('evt_invoice_payment_paid', $result->providerEventId);
        $this->assertSame('invoice_payment.paid', $result->eventType);
        $this->assertSame(42, $result->businessId);
        $this->assertSame(BillingProviderCode::STRIPE, $result->providerCode);
        $this->assertSame('cus_test', $result->providerCustomerId);
        $this->assertSame('sub_test', $result->providerSubscriptionId);
        $this->assertSame('price_test', $result->providerPriceReference);
        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $result->targetStatus);
        $this->assertSame('2024-05-01 13:21:00', $result->lastPaymentAt);
        $this->assertNull($result->lastPaymentFailedAt);
    }

    public function testInvoicePaymentPaidProvidesSubscriptionForExistingFallbackWhenBusinessIsMissing(): void
    {
        $event = [
            'id' => 'evt_invoice_payment_paid_without_business',
            'object' => 'event',
            'type' => 'invoice_payment.paid',
            'data' => [
                'object' => [
                    'id' => 'inpay_without_business',
                    'object' => 'invoice_payment',
                    'created' => 1_714_569_600,
                    'status' => 'paid',
                    'subscription' => 'sub_existing',
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertNull($result->businessId);
        $this->assertSame('sub_existing', $result->providerSubscriptionId);
        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $result->targetStatus);
        $this->assertSame('2024-05-01 13:20:00', $result->lastPaymentAt);
    }

    public function testInvoicePaymentPaidCanBeStoredAsBillingProviderEvent(): void
    {
        $event = [
            'id' => 'evt_invoice_payment_paid_stored',
            'object' => 'event',
            'type' => 'invoice_payment.paid',
            'data' => [
                'object' => [
                    'id' => 'inpay_stored',
                    'object' => 'invoice_payment',
                    'created' => 1_714_569_600,
                    'status' => 'paid',
                    'metadata' => [
                        'business_id' => '42',
                    ],
                ],
            ],
        ];
        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));
        $pdo = new PDO('sqlite::memory:');
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->sqliteCreateFunction('UTC_TIMESTAMP', static fn (): string => gmdate('Y-m-d H:i:s'));
        $pdo->exec(
            'CREATE TABLE billing_provider_events (
                provider_code TEXT NOT NULL,
                provider_event_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                business_id INTEGER NULL,
                payload_json TEXT NOT NULL,
                processed_at TEXT NOT NULL
            )'
        );
        $connection = new Connection();
        $reflection = new \ReflectionProperty(Connection::class, 'pdo');
        $reflection->setAccessible(true);
        $reflection->setValue($connection, $pdo);

        $repository = new BillingProviderEventRepository($connection);
        $repository->storeProcessedEvent($result);

        $row = $pdo->query('SELECT * FROM billing_provider_events LIMIT 1')->fetch(PDO::FETCH_ASSOC);

        $this->assertSame('stripe', $row['provider_code']);
        $this->assertSame('evt_invoice_payment_paid_stored', $row['provider_event_id']);
        $this->assertSame('invoice_payment.paid', $row['event_type']);
        $this->assertSame(42, (int) $row['business_id']);
    }

    public function testSubscriptionUpdatedCancelAtPeriodEndKeepsActiveAndPeriodEnd(): void
    {
        $periodStart = 1_714_569_600;
        $periodEnd = 1_717_161_600;
        $event = [
            'id' => 'evt_subscription_updated_cancel_at_period_end',
            'object' => 'event',
            'type' => 'customer.subscription.updated',
            'data' => [
                'object' => [
                    'id' => 'sub_cancel_at_period_end',
                    'object' => 'subscription',
                    'customer' => 'cus_test',
                    'status' => 'active',
                    'current_period_start' => $periodStart,
                    'current_period_end' => $periodEnd,
                    'cancel_at_period_end' => true,
                    'metadata' => [
                        'business_id' => '42',
                    ],
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $result->targetStatus);
        $this->assertTrue($result->cancelAtPeriodEnd);
        $this->assertSame(gmdate('Y-m-d H:i:s', $periodStart), $result->currentPeriodStart);
        $this->assertSame(gmdate('Y-m-d H:i:s', $periodEnd), $result->currentPeriodEnd);
        $this->assertNull($result->canceledAt);
    }

    public function testSubscriptionUpdatedReadsCurrentPeriodFromSubscriptionItem(): void
    {
        $periodStart = 1_714_569_600;
        $periodEnd = 1_717_161_600;
        $event = [
            'id' => 'evt_subscription_updated_item_period',
            'object' => 'event',
            'type' => 'customer.subscription.updated',
            'data' => [
                'object' => [
                    'id' => 'sub_item_period',
                    'object' => 'subscription',
                    'customer' => 'cus_test',
                    'status' => 'active',
                    'cancel_at_period_end' => true,
                    'metadata' => [
                        'business_id' => '42',
                    ],
                    'items' => [
                        'data' => [
                            [
                                'current_period_start' => $periodStart,
                                'current_period_end' => $periodEnd,
                                'price' => [
                                    'id' => 'price_test',
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $result->targetStatus);
        $this->assertTrue($result->cancelAtPeriodEnd);
        $this->assertSame(gmdate('Y-m-d H:i:s', $periodStart), $result->currentPeriodStart);
        $this->assertSame(gmdate('Y-m-d H:i:s', $periodEnd), $result->currentPeriodEnd);
        $this->assertSame('price_test', $result->providerPriceReference);
        $this->assertNull($result->canceledAt);
    }

    public function testSubscriptionDeletedSetsCanceledStatusAndCanceledAt(): void
    {
        $canceledAt = 1_714_569_660;
        $event = [
            'id' => 'evt_subscription_deleted',
            'object' => 'event',
            'created' => 1_714_569_700,
            'type' => 'customer.subscription.deleted',
            'data' => [
                'object' => [
                    'id' => 'sub_deleted',
                    'object' => 'subscription',
                    'customer' => 'cus_test',
                    'status' => 'canceled',
                    'cancel_at_period_end' => false,
                    'canceled_at' => $canceledAt,
                    'metadata' => [
                        'business_id' => '42',
                    ],
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertSame(BillingSubscriptionStatus::CANCELED, $result->targetStatus);
        $this->assertFalse($result->cancelAtPeriodEnd);
        $this->assertSame(gmdate('Y-m-d H:i:s', $canceledAt), $result->canceledAt);
    }

    public function testInvoicePaidRemainsSupportedAsSuccessfulPayment(): void
    {
        $event = [
            'id' => 'evt_invoice_paid',
            'object' => 'event',
            'type' => 'invoice.paid',
            'data' => [
                'object' => [
                    'id' => 'in_paid',
                    'object' => 'invoice',
                    'created' => 1_714_569_600,
                    'customer' => 'cus_invoice',
                    'subscription' => 'sub_invoice',
                    'metadata' => [
                        'business_id' => '7',
                    ],
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertSame('invoice.paid', $result->eventType);
        $this->assertSame(7, $result->businessId);
        $this->assertSame('cus_invoice', $result->providerCustomerId);
        $this->assertSame('sub_invoice', $result->providerSubscriptionId);
        $this->assertSame(BillingSubscriptionStatus::ACTIVE, $result->targetStatus);
        $this->assertSame('2024-05-01 13:20:00', $result->lastPaymentAt);
    }

    public function testCheckoutCompletedWithoutPaidStatusDoesNotMarkActiveOrPaid(): void
    {
        $event = [
            'id' => 'evt_checkout_unpaid',
            'object' => 'event',
            'type' => 'checkout.session.completed',
            'created' => 1_714_569_700,
            'data' => [
                'object' => [
                    'id' => 'cs_unpaid',
                    'object' => 'checkout.session',
                    'status' => 'complete',
                    'payment_status' => 'unpaid',
                    'customer' => 'cus_unpaid',
                    'subscription' => 'sub_unpaid',
                    'client_reference_id' => '42',
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertSame('checkout.session.completed', $result->eventType);
        $this->assertSame(42, $result->businessId);
        $this->assertSame('sub_unpaid', $result->providerSubscriptionId);
        $this->assertNotSame(BillingSubscriptionStatus::ACTIVE, $result->targetStatus);
        $this->assertNull($result->lastPaymentAt);
    }

    public function testInvoicePaymentFailedMarksPastDueAndDoesNotSetLastPaymentAt(): void
    {
        $event = [
            'id' => 'evt_invoice_payment_failed',
            'object' => 'event',
            'type' => 'invoice_payment.failed',
            'data' => [
                'object' => [
                    'id' => 'inpay_failed',
                    'object' => 'invoice_payment',
                    'created' => 1_714_569_700,
                    'status' => 'failed',
                    'invoice' => [
                        'id' => 'in_failed',
                        'object' => 'invoice',
                        'customer' => 'cus_failed',
                        'subscription' => 'sub_failed',
                        'metadata' => [
                            'business_id' => '42',
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->provider()->handleWebhook($this->payload($event), $this->headers($event));

        $this->assertSame(BillingSubscriptionStatus::PAST_DUE, $result->targetStatus);
        $this->assertSame('sub_failed', $result->providerSubscriptionId);
        $this->assertNull($result->lastPaymentAt);
        $this->assertSame('2024-05-01 13:21:40', $result->lastPaymentFailedAt);
    }

    private function provider(): StripeBillingProvider
    {
        return new StripeBillingProvider(
            new StripeClientFactory(),
            new BusinessBillingConfigRepository(new Connection()),
        );
    }

    private function payload(array $event): string
    {
        return json_encode($event, JSON_THROW_ON_ERROR);
    }

    /**
     * @return array<string, string>
     */
    private function headers(array $event): array
    {
        $payload = $this->payload($event);
        $timestamp = (string) time();
        $signature = hash_hmac('sha256', $timestamp . '.' . $payload, self::WEBHOOK_SECRET);

        return [
            'stripe-signature' => 't=' . $timestamp . ',v1=' . $signature,
        ];
    }
}
