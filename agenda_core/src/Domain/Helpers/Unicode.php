<?php

declare(strict_types=1);

namespace Agenda\Domain\Helpers;

/**
 * Centralized Unicode helpers for multibyte-safe string operations.
 */
final class Unicode
{
    /**
     * Returns the first user-visible character (grapheme/codepoint).
     */
    public static function firstCharacter(?string $value): string
    {
        if ($value === null) {
            return '';
        }

        $value = trim($value);
        if ($value === '') {
            return '';
        }

        if (function_exists('grapheme_substr')) {
            $first = grapheme_substr($value, 0, 1);
            if ($first !== false && $first !== null) {
                return $first;
            }
        }

        if (function_exists('mb_substr')) {
            return mb_substr($value, 0, 1, 'UTF-8');
        }

        if (preg_match('/^./us', $value, $matches) === 1) {
            return $matches[0];
        }

        return substr($value, 0, 1);
    }

    /**
     * Unicode-aware character length.
     */
    public static function length(?string $value): int
    {
        if ($value === null) {
            return 0;
        }

        if (function_exists('grapheme_strlen')) {
            $len = grapheme_strlen($value);
            if ($len !== false) {
                return $len;
            }
        }

        if (function_exists('mb_strlen')) {
            return mb_strlen($value, 'UTF-8');
        }

        if (preg_match_all('/./us', $value, $matches) === false) {
            return strlen($value);
        }

        return count($matches[0]);
    }
}

