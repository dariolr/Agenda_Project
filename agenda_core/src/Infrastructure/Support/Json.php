<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Support;

use JsonException;

/**
 * Centralized JSON helper with Unicode-safe defaults.
 */
final class Json
{
    private const ENCODE_FLAGS =
        JSON_UNESCAPED_UNICODE
        | JSON_UNESCAPED_SLASHES
        | JSON_INVALID_UTF8_SUBSTITUTE
        | JSON_THROW_ON_ERROR;

    private const DECODE_FLAGS =
        JSON_INVALID_UTF8_SUBSTITUTE
        | JSON_THROW_ON_ERROR;

    /**
     * Encode data to JSON using safe defaults for Unicode.
     */
    public static function encode(mixed $value): string
    {
        try {
            return json_encode($value, self::ENCODE_FLAGS);
        } catch (JsonException) {
            return 'null';
        }
    }

    /**
     * Decode JSON string to associative array.
     * Returns null for invalid JSON or non-array payload.
     */
    public static function decodeAssoc(string $json): ?array
    {
        try {
            $decoded = json_decode($json, true, 512, self::DECODE_FLAGS);
            return is_array($decoded) ? $decoded : null;
        } catch (JsonException) {
            return null;
        }
    }
}

