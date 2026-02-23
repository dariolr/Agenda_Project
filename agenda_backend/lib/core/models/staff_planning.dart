import 'package:flutter/foundation.dart';

/// Tipo di pianificazione settimanale.
enum StaffPlanningType {
  /// Pianificazione settimanale standard (template A).
  weekly,

  /// Pianificazione bisettimanale (template A/B alternati).
  biweekly,
}

/// Label della settimana per biweekly.
enum WeekLabel {
  /// Prima settimana del ciclo.
  a,

  /// Seconda settimana del ciclo.
  b,
}

/// Rappresenta una pianificazione settimanale o bisettimanale di uno staff.
///
/// Una pianificazione ha un intervallo di validità [validFrom, validTo]
/// dove validTo può essere null per indicare "senza scadenza".
///
/// Per uno staff, in una data D esiste al massimo un planning valido
/// (nessuna sovrapposizione di intervalli).
@immutable
class StaffPlanning {
  static const int planningStepMinutes = 5;
  static const int defaultPlanningSlotMinutes = planningStepMinutes;

  final int id;
  final int staffId;
  final StaffPlanningType type;

  /// Data di inizio validità (inclusa).
  final DateTime validFrom;

  /// Data di fine validità (inclusa). Se null, la pianificazione non ha scadenza.
  final DateTime? validTo;

  /// Template settimanali. Per weekly contiene solo weekLabel=A.
  /// Per biweekly contiene sia A che B.
  final List<StaffPlanningWeekTemplate> templates;

  final DateTime createdAt;
  final DateTime? updatedAt;

  int get planningSlotMinutes => planningStepMinutes;

  const StaffPlanning({
    required this.id,
    required this.staffId,
    required this.type,
    required this.validFrom,
    this.validTo,
    required this.templates,
    required this.createdAt,
    this.updatedAt,
  });

  /// Se true, la pianificazione è valida indefinitamente.
  bool get isOpenEnded => validTo == null;

  /// Verifica se la pianificazione è valida per una data D.
  /// Usa intervalli chiusi-chiusi: [validFrom, validTo].
  bool isValidForDate(DateTime date) {
    final d = DateUtils.dateOnly(date);
    final from = DateUtils.dateOnly(validFrom);

    if (d.isBefore(from)) return false;
    if (validTo == null) return true;

    final to = DateUtils.dateOnly(validTo!);
    return !d.isAfter(to);
  }

  /// Ottiene il template per la settimana A.
  StaffPlanningWeekTemplate? get templateA =>
      templates.where((t) => t.weekLabel == WeekLabel.a).firstOrNull;

  /// Ottiene il template per la settimana B.
  StaffPlanningWeekTemplate? get templateB =>
      templates.where((t) => t.weekLabel == WeekLabel.b).firstOrNull;

  /// Ottiene il template da usare per una data specifica.
  /// Per weekly restituisce sempre template A.
  /// Per biweekly calcola se siamo in settimana A o B.
  StaffPlanningWeekTemplate? getTemplateForDate(DateTime date) {
    if (type == StaffPlanningType.weekly) {
      return templateA;
    }

    final weekLabel = computeWeekLabel(date);
    return weekLabel == WeekLabel.a ? templateA : templateB;
  }

  /// Totale ore settimanali del template attivo per questo planning.
  double totalWeeklyHoursForTemplate(WeekLabel label) {
    final template = label == WeekLabel.a ? templateA : templateB;
    if (template == null) return 0;
    return template.totalWeeklyHoursFor(
      minutesPerSlot: planningStepMinutes,
    );
  }

  /// Calcola la label della settimana (A/B) per una data.
  /// Per weekly ritorna sempre A.
  WeekLabel computeWeekLabel(DateTime date) {
    if (type == StaffPlanningType.weekly) return WeekLabel.a;

    final d = DateUtils.dateOnly(date);
    final from = DateUtils.dateOnly(validFrom);

    // delta_days = D - valid_from
    final deltaDays = d.difference(from).inDays;

    // week_index = floor(delta_days / 7)
    final weekIndex = deltaDays ~/ 7;

    // pari → A, dispari → B
    return weekIndex.isEven ? WeekLabel.a : WeekLabel.b;
  }

  StaffPlanning copyWith({
    int? id,
    int? staffId,
    StaffPlanningType? type,
    DateTime? validFrom,
    DateTime? Function()? validTo,
    List<StaffPlanningWeekTemplate>? templates,
    DateTime? createdAt,
    DateTime? Function()? updatedAt,
  }) {
    return StaffPlanning(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      type: type ?? this.type,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo != null ? validTo() : this.validTo,
      templates: templates ?? this.templates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  factory StaffPlanning.fromJson(Map<String, dynamic> json) {
    return StaffPlanning(
      id: json['id'] as int,
      staffId: json['staff_id'] as int,
      type: StaffPlanningType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => StaffPlanningType.weekly,
      ),
      validFrom: DateTime.parse(json['valid_from'] as String),
      validTo: json['valid_to'] != null
          ? DateTime.parse(json['valid_to'] as String)
          : null,
      templates: (json['templates'] as List<dynamic>? ?? [])
          .map(
            (t) =>
                StaffPlanningWeekTemplate.fromJson(t as Map<String, dynamic>),
          )
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'type': type.name,
      'valid_from': _dateToIso(validFrom),
      'valid_to': validTo != null ? _dateToIso(validTo!) : null,
      'templates': templates.map((t) => t.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static String _dateToIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffPlanning &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          staffId == other.staffId &&
          type == other.type &&
          validFrom == other.validFrom &&
          validTo == other.validTo;

  @override
  int get hashCode => Object.hash(
    id,
    staffId,
    type,
    validFrom,
    validTo,
  );

  @override
  String toString() =>
      'StaffPlanning(id: $id, staffId: $staffId, type: $type, '
      'validFrom: ${_dateToIso(validFrom)}, '
      'validTo: ${validTo != null ? _dateToIso(validTo!) : 'null'})';
}

/// Template di una settimana con gli slot per ogni giorno.
///
/// Per ogni giorno della settimana (1-7, Mon-Sun) contiene gli slot disponibili
/// come `Set<int>` dove ogni int è l'indice dello slot (es. 108 = 09:00 con step planning da 5 min).
@immutable
class StaffPlanningWeekTemplate {
  final int id;
  final int staffPlanningId;
  final WeekLabel weekLabel;

  /// Mappa: day_of_week (1-7) -> Set di slot index.
  /// 1 = Monday, 7 = Sunday.
  /// Slot vuoto o assente = giorno non disponibile.
  final Map<int, Set<int>> daySlots;

  const StaffPlanningWeekTemplate({
    required this.id,
    required this.staffPlanningId,
    required this.weekLabel,
    required this.daySlots,
  });

  /// Verifica se il giorno ha slot definiti.
  bool hasSlots(int dayOfWeek) {
    final slots = daySlots[dayOfWeek];
    return slots != null && slots.isNotEmpty;
  }

  /// Ottiene gli slot per un giorno specifico.
  Set<int> getSlotsForDay(int dayOfWeek) => daySlots[dayOfWeek] ?? const {};

  /// Calcola le ore totali settimanali assumendo lo step planning di default.
  double get totalWeeklyHours {
    return totalWeeklyHoursFor(
      minutesPerSlot: StaffPlanning.planningStepMinutes,
    );
  }

  /// Calcola le ore totali settimanali usando lo step planning specificato.
  double totalWeeklyHoursFor({required int minutesPerSlot}) {
    int totalSlots = 0;
    for (final slots in daySlots.values) {
      totalSlots += slots.length;
    }
    return totalSlots * minutesPerSlot / 60;
  }

  StaffPlanningWeekTemplate copyWith({
    int? id,
    int? staffPlanningId,
    WeekLabel? weekLabel,
    Map<int, Set<int>>? daySlots,
  }) {
    return StaffPlanningWeekTemplate(
      id: id ?? this.id,
      staffPlanningId: staffPlanningId ?? this.staffPlanningId,
      weekLabel: weekLabel ?? this.weekLabel,
      daySlots: daySlots ?? this.daySlots,
    );
  }

  factory StaffPlanningWeekTemplate.fromJson(Map<String, dynamic> json) {
    // Parse day_slots: può essere array di {day_of_week, slots} o mappa diretta
    final Map<int, Set<int>> daySlots = {};

    final rawSlots = json['day_slots'] ?? json['slots'];
    if (rawSlots is List) {
      // Formato: [{day_of_week: 1, slots: [36, 37, ...]}, ...]
      for (final item in rawSlots) {
        if (item is Map<String, dynamic>) {
          final day = item['day_of_week'] as int;
          final slots = (item['slots'] as List<dynamic>? ?? [])
              .map((s) => s as int)
              .toSet();
          daySlots[day] = slots;
        }
      }
    } else if (rawSlots is Map) {
      // Formato: {"1": [36, 37, ...], "2": [...], ...}
      rawSlots.forEach((key, value) {
        final day = int.tryParse(key.toString()) ?? 0;
        if (day >= 1 && day <= 7 && value is List) {
          daySlots[day] = value.map((s) => s as int).toSet();
        }
      });
    }

    return StaffPlanningWeekTemplate(
      id: json['id'] as int? ?? 0,
      staffPlanningId: json['staff_planning_id'] as int? ?? 0,
      weekLabel: WeekLabel.values.firstWhere(
        (l) => l.name == (json['week_label'] as String?)?.toLowerCase(),
        orElse: () => WeekLabel.a,
      ),
      daySlots: daySlots,
    );
  }

  Map<String, dynamic> toJson() {
    // Converti daySlots in formato lista per JSON
    final List<Map<String, dynamic>> slotsJson = [];
    for (int day = 1; day <= 7; day++) {
      final slots = daySlots[day];
      if (slots != null) {
        slotsJson.add({'day_of_week': day, 'slots': slots.toList()..sort()});
      }
    }

    return {
      'id': id,
      'staff_planning_id': staffPlanningId,
      'week_label': weekLabel.name.toUpperCase(),
      'day_slots': slotsJson,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffPlanningWeekTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          staffPlanningId == other.staffPlanningId &&
          weekLabel == other.weekLabel &&
          mapEquals(daySlots, other.daySlots);

  @override
  int get hashCode => Object.hash(id, staffPlanningId, weekLabel);

  @override
  String toString() =>
      'StaffPlanningWeekTemplate(id: $id, weekLabel: ${weekLabel.name}, '
      'days: ${daySlots.keys.toList()..sort()})';
}

/// Estensione helper per DateUtils.
extension DateUtils on DateTime {
  /// Ritorna la data senza componente oraria (mezzanotte).
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
