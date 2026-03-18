<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Environment;

final class EnvironmentConfig
{
    private static ?self $current = null;

    private function __construct(
        public readonly string $environmentName,
        public readonly bool $isLocal,
        public readonly bool $isDemo,
        public readonly bool $isProduction,
        public readonly string $apiBaseUrl,
        public readonly string $webBaseUrl,
        public readonly bool $showDemoBanner,
        public readonly bool $allowRealEmails,
        public readonly bool $allowRealWhatsapp,
        public readonly bool $allowRealPayments,
        public readonly bool $allowExternalWebhooks,
        public readonly bool $allowDestructiveBusinessActions,
        public readonly bool $allowPlanChanges,
        public readonly bool $allowRealExports,
        public readonly bool $demoResetExpected,
        public readonly bool $demoAutoLoginEnabled,
        public readonly string $dbHost,
        public readonly string $dbPort,
        public readonly string $dbDatabase,
        public readonly string $dbUsername,
        public readonly string $dbPassword,
        public readonly string $corsAllowedOrigins,
        public readonly string $appTimezone,
    ) {}

    public static function bootstrap(): self
    {
        if (self::$current !== null) {
            return self::$current;
        }

        $appEnv = AppEnvironment::normalize(self::env('APP_ENV', 'production'));
        $isProduction = $appEnv === AppEnvironment::PRODUCTION;
        $isDemo = $appEnv === AppEnvironment::DEMO;
        $isLocal = $appEnv === AppEnvironment::LOCAL;

        $config = new self(
            environmentName: $appEnv,
            isLocal: $isLocal,
            isDemo: $isDemo,
            isProduction: $isProduction,
            apiBaseUrl: self::env('API_BASE_URL', 'https://api.romeolab.it'),
            webBaseUrl: self::env('FRONTEND_URL', 'https://prenota.romeolab.it'),
            showDemoBanner: self::envBool('SHOW_DEMO_BANNER', $isDemo),
            allowRealEmails: self::envBool('ALLOW_REAL_EMAILS', $isProduction),
            allowRealWhatsapp: self::envBool('ALLOW_REAL_WHATSAPP', $isProduction),
            allowRealPayments: self::envBool('ALLOW_REAL_PAYMENTS', $isProduction),
            allowExternalWebhooks: self::envBool('ALLOW_EXTERNAL_WEBHOOKS', $isProduction),
            allowDestructiveBusinessActions: self::envBool('ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS', $isProduction),
            allowPlanChanges: self::envBool('ALLOW_PLAN_CHANGES', $isProduction),
            allowRealExports: self::envBool('ALLOW_REAL_EXPORTS', $isProduction),
            demoResetExpected: self::envBool('DEMO_RESET_EXPECTED', $isDemo),
            demoAutoLoginEnabled: self::envBool('DEMO_AUTO_LOGIN_ENABLED', false),
            dbHost: self::env('DB_HOST', 'localhost'),
            dbPort: self::env('DB_PORT', '3306'),
            dbDatabase: self::env('DB_DATABASE', 'agenda_core'),
            dbUsername: self::env('DB_USERNAME', 'root'),
            dbPassword: self::env('DB_PASSWORD', ''),
            corsAllowedOrigins: self::env('CORS_ALLOWED_ORIGINS', '*'),
            appTimezone: self::env('APP_TIMEZONE', 'UTC'),
        );

        self::validate($config);
        self::$current = $config;

        return self::$current;
    }

    public static function current(): self
    {
        return self::$current ?? self::bootstrap();
    }

    private static function validate(self $config): void
    {
        self::assertValidUrl('API_BASE_URL', $config->apiBaseUrl);
        self::assertValidUrl('FRONTEND_URL', $config->webBaseUrl);

        if ($config->isDemo) {
            if (
                $config->allowRealEmails ||
                $config->allowRealWhatsapp ||
                $config->allowRealPayments ||
                $config->allowExternalWebhooks ||
                $config->allowDestructiveBusinessActions ||
                $config->allowPlanChanges ||
                $config->allowRealExports
            ) {
                throw new \RuntimeException(
                    'Configurazione demo non sicura: i flag ALLOW_REAL_* e ALLOW_* sensibili devono essere false.'
                );
            }

            if (!$config->showDemoBanner) {
                throw new \RuntimeException('Configurazione demo non sicura: SHOW_DEMO_BANNER deve essere true in demo.');
            }

            if ($config->apiBaseUrl === 'https://api.romeolab.it') {
                throw new \RuntimeException('Configurazione demo non sicura: API demo non puo\' puntare a https://api.romeolab.it.');
            }

            $dbLower = strtolower(trim($config->dbDatabase));
            if ($dbLower === '' || in_array($dbLower, ['agenda_core', 'agenda_production', 'agenda_prod'], true)) {
                throw new \RuntimeException('Configurazione demo non sicura: DB_DATABASE deve puntare a database demo dedicato.');
            }
        }
    }

    private static function assertValidUrl(string $name, string $value): void
    {
        if ($value === '') {
            throw new \RuntimeException($name . ' mancante.');
        }

        $isValid = filter_var($value, FILTER_VALIDATE_URL) !== false;
        if (!$isValid) {
            throw new \RuntimeException($name . ' non valido: ' . $value);
        }

        $scheme = (string) parse_url($value, PHP_URL_SCHEME);
        if ($scheme !== 'http' && $scheme !== 'https') {
            throw new \RuntimeException($name . ' deve usare http/https: ' . $value);
        }
    }

    private static function env(string $key, string $default): string
    {
        $value = $_ENV[$key] ?? getenv($key);
        if ($value === false || $value === null || trim((string) $value) === '') {
            return $default;
        }

        return trim((string) $value);
    }

    private static function envBool(string $key, bool $default): bool
    {
        $raw = $_ENV[$key] ?? getenv($key);
        if ($raw === false || $raw === null || trim((string) $raw) === '') {
            return $default;
        }

        return in_array(strtolower(trim((string) $raw)), ['1', 'true', 'yes', 'on'], true);
    }
}
