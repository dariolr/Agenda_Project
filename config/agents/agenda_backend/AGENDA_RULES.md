# agenda_backend Agenda Rules

## Regole calendario (agenda day/week view)

- Non modificare drag, resize, ghost overlay, auto-scroll, scroll-lock senza task esplicito.
- Non cambiare la semantica degli provider critici: `dragSessionProvider`, `resizingProvider`, `agendaScrollProvider`, `bookingsProvider`.
- Aggiungere nuove view (es. settimana) in modo additivo: non rompere la day-view esistente.
- Caricare appuntamenti con caching per combinazione data+filtri.
- Usare lo stesso flusso di apertura dettaglio appuntamento già esistente.
- Filtri staff/location/status/servizi devono essere riusati tra le view.

## Regole business

- Non modificare logica di overlap/disponibilità senza task esplicito.
- Reschedule multi-servizio: trattare come booking-level, non item-level.
- Non creare split impliciti di booking multi-servizio.
- Sempre verificare permessi operatore prima di modificare/cancellare appuntamenti.

## Anti-regressione

- Nessuna modifica ai modelli esistenti (campi, parsing, naming) senza task esplicito.
- Nessun refactor di provider non richiesto esplicitamente.
- Nessun ripple/splash effect.
- Nessun mock nei provider di produzione.
