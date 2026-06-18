class BookingForm {
  final int id;
  final String title;
  final String? description;
  final String? internalName;
  final bool isActive;
  final int sortOrder;
  final int? fieldsCount;
  final int? assignmentsCount;
  final List<BookingFormField> fields;
  final List<BookingFormAssignment> assignments;

  const BookingForm({
    required this.id,
    required this.title,
    this.description,
    this.internalName,
    this.isActive = true,
    this.sortOrder = 0,
    this.fieldsCount,
    this.assignmentsCount,
    this.fields = const [],
    this.assignments = const [],
  });

  factory BookingForm.fromJson(Map<String, dynamic> json) => BookingForm(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    internalName: json['internal_name'] as String?,
    isActive: _asBool(json['is_active']),
    sortOrder: json['sort_order'] as int? ?? 0,
    fieldsCount: json['fields_count'] as int?,
    assignmentsCount: json['assignments_count'] as int?,
    fields: (json['fields'] as List<dynamic>? ?? const [])
        .map((item) => BookingFormField.fromJson(item as Map<String, dynamic>))
        .toList(),
    assignments: (json['assignments'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              BookingFormAssignment.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );
}

class BookingFormField {
  final int id;
  final String fieldType;
  final String label;
  final bool isRequired;
  final int sortOrder;
  final List<Map<String, String>> options;

  const BookingFormField({
    required this.id,
    required this.fieldType,
    required this.label,
    this.isRequired = false,
    this.sortOrder = 0,
    this.options = const [],
  });

  factory BookingFormField.fromJson(Map<String, dynamic> json) =>
      BookingFormField(
        id: json['id'] as int,
        fieldType: json['field_type'] as String? ?? 'short_text',
        label: json['label'] as String? ?? '',
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
}

class BookingFormAssignment {
  final String scopeType;
  final int? scopeId;

  const BookingFormAssignment({required this.scopeType, this.scopeId});

  factory BookingFormAssignment.fromJson(Map<String, dynamic> json) =>
      BookingFormAssignment(
        scopeType: json['scope_type'] as String? ?? 'business',
        scopeId: json['scope_id'] as int?,
      );
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}
