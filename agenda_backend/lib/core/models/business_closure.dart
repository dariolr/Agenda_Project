import 'package:flutter/foundation.dart';

/// Rappresenta un periodo di chiusura dell'attività (es. festività, ferie collettive)
@immutable
class BusinessClosure {
  final int id;
  final int businessId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessClosure({
    required this.id,
    required this.businessId,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  /// Numero di giorni del periodo di chiusura (inclusivo)
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Verifica se una data specifica rientra nel periodo di chiusura
  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  /// Verifica se due periodi si sovrappongono
  bool overlapsWith(BusinessClosure other) {
    return !(endDate.isBefore(other.startDate) ||
        startDate.isAfter(other.endDate));
  }

  factory BusinessClosure.fromJson(Map<String, dynamic> json) {
    return BusinessClosure(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      if (reason != null) 'reason': reason,
    };
  }

  BusinessClosure copyWith({
    int? id,
    int? businessId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessClosure(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessClosure &&
        other.id == id &&
        other.businessId == businessId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.reason == reason;
  }

  @override
  int get hashCode {
    return Object.hash(id, businessId, startDate, endDate, reason);
  }

  @override
  String toString() {
    return 'BusinessClosure(id: $id, startDate: $startDate, endDate: $endDate, reason: $reason)';
  }
}
