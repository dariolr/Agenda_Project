# WhatsApp Rules

## Architettura

- Multi-tenant: 1 business = N numeri WhatsApp.
- 1 numero può coprire tutto il business o un subset di location.

## Logica associazione numero

- Se la location ha mapping in `whatsapp_location_mapping` → usa numero location.
- Se non ha mapping → usa numero business default.
- Se nessun numero configurato → NON inviare (skip silenzioso).

## Tabelle principali

- `whatsapp_business_config` — configurazione numero (waba_id, phone_number_id, token, status)
- `whatsapp_location_mapping` — mapping location → numero

## Outbox flow

`queued → sent → delivered → read`

In caso di errore:
- 429 → retry
- 5xx → retry
- 4xx → fail

## Template

- Usare solo template `approved` con categoria `utility`.
- Payload solo tramite template (no messaggi liberi).

## Opt-in

- Opt-in obbligatorio, salvato in DB.
- Bloccare invio se opt-in è false.

## Webhook

- Gestire eventi: `statuses`, `messages`.
- Webhook deve essere idempotente.

## Scheduler

- Reminder automatici: 24h prima, 2h prima.

## Go-live checklist

- Numero attivo.
- Webhook verified.
- Template approved.
- Opt-in attivo per il cliente.
