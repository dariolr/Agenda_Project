abstract final class BookingPaymentLineType {
  static const String cash = 'cash';
  static const String card = 'card';
  static const String discount = 'discount';
  static const String voucher = 'voucher';
  static const String other = 'other';

  static bool isDiscount(String value) => value == discount;
}

class BookingPaymentLine {
  const BookingPaymentLine({
    required this.type,
    required this.amountCents,
    this.meta,
  });

  final String type;
  final int amountCents;
  final Map<String, dynamic>? meta;

  factory BookingPaymentLine.fromJson(Map<String, dynamic> json) {
    return BookingPaymentLine(
      type: (json['type'] as String?)?.trim().isNotEmpty == true
          ? (json['type'] as String).trim()
          : BookingPaymentLineType.other,
      amountCents: json['amount_cents'] as int? ?? 0,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount_cents': amountCents,
      if (meta != null) 'meta': meta,
    };
  }
}
