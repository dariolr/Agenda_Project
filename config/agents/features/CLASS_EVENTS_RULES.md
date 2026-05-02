# Class Events Rules

## Principio

- Class events (sessioni di gruppo con capacità limitata) sono una feature separata dagli appointment classici.
- Non modificare o rompere nessuna logica, endpoint, UI o validazione degli appointment 1:1 esistenti.

## Entità

- `ClassEvent` — sessione di gruppo (tabella `class_events`, separata da `bookings`/`booking_items`).
- `ClassBooking` — prenotazione partecipante (tabella `class_bookings`).
- `ClassSeries` — template ricorrenza (opzionale, fase 2).

## Capacità e waitlist

- `effective_capacity = capacity_total - capacity_reserved`.
- `spots_left = max(0, effective_capacity - confirmed_count)`.
- Se `spots_left >= 1` → booking CONFIRMED.
- Se `spots_left == 0` e `waitlist_enabled` → booking WAITLISTED.
- Se `spots_left == 0` e waitlist disabilitata → rifiuta con FULL.

## Transazioni race-safe

- Booking e cancel DEVONO essere eseguiti in una singola transazione DB con FOR UPDATE.
- Counters (`confirmed_count`, `waitlist_count`) modificati solo dentro la transazione.
- Waitlist re-pack (normalizzazione posizioni) eseguita dentro la stessa transazione.

## Idempotenza

- Doppio booking stesso cliente stesso evento → restituisce stato corrente (non duplica).

## Compatibilità garantita

- Nessuna modifica a tabelle `bookings`/`booking_items`.
- Nessuna modifica agli endpoint appointment esistenti.
- Nessuna modifica alla UI degli appointment.
- Class events si aggiungono in parallelo al calendario esistente.

## Scope MVP vs Fase 2

- MVP: ClassEvent, ClassBooking, capacità, waitlist, partecipanti, feature flag.
- Fase 2: ClassSeries (ricorrenza), multi-seat, private classes, pagamento integrato, override staff manuali.

## Endpoint (nuovi, non-breaking)

- Route group `/class-events` separato dagli endpoint appointment.
- Endpoint pubblici: `GET /class-events`, `GET /class-events/{id}`, `POST /class-events/{id}/book`, `POST /class-events/{id}/cancel`.
- Endpoint staff/admin: `POST /class-events`, `PATCH /class-events/{id}`, `GET /class-events/{id}/participants`.

## Rollout

- Backend deployato con feature flag `class_events_enabled=false`.
- Abilitare per tenant interni prima del rollout generale.
