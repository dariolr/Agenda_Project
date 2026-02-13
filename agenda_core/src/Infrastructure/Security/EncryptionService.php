<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Security;

use RuntimeException;

final class EncryptionService
{
    private string $key;

    public function __construct(?string $key = null)
    {
        $appKey = $key ?? ($_ENV['ENCRYPTION_KEY'] ?? $_ENV['APP_KEY'] ?? null);
        if ($appKey === null || $appKey === '') {
            throw new RuntimeException('Missing ENCRYPTION_KEY/APP_KEY for encryption service.');
        }

        $normalized = str_starts_with($appKey, 'base64:') ? base64_decode(substr($appKey, 7), true) : $appKey;
        if ($normalized === false || strlen($normalized) < 32) {
            throw new RuntimeException('Encryption key must be at least 32 bytes (AES-256).');
        }

        $this->key = substr($normalized, 0, 32);
    }

    public function encrypt(string $plaintext): string
    {
        $iv = random_bytes(16);
        $ciphertext = openssl_encrypt($plaintext, 'aes-256-cbc', $this->key, OPENSSL_RAW_DATA, $iv);

        if ($ciphertext === false) {
            throw new RuntimeException('Unable to encrypt value.');
        }

        $mac = hash_hmac('sha256', $iv . $ciphertext, $this->key, true);

        return base64_encode($iv . $mac . $ciphertext);
    }

    public function decrypt(string $payload): string
    {
        $decoded = base64_decode($payload, true);
        if ($decoded === false || strlen($decoded) < 48) {
            throw new RuntimeException('Invalid encrypted payload.');
        }

        $iv = substr($decoded, 0, 16);
        $mac = substr($decoded, 16, 32);
        $ciphertext = substr($decoded, 48);

        $expectedMac = hash_hmac('sha256', $iv . $ciphertext, $this->key, true);
        if (!hash_equals($expectedMac, $mac)) {
            throw new RuntimeException('Invalid payload MAC.');
        }

        $plaintext = openssl_decrypt($ciphertext, 'aes-256-cbc', $this->key, OPENSSL_RAW_DATA, $iv);
        if ($plaintext === false) {
            throw new RuntimeException('Unable to decrypt value.');
        }

        return $plaintext;
    }
}
