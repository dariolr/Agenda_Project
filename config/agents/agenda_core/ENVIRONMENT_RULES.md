# agenda_core Environment Rules

- Ambienti: `local`, `demo`, `staging`, `production`.
- Configurazione centralizzata, mai hardcoded nel codice.
- Demo non deve puntare a produzione.
- Demo deve usare DB separato.
- Flag reali (pagamenti, notifiche) disattivati in demo.
- Non committare segreti o credenziali reali.
- Per documentazione completa ambienti: `config/docs/agenda_core-environments.md`.
- Per policy demo completa: `config/docs/agenda_core-demo-policy-matrix.md`.
