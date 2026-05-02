# agenda_core Booking Rules

- Booking e disponibilità sono source of truth server-side.
- Availability con controlli race-safe (transazioni DB).
- Idempotency key richiesta per POST booking quando il client può riprovare.
- Multi-servizio trattato come booking contenitore + item separati.
- Reschedule booking-level quando coinvolge più item.
- Non creare split impliciti di booking multi-servizio.
- Timezone coerente tenant/location per tutti i calcoli di disponibilità.
- Non cambiare logica appointment senza task esplicito.
- Operazioni critiche booking/disponibilità devono essere transazionali.
- Non rompere endpoint pubblici booking usati da `agenda_frontend`.
