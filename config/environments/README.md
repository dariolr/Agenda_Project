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

## WhatsApp template auto-submit

Per abilitare la creazione automatica del template Meta dopo Embedded Signup nel core:

- `META_TEMPLATE_AUTO_SUBMIT_ENABLED=true` solo negli ambienti dove la submission reale e' voluta.
- `META_SYSTEM_USER_ACCESS_TOKEN` deve essere configurato fuori dai file versionati e avere `whatsapp_business_management`.
- `META_GRAPH_API_VERSION` e' opzionale; in assenza viene usato `META_GRAPH_VERSION`.
- `META_TEMPLATE_DEFAULT_LANGUAGE` default `it`.
- `META_TEMPLATE_DEFAULT_CATEGORY` default `UTILITY`.
