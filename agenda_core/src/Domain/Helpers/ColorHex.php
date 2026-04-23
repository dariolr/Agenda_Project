<?php

declare(strict_types=1);

namespace Agenda\Domain\Helpers;

/**
 * Centralized color hex normalization/validation.
 *
 * Accepted format: #RRGGBB
 * Returned format: uppercase #RRGGBB
 */
final class ColorHex
{
    /**
     * Normalize an optional color value.
     *
     * @return array{value?: ?string, error?: string}
     */
    public static function normalizeOptional(mixed $raw, string $field = 'color_hex'): array
    {
        if ($raw === null) {
            return ['value' => null];
        }
        if (!is_string($raw)) {
            return ['error' => $field . ' must be a string'];
        }

        $value = trim($raw);
        if ($value === '') {
            return ['value' => null];
        }
        if (!preg_match('/^#[0-9A-Fa-f]{6}$/', $value)) {
            return ['error' => $field . ' must be in format #RRGGBB'];
        }

        return ['value' => strtoupper($value)];
    }
}

