# agenda_frontend UI Rules (Flutter)

## Testi e localizzazione

- Tutti i testi visibili usano `context.l10n`.
- Aggiungere chiavi in `lib/core/l10n/intl_en.arb` e `lib/core/l10n/intl_it.arb`.
- Dopo modifiche .arb: `dart run intl_utils:generate`.

## Stile

- Usare `const` constructors dove possibile.
- Estrarre widget se `build()` supera 200 righe.
- Estetica sobria e coerente con il booking flow esistente.

## Navigazione

- Routing path-based con slug: `/:slug/...` via `go_router`.
- Non introdurre push diretti che bypassano il router.

## Link esterni (HTTP/HTTPS)

- **Usare sempre** `ExternalLink` o `ExternalLinkButton` da `lib/core/widgets/external_link.dart`.
- `ExternalLink`: builder-based, per bottoni con rendering custom (es. spinner, stato disabilitato).
- `ExternalLinkButton`: drop-in `FilledButton` con spinner integrato durante caricamento.
- Entrambi aprono in nuova scheda via `Link` + `LinkTarget.blank` (evita blocco popup del browser).
- **Non usare** `launchUrl` con `LaunchMode.externalApplication` per URL HTTP/HTTPS.
- **Eccezione consentita**: `launchUrl` rimane corretto per schemi di sistema (`mailto:`, `tel:`, `sms:`).
- **Eccezione consentita**: `redirectSameTab(url)` rimane corretto per redirect full-page nello stesso tab (es. redirect a Stripe Checkout dopo conferma prenotazione).

## Commit checklist UI

- `flutter analyze` passa senza errori.
- Localizzazione aggiornata se nuovi testi.
- Nessun testo hardcoded senza chiave l10n.
- Link HTTP/HTTPS usano `ExternalLink`/`ExternalLinkButton` (non `launchUrl`).
