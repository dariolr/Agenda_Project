<?php

declare(strict_types=1);

namespace Agenda\Domain\Exceptions;

use Exception;

/**
 * Exception for validation errors.
 */
final class ValidationException extends Exception
{
    private array $errors;

    public function __construct(string $message, array $errors = [])
    {
        parent::__construct($message);
        $this->errors = $errors;
    }

    public static function withErrors(array $errors): self
    {
        $message = implode(', ', array_values($errors));
        return new self($message, $errors);
    }

    public function getErrors(): array
    {
        return $this->errors;
    }
}
