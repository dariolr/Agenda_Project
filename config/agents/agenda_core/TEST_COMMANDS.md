# agenda_core Test Commands

## Comandi principali

```bash
# Tutti i test con output dettagliato
./vendor/bin/phpunit --testdox

# Categoria specifica
./vendor/bin/phpunit --filter AuthUseCaseTest
./vendor/bin/phpunit --filter BookingUseCaseTest
./vendor/bin/phpunit --filter AvailabilityTest
```

Eseguire per verificare che tutti i test passino.

## Setup e avvio server

```bash
# Installare dipendenze
composer install

# Avviare server di sviluppo
composer serve
# oppure
php -S localhost:8080 -t public
```

## DB (schema e seed)

```bash
# Schema completo
mysql -u root -p agenda_core < config/migrations/FULL_DATABASE_SCHEMA.sql

# Dati di test (opzionale)
mysql -u root -p agenda_core < config/migrations/seed_data.sql
```
