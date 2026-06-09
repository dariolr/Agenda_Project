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
- Ogni patch deve risolvere la causa radice dimostrata del problema, non il sintomo.
- Non applicare workaround, normalizzazioni difensive o casi speciali che mascherano il bug: identifica la causa radice e correggila nel punto in cui nasce.
- Se viene richiesto esplicitamente un fix temporaneo, marcarlo come temporaneo, documentare la causa radice non risolta e non presentarlo come correzione definitiva.
- Se la causa radice è fuori scope del task corrente, segnalarlo esplicitamente invece di mascherare il sintomo.
- Alla fine indica file creati, modificati, spostati, eliminati e test/verifiche eseguite.
