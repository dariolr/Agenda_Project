# Global Agent Rules

- Non fare refactor non richiesti.
- Non modificare logiche fuori scope.
- Non modificare codice applicativo se il task riguarda solo documentazione.
- Non eseguire deploy.
- Non modificare file `.env` reali.
- Non cambiare schema DB senza migrazione dedicata.
- Non introdurre breaking change API.
- Non modificare file generati se non necessario.
- Non introdurre mock nei provider o servizi di produzione.
- Non leggere tutto il monorepo se il task è circoscritto.
- Prima individua i file coinvolti, poi modifica solo quelli.
- Mantieni compatibilità con i comportamenti esistenti.
- Se trovi istruzioni obsolete, spostale in archivio o rimuovile.
- Alla fine indica file creati, modificati, spostati, eliminati e test/verifiche eseguite.
