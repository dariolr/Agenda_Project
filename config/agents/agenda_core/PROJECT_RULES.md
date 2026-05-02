# agenda_core Agent Rules

Progetto API PHP.

Regole:

- JWT contiene solo `user_id`.
- `business_id` non deve essere preso dal client se può essere derivato server-side.
- Le API devono rispettare il formato response standard.
- Ogni nuovo errore deve usare `error.code` coerente.
- Ogni modifica DB richiede migrazione in `config/migrations/`.
- Ogni modifica DB deve aggiornare `config/migrations/FULL_DATABASE_SCHEMA.sql`.
- Validazioni sempre lato server.
- Operazioni su booking/disponibilità devono essere transazionali quando c’è rischio race condition.
- Non modificare endpoint pubblici senza verificare impatto su `agenda_frontend`.
- Non modificare endpoint gestionali senza verificare impatto su `agenda_backend`.