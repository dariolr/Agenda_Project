# WhatsApp Integration -- Agenda Platform (FINAL SPEC 2026)

## MODELLO ARCHITETTURALE

-   Multi-tenant SaaS
-   1 business = N numeri WhatsApp
-   1 numero può essere associato a:
    -   tutto il business
    -   subset di location

------------------------------------------------------------------------

## CONFIGURAZIONE

### whatsapp_business_config

-   id
-   business_id
-   waba_id
-   phone_number_id
-   access_token_encrypted
-   status

### whatsapp_location_mapping

-   id
-   business_id
-   location_id
-   whatsapp_config_id

------------------------------------------------------------------------

## LOGICA ASSOCIAZIONE

-   Se location ha mapping → usa numero location
-   Se no → usa numero business default
-   Se nessuno → NON inviare

------------------------------------------------------------------------

## ONBOARDING (EMBEDDED SIGNUP)

1.  Click "Collega WhatsApp"
2.  Meta OAuth
3.  Selezione business / numero
4.  Salvataggio:
    -   waba_id
    -   phone_number_id
    -   token

------------------------------------------------------------------------

## INVIO MESSAGGI

Endpoint:

POST https://graph.facebook.com/v19.0/{phone_number_id}/messages

Payload template ONLY

------------------------------------------------------------------------

## OUTBOX FLOW

queued → sent → delivered → read

------------------------------------------------------------------------

## WORKER

-   prende queued
-   invia via API
-   aggiorna stato

Retry: - 429 → retry - 5xx → retry - 4xx → fail

------------------------------------------------------------------------

## WEBHOOK

Gestire: - statuses - messages

Idempotente.

------------------------------------------------------------------------

## TEMPLATE

-   solo approved
-   categoria utility

------------------------------------------------------------------------

## OPT-IN

-   obbligatorio
-   salvato DB
-   blocco invio se false

------------------------------------------------------------------------

## SCHEDULER

-   reminder 24h
-   reminder 2h

------------------------------------------------------------------------

## FALLBACK

-   se numero non configurato → skip

------------------------------------------------------------------------

## GO LIVE CHECK

-   numero attivo
-   webhook verified
-   template approved
-   opt-in attivo

------------------------------------------------------------------------

END
