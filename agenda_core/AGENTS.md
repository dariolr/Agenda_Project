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
5. Ogni modifica DB deve avere una query SQL unica e operativa (phpMyAdmin-ready) in `config/migrations/`.
6. Ogni modifica DB deve aggiornare anche `config/migrations/FULL_DATABASE_SCHEMA.sql`.

## Comandi Utili
```bash
composer install
./vendor/bin/phpunit --testdox
php -l <file>
```

## Qualità
- Ogni modifica API deve includere validazione input e gestione errori standard.
- Endpoint nuovi/variati devono essere documentati in `../config/instructions/agenda_core/docs/api_contract_v1.md`.

## Deploy
- Guida deploy: `../config/instructions/agenda_core/DEPLOY.md`

## Source of Truth Staff Planning
- Documento canonico: `../config/docs/STAFF_PLANNING_MODEL.md`
- Non introdurre regole diverse dal documento.

## Documentazione Progetto Centralizzata
- Cartella: `../config/instructions/agenda_core/`
