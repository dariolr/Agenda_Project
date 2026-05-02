# agenda_backend UI Rules (Flutter)

## Responsive

- Desktop: > 840px — usare Dialog/popup.
- Tablet/Mobile: < 840px — usare BottomSheet.
- Usare `formFactorProvider` per determinare form factor.

## Testi e localizzazione

- Tutti i testi visibili usano `context.l10n` (import: `/core/l10n/l10_extension.dart`).
- Aggiungere chiavi in `lib/core/l10n/intl_it.arb` e `lib/core/l10n/intl_en.arb`.
- Dopo modifiche .arb: `dart run intl_utils:generate`.

## Stile

- Nessun ripple/splash effect invasivo.
- Usare `const` constructors dove possibile.
- Estrarre widget se `build()` supera 200 righe.
- Estetica sobria e coerente con l'esistente.

## Navigazione

- Usare `go_router` e le rotte definite in `lib/app/router.dart`.
- Non introdurre push diretti che bypassano il router.

## Code generation

- Dopo modifiche a file `@riverpod`: `dart run build_runner build --delete-conflicting-outputs`.
- Non lasciare generated file non aggiornati.

## Commit checklist UI

- `flutter analyze` passa senza errori.
- Localizzazione aggiornata se nuovi testi.
- Nessun testo hardcoded senza chiave l10n.
