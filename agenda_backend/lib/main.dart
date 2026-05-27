import 'package:agenda_backend/app/app.dart';
import 'package:agenda_backend/core/environment/app_environment_config.dart';
import 'package:agenda_backend/core/services/preferences_service.dart';
import 'package:agenda_backend/core/services/meta_whatsapp_callback_notifier.dart';
import 'package:agenda_backend/core/services/version_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb && Uri.base.path == '/auth/meta-whatsapp-callback') {
    notifyMetaWhatsappCallback();
    runApp(const _MetaWhatsappCallbackApp());
    return;
  }

  AppEnvironmentConfig.bootstrap();
  debugPrint(
    '[bootstrap] APP_ENV=${AppEnvironmentConfig.current.environmentName} API_BASE_URL=${AppEnvironmentConfig.current.apiBaseUrl}',
  );
  usePathUrlStrategy(); // Usa URL path-based (senza #)
  tz_data.initializeTimeZones();
  if (kIsWeb) {
    await BrowserContextMenu.disableContextMenu();
  }

  // Avvia il controllo periodico della versione solo su web non-debug.
  // Se rileva una nuova versione, forza il reload automatico.
  if (kIsWeb && !kDebugMode) {
    VersionChecker.instance.startPeriodicCheck();
  }

  // Inizializza SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class _MetaWhatsappCallbackApp extends StatelessWidget {
  const _MetaWhatsappCallbackApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Connessione Meta completata. Puoi chiudere questa finestra.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
