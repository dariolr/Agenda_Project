# Timezone Policy (Location-first)

Questo documento definisce la policy ufficiale di gestione date/ora in `agenda_backend`.

## Obiettivo

L'app deve comportarsi come se l'operatore fosse sempre nella stessa localizzazione della location/business selezionata, indipendentemente dal timezone impostato su browser/dispositivo.

## Regola di risoluzione timezone

Ordine obbligatorio:

1. `location.timezone` della location corrente
2. fallback `business.timezone`
3. fallback finale `Europe/Rome`

La risoluzione è implementata in:
- `lib/features/agenda/providers/tenant_time_provider.dart`
- `lib/core/services/tenant_time_service.dart`

## Source of truth applicativa

Per logica business/UI usare sempre:

- `effectiveTenantTimezoneProvider`
- `tenantNowProvider`
- `tenantTodayProvider`

Evitare `DateTime.now()` per logiche tenant-sensitive.

## Conversioni date/ora

Usare `TenantTimeService`:

- `nowInTimezone(timezone)` per "adesso" tenant
- `dateOnlyTodayInTimezone(timezone)` per "oggi" tenant
- `fromUtcToTenant(value, timezone)` per visualizzazione locale tenant
- `tenantLocalToUtc(value, timezone)` per invio/persistenza in UTC

## Inizializzazione timezone

Il database timezone è inizializzato in avvio app:

- `lib/main.dart`
- `tz_data.initializeTimeZones()`

## Linee guida per nuove feature

1. Se una feature usa "oggi", leggere `tenantTodayProvider`.
2. Se una feature usa "adesso", leggere `tenantNowProvider`.
3. Se una feature riceve UTC da API, convertire con `fromUtcToTenant`.
4. Se una feature invia orari locali tenant, convertire con `tenantLocalToUtc`.
5. Non introdurre nuova logica timezone basata sul timezone del device.

## Note operative

- `normalizeTimezone` valida il timezone e applica fallback sicuro.
- I provider timezone sono business/location-scoped: quando cambia business/location, ricalcolare i dati dipendenti.
