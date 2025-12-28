<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Infrastructure\Security\PasswordHasher;

final class PasswordHasherTest extends TestCase
{
    private PasswordHasher $hasher;

    protected function setUp(): void
    {
        $this->hasher = new PasswordHasher();
    }

    public function testCanHashPassword(): void
    {
        $password = 'secure-password-123';
        $hash = $this->hasher->hash($password);

        $this->assertNotEquals($password, $hash);
        $this->assertStringStartsWith('$2y$', $hash); // bcrypt format
    }

    public function testCanVerifyCorrectPassword(): void
    {
        $password = 'my-secret-pass';
        $hash = $this->hasher->hash($password);

        $this->assertTrue($this->hasher->verify($password, $hash));
    }

    public function testRejectsWrongPassword(): void
    {
        $password = 'correct-password';
        $hash = $this->hasher->hash($password);

        $this->assertFalse($this->hasher->verify('wrong-password', $hash));
    }

    public function testDifferentHashesForSamePassword(): void
    {
        $password = 'test-password';
        $hash1 = $this->hasher->hash($password);
        $hash2 = $this->hasher->hash($password);

        // Hashes should be different (different salt)
        $this->assertNotEquals($hash1, $hash2);

        // But both should verify
        $this->assertTrue($this->hasher->verify($password, $hash1));
        $this->assertTrue($this->hasher->verify($password, $hash2));
    }
}
