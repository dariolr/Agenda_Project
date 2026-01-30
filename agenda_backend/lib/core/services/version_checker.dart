import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'version_checker_stub.dart'
    if (dart.library.html) 'version_checker_web.dart';

/// Service che controlla periodicamente se c'è una nuova versione dell'app.
/// Se rileva un aggiornamento, forza il reload automatico della pagina.
///
/// Usa il file `app_version.txt` che contiene solo la stringa versione
/// (es. "20260129-1.6"). Questo file deve essere generato/aggiornato
/// manualmente durante il deploy.
class VersionChecker {
  static VersionChecker? _instance;
  static VersionChecker get instance => _instance ??= VersionChecker._();

  VersionChecker._();

  Timer? _timer;
  String? _currentVersion;
  bool _isChecking = false;

  /// Intervallo di controllo (default: 60 secondi)
  static const _checkInterval = Duration(seconds: 60);

  /// Avvia il controllo periodico della versione.
  /// Chiamare una sola volta all'avvio dell'app.
  void startPeriodicCheck() {
    // Solo su web
    if (!kIsWeb) return;

    // Evita avvii multipli
    if (_timer != null) return;

    debugPrint('VersionChecker: Starting periodic version check');

    // Primo check immediato per salvare la versione corrente
    _checkVersion();

    // Check periodico
    _timer = Timer.periodic(_checkInterval, (_) => _checkVersion());
  }

  /// Ferma il controllo periodico
  void stopPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkVersion() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // Fetch app_version.txt con cache-busting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http
          .get(Uri.parse('/app_version.txt?_=$timestamp'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final serverVersion = response.body.trim();

        if (serverVersion.isNotEmpty) {
          if (_currentVersion == null) {
            // Prima esecuzione: salva la versione corrente
            _currentVersion = serverVersion;
            debugPrint('VersionChecker: Initial version: $_currentVersion');
          } else if (_currentVersion != serverVersion) {
            // Versione cambiata: forza reload
            debugPrint(
              'VersionChecker: New version detected! '
              '$_currentVersion -> $serverVersion. Reloading...',
            );
            forceReload();
          }
        }
      }
    } catch (e) {
      // Ignora errori di rete - riproverà al prossimo ciclo
      debugPrint('VersionChecker: Check failed: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Forza il reload della pagina (solo web)
  void forceReload() {
    performHardReload();
  }
}
