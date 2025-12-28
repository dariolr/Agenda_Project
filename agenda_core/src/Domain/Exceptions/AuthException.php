<?php

declare(strict_types=1);

namespace Agenda\Domain\Exceptions;

use Exception;

final class AuthException extends Exception
{
    public const INVALID_CREDENTIALS = 'invalid_credentials';
    public const ACCOUNT_DISABLED = 'account_disabled';
    public const TOKEN_EXPIRED = 'token_expired';
    public const TOKEN_INVALID = 'token_invalid';
    public const SESSION_REVOKED = 'session_revoked';
    public const EMAIL_ALREADY_EXISTS = 'email_already_exists';
    public const WEAK_PASSWORD = 'weak_password';
    public const INVALID_RESET_TOKEN = 'invalid_reset_token';
    public const RESET_TOKEN_EXPIRED = 'reset_token_expired';

    private string $errorCode;

    private function __construct(string $message, string $errorCode, int $httpStatus = 401)
    {
        parent::__construct($message, $httpStatus);
        $this->errorCode = $errorCode;
    }

    public static function invalidCredentials(): self
    {
        return new self('Invalid email or password', self::INVALID_CREDENTIALS, 401);
    }

    public static function accountDisabled(): self
    {
        return new self('Account is disabled', self::ACCOUNT_DISABLED, 401);
    }

    public static function tokenExpired(): self
    {
        return new self('Token has expired', self::TOKEN_EXPIRED, 401);
    }

    public static function tokenInvalid(): self
    {
        return new self('Token is invalid', self::TOKEN_INVALID, 401);
    }

    public static function sessionRevoked(): self
    {
        return new self('Session has been revoked', self::SESSION_REVOKED, 401);
    }

    public static function emailAlreadyExists(): self
    {
        return new self('Email already registered', self::EMAIL_ALREADY_EXISTS, 409);
    }

    public static function weakPassword(string $reason): self
    {
        return new self($reason, self::WEAK_PASSWORD, 400);
    }

    public static function invalidResetToken(): self
    {
        return new self('Invalid password reset token', self::INVALID_RESET_TOKEN, 400);
    }

    public static function resetTokenExpired(): self
    {
        return new self('Password reset token has expired', self::RESET_TOKEN_EXPIRED, 400);
    }

    public function getErrorCode(): string
    {
        return $this->errorCode;
    }

    public function getHttpStatus(): int
    {
        return $this->getCode();
    }
}
