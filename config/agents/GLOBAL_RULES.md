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
- Risolvi i problemi alla radice, non con escamotage sul sintomo. Prima di modificare codice, individua il flow reale, la sorgente dello stato e il confine corretto della fix.
- Non mascherare errori o comportamenti errati con filtri di log, flag locali, retry arbitrari, normalizzazioni UI o query param aggiunti a posteriori se la causa è nel flow, nell'API, nello stato condiviso o nel contratto tra componenti.
- I workaround sono ammessi solo se richiesti esplicitamente o se dichiarati come temporanei, con causa radice, rischio residuo e fix definitiva da fare.
- Se la causa radice è fuori scope del task corrente, segnalarlo esplicitamente invece di mascherare il sintomo.
- Alla fine indica file creati, modificati, spostati, eliminati e test/verifiche eseguite.
