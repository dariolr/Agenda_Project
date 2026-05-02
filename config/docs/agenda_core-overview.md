# agenda_core

Server API REST PHP per la piattaforma Agenda.

Gestisce autenticazione, servizi, staff, disponibilità e prenotazioni.

## Stack

- PHP 8.2+
- MySQL 8.0+ / MariaDB 10.6+
- Composer

## Setup

```bash
# Dipendenze
composer install

# Configurazione ambiente
cp .env.example .env
# Modificare .env con credenziali DB

# Schema DB
mysql -u root -p agenda_core < config/migrations/FULL_DATABASE_SCHEMA.sql

# Avviare server
composer serve
# oppure: php -S localhost:8080 -t public
```

## Test

```bash
./vendor/bin/phpunit --testdox
```

Eseguire per verificare che tutti i test passino.

## Architettura

```
src/
├── Domain/Exceptions/
├── Http/
│   ├── Controllers/
│   ├── Middleware/     # Auth, Location, Idempotency
│   ├── Kernel.php
│   ├── Request.php
│   ├── Response.php
│   └── Router.php
├── Infrastructure/
│   ├── Database/
│   ├── Repositories/
│   └── Security/       # JWT, Password hashing
└── UseCases/
    ├── Auth/
    └── Booking/
```

## Note critiche

- JWT contiene solo `user_id`. Non fidarsi di `business_id` dal client.
- Ogni modifica DB richiede migrazione + aggiornamento `FULL_DATABASE_SCHEMA.sql`.
- Operazioni booking/disponibilità devono essere transazionali.
- Non modificare endpoint pubblici senza verificare impatto su `agenda_frontend`.

## Regole agente

- `config/agents/agenda_core/PROJECT_RULES.md`
- `config/agents/agenda_core/API_RULES.md`
- `config/agents/agenda_core/DB_RULES.md`
- `config/agents/agenda_core/BOOKING_RULES.md`
- `config/agents/agenda_core/SECURITY_RULES.md`

## Documentazione correlata

- `config/docs/api_contract_v1.md` — contratto API completo con tutti gli endpoint
- `config/docs/agenda_core-environments.md` — configurazione ambienti
- `config/docs/agenda_core-demo-environment.md` — ambiente demo
- `config/docs/data_models.md` — modelli dati
