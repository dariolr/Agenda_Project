# Codex Instructions — Booking Payments Persistence + Reports Integration (MINIMO ma scalabile)

## Obiettivo
Integrare la funzionalità UI “Pagamento” (ripartizione importo prenotazione su più voci) **con persistenza backend** e **integrazione nei report esistenti**, mantenendo tutto il comportamento attuale delle prenotazioni e dei report (nessuna regressione).

- Salvataggio/lettura pagamenti **per singola prenotazione**.
- Struttura dati **minima**: 1 header + N righe (scalabile).
- Report: riusare i report già implementati aggiungendo i nuovi aggregati (cash/card/discount/voucher/other/credit_applied).

---

## Vincoli
1. **Non modificare** logica esistente di booking/appointment, tabelle esistenti, flussi UI esistenti.
2. Implementazione **additiva**.
3. Importi in DB in **cents interi** (INT) per evitare problemi di floating.
4. API “single shot”: salva header + righe in un solo PUT.
5. Lato backend: calcoli (totali/saldi) possono essere **calcolati al volo** (no ridondanza obbligatoria).

---

## Repo / Punti di aggancio (da usare come riferimento nel progetto)
- API booking già presenti in `ApiClient`:
  - `getBooking`, `getBookings`, `updateBooking`, `getBookingsList`, `getBookingHistory`, `addBookingItem`, ecc.
- Router PHP già contiene:
  - `GET/POST/PUT/DELETE /v1/locations/{location_id}/bookings...`
  - `GET /v1/bookings/{booking_id}/history`
  - `GET /v1/reports/appointments`
  - `GET /v1/reports/work-hours`
- SQL schema esistente usa `business_id`, `location_id`, `booking_id` in molte tabelle.

> Nota: nel repo cerca le sezioni con commenti “// Bookings (protected, business-scoped via path)” e “// Reports (admin/owner only)” per aggiungere le route nuove nella stessa area.

---

## 1) Database — nuove tabelle (MySQL)

### 1.1 Tabella header: `booking_payments`
**1 record per booking** (minimo indispensabile).  
Motivo: ti serve salvare “Importo da pagare” corretto (override), note, audit.

```sql
CREATE TABLE `booking_payments` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `booking_id` int UNSIGNED NOT NULL,

  `currency` char(3) NOT NULL DEFAULT 'EUR',
  `total_due_cents` int UNSIGNED NOT NULL DEFAULT 0,
  `note` text NULL,

  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by_user_id` int UNSIGNED NULL,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_booking_payments_booking` (`booking_id`),
  KEY `idx_booking_payments_business` (`business_id`),
  KEY `idx_booking_payments_location` (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 1.2 Tabella righe: `booking_payment_lines`
**N righe** per booking_payment.

```sql
CREATE TABLE `booking_payment_lines` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `booking_payment_id` int UNSIGNED NOT NULL,

  `type` enum('cash','card','discount','voucher','other','credit_applied') NOT NULL,
  `amount_cents` int UNSIGNED NOT NULL DEFAULT 0,
  `meta_json` json NULL,

  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by_user_id` int UNSIGNED NULL,

  PRIMARY KEY (`id`),
  KEY `idx_booking_payment_lines_payment` (`booking_payment_id`),
  KEY `idx_booking_payment_lines_type` (`type`),
  CONSTRAINT `fk_booking_payment_lines_payment`
    FOREIGN KEY (`booking_payment_id`) REFERENCES `booking_payments`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 1.3 Migrazione / deploy
- Integra le CREATE TABLE nel tuo meccanismo di migrazioni (o SQL init) usato dal progetto.
- Verifica che `booking_id` esista e che la cancellazione di una booking gestisca la FK:
  - **Opzione minima**: su delete booking, elimina `booking_payments` (cascata elimina lines).
  - Se non vuoi FK su booking_id (per compatibilità), mantieni solo UNIQUE/IDX e gestisci in codice.

---

## 2) Backend PHP (agenda_core) — API & Controller

### 2.1 Nuove route
Aggiungi nel router:

- `GET  /v1/bookings/{booking_id}/payment`  (auth)
- `PUT  /v1/bookings/{booking_id}/payment`  (auth)

Motivazione:
- `booking_id` è già usato in route “history” e “replace” (coerenza).
- Le regole di accesso devono verificare che l’utente autenticato abbia accesso al business/location della booking.

### 2.2 Controller
Crea controller dedicato, es. `BookingPaymentsController` (preferibile per mantenere BookingsController pulito), con metodi:

- `show($booking_id)`
- `upsert($booking_id)` (PUT)

### 2.3 Validazioni (minime)
Nel `PUT`:
- `total_due_cents` obbligatorio, `>= 0`
- `currency` opzionale (default EUR), valida `^[A-Z]{3}$`
- `lines` array opzionale (se assente o vuoto = azzera righe)
- per ogni linea:
  - `type` in enum
  - `amount_cents >= 0`
  - `meta_json` opzionale

### 2.4 Persistenza (minimo robusto)
Nel `PUT` fai transazione:
1. Recupera booking e **deriva** `business_id` e `location_id` (non fidarti del client).
2. Upsert `booking_payments` by `booking_id`:
   - se esiste: update `total_due_cents`, `currency`, `note`, `updated_by_user_id`
   - se non esiste: insert
3. `DELETE FROM booking_payment_lines WHERE booking_payment_id = :id`
4. `INSERT` righe nuove.

> Questa strategia evita problemi di sync e gestisce bene l’editing UI.

### 2.5 Response JSON (standard del progetto)
Allinea al formato `{"success": true, "data": ...}`.

#### GET response (200)
```json
{
  "success": true,
  "data": {
    "booking_id": 123,
    "currency": "EUR",
    "total_due_cents": 5000,
    "note": null,
    "lines": [
      {"type": "cash", "amount_cents": 2000, "meta": null},
      {"type": "card", "amount_cents": 3000, "meta": {"last4": "1234"}}
    ],

    "computed": {
      "total_paid_cents": 5000,
      "total_discount_cents": 0,
      "total_credit_applied_cents": 0,
      "balance_cents": 0
    }
  }
}
```

#### PUT response (200)
Ritorna lo stesso payload del GET (dopo persistenza), così UI si riallinea.

### 2.6 Calcoli server-side (computed)
Calcola sempre sul server (anche se UI lo mostra) per coerenza report e future API:
- `paid_types = cash + card + voucher + other`
- `discount = discount`
- `credit_applied = credit_applied`
- `balance = total_due - paid - discount - credit_applied`
  - `balance > 0` → manca da pagare
  - `balance = 0` → ok
  - `balance < 0` → credito cliente (per ora solo informativo; non implementare ledger se vuoi restare “minimo indispensabile”)

---

## 3) Flutter (agenda_backend) — Models + ApiClient + Providers + UI

### 3.1 Modelli (minimi)
Crea in `lib/core/models/`:

- `booking_payment.dart`
  - `BookingPayment` (bookingId, currency, totalDueCents, note, lines, computed)
- `booking_payment_line.dart`
  - `BookingPaymentLine` (type, amountCents, metaMap)
- `booking_payment_computed.dart`
  - `BookingPaymentComputed` (totalPaidCents, totalDiscountCents, totalCreditAppliedCents, balanceCents)

Parsing:
- `fromJson` e `toJson` coerenti con la API sopra.
- `type` come enum Dart + serializer string.

### 3.2 ApiConfig
Aggiungi metodi:
- `static String bookingPayment(int bookingId) => '/v1/bookings/$bookingId/payment';`

### 3.3 ApiClient
Aggiungi:
- `Future<Map<String, dynamic>> getBookingPayment({required int bookingId})`
- `Future<Map<String, dynamic>> upsertBookingPayment({required int bookingId, required Map<String,dynamic> payload})`

### 3.4 Provider / Repository
Crea un provider dedicato per lettura/scrittura, pattern identico agli altri feature provider già esistenti:
- `bookingPaymentProvider(bookingId)` → fetch GET
- `bookingPaymentControllerProvider(bookingId)` → save PUT + optimistic update

### 3.5 UI: aggancio al pulsante “Pagamento”
Nel file dove hai implementato la UI del dialog/pannello Pagamento (cerca “Pagamento” nel backend):
- On open:
  - carica payment via provider; se 404/empty, inizializza con default:
    - `currency: EUR`
    - `total_due_cents`: derivato dal totale prenotazione/servizi (come già mostri in UI)
    - `lines`: vuote
- On save:
  - costruisci payload:
    - `total_due_cents`
    - `currency`
    - `note` (se hai campo)
    - `lines[]` (solo righe con amount > 0 oppure anche 0 se vuoi)
  - chiama `upsertBookingPayment`
  - aggiorna UI con response (computed, eventuale normalizzazione).

UI MUST:
- non cambiare layout/UX già implementata
- solo aggiungere caricamento/salvataggio.

---

## 4) Reports — integrazione minima (backend + UI)

### 4.1 Backend ReportsController (appointments report)
Individua il metodo che produce il report “appointments” e aggiungi aggregati pagamenti.

Strategia minima: aggiungere LEFT JOIN dei pagamenti e somma per type.

Esempio SQL concettuale (adatta ai nomi reali delle tabelle/alias già usati nel controller):
- join bookings (o booking_items/appointments) → booking_payments (by booking_id)
- join booking_payments → booking_payment_lines

Aggregati utili:
- `sum_cash_cents = SUM(CASE WHEN type='cash' THEN amount_cents ELSE 0 END)`
- `sum_card_cents = ...`
- `sum_voucher_cents = ...`
- `sum_other_cents = ...`
- `sum_discount_cents = ...`
- `sum_credit_applied_cents = ...`
- `sum_paid_cents = cash+card+voucher+other`
- `sum_due_cents = SUM(booking_payments.total_due_cents)` (oppure fallback a prezzo prenotazione se payment non esiste)

IMPORTANT:
- Usa `LEFT JOIN` così report include anche prenotazioni senza pagamenti.
- Se nel report attuale ragioni per appointment/items, assicurati di non duplicare righe (attenzione a moltiplicazioni join):
  - Soluzione minima: fare subquery aggregata per booking_id su `booking_payment_lines`, poi joinare quella subquery al report.

### 4.2 Payload report verso app
Aggiungi i nuovi campi al JSON del report (summary e/o righe byLocation/byStaff/byService in base a quello che già esponi).

Minimo indispensabile:
- Summary: totali per type + totale pagato + totale sconti.
- byLocation: stessi totali.
- byStaff: opzionale se i report già lo fanno, ma solo se join non rompe (altrimenti lascia solo summary/byLocation).

### 4.3 Flutter report models
Nel file dove hai i model del report appointments (cerca `AppointmentsReport`, `ReportSummary`, `StaffReportRow`, `LocationReportRow`, ecc.):
- aggiungi campi:
  - `cashCents`, `cardCents`, `voucherCents`, `otherCents`, `discountCents`, `creditAppliedCents`, `paidCents`, `dueCents`
- parsing `fromJson` con default 0.

### 4.4 UI report
Integra nelle viste che già mostrano i report:
- aggiungi nuove righe/colonne dove ha senso (minimo: blocco “Pagamenti” nel summary con breakdown).
- Non cambiare struttura/filtri già esistenti.

---

## 5) Error handling & compatibilità
- `GET /payment`:
  - se non esiste `booking_payments` per quel booking, torna `success:true` con `data` default (total_due derivato?):
    - **Scelta minima**: `total_due_cents = 0` e lines vuote, e UI usa il suo totale attuale.
    - **Scelta consigliata**: server calcola `total_due_cents` da booking/items se disponibile e lo ritorna.
- `PUT /payment`:
  - se booking non esiste o non accessibile → 404/403 coerente con pattern esistente.

---

## 6) Test minimi (manual + API)
1. Crea booking.
2. Apri Pagamento → salva split (cash/card/discount).
3. Riapri booking → Pagamento deve ricaricare identico.
4. Azzera righe e salva → righe cancellate.
5. Report appointments:
   - periodo che include booking: i totali devono includere i nuovi importi.
   - prenotazioni senza pagamenti devono restare contate e non rompere la UI.

---

## 7) Checklist finale (prima merge)
- [ ] DB migration applicata su dev/stage.
- [ ] Route registrate e protette da auth.
- [ ] Controller: show + upsert con transazioni.
- [ ] ApiConfig + ApiClient aggiornati.
- [ ] Models Flutter + parsing.
- [ ] UI Pagamento: load/save senza regressioni.
- [ ] Report backend aggrega senza duplicazioni (subquery per booking_id se necessario).
- [ ] Report Flutter parsing e UI aggiornata.
- [ ] Nessun breaking change su endpoint esistenti.

---

## Note operative per Codex
Nel repo, per trovare rapidamente i punti:
- Cerca stringhe:
  - `'/v1/reports/appointments'`
  - `ReportsController`
  - `BookingsController`
  - `booking-notifications`
  - `ApiConfig.bookingHistory` / `ApiConfig.booking(` / `bookingsList`
  - `reportsPreset` / `AppointmentsReport` / `WorkHoursReport`
  - `Pagamento` (UI dialog)
- Implementa in modo additivo, seguendo i pattern già usati (response wrapper, dio client, provider riverpod, ecc.).

FINE.
