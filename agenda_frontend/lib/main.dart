import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'core/services/version_checker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Usa path URL strategy invece di hash (#) per URL puliti
  // Es: /vamps/booking invece di /#/vamps/booking
  usePathUrlStrategy();

  // Avvia il controllo periodico della versione (solo web).
  // Se rileva una nuova versione, forza il reload automatico.
  VersionChecker.instance.startPeriodicCheck();

  runApp(const ProviderScope(child: App()));
}
