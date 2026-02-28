import 'booking_payment_computed.dart';
import 'booking_payment_line.dart';

class BookingPayment {
  const BookingPayment({
    required this.bookingId,
    required this.clientId,
    required this.isActive,
    required this.currency,
    required this.totalDueCents,
    this.note,
    required this.lines,
    required this.computed,
  });

  final int bookingId;
  final int? clientId;
  final bool isActive;
  final String currency;
  final int totalDueCents;
  final String? note;
  final List<BookingPaymentLine> lines;
  final BookingPaymentComputed computed;

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      bookingId: json['booking_id'] as int? ?? 0,
      clientId: json['client_id'] as int?,
      isActive: json['is_active'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'EUR',
      totalDueCents: json['total_due_cents'] as int? ?? 0,
      note: json['note'] as String?,
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookingPaymentLine.fromJson)
          .toList(),
      computed: BookingPaymentComputed.fromJson(
        json['computed'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'currency': currency,
      'total_due_cents': totalDueCents,
      'note': note,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }
}
