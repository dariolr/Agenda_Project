<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Environment;

final class AppEnvironment
{
    public const LOCAL = 'local';
    public const DEMO = 'demo';
    public const PRODUCTION = 'production';

    public static function normalize(string $value): string
    {
        $normalized = strtolower(trim($value));

        if ($normalized === 'prod') {
            return self::PRODUCTION;
        }

        // Alias legacy/comuni in ambienti locali (es. MAMP/Apache).
        if ($normalized === 'dev' || $normalized === 'development') {
            return self::LOCAL;
        }

        if (!in_array($normalized, [self::LOCAL, self::DEMO, self::PRODUCTION], true)) {
            throw new \RuntimeException(
                sprintf('APP_ENV non riconosciuto: "%s". Valori ammessi: local, demo, production.', $value)
            );
        }

        return $normalized;
    }
}
