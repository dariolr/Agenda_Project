/// Risposta (compilata) a un modulo per-cliente, per la sola lettura nella
/// scheda cliente del gestionale.
class CustomerFormSubmission {
  final int id;
  final int formId;
  final String formTitle;
  final int? locationId;
  final String? submittedAt;
  final List<CustomerFormAnswer> answers;

  const CustomerFormSubmission({
    required this.id,
    required this.formId,
    required this.formTitle,
    this.locationId,
    this.submittedAt,
    this.answers = const [],
  });

  factory CustomerFormSubmission.fromJson(Map<String, dynamic> json) =>
      CustomerFormSubmission(
        id: json['id'] as int? ?? 0,
        formId: json['form_id'] as int? ?? 0,
        formTitle: json['form_title'] as String? ?? '',
        locationId: json['location_id'] as int?,
        submittedAt: json['submitted_at'] as String?,
        answers: (json['answers'] as List<dynamic>? ?? const [])
            .map((item) =>
                CustomerFormAnswer.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class CustomerFormAnswer {
  final int fieldId;
  final String fieldType;
  final String fieldLabel;
  final String? answerText;
  final dynamic answerJson;

  const CustomerFormAnswer({
    required this.fieldId,
    required this.fieldType,
    required this.fieldLabel,
    this.answerText,
    this.answerJson,
  });

  factory CustomerFormAnswer.fromJson(Map<String, dynamic> json) =>
      CustomerFormAnswer(
        fieldId: json['field_id'] as int? ?? 0,
        fieldType: json['field_type'] as String? ?? '',
        fieldLabel: json['field_label'] as String? ?? '',
        answerText: json['answer_text'] as String?,
        answerJson: json['answer_json'],
      );

  /// Rappresentazione testuale leggibile della risposta.
  String get displayValue {
    if (answerJson is List) {
      return (answerJson as List).join(', ');
    }
    if (fieldType == 'checkbox' || fieldType == 'consent') {
      return answerText == '1' ? '✓' : '—';
    }
    return answerText ?? '';
  }
}
