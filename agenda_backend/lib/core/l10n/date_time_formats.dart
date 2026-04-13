import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper centralizzati per formattare date e orari in base alla locale corrente.
class DtFmt {
  DtFmt._();

  static bool use24h(BuildContext context) {
    return MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
  }

  static String localeTag(BuildContext context) {
    return Localizations.localeOf(context).toLanguageTag();
  }

  /// HH:mm secondo la locale; su it rimane 24h, su en può essere 12/24 in base alle impostazioni.
  static String hm(BuildContext context, int hour, int minute) {
    final localizations = MaterialLocalizations.of(context);
    final time = TimeOfDay(hour: hour, minute: minute);
    return localizations.formatTimeOfDay(
      time,
      alwaysUse24HourFormat: use24h(context),
    );
  }

  /// Etichetta ora piena (senza minuti): es. "09:00" o "9 AM" a seconda locale.
  static String hOnly(BuildContext context, int hour) {
    return hm(context, hour, 0);
  }

  /// Giorno breve localizzato per intestazioni (Lun, Mar, ... / Mon, Tue, ...)
  static String weekdayShort(BuildContext context, int weekdayIso) {
    final locale = localeTag(context);
    final now = DateTime.now();
    final base = now.subtract(Duration(days: now.weekday - weekdayIso));
    return DateFormat.E(locale).format(base);
  }

  /// Data compatta per form: "sab 6 dic 25" / "Sat 6 Dec 25"
  static String shortDate(BuildContext context, DateTime date) {
    final locale = localeTag(context);
    // E = giorno settimana abbreviato, d = giorno, MMM = mese abbreviato, yy = anno a 2 cifre
    return DateFormat('E d MMM yy', locale).format(date);
  }

  /// Data estesa localizzata: es. "sabato 14 febbraio 2026" / "Saturday, February 14, 2026".
  static String longDate(BuildContext context, DateTime date) {
    final locale = localeTag(context);
    return DateFormat.yMMMMEEEEd(locale).format(date);
  }
}
