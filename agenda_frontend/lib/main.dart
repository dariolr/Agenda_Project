import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'app/app.dart';
import 'app/providers/route_slug_provider.dart';
import 'core/environment/app_environment_config.dart';
import 'core/services/version_checker.dart';

/// Estrae lo slug del business dall'URL corrente prima che il router lo processi.
/// Stessa logica di _reservedPaths in router.dart.
String? _extractInitialSlug() {
  final segments = Uri.base.pathSegments
      .where((s) => s.isNotEmpty)
      .toList();
  if (segments.isEmpty) return null;
  final slug = segments.first;
  const reserved = {
    'reset-password', 'login', 'register', 'booking',
    'my-bookings', 'change-password', 'profile', 'privacy', 'terms',
  };
  if (reserved.contains(slug)) return null;
  return slug;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironmentConfig.bootstrap();
  debugPrint(
    '[bootstrap] APP_ENV=${AppEnvironmentConfig.current.environmentName} API_BASE_URL=${AppEnvironmentConfig.current.apiBaseUrl}',
  );
  tz_data.initializeTimeZones();

  // Usa path URL strategy invece di hash (#) per URL puliti
  // Es: /vamps/booking invece di /#/vamps/booking
  usePathUrlStrategy();

  // Avvia il controllo periodico della versione solo su web non-debug.
  // Se rileva una nuova versione, forza il reload automatico.
  if (kIsWeb && !kDebugMode) {
    VersionChecker.instance.startPeriodicCheck();
  }

  // Inizializza routeSlugProvider dal URL corrente prima del primo build,
  // evitando il flash "business non trovato" causato dal microtask del router.
  runApp(ProviderScope(
    overrides: [
      routeSlugProvider.overrideWith((ref) => _extractInitialSlug()),
    ],
    child: const App(),
  ));
}
