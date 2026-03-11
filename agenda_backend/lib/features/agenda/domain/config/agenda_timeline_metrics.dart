/// Source of truth unica per la metrica verticale della timeline agenda.
///
/// La viewport decide solo quanta parte della timeline e' visibile tramite
/// scroll; la conversione tempo <-> pixel resta stabile su tutti i device.
class AgendaTimelineMetrics {
  const AgendaTimelineMetrics._();

  static const int dayMinutes = 24 * 60;

  /// Source of truth verticale della timeline.
  static const double pixelsPerMinute = 2.0;

  static double slotHeightFor(int minutesPerSlot) {
    return heightForMinutes(minutesPerSlot.toDouble());
  }

  static double heightForMinutes(double minutes) {
    return minutes * pixelsPerMinute;
  }

  static double topOffsetForMinuteOfDay(double minuteOfDay) {
    return heightForMinutes(minuteOfDay);
  }

  static double minutesForHeight(double height) {
    if (pixelsPerMinute == 0) return 0;
    return height / pixelsPerMinute;
  }

  static double timelineHeightForMinutes(int totalMinutes) {
    return heightForMinutes(totalMinutes.toDouble());
  }
}
