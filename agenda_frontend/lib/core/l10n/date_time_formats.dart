import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Helper centralizzati per formattare date e orari in base alla locale corrente.
class DtFmt {
  DtFmt._();

  /// HH:mm secondo la locale; su it rimane 24h, su en può essere 12/24 in base alle impostazioni.
  static String hm(BuildContext context, int hour, int minute) {
    final locale = Intl.getCurrentLocale();
    final dt = DateTime(0, 1, 1, hour, minute);
    // Prefer format 'HH:mm' but respect locale by using DateFormat.Hm
    return DateFormat.Hm(locale).format(dt);
  }

  /// Etichetta ora piena (senza minuti): es. "09:00" o "9 AM" a seconda locale.
  static String hOnly(BuildContext context, int hour) {
    final locale = Intl.getCurrentLocale();
    final dt = DateTime(0, 1, 1, hour, 0);
    return DateFormat.Hm(locale).format(dt);
  }

  /// Giorno breve localizzato per intestazioni (Lun, Mar, ... / Mon, Tue, ...)
  static String weekdayShort(BuildContext context, int weekdayIso) {
    final locale = Intl.getCurrentLocale();
    final now = DateTime.now();
    final base = now.subtract(Duration(days: now.weekday - weekdayIso));
    return DateFormat.E(locale).format(base);
  }

  /// Data compatta per form: "sab 6 dic 25" / "Sat 6 Dec 25"
  static String shortDate(BuildContext context, DateTime date) {
    final locale = Intl.getCurrentLocale();
    // E = giorno settimana abbreviato, d = giorno, MMM = mese abbreviato, yy = anno a 2 cifre
    return DateFormat('E d MMM yy', locale).format(date);
  }
}
