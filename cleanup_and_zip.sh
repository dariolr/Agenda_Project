#!/bin/bash
# 🔹 Script di pulizia e creazione archivio aggiornato per Agenda Platform
# Usa: bash cleanup_and_zip.sh

echo "🚀 Avvio processo di pulizia del progetto..."

# 1️⃣ Verifica di essere nella root del progetto
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Errore: esegui questo script nella cartella principale del progetto (dove c'è pubspec.yaml)"
  exit 1
fi

# 2️⃣ Rimozione file e cartelle inutili
echo "🧹 Rimozione file inutilizzati..."
rm -f lib/features/agenda/data/agenda_api.dart 2>/dev/null
rm -f lib/features/agenda/data/agenda_repository.dart 2>/dev/null
rm -f lib/shared/styles/colors.dart 2>/dev/null
rm -f lib/shared/styles/spacing.dart 2>/dev/null
rm -f lib/shared/styles/typography.dart 2>/dev/null
rm -f lib/shared/widgets/app_card.dart 2>/dev/null
rm -f lib/shared/widgets/app_button.dart 2>/dev/null
rm -f lib/shared/widgets/app_loading.dart 2>/dev/null

# 3️⃣ Aggiornamento del pubspec.yaml
echo "📝 Aggiornamento del pubspec.yaml..."

cat > pubspec.yaml <<'EOF'
name: agenda_frontend
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.0.3
  riverpod_annotation: ^3.0.3
  go_router: ^16.2.4

dev_dependencies:
  build_runner: ^2.7.1
  riverpod_generator: ^3.0.3
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
EOF

# 4️⃣ Pulizia vecchi artefatti di build
echo "🧱 Pulizia build..."
flutter clean >/dev/null 2>&1

# 5️⃣ Creazione dello zip aggiornato
ZIP_NAME="agenda_platform_clean_16_ottobre.zip"
echo "📦 Creazione archivio $ZIP_NAME..."
zip -r "$ZIP_NAME" lib pubspec.yaml >/dev/null

# 6️⃣ Conclusione
echo "✅ Operazione completata!"
echo "👉 Archivio generato: $ZIP_NAME"
echo "📂 Si trova nella directory corrente."
