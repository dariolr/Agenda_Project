# Online Booking Payments

## Scope

I pagamenti online prenotazione sono separati dagli abbonamenti business.

- Abbonamenti business: webhook `/v1/stripe/webhook`, tabelle `business_billing_*`, variabili `STRIPE_SECRET_KEY` e `STRIPE_WEBHOOK_SECRET`.
- Prenotazioni online: webhook `/v1/online-payments/stripe/webhook`, tabelle `business_online_payment_accounts`, `online_booking_payments`, `online_payment_provider_events`, variabili `STRIPE_ONLINE_PAYMENTS_*` e `STRIPE_CONNECT_*`.

Non riusare secret, webhook o tabelle degli abbonamenti per i pagamenti prenotazione.

## Provider

Provider operativo attuale: Stripe Connect.

PayPal resta riservato per infrastruttura futura, ma non e operativo in questa release:

- non viene mostrato nel gestionale;
- non e abilitabile via API;
- le chiamate dirette agli endpoint provider con `paypal` devono rispondere con `online_payment_provider_not_available`.

## Env

Variabili richieste per `agenda_core`:

- `ONLINE_PAYMENTS_DEFAULT_PROVIDER=stripe`
- `STRIPE_ONLINE_PAYMENTS_SECRET_KEY`
- `STRIPE_CONNECT_CLIENT_ID`
- `STRIPE_CONNECT_WEBHOOK_SECRET`
- `STRIPE_CONNECT_ONBOARDING_URL` - URL gestionale canonica per Stripe Connect, es. `https://gestionale.romeolab.it/altro/pagamenti-online?from_altro=1`
- `STRIPE_ONLINE_PAYMENT_SUCCESS_URL` — deve contenere `{slug}` per lo slug business (es. `https://prenota.romeolab.it/{slug}/payment-result?status=success`)
- `STRIPE_ONLINE_PAYMENT_CANCEL_URL` — deve contenere `{slug}` (es. `https://prenota.romeolab.it/{slug}/payment-result?status=cancel`)

Il provider sostituisce `{slug}` con lo slug reale del business al momento della creazione del checkout. `payment_id` e `booking_id` vengono aggiunti automaticamente come query param.

In demo/local, se `ALLOW_REAL_PAYMENTS=false`, la policy ambiente blocca la creazione di checkout reali (risponde `demo_blocked`).

## Booking Flow

Quando nessun elemento richiede pagamento, il booking pubblico resta invariato: stato `confirmed`, notifiche e reminder come da flusso esistente, nessun record in `online_booking_payments`.

Quando almeno un servizio o pacchetto richiede pagamento:

1. il server valida disponibilita, visibilita e ownership come nel flusso standard;
2. crea il booking in stato `pending_payment`;
3. crea gli item prenotazione;
4. calcola l'importo lato server dai prezzi location/business;
5. recupera lo slug business dal DB;
6. crea `online_booking_payments` in stato `pending`;
7. crea una Stripe Checkout Session sull'account Connect del business con URL success/cancel contenenti `/{slug}/payment-result`;
8. restituisce `payment_required=true`, `payment_provider=stripe`, `payment_id`, `checkout_url`;
9. il frontend reindirizza nella stessa tab a Stripe;
10. il webhook conferma o cancella il booking.

Se la Stripe Checkout creation fallisce, il payment viene marcato `failed` e il booking viene cancellato (nessun record orfano).

### Class Events

Il flusso per `class_events.online_payment_required = 1`:

1. Validazione Stripe account del business;
2. `classEventRepo->book()` crea class booking in stato `CONFIRMED` (slot riservato, `confirmed_count` incrementato atomicamente);
3. Il controller aggiorna immediatamente il class booking a `PENDING_PAYMENT`;
4. Crea `online_booking_payments` con `class_booking_id`;
5. Crea Stripe Checkout Session;
6. Restituisce `payment_required=true`, `payment_id`, `checkout_url`;
7. Webhook/polling `paid` → status `CONFIRMED`, notifica accodata;
8. Webhook/polling `expired/failed/cancelled` → `CANCELLED_BY_CUSTOMER`, `confirmed_count` decrementato.

Se il class booking finisce in waitlist, non viene richiesto pagamento (il posto non e confermato).

## Stati

Payment:

- `pending`
- `requires_action`
- `paid`
- `failed`
- `cancelled`
- `expired`
- `refunded`

Booking collegato (`bookings.status`):

- `pending_payment` — blocca temporaneamente lo slot durante checkout;
- `confirmed` — solo dopo pagamento riuscito;
- `cancelled` — su pagamento fallito, scaduto o annullato.

Class booking collegato (`class_bookings.status`):

- `PENDING_PAYMENT` — slot riservato (`confirmed_count` incrementato), notifica non ancora accodata;
- `CONFIRMED` — dopo pagamento riuscito;
- `CANCELLED_BY_CUSTOMER` — su pagamento fallito/scaduto/annullato, `confirmed_count` decrementato.

## Policy cancel/retry

- **Cancel URL** (utente clicca "torna indietro" su Stripe): payment resta `pending`, booking/class booking resta `pending_payment`. Il frontend mostra "Pagamento non completato" e pulsante "Riprova pagamento" (`can_retry=true`).
- **Retry**: consentito solo se booking/class booking e ancora `pending_payment` e payment non e `paid`.
- **Expired** (`checkout.session.expired` o job scadenza): payment `expired`, booking/class booking cancellato, `confirmed_count` decrementato, retry non consentito (`can_retry=false`).
- **Failed**: payment `failed`, booking/class booking cancellato.
- **Paid**: payment `paid`, booking/class booking `confirmed`, notifiche accodate una sola volta.

## Status endpoint e riconciliazione

`GET /v1/online-booking-payments/{payment_id}/status` — se il payment e `pending` o `requires_action` e Stripe gia risulta `paid`, l'endpoint riconcilia in tempo reale: aggiorna payment, conferma booking/class booking e accoda notifiche. Questo garantisce UX corretta anche se il webhook arriva in ritardo.

L'idempotenza e garantita: se webhook e polling arrivano insieme, il primo che trova `status <> 'paid'` esegue l'update; il secondo trova gia `paid` e non duplica notifiche.

## Webhook

Endpoint: `POST /v1/online-payments/stripe/webhook`.

Regole:

- endpoint pubblico senza auth utente;
- firma obbligatoria con `STRIPE_CONNECT_WEBHOOK_SECRET`;
- idempotenza tramite `online_payment_provider_events`;
- mapping tramite metadata Stripe e/o `provider_checkout_id`;
- update pagamento + booking in transazione;
- notifiche accodate solo quando il booking passa da `pending_payment` a `confirmed`.

## Frontend Cliente

Il frontend mostra il badge localizzato `Pagamento online richiesto` quando la selezione contiene elementi con `online_payment_required=true`.

Dopo il submit, se la response contiene `payment_required=true` e `checkout_url`, non mostra la conferma finale e reindirizza a Stripe.

La route `/:slug/payment-result` legge `payment_id`, chiama lo stato pagamento, usa polling limitato e mostra:

- conferma solo con payment `paid` o booking `confirmed`;
- attesa se `pending`;
- errore e retry se `failed`, `cancelled` o `expired` e il retry e consentito.

## Endpoint

- `GET /v1/businesses/{business_id}/online-payment-accounts`
- `POST /v1/businesses/{business_id}/online-payment-accounts/{provider_code}/onboarding-link`
- `POST /v1/businesses/{business_id}/online-payment-accounts/{provider_code}/sync`
- `PUT /v1/businesses/{business_id}/online-payment-accounts/{provider_code}`
- `DELETE /v1/businesses/{business_id}/online-payment-accounts/{provider_code}`
- `POST /v1/online-payments/stripe/webhook`
- `GET /v1/online-booking-payments/{payment_id}/status`
- `POST /v1/online-booking-payments/{payment_id}/retry`

## Cleanup

Lo script `agenda_core/bin/job-expire-online-booking-payments.php` marca come scaduti i payment pending oltre `expires_at` e cancella i booking ancora `pending_payment`.

## Checklist Test

- Booking senza pagamento: booking `confirmed`, nessun payment.
- Booking con pagamento: booking `pending_payment`, payment `pending`, checkout Stripe.
- Webhook success: payment `paid`, booking `confirmed`, notifiche accodate una sola volta.
- Webhook failed/expired/cancelled: booking `cancelled`, nessuna conferma.
- Retry: nuova checkout sullo stesso payment recuperabile.
- PayPal: non visibile e non abilitabile.
- Demo senza real payments: checkout bloccata dalla policy ambiente.
