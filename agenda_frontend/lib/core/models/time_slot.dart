/// Slot temporale disponibile per la prenotazione
class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final int? staffId;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    this.staffId,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  String get formattedTime {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeSlot copyWith({DateTime? startTime, DateTime? endTime, int? staffId}) =>
      TimeSlot(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        staffId: staffId ?? this.staffId,
      );

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    // Parse mantenendo l'orario originale (timezone del business)
    // DateTime.parse converte in UTC, quindi usiamo toLocal per evitare
    // confusione, MA il problema è che toLocal usa il timezone del DISPOSITIVO.
    // La soluzione corretta è estrarre l'orario "naive" ignorando il timezone.
    final startStr = json['start_time'] as String;
    final endStr = json['end_time'] as String;

    return TimeSlot(
      startTime: _parseAsLocalTime(startStr),
      endTime: _parseAsLocalTime(endStr),
      staffId: json['staff_id'] as int?,
    );
  }

  /// Parse una stringa ISO8601 estraendo solo l'orario locale,
  /// ignorando il timezone offset. Questo mantiene l'orario
  /// come visualizzato nel business.
  static DateTime _parseAsLocalTime(String isoString) {
    // Rimuovi l'offset timezone dalla stringa
    // Es: "2026-01-10T10:00:00+07:00" -> "2026-01-10T10:00:00"
    final withoutOffset = isoString.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '');
    // Rimuovi anche eventuale 'Z' per UTC
    final cleaned = withoutOffset.replaceAll('Z', '');
    return DateTime.parse(cleaned);
  }

  Map<String, dynamic> toJson() => {
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    if (staffId != null) 'staff_id': staffId,
  };
}
