# agenda_backend UI Rules (Flutter)

## Responsive

- Desktop: > 840px — usare Dialog/popup.
- Tablet/Mobile: < 840px — usare BottomSheet.
- Usare `formFactorProvider` per determinare form factor.

## Form Responsive

- Per form/modali responsive usare `showAppFormDialog(...)`, `AppForm.show(...)` o `AppBottomSheet.show(...)`.
- Non usare `showDialog(... AppFormDialog ...)` per flussi che possono essere aperti su tablet/mobile: su tablet/mobile deve essere usato un BottomSheet.
- `showDialog(... AppFormDialog ...)` è ammesso solo in rami esplicitamente desktop-only (`formFactor == AppFormFactor.desktop` oppure `else` di `if (formFactor != AppFormFactor.desktop)` / `if (useBottomSheet)`).
- Se una schermata distingue manualmente i form factor, la regola è:
  - mobile/tablet: `AppBottomSheet.show(...)`
  - desktop: `showDialog(...)`
- Dopo modifiche a form/dialog responsive, eseguire il check:

```bash
../config/scripts/checks/check_backend_app_form_dialog_usage.sh
```

## Testi e localizzazione

- Tutti i testi visibili usano `context.l10n` (import: `/core/l10n/l10_extension.dart`).
- Aggiungere chiavi in `lib/core/l10n/intl_it.arb` e `lib/core/l10n/intl_en.arb`.
- Dopo modifiche .arb: `dart run intl_utils:generate`.

## Stile

- Nessun ripple/splash effect invasivo.
- Usare `const` constructors dove possibile.
- Estrarre widget se `build()` supera 200 righe.
- Estetica sobria e coerente con l'esistente.

## Material e Ink

- Widget Material-interattivi (`ListTile`, `SwitchListTile`, `CheckboxListTile`, `RadioListTile`, `InkWell`, `InkResponse`, `Chip`, `FilterChip`, `ChoiceChip`, `InputChip`, `ActionChip`) devono avere un ancestor `Material` valido.
- Non avvolgere questi widget direttamente in `Container`/`DecoratedBox` con `color` o `BoxDecoration.color`: il background nasconde ink, hover, selected state e può generare warning/exception "No Material widget found".
- Se serve un background, metterlo sul `Material`:

```dart
Material(
  color: rowColor,
  borderRadius: borderRadius,
  child: ListTile(...),
)
```

- Se serve mantenere una decorazione complessa, usare `Material` come ancestor immediato o comunque non oscurato:

```dart
Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: onTap,
    child: DecoratedBox(...),
  ),
)
```

- Prima di introdurre righe con background alternato, hover color, chip cliccabili o menu basati su `ListTile`, verificare esplicitamente che gli effetti Material non siano nascosti da wrapper intermedi.

## Navigazione

- Usare `go_router` e le rotte definite in `lib/app/router.dart`.
- Non introdurre push diretti che bypassano il router.

## Code generation

- Dopo modifiche a file `@riverpod`: `dart run build_runner build --delete-conflicting-outputs`.
- Non lasciare generated file non aggiornati.

## Link esterni (HTTP/HTTPS)

- **Usare sempre** `ExternalLink` o `ExternalLinkButton` da `lib/core/widgets/external_link.dart`.
- `ExternalLink`: builder-based, per bottoni con rendering custom (es. spinner, stato disabilitato).
- `ExternalLinkButton`: drop-in `FilledButton` con spinner integrato durante caricamento.
- Entrambi aprono in nuova scheda via `Link` + `LinkTarget.blank` (evita blocco popup del browser).
- **Non usare** `launchUrl` con `LaunchMode.externalApplication` per URL HTTP/HTTPS.
- **Eccezione consentita**: `launchUrl` rimane corretto per schemi di sistema (`mailto:`, `tel:`, `sms:`, `whatsapp:`).
- Per link che richiedono una chiamata API preventiva (es. onboarding Stripe), pre-caricare l'URL in state e passarlo al widget; non chiamare API dentro `onPressed`.

## Commit checklist UI

- `flutter analyze` passa senza errori.
- Localizzazione aggiornata se nuovi testi.
- Nessun testo hardcoded senza chiave l10n.
- Link HTTP/HTTPS usano `ExternalLink`/`ExternalLinkButton` (non `launchUrl`).
