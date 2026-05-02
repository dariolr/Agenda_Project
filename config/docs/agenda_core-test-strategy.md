# agenda_core Test Strategy

## Comando principale

```bash
./vendor/bin/phpunit --testdox
```

## Aree coperte

- Auth
- Booking
- Availability
- HTTP request/response
- Routing
- Idempotency
- Password hashing
- Domain exceptions

## Regole

- Non inserire numeri test fissi.
- Non inserire script bash lunghi.
- Non duplicare il contratto API.
- Aggiornare questo file solo se cambia la strategia di test, non a ogni nuovo test.
