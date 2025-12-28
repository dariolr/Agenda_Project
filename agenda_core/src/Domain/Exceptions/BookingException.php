<?php

declare(strict_types=1);

namespace Agenda\Domain\Exceptions;

use Exception;

final class BookingException extends Exception
{
    public const SLOT_CONFLICT = 'slot_conflict';
    public const INVALID_SERVICE = 'invalid_service';
    public const INVALID_STAFF = 'invalid_staff';
    public const INVALID_LOCATION = 'invalid_location';
    public const INVALID_TIME = 'invalid_time';
    public const STAFF_UNAVAILABLE = 'staff_unavailable';
    public const OUTSIDE_WORKING_HOURS = 'outside_working_hours';
    public const NOT_FOUND = 'not_found';
    public const UNAUTHORIZED = 'unauthorized';
    public const VALIDATION_ERROR = 'validation_error';
    public const SERVER_ERROR = 'internal_error';

    private string $errorCode;
    private array $details;

    private function __construct(string $message, string $errorCode, int $httpStatus = 400, array $details = [])
    {
        parent::__construct($message, $httpStatus);
        $this->errorCode = $errorCode;
        $this->details = $details;
    }

    public static function slotConflict(array $conflictingSlots = []): self
    {
        return new self(
            'The requested time slot is no longer available',
            self::SLOT_CONFLICT,
            409,
            ['conflicts' => $conflictingSlots]
        );
    }

    public static function invalidService(array $serviceIds = []): self
    {
        return new self(
            'One or more services are invalid or not available',
            self::INVALID_SERVICE,
            400,
            ['service_ids' => $serviceIds]
        );
    }

    public static function invalidStaff(int $staffId): self
    {
        return new self(
            'The selected staff member is not available for these services',
            self::INVALID_STAFF,
            400,
            ['staff_id' => $staffId]
        );
    }

    public static function invalidLocation(int $locationId): self
    {
        return new self(
            'The specified location does not exist or is not active',
            self::INVALID_LOCATION,
            400,
            ['location_id' => $locationId]
        );
    }

    public static function invalidTime(string $reason): self
    {
        return new self(
            'The requested time is invalid: ' . $reason,
            self::INVALID_TIME,
            400,
            ['reason' => $reason]
        );
    }

    public static function staffUnavailable(int $staffId): self
    {
        return new self(
            'The selected staff member is not available at this time',
            self::STAFF_UNAVAILABLE,
            400,
            ['staff_id' => $staffId]
        );
    }

    public static function outsideWorkingHours(): self
    {
        return new self(
            'The requested time is outside of working hours',
            self::OUTSIDE_WORKING_HOURS,
            400
        );
    }

    public static function notFound(string $message = 'Resource not found'): self
    {
        return new self($message, self::NOT_FOUND, 404);
    }

    public static function unauthorized(string $message = 'Unauthorized'): self
    {
        return new self($message, self::UNAUTHORIZED, 403);
    }

    public static function validationError(string $message): self
    {
        return new self($message, self::VALIDATION_ERROR, 400);
    }

    public static function serverError(string $message = 'Internal server error'): self
    {
        return new self($message, self::SERVER_ERROR, 500);
    }

    public function getErrorCode(): string
    {
        return $this->errorCode;
    }

    public function getHttpStatus(): int
    {
        return $this->getCode();
    }

    public function getDetails(): array
    {
        return $this->details;
    }
}
