/// Modello per le regole di ricorrenza delle prenotazioni
class RecurrenceRule {
  final int id;
  final int businessId;
  final RecurrenceFrequency frequency;
  final int intervalValue;
  final int? maxOccurrences;
  final DateTime? endDate;
  final ConflictStrategy conflictStrategy;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurrenceRule({
    required this.id,
    required this.businessId,
    required this.frequency,
    this.intervalValue = 1,
    this.maxOccurrences,
    this.endDate,
    this.conflictStrategy = ConflictStrategy.skip,
    this.daysOfWeek,
    this.dayOfMonth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      frequency: RecurrenceFrequency.fromString(json['frequency'] as String),
      intervalValue: json['interval_value'] as int? ?? 1,
      maxOccurrences: json['max_occurrences'] as int?,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      conflictStrategy: ConflictStrategy.fromString(
        json['conflict_strategy'] as String? ?? 'skip',
      ),
      daysOfWeek: json['days_of_week'] != null
          ? List<int>.from(json['days_of_week'] as List)
          : null,
      dayOfMonth: json['day_of_month'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'frequency': frequency.value,
    'interval_value': intervalValue,
    if (maxOccurrences != null) 'max_occurrences': maxOccurrences,
    if (endDate != null) 'end_date': endDate!.toIso8601String().split('T')[0],
    'conflict_strategy': conflictStrategy.value,
    if (daysOfWeek != null) 'days_of_week': daysOfWeek,
    if (dayOfMonth != null) 'day_of_month': dayOfMonth,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  RecurrenceRule copyWith({
    int? id,
    int? businessId,
    RecurrenceFrequency? frequency,
    int? intervalValue,
    int? maxOccurrences,
    DateTime? endDate,
    ConflictStrategy? conflictStrategy,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      frequency: frequency ?? this.frequency,
      intervalValue: intervalValue ?? this.intervalValue,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      endDate: endDate ?? this.endDate,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Descrizione leggibile della ricorrenza (es. "Ogni 2 settimane")
  String toReadableString({String locale = 'it'}) {
    final interval = intervalValue;
    switch (frequency) {
      case RecurrenceFrequency.daily:
        if (interval == 1) {
          return locale == 'it' ? 'Ogni giorno' : 'Every day';
        }
        return locale == 'it'
            ? 'Ogni $interval giorni'
            : 'Every $interval days';
      case RecurrenceFrequency.weekly:
        if (interval == 1) {
          return locale == 'it' ? 'Ogni settimana' : 'Every week';
        }
        return locale == 'it'
            ? 'Ogni $interval settimane'
            : 'Every $interval weeks';
      case RecurrenceFrequency.monthly:
        if (interval == 1) {
          return locale == 'it' ? 'Ogni mese' : 'Every month';
        }
        return locale == 'it'
            ? 'Ogni $interval mesi'
            : 'Every $interval months';
      case RecurrenceFrequency.custom:
        return locale == 'it'
            ? 'Ogni $interval giorni'
            : 'Every $interval days';
    }
  }
}

/// Frequenza di ricorrenza
enum RecurrenceFrequency {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  custom('custom');

  final String value;
  const RecurrenceFrequency(this.value);

  static RecurrenceFrequency fromString(String value) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecurrenceFrequency.weekly,
    );
  }
}

/// Strategia per gestione conflitti
enum ConflictStrategy {
  skip('skip'),
  force('force');

  final String value;
  const ConflictStrategy(this.value);

  static ConflictStrategy fromString(String value) {
    return ConflictStrategy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ConflictStrategy.skip,
    );
  }
}

/// Configurazione per creare una nuova ricorrenza (lato UI)
class RecurrenceConfig {
  final RecurrenceFrequency frequency;
  final int intervalValue;
  final int? maxOccurrences;
  final DateTime? endDate;
  final ConflictStrategy conflictStrategy;

  const RecurrenceConfig({
    this.frequency = RecurrenceFrequency.weekly,
    this.intervalValue = 1,
    this.maxOccurrences,
    this.endDate,
    this.conflictStrategy = ConflictStrategy.skip,
  });

  /// Indica se la ricorrenza ha un termine definito
  bool get hasEnd => maxOccurrences != null || endDate != null;

  /// Converte in payload per API
  Map<String, dynamic> toApiPayload() => {
    'frequency': frequency.value,
    'interval_value': intervalValue,
    if (maxOccurrences != null) 'max_occurrences': maxOccurrences,
    if (endDate != null) 'end_date': endDate!.toIso8601String().split('T')[0],
    'conflict_strategy': conflictStrategy.value,
  };

  RecurrenceConfig copyWith({
    RecurrenceFrequency? frequency,
    int? intervalValue,
    int? maxOccurrences,
    bool clearMaxOccurrences = false,
    DateTime? endDate,
    bool clearEndDate = false,
    ConflictStrategy? conflictStrategy,
  }) {
    return RecurrenceConfig(
      frequency: frequency ?? this.frequency,
      intervalValue: intervalValue ?? this.intervalValue,
      maxOccurrences: clearMaxOccurrences
          ? null
          : (maxOccurrences ?? this.maxOccurrences),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
    );
  }

  /// Calcola le date delle occorrenze a partire da una data iniziale
  List<DateTime> calculateOccurrences(
    DateTime startDate, {
    int maxPreview = 365,
  }) {
    final dates = <DateTime>[startDate];
    var current = startDate;

    // Se maxOccurrences è specificato, usa quello
    // Altrimenti ("Mai"), calcola fino a 1 anno dalla data iniziale
    final limit = maxOccurrences ?? maxPreview;
    final maxEndDate = endDate ?? startDate.add(const Duration(days: 365));

    while (dates.length < limit) {
      switch (frequency) {
        case RecurrenceFrequency.daily:
        case RecurrenceFrequency.custom:
          current = current.add(Duration(days: intervalValue));
        case RecurrenceFrequency.weekly:
          current = current.add(Duration(days: 7 * intervalValue));
        case RecurrenceFrequency.monthly:
          current = DateTime(
            current.year,
            current.month + intervalValue,
            current.day,
          );
      }

      // Verifica se superato end_date (o limite 1 anno per "Mai")
      if (current.isAfter(maxEndDate)) {
        break;
      }

      dates.add(current);
    }

    return dates;
  }
}
