# agenda_frontend Test Commands

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
# Web (development, local)
flutter run -d chrome \
  --dart-define=APP_ENV=local \
  --dart-define=API_BASE_URL=http://localhost:8888/agenda_core/public \
  --dart-define=FRONTEND_URL=http://localhost:3000

# Build produzione
flutter build web --release --no-tree-shake-icons

# Deploy SiteGround
cp web/.htaccess build/web/
rsync -avz --delete -e "ssh -p 18765" build/web/ siteground:~/www/prenota.romeolab.it/public_html/
```

## Troubleshooting

```bash
# Mancata generazione provider
dart run build_runner build --delete-conflicting-outputs

# Localizzazioni mancanti
dart run intl_utils:generate
flutter clean && flutter pub get
```
