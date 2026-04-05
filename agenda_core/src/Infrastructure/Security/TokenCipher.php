<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Security;

final class TokenCipher
{
    private const CIPHER = 'aes-256-gcm';

    private readonly string $key;

    public function __construct(?string $rawKey = null)
    {
        $input = trim((string) ($rawKey ?? ($_ENV['WHATSAPP_TOKEN_ENCRYPTION_KEY'] ?? getenv('WHATSAPP_TOKEN_ENCRYPTION_KEY') ?? '')));
        if ($input === '') {
            throw new \RuntimeException('WHATSAPP_TOKEN_ENCRYPTION_KEY is required');
        }

        $decoded = base64_decode($input, true);
        $material = $decoded !== false && $decoded !== '' ? $decoded : $input;

        // Normalize to 32 bytes deterministically.
        $this->key = strlen($material) === 32
            ? $material
            : hash('sha256', $material, true);
    }

    public function encrypt(string $plainToken): string
    {
        $ivLen = openssl_cipher_iv_length(self::CIPHER);
        if ($ivLen <= 0) {
            throw new \RuntimeException('Invalid cipher IV length');
        }

        $iv = random_bytes($ivLen);
        $tag = '';
        $ciphertext = openssl_encrypt(
            $plainToken,
            self::CIPHER,
            $this->key,
            OPENSSL_RAW_DATA,
            $iv,
            $tag,
            '',
            16
        );

        if (!is_string($ciphertext) || $ciphertext === '') {
            throw new \RuntimeException('Failed to encrypt token');
        }

        return 'v1:' . base64_encode($iv) . ':' . base64_encode($tag) . ':' . base64_encode($ciphertext);
    }

    public function decrypt(string $encryptedToken): string
    {
        $parts = explode(':', $encryptedToken, 4);
        if (count($parts) !== 4 || $parts[0] !== 'v1') {
            throw new \RuntimeException('Unsupported encrypted token format');
        }

        [$version, $ivB64, $tagB64, $cipherB64] = $parts;
        $iv = base64_decode($ivB64, true);
        $tag = base64_decode($tagB64, true);
        $ciphertext = base64_decode($cipherB64, true);

        if ($iv === false || $tag === false || $ciphertext === false) {
            throw new \RuntimeException('Corrupted encrypted token payload');
        }

        $plain = openssl_decrypt(
            $ciphertext,
            self::CIPHER,
            $this->key,
            OPENSSL_RAW_DATA,
            $iv,
            $tag,
            ''
        );

        if (!is_string($plain)) {
            throw new \RuntimeException('Failed to decrypt token');
        }

        return $plain;
    }
}
