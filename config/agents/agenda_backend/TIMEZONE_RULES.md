# agenda_backend Timezone Rules

## Regola di risoluzione timezone

Ordine obbligatorio:

1. `location.timezone` della location corrente
2. fallback `business.timezone`
3. fallback finale `Europe/Rome`

## Provider da usare

- `effectiveTenantTimezoneProvider` — risolve timezone effettivo (location → business → default)
- `tenantNowProvider` — orario corrente nel timezone effettivo
- `tenantTodayProvider` — data odierna nel timezone effettivo

Mai usare `DateTime.now()` per logica tenant-sensitive.

## Servizio da usare

`TenantTimeService`:

- `nowInTimezone(timezone)` — "adesso" nel timezone tenant
- `dateOnlyTodayInTimezone(timezone)` — "oggi" nel timezone tenant
- `fromUtcToTenant(value, timezone)` — conversione per visualizzazione
- `tenantLocalToUtc(value, timezone)` — conversione per invio/persistenza

## Linee guida

- Se una feature usa "oggi": leggere `tenantTodayProvider`.
- Se una feature usa "adesso": leggere `tenantNowProvider`.
- Se una feature riceve UTC da API: convertire con `fromUtcToTenant`.
- Se una feature invia orari locali tenant: convertire con `tenantLocalToUtc`.
- Non introdurre logica timezone basata sul timezone del device/browser.
- `booking_default_locale` non influenza logica temporale.
- `country` è metadato geografico, non usato per calcoli data/ora.
- Database timezone inizializzato in `lib/main.dart` con `tz_data.initializeTimeZones()`.
