# Documentazione Patch — `client_id` su `booking_payments` (stato consolidato)

## Obiettivo
`client_id` è mantenuto su `booking_payments` come dato strutturale stabile.

Scopo:
- rendere più semplici le join future verso report/viste per cliente
- evitare di derivare sempre il cliente passando da `bookings`
- mantenere il dato coerente con la booking al momento del salvataggio

Questa patch non introduce alcuna logica di saldo cliente.

---

## 1) Stato attuale del database

`client_id` è già integrato direttamente nella migrazione consolidata:

- `migrations/20260228_add_booking_payments.sql`

Schema attuale della tabella `booking_payments`:
- `client_id` presente
- `client_id` nullable
- indice `idx_booking_payments_client`

Motivo della nullabilità:
- anche `bookings.client_id` può essere `NULL`

Non serve più una migrazione separata di alter table: il campo fa parte dello schema finale della feature.

---

## 2) Backend PHP

### 2.1 Regola applicativa
Il backend:
- legge sempre `client_id` dal booking
- non si fida mai del client
- lo salva nell’header `booking_payments`

### 2.2 GET `/v1/bookings/{booking_id}/payment`
La response include:

- `booking_id`
- `client_id`
- gli altri campi del pagamento

### 2.3 PUT `/v1/bookings/{booking_id}/payment`
Durante il salvataggio:

1. il server recupera la booking
2. deriva `business_id`, `location_id`, `client_id`
3. salva `client_id` nel nuovo record attivo di `booking_payments`

Il frontend non invia `client_id` nel payload di upsert.

### 2.4 Aggiornamenti successivi
Se il pagamento viene salvato di nuovo:
- il record attivo precedente viene disattivato
- il nuovo record attivo salva di nuovo anche il `client_id` corrente del booking

Quindi `client_id` resta coerente con la versione del pagamento che è stata effettivamente salvata.

---

## 3) Flutter (agenda_backend)

`BookingPayment` espone:

- `int? clientId`

Comportamento:
- `fromJson` legge `client_id`
- `toUpsertJson()` non lo invia

Questo permette:
- parsing coerente della response
- disponibilità del dato per UI/report futuri
- nessuna duplicazione di responsabilità lato client

---

## 4) Note architetturali

`client_id` è stato mantenuto anche dopo la bonifica della feature pagamenti, pur senza logica di saldo, perché:

- è utile per estensioni future
- non complica il modello corrente
- riduce il costo di join per elaborazioni per cliente

Oggi è quindi:
- presente
- persistito
- restituito dalle API
- non usato per calcoli di saldo

---

## 5) Stato patch

- [x] `client_id` presente nello schema consolidato
- [x] indice su `client_id`
- [x] `GET /payment` restituisce `client_id`
- [x] `PUT /payment` salva `client_id` derivato dal booking
- [x] Flutter parse-a `client_id`
- [x] `client_id` non viene inviato dal client
- [ ] Resta da applicare la migrazione consolidata su DB reale, se l’ambiente non è ancora allineato

FINE.
