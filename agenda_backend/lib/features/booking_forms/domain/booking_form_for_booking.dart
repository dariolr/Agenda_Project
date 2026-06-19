import 'booking_form_models.dart';

/// Modulo applicabile a una prenotazione, con la definizione dei campi e il
/// valore corrente di ciascun campo (dalle submission già salvate).
/// Usato nel gestionale per visualizzare/modificare i moduli di una prenotazione.
class BookingFormForBooking {
  final int id;
  final String title;
  final String? description;
  final List<BookingFormField> fields;

  /// Valore corrente per id campo: String / bool / `List<String>` / null.
  final Map<int, dynamic> values;

  const BookingFormForBooking({
    required this.id,
    required this.title,
    this.description,
    this.fields = const [],
    this.values = const {},
  });

  factory BookingFormForBooking.fromJson(Map<String, dynamic> json) {
    final rawFields =
        (json['fields'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final fields = rawFields.map(BookingFormField.fromJson).toList();
    final values = <int, dynamic>{};
    for (final field in rawFields) {
      final id = field['id'];
      if (id is int) {
        values[id] = field['value'];
      }
    }
    return BookingFormForBooking(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      fields: fields,
      values: values,
    );
  }
}
