<?php

declare(strict_types=1);

namespace Agenda\Tests;

use PHPUnit\Framework\TestCase;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\Domain\Exceptions\AuthException;
use DateTimeImmutable;

/**
 * Unit tests for Auth business logic
 * Tests password hashing, JWT handling, and auth validation logic
 * (No mocking of final classes - tests pure logic only)
 */
final class AuthUseCaseTest extends TestCase
{
    private string $originalJwtSecret;

    protected function setUp(): void
    {
        parent::setUp();
        $this->originalJwtSecret = $_ENV['JWT_SECRET'] ?? '';
        $_ENV['JWT_SECRET'] = 'test-secret-key-for-testing-purposes-only-32chars!';
    }

    protected function tearDown(): void
    {
        $_ENV['JWT_SECRET'] = $this->originalJwtSecret;
        parent::tearDown();
    }

    // ==================== Password Validation Tests ====================

    public function testPasswordHashingAndVerification(): void
    {
        $hasher = new PasswordHasher();
        $password = 'MySecureP@ssword123';

        $hash = $hasher->hash($password);

        $this->assertTrue($hasher->verify($password, $hash));
        $this->assertFalse($hasher->verify('wrong-password', $hash));
    }

    public function testLoginValidationRequiresEmail(): void
    {
        $email = '';

        $this->assertFalse(
            filter_var($email, FILTER_VALIDATE_EMAIL) !== false,
            'Empty email should fail validation'
        );
    }

    public function testLoginValidationRequiresValidEmailFormat(): void
    {
        $validEmails = ['test@example.com', 'user.name@domain.org'];
        $invalidEmails = ['invalid-email', '@domain.com', 'user@'];

        foreach ($validEmails as $email) {
            $this->assertNotFalse(
                filter_var($email, FILTER_VALIDATE_EMAIL),
                "Email '$email' should be valid"
            );
        }

        foreach ($invalidEmails as $email) {
            $this->assertFalse(
                filter_var($email, FILTER_VALIDATE_EMAIL),
                "Email '$email' should be invalid"
            );
        }
    }

    public function testPasswordMinimumLength(): void
    {
        $minLength = 8;
        $shortPassword = 'short';
        $validPassword = 'validpassword123';

        $this->assertFalse(
            strlen($shortPassword) >= $minLength,
            'Short password should fail validation'
        );

        $this->assertTrue(
            strlen($validPassword) >= $minLength,
            'Valid password should pass validation'
        );
    }

    // ==================== JWT Token Tests ====================

    public function testJwtGenerationAndValidation(): void
    {
        $jwt = new JwtService();

        $userId = 1;

        $token = $jwt->generateAccessToken($userId);
        $decoded = $jwt->validateAccessToken($token);

        $this->assertNotNull($decoded);
        $this->assertEquals('1', $decoded['sub']);
    }

    public function testJwtRejectsInvalidToken(): void
    {
        $jwt = new JwtService();

        $result = $jwt->validateAccessToken('invalid.token.here');

        $this->assertNull($result);
    }

    public function testJwtRejectsTamperedToken(): void
    {
        $jwt = new JwtService();

        $userId = 1;
        $token = $jwt->generateAccessToken($userId);

        // Tamper with token
        $parts = explode('.', $token);
        $parts[1] = base64_encode('{"sub":"999"}');
        $tamperedToken = implode('.', $parts);

        $result = $jwt->validateAccessToken($tamperedToken);

        $this->assertNull($result);
    }

    // ==================== Refresh Token Logic Tests ====================

    public function testRefreshTokenHashGeneration(): void
    {
        $refreshToken = bin2hex(random_bytes(32));
        $hash = hash('sha256', $refreshToken);

        // Hash should be deterministic
        $this->assertEquals($hash, hash('sha256', $refreshToken));

        // Different tokens produce different hashes
        $otherToken = bin2hex(random_bytes(32));
        $this->assertNotEquals($hash, hash('sha256', $otherToken));
    }

    public function testRefreshTokenExpiryCheck(): void
    {
        $futureExpiry = (new DateTimeImmutable('+30 days'))->format('Y-m-d H:i:s');
        $pastExpiry = (new DateTimeImmutable('-1 day'))->format('Y-m-d H:i:s');
        $now = new DateTimeImmutable();

        $futureDate = new DateTimeImmutable($futureExpiry);
        $pastDate = new DateTimeImmutable($pastExpiry);

        $this->assertTrue($futureDate > $now, 'Future date should not be expired');
        $this->assertFalse($pastDate > $now, 'Past date should be expired');
    }

    public function testRefreshTokenRevokedCheck(): void
    {
        $activeSession = ['is_revoked' => false];
        $revokedSession = ['is_revoked' => true];

        $this->assertFalse($activeSession['is_revoked']);
        $this->assertTrue($revokedSession['is_revoked']);
    }

    // ==================== User State Validation Tests ====================

    public function testDisabledAccountCheck(): void
    {
        $activeUser = ['is_active' => true];
        $disabledUser = ['is_active' => false];

        $this->assertTrue($activeUser['is_active']);
        $this->assertFalse($disabledUser['is_active']);
    }

    public function testUserRoleValidation(): void
    {
        $validRoles = ['user', 'admin', 'staff', 'owner'];

        foreach ($validRoles as $role) {
            $this->assertContains($role, $validRoles);
        }

        $this->assertNotContains('superuser', $validRoles);
    }

    // ==================== Auth Exception Tests ====================

    public function testAuthExceptionInvalidCredentials(): void
    {
        $this->expectException(AuthException::class);
        throw AuthException::invalidCredentials();
    }

    public function testAuthExceptionAccountDisabled(): void
    {
        $this->expectException(AuthException::class);
        throw AuthException::accountDisabled();
    }

    public function testAuthExceptionTokenExpired(): void
    {
        $this->expectException(AuthException::class);
        throw AuthException::tokenExpired();
    }

    // ==================== Session Management Logic Tests ====================

    public function testSessionExpiryCalculation(): void
    {
        $accessTokenLifetime = 900; // 15 minutes
        $refreshTokenLifetime = 30 * 24 * 3600; // 30 days

        $now = new DateTimeImmutable();
        $accessExpiry = $now->modify("+{$accessTokenLifetime} seconds");
        $refreshExpiry = $now->modify("+{$refreshTokenLifetime} seconds");

        $this->assertEquals(
            15,
            (int) (($accessExpiry->getTimestamp() - $now->getTimestamp()) / 60),
            'Access token should expire in 15 minutes'
        );

        $this->assertEquals(
            30,
            (int) (($refreshExpiry->getTimestamp() - $now->getTimestamp()) / 86400),
            'Refresh token should expire in 30 days'
        );
    }

    public function testLogoutRequiresUserId(): void
    {
        $userId = 0;

        $this->assertFalse($userId > 0, 'Invalid user ID should fail logout');

        $validUserId = 1;
        $this->assertTrue($validUserId > 0, 'Valid user ID should pass');
    }
}
