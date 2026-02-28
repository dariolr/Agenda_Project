enum BookingPaymentLineType {
  cash,
  card,
  discount,
  voucher,
  other;

  String get apiValue {
    switch (this) {
      case BookingPaymentLineType.cash:
        return 'cash';
      case BookingPaymentLineType.card:
        return 'card';
      case BookingPaymentLineType.discount:
        return 'discount';
      case BookingPaymentLineType.voucher:
        return 'voucher';
      case BookingPaymentLineType.other:
        return 'other';
    }
  }

  static BookingPaymentLineType fromApiValue(String value) {
    switch (value) {
      case 'cash':
        return BookingPaymentLineType.cash;
      case 'card':
        return BookingPaymentLineType.card;
      case 'discount':
        return BookingPaymentLineType.discount;
      case 'voucher':
        return BookingPaymentLineType.voucher;
      case 'other':
        return BookingPaymentLineType.other;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported payment line type');
      }
  }
}

class BookingPaymentLine {
  const BookingPaymentLine({
    required this.type,
    required this.amountCents,
    this.meta,
  });

  final BookingPaymentLineType type;
  final int amountCents;
  final Map<String, dynamic>? meta;

  factory BookingPaymentLine.fromJson(Map<String, dynamic> json) {
    return BookingPaymentLine(
      type: BookingPaymentLineType.fromApiValue(json['type'] as String? ?? 'other'),
      amountCents: json['amount_cents'] as int? ?? 0,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'amount_cents': amountCents,
      if (meta != null) 'meta': meta,
    };
  }
}
