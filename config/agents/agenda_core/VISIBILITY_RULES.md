# agenda_core Visibility Rules

- Visibilità online influenza solo il booking pubblico (`agenda_frontend`).
- Il gestionale (`agenda_backend`) vede e gestisce anche elementi non prenotabili online.
- Valori visibilità:
  - `pubblico` — visibile e prenotabile nel booking pubblico
  - `non prenotabile online` — non visibile nel booking pubblico
  - `solo direct link` — visibile/prenotabile solo tramite link valido
- Endpoint pubblici devono filtrare correttamente per visibilità.
- Endpoint gestionali non devono filtrare per visibilità online salvo richiesta esplicita.
- Direct link deve essere validato server-side.
- Mantenere coerenza tra visibilità di servizi, pacchetti, eventi e categorie.
