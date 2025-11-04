#!/bin/bash
# 🚀 Agenda Platform — Flutter Project Structure Generator
# Usage: bash setup_structure.sh [feature_name]
# If no feature name is passed, it defaults to "agenda"

FEATURE=${1:-agenda}

echo "📁 Creating Flutter structure for feature: $FEATURE ..."

mkdir -p lib/{app/{theme,},core/{models,network,utils},features/$FEATURE/{data,domain,presentation,providers}}

# Feature (dynamic)
touch \
lib/features/$FEATURE/data/{${FEATURE}_repository.dart,${FEATURE}_api.dart} \
lib/features/$FEATURE/domain/${FEATURE}.dart \
lib/features/$FEATURE/presentation/${FEATURE}_screen.dart \
lib/features/$FEATURE/providers/${FEATURE}_providers.dart 

echo "✅ Structure created successfully!"
echo "Feature created: $FEATURE"
