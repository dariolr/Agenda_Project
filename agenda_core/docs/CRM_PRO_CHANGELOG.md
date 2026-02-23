# CRM Pro Changelog

## 2026-02-23 - Phase 1

## Nuove tabelle
- `client_contacts`
- `client_addresses`
- `client_consents`
- `client_tags`
- `client_tag_links`
- `client_events`
- `client_tasks`
- `client_loyalty_ledger`
- `client_merge_map`
- `client_segments`
- `client_kpis`

## Estensioni tabella `clients`
- `status` (`lead|active|inactive|lost`)
- `source`
- `company_name`
- `vat_number`
- `address_city`
- `deleted_at`
- `tags` (JSON legacy compatibility)
- indice composto `idx_clients_business_archived_last_visit`

## Endpoint introdotti
Base path: `/v1/businesses/{business_id}`
- CRM client master: list/create/detail/patch/archive/unarchive
- tag management e link/unlink clienti
- contacts CRUD + make-primary
- consents get/put (idempotente)
- timeline events list/create (manual note/message)
- task list/create/update/complete/reopen
- loyalty read/adjust con ledger
- dedup suggestions + merge endpoint
- gdpr export/delete
- segmenti salvati CRUD
- import CSV (dry-run + commit) e export CSV (anche per segmento)
- customer self profile (`/v1/customer/me`) esteso con `marketing_opt_in`, `profiling_opt_in`, `preferred_channel`

## Merge strategy
- Strategia v1 preparata a DB con tabella `client_merge_map`.
- Endpoint dedup/merge esposti.
- Strategia applicata: repoint su tabelle CRM/booking principali + `client_merge_map` per audit.

## Limiti noti v1
- Hook automatici booking->`client_events` da completare in fase successiva.

## Migrazioni
- Forward: `migrations/20260223_crm_pro_phase1.sql`
- Rollback: `migrations/20260223_crm_pro_phase1_rollback.sql`
