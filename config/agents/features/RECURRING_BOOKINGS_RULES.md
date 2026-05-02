# Recurring Bookings Rules

## Modello

- Una serie ricorrente è un `booking_recurrence_rules` con N booking collegati.
- Ogni booking ha `recurrence_rule_id`, `recurrence_index`, `is_recurrence_parent`.
- Frequenze: `daily`, `weekly`, `monthly`, `custom`.

## Endpoint attivi

```
POST   /v1/locations/{location_id}/bookings/recurring  — crea serie
GET    /v1/bookings/recurring/{rule_id}                — leggi serie
PATCH  /v1/bookings/recurring/{rule_id}                — modifica serie
DELETE /v1/bookings/recurring/{rule_id}                — cancella serie
```

## Modifica e cancellazione

- Scope obbligatorio: `all` (tutta la serie) o `future` (da `from_index` in poi).
- Non fare modifiche parziali implicite.
- Modifiche supportate: `staff_id`, `notes`, `time`.

## Multi-staff

- Se presente `staff_by_service`, usare la mappa per ogni servizio.
- Se presente solo `staff_id`, usarlo per tutti i servizi (backward compatible).
- `staff_by_service` ha priorità su `staff_id`.

## Vincoli

- Non creare split impliciti di booking multi-servizio in una serie.
- Label ricorrenza deve restare coerente tra le occorrenze.
- Operazioni serie devono essere transazionali.
- Non rompere comportamento booking singoli (mono-ricorrenti o manuali).

## Notifiche/reminder

- Occorrenze ricorrenti attualmente non accodano reminder automatici (TODO fase 2).
- Non modificare la logica notifiche senza task esplicito.
- Quando implementato, accodare conferma + reminder per ogni occorrenza valida.

## Gestione conflitti

- `conflict_strategy`: `skip` (default, salta date con conflitto) o `force` (crea comunque).
- In caso di `skip`, il booking non viene creato per quella data.
