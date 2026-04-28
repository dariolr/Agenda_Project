#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Diagnostica notifiche class_booking.
 * Uso: php bin/diagnose-notify.php [class_booking_id]
 * Se ometti l'id, usa l'ultima prenotazione.
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Agenda\Infrastructure\Database\Connection;
use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

$db = new Connection();
$pdo = $db->getPdo();

echo "=== Diagnosi notifica class_booking ===\n\n";

// Trova la prenotazione da testare
$targetId = isset($argv[1]) ? (int) $argv[1] : null;

if ($targetId) {
    $stmt = $pdo->prepare('SELECT cb.*, ce.starts_at, ce.business_id AS ce_business_id FROM class_bookings cb INNER JOIN class_events ce ON ce.id = cb.class_event_id WHERE cb.id = ?');
    $stmt->execute([$targetId]);
} else {
    $stmt = $pdo->query('SELECT cb.*, ce.starts_at, ce.business_id AS ce_business_id FROM class_bookings cb INNER JOIN class_events ce ON ce.id = cb.class_event_id ORDER BY cb.id DESC LIMIT 1');
}
$booking = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$booking) {
    echo "ERRORE: nessuna class_booking trovata.\n";
    exit(1);
}

$bookingId  = (int) $booking['id'];
$businessId = (int) $booking['business_id'];
$customerId = (int) $booking['customer_id'];
echo "class_booking_id : {$bookingId}\n";
echo "business_id      : {$businessId}\n";
echo "customer_id      : {$customerId}\n";
echo "status           : {$booking['status']}\n";
echo "starts_at (UTC)  : {$booking['starts_at']}\n\n";

// --- CHECK 1: loadClassBookingData ---
$stmt = $pdo->prepare(
    'SELECT cb.id, cb.business_id, cb.customer_id, cb.status, cb.waitlist_position,
            ce.id AS class_event_id, ce.starts_at, ce.ends_at, ce.cancel_cutoff_minutes,
            ce.price_cents, ce.currency,
            ct.name AS class_type_name,
            l.id AS location_id, l.name AS location_name, l.address AS location_address,
            l.city AS location_city, l.phone AS location_phone, l.timezone AS location_timezone,
            bus.name AS business_name, bus.email AS business_email, bus.locale AS business_locale
     FROM class_bookings cb
     INNER JOIN class_events ce ON ce.id = cb.class_event_id AND ce.business_id = cb.business_id
     INNER JOIN class_types ct ON ct.id = ce.class_type_id
     INNER JOIN locations l ON l.id = ce.location_id
     INNER JOIN businesses bus ON bus.id = cb.business_id
     WHERE cb.id = :id AND cb.business_id = :business_id
     LIMIT 1'
);
$stmt->execute(['id' => $bookingId, 'business_id' => $businessId]);
$data = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;

if ($data === null) {
    echo "[FAIL] CHECK 1 loadClassBookingData: query ha restituito NULL.\n";
    echo "       Possibile causa: class_type_id, location_id o business_id non collegati correttamente.\n";
    exit(1);
}
echo "[OK]   CHECK 1 loadClassBookingData: dati trovati.\n";
echo "       location_timezone : {$data['location_timezone']}\n";
echo "       class_type_name   : {$data['class_type_name']}\n";
echo "       business_email    : {$data['business_email']}\n";

// --- CHECK 2: evento non ancora iniziato ---
$tz      = $data['location_timezone'] ?? 'Europe/Rome';
$now     = new DateTimeImmutable('now', new DateTimeZone($tz));
$startsAt = new DateTimeImmutable((string) $data['starts_at'], new DateTimeZone('UTC'));

if ($startsAt < $now) {
    echo "[FAIL] CHECK 2 evento già iniziato: starts_at={$data['starts_at']} UTC, ora locale=" . $now->format('Y-m-d H:i:s') . " ({$tz}).\n";
    echo "       Le notifiche vengono bloccate per eventi passati. Usa un evento futuro.\n";
    exit(1);
}
echo "[OK]   CHECK 2 evento futuro: starts_at=" . $startsAt->format('Y-m-d H:i:s') . " UTC, ora=" . $now->format('Y-m-d H:i:s') . " {$tz}.\n";

// --- CHECK 3: deduplicazione ---
$stmt = $pdo->prepare(
    'SELECT 1 FROM notification_queue
     WHERE channel = :channel
       AND class_booking_id = :class_booking_id
       AND status = "sent"
       AND sent_at > DATE_SUB(NOW(), INTERVAL 60 MINUTE)
     LIMIT 1'
);
$stmt->execute(['channel' => 'class_booking_confirmed', 'class_booking_id' => $bookingId]);
if ($stmt->fetch()) {
    echo "[FAIL] CHECK 3 deduplicazione: notifica già inviata nell'ultima ora per questa prenotazione.\n";
    exit(1);
}
echo "[OK]   CHECK 3 deduplicazione: nessun duplicato recente.\n";

// --- CHECK 4: impostazioni notifiche ---
$stmt = $pdo->prepare('SELECT * FROM notification_settings WHERE business_id = :business_id');
$stmt->execute(['business_id' => $businessId]);
$settings = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;

if ($settings && isset($settings['email_class_booking_confirmed']) && (int) $settings['email_class_booking_confirmed'] === 0) {
    echo "[FAIL] CHECK 4 impostazioni: email_class_booking_confirmed=0 per business_id={$businessId}.\n";
    echo "       Abilitalo nelle impostazioni notifiche del business.\n";
    exit(1);
}
echo "[OK]   CHECK 4 impostazioni notifiche: class_booking_confirmed abilitato (o non configurato = default ON).\n";

// --- CHECK 5: customer_id ---
if ($customerId <= 0) {
    echo "[FAIL] CHECK 5 customer_id non valido: {$customerId}.\n";
    exit(1);
}
echo "[OK]   CHECK 5 customer_id valido: {$customerId}.\n";

// --- CHECK 6: email cliente ---
$stmt = $pdo->prepare('SELECT email, CONCAT(first_name, " ", last_name) AS name FROM clients WHERE id = :id');
$stmt->execute(['id' => $customerId]);
$clientEmail = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;

if ($clientEmail === null || empty($clientEmail['email'])) {
    echo "[FAIL] CHECK 6 email cliente: il cliente ID={$customerId} non ha email nel database.\n";
    exit(1);
}
echo "[OK]   CHECK 6 email cliente: {$clientEmail['email']}.\n";

// --- CHECK 7: notification_queue (esistono righe pending/failed per questo booking?) ---
$stmt = $pdo->prepare('SELECT status, COUNT(*) AS cnt FROM notification_queue WHERE class_booking_id = :id GROUP BY status');
$stmt->execute(['id' => $bookingId]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
if (empty($rows)) {
    echo "[INFO] CHECK 7 notification_queue: nessuna riga per class_booking_id={$bookingId}.\n";
    echo "       La notifica non è mai stata accodata — il problema è prima di notificationRepo->queue().\n";
} else {
    foreach ($rows as $r) {
        echo "[INFO] CHECK 7 notification_queue: status={$r['status']} count={$r['cnt']}.\n";
    }
}

echo "\n=== Tutti i controlli passati ===\n";
echo "La notifica DOVREBBE essere accodata. Prova a ricreare la prenotazione oppure\n";
echo "controlla se c'è un'eccezione PHP nel blocco try/catch del controller.\n";
echo "\nSe tutti i check sono OK ma la riga non viene inserita, c'è un'eccezione\n";
echo "nell'assemblaggio del template email. Controlla:\n";
echo "  - EmailTemplateRenderer::classBookingConfirmed('{$data['business_locale']}')\n";
echo "  - locale del business: '{$data['business_locale']}'\n";
