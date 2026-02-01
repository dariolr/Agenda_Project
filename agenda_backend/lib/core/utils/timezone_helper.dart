import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Helper per la gestione dei timezone.
/// Usa il package `timezone` per calcolare l'orario corrente
/// in un fuso orario specifico.
class TimezoneHelper {
  static bool _initialized = false;

  /// Inizializza il database dei timezone.
  /// Deve essere chiamato una volta all'avvio dell'app.
  static void initialize() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }

  /// Restituisce il DateTime corrente nel timezone specificato.
  /// [timezone] deve essere un identificatore IANA valido (es. 'Europe/Rome').
  static DateTime nowInTimezone(String timezone) {
    initialize();
    try {
      final location = tz.getLocation(timezone);
      final tzNow = tz.TZDateTime.now(location);
      // Convertiamo in DateTime normale mantenendo i valori
      return DateTime(
        tzNow.year,
        tzNow.month,
        tzNow.day,
        tzNow.hour,
        tzNow.minute,
        tzNow.second,
        tzNow.millisecond,
      );
    } catch (e) {
      // Fallback a Europe/Rome se timezone non valido
      return nowInTimezone('Europe/Rome');
    }
  }

  /// Restituisce solo la data odierna nel timezone specificato.
  static DateTime todayInTimezone(String timezone) {
    final now = nowInTimezone(timezone);
    return DateTime(now.year, now.month, now.day);
  }
}
