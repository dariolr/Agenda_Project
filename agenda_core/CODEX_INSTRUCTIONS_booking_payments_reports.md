# Documentazione — Booking Payments + Reports (stato attuale)

## Stato attuale
La funzionalità `Pagamento` è attiva con un modello semplificato e coerente:

- persistenza backend per prenotazione
- storico versionato tramite record `is_active`
- salvataggio/lettura via `GET/PUT /v1/bookings/{booking_id}/payment`
- integrazione dei totali nei report appuntamenti
- supporto a `client_id` su `booking_payments` per join futuri

Non è più presente alcuna logica di saldo cliente / credito applicato.

I soli tipi di riga attivi sono:
- `cash`
- `card`
- `discount`
- `voucher`
- `other`

---

## 1) Database

### 1.1 Migrazione consolidata
La migrazione di riferimento è una sola:

- `migrations/20260228_add_booking_payments.sql`

Contiene già lo schema finale attuale. Non ci sono più migrazioni correttive da applicare per questa feature.

### 1.2 Tabella `booking_payments`
Schema logico:

- 1 o più record nel tempo per la stessa `booking_id`
- 1 solo record attivo per booking (`is_active = 1`)
- i salvataggi successivi disattivano l’attivo precedente e inseriscono una nuova versione

Campi principali:
- `business_id`
- `location_id`
- `booking_id`
- `client_id` nullable
- `currency`
- `total_due_cents`
- `note`
- `is_active`
- audit minimo (`created_at`, `updated_at`, `updated_by_user_id`)

`client_id` è mantenuto in tabella per:
- report futuri
- join semplificate
- evitare di derivarlo ogni volta da `bookings`

### 1.3 Tabella `booking_payment_lines`
Contiene le righe del pagamento attivo/storico.

Tipi ammessi:

```sql
enum('cash','card','discount','voucher','other')
```

Importi:
- `amount_cents` è `INT UNSIGNED`
- nessun importo negativo

---

## 2) Backend PHP

### 2.1 Route attive

- `GET /v1/bookings/{booking_id}/payment`
- `PUT /v1/bookings/{booking_id}/payment`

### 2.2 Controller
Il controller attivo è `BookingPaymentsController`.

Comportamento:
- `show()` restituisce il record attivo della prenotazione
- se non esiste un record attivo, restituisce un payload vuoto coerente
- `upsert()` salva una nuova versione attiva

### 2.3 Regole di salvataggio
Nel `PUT`:

1. il server recupera la booking
2. deriva sempre:
   - `business_id`
   - `location_id`
   - `client_id`
3. disattiva l’eventuale record attivo precedente
4. inserisce un nuovo header `booking_payments`
5. inserisce le nuove righe `booking_payment_lines`

Se il pagamento è vuoto:
- `total_due_cents <= 0`
- nessuna riga
- nessuna nota

allora non viene mantenuto un pagamento attivo: il backend disattiva l’attivo esistente e la prenotazione resta senza pagamento associato.

### 2.4 Validazioni
- `total_due_cents` obbligatorio, intero `>= 0`
- `currency` opzionale, formato ISO a 3 lettere
- `lines` opzionale
- per ogni linea:
  - `type` in enum attuale
  - `amount_cents` intero `>= 0`
  - `meta` / `meta_json` opzionale

### 2.5 Response
Il payload applicativo include:

- `booking_id`
- `client_id`
- `currency`
- `total_due_cents`
- `note`
- `is_active`
- `lines`
- `computed`

`computed` contiene:
- `total_paid_cents`
- `total_discount_cents`
- `balance_cents`

Formula attuale:

- `total_paid_cents = cash + card + voucher + other`
- `total_discount_cents = discount`
- `balance_cents = total_due_cents - total_paid_cents - total_discount_cents`

Non esistono più:
- `total_credit_applied_cents`
- `previous_balance`
- saldo cliente calcolato

---

## 3) Flutter (agenda_backend)

### 3.1 Modelli
I model attivi sono:

- `BookingPayment`
- `BookingPaymentLine`
- `BookingPaymentComputed`

`BookingPayment` include:
- `bookingId`
- `clientId`
- `currency`
- `totalDueCents`
- `note`
- `isActive`
- `lines`
- `computed`

`clientId` viene letto dalla response ma non inviato nel payload di salvataggio (`server-derived`).

### 3.2 UI `Pagamento`
Il dialog permette di ripartire l’importo prenotazione sulle sole voci:

- Contanti
- Bancomat/Carta di credito
- Sconto
- Buono
- Altro

Caratteristiche attuali:
- importi non negativi
- decimali limitati in base alla currency
- riequilibrio automatico quando il totale supera il dovuto
- nessuna eccedenza salvata: se si supera il dovuto, viene tenuto solo il massimo utile
- nessuna logica di credito cliente

### 3.3 Flusso nuova prenotazione
Se non esiste ancora `bookingId`:
- il dialog lavora localmente
- restituisce un pagamento temporaneo al form
- la persistenza reale parte quando la booking viene salvata e ha un `bookingId`

---

## 4) Reports

### 4.1 Backend report appointments
Il report appuntamenti integra gli aggregati del pagamento attivo.

Campi attivi:
- `cash_cents`
- `card_cents`
- `voucher_cents`
- `other_cents`
- `discount_cents`
- `paid_cents`
- `due_cents`

I report non considerano più alcun campo di saldo/credito.

### 4.2 UI report
Nel box `Pagamenti` della schermata report vengono mostrati:

- `Totale appuntamenti`
- `Totale inserito`
- `Totale contanti e carte`
- dettaglio per `Contanti`, `Carta`, `Buono`, `Altro`, `Sconto`
- `Residuo da incassare` / `Ancora da pagare` quando c’è scoperto

Le percentuali mostrate nel box sono sempre riferite a `Totale appuntamenti`.

---

## 5) Stato implementazione

- [x] Migrazione unica consolidata
- [x] `client_id` presente su `booking_payments`
- [x] Storico versionato con `is_active`
- [x] `GET /payment` e `PUT /payment` attivi
- [x] Flutter allineato al modello semplificato
- [x] Reports integrati sui tipi attivi
- [x] Nessuna logica di saldo cliente / credito applicato
- [ ] Migrazione ancora da eseguire su database reale, se non già applicata

FINE.
