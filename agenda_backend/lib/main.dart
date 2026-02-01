import 'package:agenda_backend/app/app.dart';
import 'package:agenda_backend/core/services/preferences_service.dart';
import 'package:agenda_backend/core/services/version_checker.dart';
import 'package:agenda_backend/core/utils/timezone_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Usa URL path-based (senza #)

  // Inizializza il database dei timezone
  TimezoneHelper.initialize();

  // Avvia il controllo periodico della versione (solo web).
  // Se rileva una nuova versione, forza il reload automatico.
  VersionChecker.instance.startPeriodicCheck();

  // Inizializza SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}
