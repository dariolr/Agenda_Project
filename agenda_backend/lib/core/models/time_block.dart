/// Rappresenta un blocco di non disponibilità nell'agenda.
///
/// Un blocco può essere assegnato a uno o più membri dello staff
/// per una fascia oraria specifica.
class TimeBlock {
  final int id;
  final int businessId;
  final int locationId;

  /// Lista degli ID degli staff a cui è assegnato il blocco.
  final List<int> staffIds;

  /// Inizio del blocco.
  final DateTime startTime;

  /// Fine del blocco.
  final DateTime endTime;

  /// Motivo opzionale del blocco (es. "Riunione", "Pausa pranzo", ecc.).
  final String? reason;

  /// Se true, il blocco copre l'intera giornata lavorativa.
  final bool isAllDay;

  const TimeBlock({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.staffIds,
    required this.startTime,
    required this.endTime,
    this.reason,
    this.isAllDay = false,
  });

  factory TimeBlock.fromJson(Map<String, dynamic> json) => TimeBlock(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    locationId: json['location_id'] as int,
    staffIds: (json['staff_ids'] as List<dynamic>)
        .map((id) => id as int)
        .toList(),
    startTime: DateTime.parse(json['start_time'] as String),
    endTime: DateTime.parse(json['end_time'] as String),
    reason: json['reason'] as String?,
    isAllDay: json['is_all_day'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'location_id': locationId,
    'staff_ids': staffIds,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    if (reason != null) 'reason': reason,
    'is_all_day': isAllDay,
  };

  TimeBlock copyWith({
    int? id,
    int? businessId,
    int? locationId,
    List<int>? staffIds,
    DateTime? startTime,
    DateTime? endTime,
    String? reason,
    bool? isAllDay,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      locationId: locationId ?? this.locationId,
      staffIds: staffIds ?? this.staffIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reason: reason ?? this.reason,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }

  /// Durata del blocco in minuti.
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Verifica se il blocco include uno specifico staff.
  bool includesStaff(int staffId) => staffIds.contains(staffId);

  /// Verifica se il blocco si sovrappone a un intervallo di tempo.
  bool overlaps(DateTime start, DateTime end) {
    return startTime.isBefore(end) && endTime.isAfter(start);
  }

  /// Verifica se il blocco è nella stessa data.
  bool isOnDate(DateTime date) {
    final blockDate = DateTime(startTime.year, startTime.month, startTime.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return blockDate == targetDate;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeBlock && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
