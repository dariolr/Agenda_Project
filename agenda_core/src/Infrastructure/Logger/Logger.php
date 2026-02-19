<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Logger;

use Agenda\Infrastructure\Support\Json;

final class Logger
{
    private string $logFile;

    public function __construct()
    {
        $this->logFile = __DIR__ . '/../../../logs/app.log';
        $dir = dirname($this->logFile);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
    }

    public function info(string $message, array $context = []): void
    {
        $this->log('INFO', $message, $context);
    }

    public function error(string $message, array $context = []): void
    {
        $this->log('ERROR', $message, $context);
    }

    public function warning(string $message, array $context = []): void
    {
        $this->log('WARNING', $message, $context);
    }

    private function log(string $level, string $message, array $context): void
    {
        $timestamp = date('Y-m-d H:i:s');
        $contextJson = empty($context)
            ? ''
            : ' ' . Json::encode($context);
        $line = "[{$timestamp}] [{$level}] {$message}{$contextJson}\n";
        
        file_put_contents($this->logFile, $line, FILE_APPEND | LOCK_EX);
    }
}
