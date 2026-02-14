# Agenda Core (API PHP) — AGENTS

## Identificazione Progetto
- Progetto: `agenda_core`
- Scopo: API/backend PHP della piattaforma Agenda
- Produzione: `https://api.romeolab.it`

## Regole Critiche
1. Non eseguire deploy produzione senza richiesta esplicita.
2. Non modificare schema DB senza migrazione coerente.
3. Non introdurre breaking change API senza richiesta esplicita.
4. Mantenere compatibilità con `agenda_backend` e `agenda_frontend`.

## Comandi Utili
```bash
composer install
./vendor/bin/phpunit --testdox
php -l <file>
```

## Qualità
- Ogni modifica API deve includere validazione input e gestione errori standard.
- Endpoint nuovi/variati devono essere documentati in `docs/api_contract_v1.md`.

## Deploy
- Guida deploy: `DEPLOY.md`

## Source of Truth Staff Planning
- Documento canonico: `docs/STAFF_PLANNING_MODEL.md`
- Non introdurre regole diverse dal documento.
