<?php

declare(strict_types=1);

namespace Agenda\Tests;

use Agenda\Infrastructure\Environment\EnvironmentConfig;
use Agenda\Infrastructure\Environment\EnvironmentPolicy;
use PHPUnit\Framework\TestCase;

final class EnvironmentConfigTest extends TestCase
{
    private array $backupEnv = [];

    protected function setUp(): void
    {
        parent::setUp();
        $this->backupEnv = $_ENV;
        $this->resetEnvironmentConfigSingleton();
    }

    protected function tearDown(): void
    {
        $_ENV = $this->backupEnv;
        $this->resetEnvironmentConfigSingleton();
        parent::tearDown();
    }

    public function testDemoConfigIsValidatedAsSafe(): void
    {
        $_ENV['APP_ENV'] = 'demo';
        $_ENV['API_BASE_URL'] = 'https://demo-api.romeolab.it';
        $_ENV['FRONTEND_URL'] = 'https://demo-gestionale.romeolab.it';
        $_ENV['SHOW_DEMO_BANNER'] = 'true';
        $_ENV['ALLOW_REAL_EMAILS'] = 'false';
        $_ENV['ALLOW_REAL_WHATSAPP'] = 'false';
        $_ENV['ALLOW_REAL_PAYMENTS'] = 'false';
        $_ENV['ALLOW_EXTERNAL_WEBHOOKS'] = 'false';
        $_ENV['ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS'] = 'false';
        $_ENV['ALLOW_PLAN_CHANGES'] = 'false';
        $_ENV['ALLOW_REAL_EXPORTS'] = 'false';
        $_ENV['DB_DATABASE'] = 'agenda_demo';

        $config = EnvironmentConfig::bootstrap();
        $policy = EnvironmentPolicy::current();

        $this->assertTrue($config->isDemo);
        $this->assertFalse($policy->canSendRealEmails());
        $this->assertFalse($policy->canUseRealPayments());
        $this->assertFalse($policy->canDeleteBusiness());
    }

    public function testDemoConfigFailsIfRealEmailsEnabled(): void
    {
        $_ENV['APP_ENV'] = 'demo';
        $_ENV['API_BASE_URL'] = 'https://demo-api.romeolab.it';
        $_ENV['FRONTEND_URL'] = 'https://demo-gestionale.romeolab.it';
        $_ENV['SHOW_DEMO_BANNER'] = 'true';
        $_ENV['ALLOW_REAL_EMAILS'] = 'true';
        $_ENV['DB_DATABASE'] = 'agenda_demo';

        $this->expectException(\RuntimeException::class);
        EnvironmentConfig::bootstrap();
    }

    public function testDemoConfigFailsIfProductionApiIsUsed(): void
    {
        $_ENV['APP_ENV'] = 'demo';
        $_ENV['API_BASE_URL'] = 'https://api.romeolab.it';
        $_ENV['FRONTEND_URL'] = 'https://demo-gestionale.romeolab.it';
        $_ENV['SHOW_DEMO_BANNER'] = 'true';
        $_ENV['DB_DATABASE'] = 'agenda_demo';

        $this->expectException(\RuntimeException::class);
        EnvironmentConfig::bootstrap();
    }

    public function testDevelopmentAliasIsNormalizedToLocal(): void
    {
        $_ENV['APP_ENV'] = 'development';
        $_ENV['API_BASE_URL'] = 'http://localhost:8888';
        $_ENV['FRONTEND_URL'] = 'http://localhost:3001';

        $config = EnvironmentConfig::bootstrap();

        $this->assertSame('local', $config->environmentName);
        $this->assertTrue($config->isLocal);
        $this->assertFalse($config->isDemo);
        $this->assertFalse($config->isProduction);
    }

    private function resetEnvironmentConfigSingleton(): void
    {
        $reflection = new \ReflectionClass(EnvironmentConfig::class);
        $property = $reflection->getProperty('current');
        $property->setAccessible(true);
        $property->setValue(null, null);
    }
}
