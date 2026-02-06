// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Esegue un hard reload della pagina web (bypassa la cache)
void performHardReload() {
  // true = forza reload dal server, ignora cache
  html.window.location.reload();
  debugPrint('Performed hard reload of the page');
}
