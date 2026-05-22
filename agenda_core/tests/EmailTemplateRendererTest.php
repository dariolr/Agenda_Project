<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use PHPUnit\Framework\TestCase;

final class EmailTemplateRendererTest extends TestCase
{
    public function testEmptyAddressAndPhoneDoNotLeaveBlankFooterBreaks(): void
    {
        $template = '<p>Il team di {{business_name}}<br>{{location_address_line}}<br>{{location_phone}}</p>';

        $rendered = EmailTemplateRenderer::render($template, [
            'business_name' => 'Romeo Lab',
            'location_address_line' => '',
            'location_phone' => '',
        ]);

        $this->assertSame('<p>Il team di Romeo Lab</p>', $rendered);
    }

    public function testMissingPhoneDoesNotLeavePipeSeparator(): void
    {
        $template = "Il team di {{business_name}} | {{location_phone}}\n";

        $rendered = EmailTemplateRenderer::render($template, [
            'business_name' => 'Romeo Lab',
            'location_phone' => '',
        ]);

        $this->assertSame("Il team di Romeo Lab\n", $rendered);
    }
}
