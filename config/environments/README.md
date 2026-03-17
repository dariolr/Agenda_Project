# Environment Templates

Questa cartella contiene template centralizzati per i 3 ambienti ufficiali del monorepo:

- `local`
- `demo`
- `production`

Ogni ambiente contiene 3 file:

- `agenda_backend.env` (gestionale Flutter)
- `agenda_frontend.env` (frontend clienti Flutter)
- `agenda_core.env` (API PHP)

Regole:

- Non inserire segreti reali nei file versionati.
- Usare questi file come base per variabili CI/CD o file `.env` locali.
- In demo, i flag sensibili devono restare disattivati.
