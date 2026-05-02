# agenda_core DB Rules

## Migrations

- Ogni modifica allo schema richiede una migrazione in `config/migrations/`.
- Nome file migrazione: `YYYYMMDD_descrizione.sql`.
- Ogni migrazione deve essere additiva e backward-compatible (no drop column senza deprecazione).
- Dopo ogni migrazione aggiornare `config/migrations/FULL_DATABASE_SCHEMA.sql`.

## Query e repository

- Le query usano PDO (mai costruzione diretta di SQL con input non sanitizzato).
- I repository sono in `src/Infrastructure/Repositories/`.
- Nessuna logica di business nei repository: solo accesso dati.
- Operazioni critiche (booking, disponibilità) devono essere transazionali.

## Schema chiave

- `bookings` — prenotazione principale (contenitore multi-servizio)
- `booking_items` — singoli servizi di una prenotazione
- `locations` — sedi con timezone e configurazione
- `businesses` — business con cancellation_hours e timezone
- Schema completo: `config/migrations/FULL_DATABASE_SCHEMA.sql`

## Anti-regressione

- Non rinominare colonne esistenti senza verificare tutti i repository che le usano.
- Non eliminare colonne senza verificare che nessun endpoint le esponga.
- Nuovi campi nullable o con default: non rompono client esistenti.
