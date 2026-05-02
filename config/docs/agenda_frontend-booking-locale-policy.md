# Booking Locale Policy (Country, Timezone, Language)

Questo documento definisce la policy ufficiale per la lingua del frontend prenotazioni (`agenda_frontend`).

## Obiettivo

Separare in modo esplicito:

- `country`: metadato geografico/amministrativo della location
- `timezone`: dato operativo per la logica temporale
- `locale/language`: lingua UI del booking

## Regole principali

1. `timezone` resta l'unica source of truth per disponibilità, slot, cutoff e logiche data/ora.
2. `country` non deve guidare la logica temporale.
3. `country` non è la regola primaria per la lingua; è solo fallback debole.
4. La lingua del booking è risolta centralmente da `BookingLocaleResolver`.

## Ordine di risoluzione lingua booking

1. query param URL `?lang=it|en`
2. `location.booking_default_locale`
3. locale browser/device supportata
4. hint da `location.country`
5. fallback finale deterministico: `it`

## Campo API usato dal booking

Le location pubbliche espongono:

- `booking_default_locale` (nullable, valori validi: `it`, `en`)

Se è `null`, il resolver passa ai fallback successivi.

## Test minimi coperti

- override URL prevale su tutto
- default location usato se presente
- fallback browser se supportato
- country hint solo come fallback debole
- fallback finale deterministico `it`

