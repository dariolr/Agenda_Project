class BookingForm {
  final int id;
  final String title;
  final String? description;
  final int sortOrder;
  final List<BookingFormField> fields;

  const BookingForm({
    required this.id,
    required this.title,
    this.description,
    this.sortOrder = 0,
    this.fields = const [],
  });

  factory BookingForm.fromJson(Map<String, dynamic> json) => BookingForm(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    fields: (json['fields'] as List<dynamic>? ?? const [])
        .map((item) => BookingFormField.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class BookingFormField {
  final int id;
  final int formId;
  final String fieldType;
  final String label;
  final String? description;
  final String? placeholder;
  final String? helpText;
  final Map<String, dynamic> validation;
  final bool isRequired;
  final int sortOrder;
  final List<BookingFormOption> options;

  const BookingFormField({
    required this.id,
    required this.formId,
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

  bool get isInput => fieldType != 'info_text';

  factory BookingFormField.fromJson(Map<String, dynamic> json) =>
      BookingFormField(
        id: json['id'] as int,
        formId: json['form_id'] as int,
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
            .map((item) => BookingFormOption.fromJson(item))
            .toList(),
      );

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  String? get consentUrl {
    final value = validation['url']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}

class BookingFormOption {
  final String value;
  final String label;

  const BookingFormOption({required this.value, required this.label});

  factory BookingFormOption.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final value =
          json['value']?.toString() ?? json['label']?.toString() ?? '';
      return BookingFormOption(
        value: value,
        label: json['label']?.toString() ?? value,
      );
    }
    final value = json.toString();
    return BookingFormOption(value: value, label: value);
  }
}
