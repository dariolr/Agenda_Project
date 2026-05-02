# Monorepo Map

## Progetti

- `agenda_core/`
  API PHP, database, business logic, endpoint REST, validazioni server-side.

- `agenda_backend/`
  Gestionale Flutter per operatori, admin e superadmin.

- `agenda_frontend/`
  Frontend Flutter per prenotazione clienti.

- `config/`
  Documentazione, ambienti, migrazioni, script, regole agenti.

## Relazioni

- `agenda_backend` chiama `agenda_core`.
- `agenda_frontend` chiama `agenda_core`.
- `agenda_core` è source of truth per DB, disponibilità, booking, servizi, pacchetti, eventi, pagamenti, visibilità e validazioni.

## Regole

- Non lavorare su più progetti se il task non lo richiede.
- Se una modifica UI richiede supporto API, verificare anche `agenda_core`.
- Se una modifica API impatta il booking clienti, verificare anche `agenda_frontend`.
- Se una modifica API impatta il gestionale, verificare anche `agenda_backend`.
