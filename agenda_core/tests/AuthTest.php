<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;

/**
 * Auth module tests
 */
final class AuthTest extends TestCase
{
    private PasswordHasher $hasher;

    protected function setUp(): void
    {
        // Set JWT_SECRET for tests
        $_ENV['JWT_SECRET'] = 'test-secret-key-for-unit-testing-only-minimum-32-chars';
        $this->hasher = new PasswordHasher();
    }

    protected function tearDown(): void
    {
        unset($_ENV['JWT_SECRET']);
    }

    public function testPasswordHashingWorks(): void
    {
        $password = 'Password123!';
        $hash = $this->hasher->hash($password);

        $this->assertNotEquals($password, $hash);
        $this->assertTrue($this->hasher->verify($password, $hash));
    }

    public function testPasswordVerificationFailsForWrongPassword(): void
    {
        $password = 'Password123!';
        $wrongPassword = 'WrongPassword!';
        $hash = $this->hasher->hash($password);

        $this->assertFalse($this->hasher->verify($wrongPassword, $hash));
    }

    public function testJwtGeneratesValidAccessToken(): void
    {
        $jwtService = new JwtService();
        $userId = 1;
        $accessToken = $jwtService->generateAccessToken($userId);
        $refreshToken = $jwtService->generateRefreshToken();

        $this->assertNotEmpty($accessToken);
        $this->assertNotEmpty($refreshToken);
        $this->assertStringStartsWith('eyJ', $accessToken); // JWT starts with eyJ
    }

    public function testJwtValidatesAccessToken(): void
    {
        $jwtService = new JwtService();
        $userId = 1;
        $accessToken = $jwtService->generateAccessToken($userId);

        $payload = $jwtService->validateAccessToken($accessToken);

        $this->assertNotNull($payload);
        $this->assertEquals($userId, (int) $payload['sub']);
    }

    public function testJwtRejectsInvalidToken(): void
    {
        $jwtService = new JwtService();
        $result = $jwtService->validateAccessToken('invalid.token.here');
        $this->assertNull($result);
    }

    public function testJwtRejectsTamperedToken(): void
    {
        $jwtService = new JwtService();
        $accessToken = $jwtService->generateAccessToken(1);
        $tamperedToken = $accessToken . 'tampered';

        $result = $jwtService->validateAccessToken($tamperedToken);
        $this->assertNull($result);
    }
}
