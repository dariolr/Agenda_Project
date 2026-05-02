# agenda_backend Riverpod Rules

## Pattern obbligatori

- Usare `FutureProvider` per dati read-only asincroni.
- Usare `Notifier` per state mutabile con async initialization.
- NON usare `AsyncNotifier`: incompatibile con logica sincrona esistente.
- Ogni feature usa il proprio repository per le chiamate API.

## Provider critici (NON modificare senza task esplicito)

- `dragSessionProvider` — stato drag & drop appuntamenti
- `resizingProvider` — stato resize appuntamento
- `agendaScrollProvider` — controller scroll condivisi
- `bookingsProvider` — CRUD bookings con validazione

## Regole

- Non introdurre mock nei provider di produzione.
- Usare provider e repository esistenti prima di crearne di nuovi.
- Aggiungere provider in modo additivo (non modificare interfacce esistenti).
- Nessun `ref.read` nei `build()` senza motivo esplicito.
- Nessun `ref.invalidate` senza capire gli effetti a cascata.

## Code generation

- Dopo modifiche a file annotati `@riverpod`:
  `dart run build_runner build --delete-conflicting-outputs`
- Non fare commit con generated file non aggiornati.
