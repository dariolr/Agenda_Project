# Booking Payments Rules

## Modello attivo

- 1 record attivo per booking (`is_active = 1`), storico versionato.
- Salvataggio disattiva il record attivo precedente e inserisce nuova versione.
- Se pagamento vuoto (nessuna riga, totale <= 0, nessuna nota), il backend disattiva l'attivo e la booking resta senza pagamento.

## Endpoint attivi

- `GET /v1/bookings/{booking_id}/payment` — restituisce record attivo
- `PUT /v1/bookings/{booking_id}/payment` — salva nuova versione attiva

## Regole server-side

- Il server deriva sempre `business_id`, `location_id`, `client_id` dal booking.
- Il frontend NON invia `client_id` nel payload di upsert.
- `client_id` è nullable (anche `bookings.client_id` può essere NULL).

## Tipi di riga ammessi

`cash`, `card`, `discount`, `voucher`, `other`

- `amount_cents` è `INT UNSIGNED` (nessun importo negativo).
- Nessun tipo di riga aggiuntivo senza task esplicito.

## Calcoli (computed)

- `total_paid_cents = cash + card + voucher + other`
- `total_discount_cents = discount`
- `balance_cents = total_due_cents - total_paid_cents - total_discount_cents`

Non esistono: `total_credit_applied_cents`, `previous_balance`, saldo cliente calcolato.

## Report

- Campi attivi: `cash_cents`, `card_cents`, `voucher_cents`, `other_cents`, `discount_cents`, `paid_cents`, `due_cents`.
- Nessun campo di saldo/credito nei report.

## Flutter (agenda_backend)

- `BookingPayment.clientId` viene letto dalla response ma non inviato in `toUpsertJson()`.
- Nessuna logica di credito cliente nel dialog pagamento.
- Importi non negativi; nessuna eccedenza salvata oltre il dovuto.
