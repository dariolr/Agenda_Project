#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Compute Popular Services
 * 
 * Analyzes booking data from the last 90 days to determine the top 5 most
 * booked services per staff member. Results are stored in the popular_services table.
 * 
 * Run via cron: 0 4 * * 0 php /path/to/agenda_core/bin/compute-popular-services.php
 * (Every Sunday at 4:00 AM)
 * 
 * Options:
 *   --verbose     Show detailed output
 *   --staff=ID    Compute only for specific staff member
 *   --help        Show this help message
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\PopularServiceRepository;
use Dotenv\Dotenv;

// Parse CLI options
$options = getopt('', ['verbose', 'staff:', 'help']);

if (isset($options['help'])) {
    echo <<<HELP
Compute Popular Services

Usage: php compute-popular-services.php [options]

Options:
  --verbose     Show detailed output
  --staff=ID    Compute only for a specific staff ID
  --help        Show this help message

Notes:
  - Analyzes booking_items from the last 90 days
  - Computes top 5 most booked services per staff member
  - Results stored in popular_services table
  - Should be run weekly (recommended: Sunday 4:00 AM)

HELP;
    exit(0);
}

$verbose = isset($options['verbose']);
$specificStaffId = isset($options['staff']) ? (int) $options['staff'] : null;

// Load environment
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// Check required config
$requiredEnv = ['DB_HOST', 'DB_DATABASE', 'DB_USERNAME', 'DB_PASSWORD'];
foreach ($requiredEnv as $key) {
    if (empty($_ENV[$key])) {
        fwrite(STDERR, "Missing required environment variable: {$key}\n");
        exit(1);
    }
}

// Log start
$startTime = microtime(true);
$timestamp = date('Y-m-d H:i:s');

if ($verbose) {
    echo "[{$timestamp}] Starting popular services computation...\n";
}

try {
    $db = new Connection();
    $repository = new PopularServiceRepository($db);

    if ($specificStaffId !== null) {
        // Compute for specific staff
        if ($verbose) {
            echo "  Computing for staff ID: {$specificStaffId}\n";
        }

        $servicesCount = $repository->computeForStaff($specificStaffId);

        if ($verbose) {
            echo "  Staff {$specificStaffId}: {$servicesCount} popular services stored\n";
        }

        $summary = [
            'staff_processed' => 1,
            'total_services' => $servicesCount,
        ];
    } else {
        // Compute for all staff
        $summary = $repository->computeForAllStaff();

        if ($verbose) {
            echo "  Staff processed: {$summary['staff_processed']}\n";
            echo "  Total popular services stored: {$summary['total_services']}\n";
        }
    }

    $elapsed = round((microtime(true) - $startTime) * 1000, 2);

    if ($verbose) {
        echo "[" . date('Y-m-d H:i:s') . "] Completed in {$elapsed}ms\n";
    }

    // Output JSON summary for logging
    echo json_encode([
        'status' => 'success',
        'timestamp' => $timestamp,
        'staff_processed' => $summary['staff_processed'],
        'total_services' => $summary['total_services'],
        'elapsed_ms' => $elapsed,
    ]) . "\n";

} catch (Throwable $e) {
    $errorMsg = "[ERROR] " . $e->getMessage();
    
    if ($verbose) {
        echo $errorMsg . "\n";
        echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    }

    echo json_encode([
        'status' => 'error',
        'timestamp' => $timestamp,
        'error' => $e->getMessage(),
    ]) . "\n";

    exit(1);
}
