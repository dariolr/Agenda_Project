class BookingForm {
  final int id;
  final String title;
  final String? description;
  final String? internalName;
  final bool isActive;
  final int sortOrder;
  final int? fieldsCount;
  final int? rulesCount;
  final List<BookingFormField> fields;
  final List<BookingFormRule> rules;

  const BookingForm({
    required this.id,
    required this.title,
    this.description,
    this.internalName,
    this.isActive = true,
    this.sortOrder = 0,
    this.fieldsCount,
    this.rulesCount,
    this.fields = const [],
    this.rules = const [],
  });

  factory BookingForm.fromJson(Map<String, dynamic> json) => BookingForm(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    internalName: json['internal_name'] as String?,
    isActive: _asBool(json['is_active']),
    sortOrder: json['sort_order'] as int? ?? 0,
    fieldsCount: json['fields_count'] as int?,
    rulesCount: json['rules_count'] as int?,
    fields: (json['fields'] as List<dynamic>? ?? const [])
        .map((item) => BookingFormField.fromJson(item as Map<String, dynamic>))
        .toList(),
    rules: (json['rules'] as List<dynamic>? ?? const [])
        .map((item) => BookingFormRule.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class BookingFormField {
  final int id;
  final String fieldType;
  final String label;
  final String? description;
  final String? placeholder;
  final String? helpText;
  final Map<String, dynamic> validation;
  final bool isRequired;
  final int sortOrder;
  final List<Map<String, String>> options;

  const BookingFormField({
    required this.id,
    required this.fieldType,
    required this.label,
    this.description,
    this.placeholder,
    this.helpText,
    this.validation = const {},
    this.isRequired = false,
    this.sortOrder = 0,
    this.options = const [],
  });

  factory BookingFormField.fromJson(Map<String, dynamic> json) =>
      BookingFormField(
        id: json['id'] as int,
        fieldType: json['field_type'] as String? ?? 'short_text',
        label: json['label'] as String? ?? '',
        description: json['description'] as String?,
        placeholder: json['placeholder'] as String?,
        helpText: json['help_text'] as String?,
        validation: json['validation'] is Map<String, dynamic>
            ? json['validation'] as Map<String, dynamic>
            : const {},
        isRequired: _asBool(json['is_required']),
        sortOrder: json['sort_order'] as int? ?? 0,
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((option) {
              if (option is Map<String, dynamic>) {
                final value = option['value']?.toString() ?? '';
                final label = option['label']?.toString() ?? value;
                return {'value': value, 'label': label};
              }
              final value = option.toString();
              return {'value': value, 'label': value};
            })
            .where((option) => option['value']!.isNotEmpty)
            .toList(),
      );

  /// Campi compilabili dal cliente (non puramente informativi). Usato per la
  /// raccolta delle risposte: i campi `info_text` non producono un valore.
  /// NB: un modulo con soli campi informativi è comunque mostrato online.
  bool get isInputField => fieldType != 'info_text';

  String? get consentUrl {
    final value = validation['url']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}

/// Una condizione di una regola: un singolo ambito (business, sede, categoria,
/// o tipo appuntamento).
class BookingFormCondition {
  final String scopeType;
  final int? scopeId;

  const BookingFormCondition({required this.scopeType, this.scopeId});

  factory BookingFormCondition.fromJson(Map<String, dynamic> json) =>
      BookingFormCondition(
        scopeType: json['scope_type'] as String? ?? 'business',
        scopeId: json['scope_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'scope_type': scopeType,
    'scope_id': scopeId,
  };
}

/// Una regola di visualizzazione: tutte le sue condizioni devono essere
/// rispettate (AND). Il modulo appare se almeno una regola è soddisfatta (OR).
class BookingFormRule {
  final int? id;
  final int sortOrder;
  final List<BookingFormCondition> conditions;

  const BookingFormRule({
    this.id,
    this.sortOrder = 0,
    this.conditions = const [],
  });

  factory BookingFormRule.fromJson(Map<String, dynamic> json) => BookingFormRule(
    id: json['id'] as int?,
    sortOrder: json['sort_order'] as int? ?? 0,
    conditions: (json['conditions'] as List<dynamic>? ?? const [])
        .map(
          (item) => BookingFormCondition.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'conditions': conditions.map((c) => c.toJson()).toList(),
  };
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}
