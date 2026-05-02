# Agenda Frontend

App Flutter per prenotazioni online clienti finali.

## Stack

| Tecnologia | Versione | Note |
|------------|----------|------|
| Flutter | 3.35+ | SDK 3.10+ |
| Riverpod | 3.x | State management |
| go_router | 16.x | Navigation |
| intl | 0.20+ | Localizzazioni IT/EN |

## Architettura

```
lib/
├── app/                    # Router, theme, providers globali
├── core/
│   ├── l10n/              # Localizzazioni IT/EN
│   ├── models/            # Service, Staff, TimeSlot, etc.
│   ├── network/           # ApiClient + TokenStorage
│   └── widgets/           # Widget riutilizzabili
└── features/
    ├── auth/              # Login, Register, Password reset
    └── booking/           # Flow prenotazione completo
```

## Comandi base

```bash
# Localizzazione (dopo modifiche .arb)
dart run intl_utils:generate

# Code generation (dopo @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Build web produzione
flutter build web --release --no-tree-shake-icons

# Deploy su SiteGround
cp web/.htaccess build/web/
rsync -avz --delete -e "ssh -p 18765" build/web/ siteground:~/www/prenota.romeolab.it/public_html/
```

## Routing multi-business (path-based)

URL struttura: `/:slug/booking`, `/:slug/login`, `/:slug/my-bookings`, ecc.

Slug ricavato da `routeSlugProvider` — NON usare `SubdomainResolver.getBusinessSlug()`.

Route protette richiedono auth, redirect a `/:slug/login?from={route}` se non autenticato.

Su web, `/:slug/login` reindirizza a `web/login.html` (form HTML nativo per autofill iOS Safari).

## Multi-location

Se il business ha più sedi attive, l'utente sceglie la sede prima di prenotare. Con una sola sede, lo step viene saltato. Provider chiave: `locationsProvider`, `selectedLocationProvider`, `hasMultipleLocationsProvider`, `effectiveLocationIdProvider`.

## Note critiche

- `routeSlugProvider` è l'unica fonte affidabile dello slug corrente nel routing.
- Booking locale risolto nell'ordine: query param `?lang=`, `location.booking_default_locale`, locale browser, fallback `it`. Riferimento: `config/docs/agenda_frontend-booking-locale-policy.md`.
- Provider che chiamano API usano `StateNotifier` con flag `_hasFetched` per evitare loop.

## Regole agente

- `config/agents/agenda_frontend/PROJECT_RULES.md`
- `config/agents/agenda_frontend/BOOKING_FLOW_RULES.md`
- `config/agents/agenda_frontend/TIMEZONE_RULES.md`
- `config/agents/agenda_frontend/VISIBILITY_RULES.md`
- `config/agents/agenda_frontend/SECURITY_RULES.md`

## Documentazione correlata

- `config/docs/agenda_frontend-environments.md` — configurazione ambienti
- `config/docs/agenda_frontend-booking-locale-policy.md` — policy locale booking
