<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;

final class ReportsPaymentAggregationTest extends TestCase
{
    public function testReportsUseAppliedBookingPriceAsDueCents(): void
    {
        $reportsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ReportsController.php');

        $this->assertStringContainsString('COALESCE(SUM(fb.fallback_due_cents), 0) AS due_cents', $reportsController);
        $this->assertStringContainsString('CAST(ROUND(COALESCE(SUM(bi.price), 0) * 100, 0) AS UNSIGNED) AS fallback_due_cents', $reportsController);
        $this->assertStringNotContainsString('COALESCE(SUM(COALESCE(bp.total_due_cents, fb.fallback_due_cents)), 0) AS due_cents', $reportsController);
    }

    public function testReportsIgnoreLegacyAutomaticBookingPriceAdjustmentDiscounts(): void
    {
        $reportsController = (string) file_get_contents(__DIR__ . '/../src/Http/Controllers/ReportsController.php');

        $this->assertStringContainsString("private const AUTO_DISCOUNT_SOURCE = 'appointment_amount_adjustment';", $reportsController);
        $this->assertStringContainsString("COALESCE(JSON_UNQUOTE(JSON_EXTRACT(bpl.meta_json, '$.source')), '') <> '\" . self::AUTO_DISCOUNT_SOURCE . \"'", $reportsController);
    }
}
