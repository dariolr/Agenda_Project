# agenda_frontend Booking Flow Rules

## Flow steps (ordine obbligatorio)

1. Sede (saltato automaticamente se il business ha una sola sede)
2. Servizi
3. Staff
4. Data e slot
5. Conferma

## Provider chiave (NON modificare senza task esplicito)

- `locationsProvider` — lista sedi dal backend
- `selectedLocationProvider` — selezione sede utente
- `hasMultipleLocationsProvider` — determina se mostrare step Sede
- `effectiveLocationIdProvider` — ID sede per chiamate API
- `routeSlugProvider` — slug business estratto dal path URL

## Regole

- Non modificare l'ordine degli step senza task esplicito.
- Non rompere login, register, my-bookings.
- Preservare slug business e query params nelle navigazioni.
- Rotte protette (booking, my-bookings, profile, change-password) richiedono auth.
- Se non autenticato: redirect a `/:slug/login?from={route}`.
- Non usare `SubdomainResolver.getBusinessSlug()`: usare sempre `routeSlugProvider`.
- Reschedule: usare il flow di availability check, non calcoli locali.
- Ottimismo UI (rimozione/update dalla lista locale) solo dopo conferma server.

## URL structure

| Pattern | Comportamento |
|---------|---------------|
| `/:slug` | Redirect a `/:slug/booking` |
| `/:slug/booking` | Flow prenotazione (auth required) |
| `/:slug/login` | Login (su web: redirect a `login.html`) |
| `/:slug/my-bookings` | Le mie prenotazioni |

## Login web

- Su web, `/:slug/login` reindirizza a `web/login.html`.
- `login.html` non accetta `api_base` da query string: l'API base è derivata dall'host.
