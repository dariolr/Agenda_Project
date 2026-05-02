# agenda_core API Rules

## Versioning e path

- Tutti gli endpoint sotto `/v1/`.
- Non cambiare URL di endpoint esistenti (breaking change).
- Nuovi endpoint devono essere additivi.

## Response format (obbligatorio)

```json
// Successo
{ "success": true, "data": { ... } }

// Errore
{ "success": false, "error": { "code": "snake_case_code", "message": "...", "details": {} } }
```

- Codice errore sempre `snake_case` nel campo `error.code`.
- HTTP status coerente: 400 validazione, 401 auth, 403 permessi, 404 not found, 409 conflitto, 500 server error.

## Validazione

- Validazioni sempre lato server.
- Input da client mai fidati per `business_id`, `location_id`, o id sensibili: derivare server-side quando possibile.
- JWT contiene solo `user_id`.

## Idempotency

- `X-Idempotency-Key` obbligatorio per POST booking quando il client può riprovare.
- Le operazioni idempotenti devono restituire lo stesso risultato se la chiave è già usata.

## Endpoint pubblici vs gestionali

- Endpoint pubblici filtrano per visibilità online.
- Endpoint gestionali non filtrano per visibilità (salvo richiesta esplicita).
- Non modificare endpoint pubblici senza verificare impatto su `agenda_frontend`.
- Non modificare endpoint gestionali senza verificare impatto su `agenda_backend`.

## Contratto completo

Vedere: `config/docs/api_contract_v1.md`
