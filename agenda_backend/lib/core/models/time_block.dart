/// Rappresenta un blocco di non disponibilità nell'agenda.
class TimeBlock {
  final int id;
  final int businessId;
  final int locationId;
  final List<int> staffIds;
  final DateTime startTime;
  final DateTime endTime;
  final String? reason;
  final bool isAllDay;
  final bool allowOnlineBookingDuringBlock;

  // Recurrence
  final int? recurrenceRuleId;
  final int? recurrenceIndex;
  final bool isRecurrenceParent;

  const TimeBlock({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.staffIds,
    required this.startTime,
    required this.endTime,
    this.reason,
    this.isAllDay = false,
    this.allowOnlineBookingDuringBlock = false,
    this.recurrenceRuleId,
    this.recurrenceIndex,
    this.isRecurrenceParent = false,
  });

  bool get isRecurring => recurrenceRuleId != null;

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
    isAllDay: _asBool(json['is_all_day']),
    allowOnlineBookingDuringBlock: _asBool(
      json['allow_online_booking_during_block'],
    ),
    recurrenceRuleId: json['recurrence_rule_id'] as int?,
    recurrenceIndex: json['recurrence_index'] as int?,
    isRecurrenceParent: _asBool(json['is_recurrence_parent']),
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
    'allow_online_booking_during_block': allowOnlineBookingDuringBlock,
    if (recurrenceRuleId != null) 'recurrence_rule_id': recurrenceRuleId,
    if (recurrenceIndex != null) 'recurrence_index': recurrenceIndex,
    'is_recurrence_parent': isRecurrenceParent,
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
    bool? allowOnlineBookingDuringBlock,
    int? recurrenceRuleId,
    int? recurrenceIndex,
    bool? isRecurrenceParent,
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
      allowOnlineBookingDuringBlock:
          allowOnlineBookingDuringBlock ?? this.allowOnlineBookingDuringBlock,
      recurrenceRuleId: recurrenceRuleId ?? this.recurrenceRuleId,
      recurrenceIndex: recurrenceIndex ?? this.recurrenceIndex,
      isRecurrenceParent: isRecurrenceParent ?? this.isRecurrenceParent,
    );
  }

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  bool includesStaff(int staffId) => staffIds.contains(staffId);

  bool overlaps(DateTime start, DateTime end) {
    return startTime.isBefore(end) && endTime.isAfter(start);
  }

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

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    return false;
  }
}
