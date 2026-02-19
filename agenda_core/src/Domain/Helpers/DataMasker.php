<?php

declare(strict_types=1);

namespace Agenda\Domain\Helpers;

/**
 * Helper class for masking personal data (GDPR compliance).
 */
final class DataMasker
{
    /**
     * Mask an email address.
     * Example: mario.rossi@gmail.com -> m***@gmail.com
     */
    public static function maskEmail(?string $email): ?string
    {
        if ($email === null || $email === '') {
            return null;
        }

        $parts = explode('@', $email);
        if (count($parts) !== 2) {
            return '***';
        }

        $localPart = $parts[0];
        $domain = $parts[1];

        // Keep first character, mask the rest
        $maskedLocal = Unicode::length($localPart) > 1
            ? Unicode::firstCharacter($localPart) . '***'
            : '***';

        return $maskedLocal . '@' . $domain;
    }

    /**
     * Mask a phone number.
     * Example: 3331234567 -> 333****567
     */
    public static function maskPhone(?string $phone): ?string
    {
        if ($phone === null || $phone === '') {
            return null;
        }

        // Remove non-numeric characters for processing
        $digits = preg_replace('/[^0-9]/', '', $phone);
        
        if ($digits === null || strlen($digits) < 6) {
            return '***';
        }

        $length = strlen($digits);
        
        // Keep first 3 and last 3 digits
        $prefix = substr($digits, 0, 3);
        $suffix = substr($digits, -3);
        $middleLength = $length - 6;
        
        return $prefix . str_repeat('*', max($middleLength, 4)) . $suffix;
    }

    /**
     * Mask a generic string (e.g., name).
     * Example: Mario -> M***
     */
    public static function maskString(?string $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Unicode::length($value) > 1
            ? Unicode::firstCharacter($value) . '***'
            : '***';
    }
}
