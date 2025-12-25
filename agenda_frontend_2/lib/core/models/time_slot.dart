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

  TimeSlot copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? staffId,
  }) =>
      TimeSlot(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        staffId: staffId ?? this.staffId,
      );

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        staffId: json['staff_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        if (staffId != null) 'staff_id': staffId,
      };
}
