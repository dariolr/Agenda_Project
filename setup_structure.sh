#!/bin/bash
# 🚀 Agenda Platform — Flutter Project Structure Generator
# Usage: bash setup_structure.sh [feature_name]
# If no feature name is passed, it defaults to "agenda"

FEATURE=${1:-agenda}

echo "📁 Creating Flutter project structure for feature: $FEATURE ..."

mkdir -p lib/{app/{theme,},core/{models,network,utils},features/$FEATURE/{data,domain,presentation,providers},shared/{widgets,styles}}

# Common App Layer
touch \
lib/app/app.dart \
lib/app/router.dart \
lib/app/theme/theme_config.dart \
lib/app/theme/theme_provider.dart \
lib/app/theme/theme.dart

# Core
touch \
lib/core/models/{appointment.dart,staff.dart} \
lib/core/network/api_client.dart \
lib/core/utils/date_utils.dart

# Feature (dynamic)
touch \
lib/features/$FEATURE/data/{${FEATURE}_repository.dart,${FEATURE}_api.dart} \
lib/features/$FEATURE/domain/.gitkeep \
lib/features/$FEATURE/presentation/${FEATURE}_screen.dart \
lib/features/$FEATURE/providers/${FEATURE}_providers.dart

# Shared widgets and styles
touch \
lib/shared/widgets/{app_button.dart,app_card.dart,app_loading.dart} \
lib/shared/styles/{colors.dart,typography.dart,spacing.dart}

# Main entry point
touch lib/main.dart

echo "✅ Structure created successfully!"
echo "Feature created: $FEATURE"
