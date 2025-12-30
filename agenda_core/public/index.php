<?php

declare(strict_types=1);

// SiteGround structure: public_html is web root, vendor/src are in parent directory
require_once __DIR__ . '/../vendor/autoload.php';

use Agenda\Http\Kernel;
use Agenda\Http\Request;

// Load environment - .env is outside public_html (parent directory)
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->safeLoad();

// Set timezone
date_default_timezone_set($_ENV['APP_TIMEZONE'] ?? 'UTC');

// Determina l'origin consentito dinamicamente
$allowedOrigins = array_map('trim', explode(',', $_ENV['CORS_ALLOWED_ORIGINS'] ?? '*'));
$requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
$corsOrigin = in_array($requestOrigin, $allowedOrigins, true) ? $requestOrigin : ($allowedOrigins[0] ?? '*');

// Handle CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: ' . $corsOrigin);
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, Idempotency-Key');
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
    http_response_code(204);
    exit;
}

// Create request from globals
$request = Request::fromGlobals();

// Boot kernel and handle request
$kernel = new Kernel();
$response = $kernel->handle($request);

// Send response
$response->send();
