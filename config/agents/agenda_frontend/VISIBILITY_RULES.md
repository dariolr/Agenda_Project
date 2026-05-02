# agenda_frontend Visibility Rules

## Visibilità online

Il booking pubblico mostra solo elementi con visibilità `pubblico`.

| Valore visibilità | Comportamento nel booking pubblico |
|-------------------|------------------------------------|
| `pubblico` | Visibile e prenotabile |
| `non prenotabile online` | Non visibile |
| `solo direct link` | Visibile/prenotabile solo tramite link diretto valido |

## Direct link

- Se il flow è avviato tramite link diretto, rispettare la restrizione di visibilità `direct_link`.
- Non mostrare elementi `direct_link` nel listing pubblico normale.
- La validazione del direct link avviene server-side.

## Lingua booking

Ordine di risoluzione lingua (rispettare obbligatoriamente):

1. Query param URL `?lang=it|en`
2. `location.booking_default_locale`
3. Locale browser/device (se supportata)
4. Hint da `location.country` (fallback debole)
5. Fallback finale deterministico: `it`

Riferimento: `config/docs/agenda_frontend-booking-locale-policy.md`

## Regole

- Non mostrare nel booking pubblico elementi `non prenotabile online` o `direct_link`.
- Non modificare la logica di risoluzione lingua senza task esplicito.
- `booking_default_locale` non influenza timezone.
- `country` è metadato geografico, non usato per calcoli data/ora.
