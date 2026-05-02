# Service Capacity Rules

## Regola principale

- La capienza di un servizio (`capacity`) è un campo del servizio, non dello staff.
- Controllare `capacity` sul modello `service` (o `service_variant`), non sull'entità `staff`.

## Implicazioni

- Un servizio può avere più posti (es. corso di gruppo: capacity = 10).
- Un appuntamento con capacity > 1 ammette più booking sullo stesso slot.
- Il conflict detection deve tenere conto della capacity residua, non solo dell'overlap.
- Lo staff può avere più slot contemporanei solo se il servizio lo permette esplicitamente.

## Anti-pattern da evitare

- Non usare il numero di staff come surrogato della capienza del servizio.
- Non ignorare `capacity` nei controlli di disponibilità per servizi di gruppo.
- Non assumere capacity = 1 senza leggere il campo sul servizio.
