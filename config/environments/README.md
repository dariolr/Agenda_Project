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

## WhatsApp template Meta

La creazione del template Meta si configura per singola configurazione WhatsApp Business dal gestionale superadmin.

- La richiesta usa il token salvato nella configurazione WhatsApp del business (`access_token_encrypted`).
- `template_auto_submit_enabled` abilita solo l'invio automatico dopo Embedded Signup.
- Se `template_auto_submit_enabled` e' disattivo, il superadmin puo' comunque inviare il template in un secondo momento dal gestionale con l'azione manuale "Invia template a Meta".
- `META_GRAPH_VERSION` e' opzionale; in assenza il core usa `v22.0`.
