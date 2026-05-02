# agenda_backend Test Commands

## Comandi principali

```bash
# Tutti i test
flutter test

# Coverage
flutter test --coverage

# Analisi statica
flutter analyze

# Code generation (dopo modifiche @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Localizzazione (dopo modifiche .arb)
dart run intl_utils:generate
```

## Build e run

```bash
# Web (development)
flutter run -d chrome

# Web (production build)
flutter build web --release --no-tree-shake-icons

# Desktop (macOS)
flutter run -d macos
```

## Troubleshooting

```bash
# "Provider not found" dopo modifiche Riverpod
dart run build_runner build --delete-conflicting-outputs

# "Missing localizations"
dart run intl_utils:generate
flutter clean && flutter pub get

# Backend non raggiungibile
cd ../agenda_core && php -S localhost:8080 -t public
```
