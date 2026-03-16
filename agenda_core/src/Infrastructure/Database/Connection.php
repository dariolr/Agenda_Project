<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Database;

use Agenda\Infrastructure\Environment\EnvironmentConfig;
use PDO;
use PDOException;

final class Connection
{
    private ?PDO $pdo = null;

    public function getPdo(): PDO
    {
        if ($this->pdo === null) {
            $env = EnvironmentConfig::current();

            $host = $env->dbHost;
            $port = $env->dbPort;
            $database = $env->dbDatabase;
            $username = $env->dbUsername;
            $password = $env->dbPassword;

            $dsn = "mysql:host={$host};port={$port};dbname={$database};charset=utf8mb4";

            try {
                $this->pdo = new PDO($dsn, $username, $password, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
                ]);
            } catch (PDOException $e) {
                throw new PDOException("Database connection failed: " . $e->getMessage());
            }
        }

        return $this->pdo;
    }

    public function beginTransaction(): void
    {
        $this->getPdo()->beginTransaction();
    }

    public function commit(): void
    {
        $this->getPdo()->commit();
    }

    public function rollback(): void
    {
        if ($this->getPdo()->inTransaction()) {
            $this->getPdo()->rollBack();
        }
    }

    public function inTransaction(): bool
    {
        return $this->getPdo()->inTransaction();
    }
}
