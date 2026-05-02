# agenda_core Security Rules

- JWT contiene solo `user_id`.
- Controlli permessi sempre server-side.
- Superadmin gestito server-side, non derivabile da client.
- Non fidarsi di `business_id` o altri id sensibili dal payload client.
- Token e segreti mai nel repository.
- Demo policy deve bloccare azioni reali (pagamenti, invio messaggi reali, ecc.).
- Validare ownership di business/location/staff/client prima di ogni operazione.
- Webhook devono essere idempotenti.
- Non esporre stack trace in production.
- Validazioni sempre lato server, mai solo lato client.
