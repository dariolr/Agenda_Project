class BookingPaymentComputed {
  const BookingPaymentComputed({
    required this.totalPaidCents,
    required this.totalDiscountCents,
    required this.balanceCents,
  });

  final int totalPaidCents;
  final int totalDiscountCents;
  final int balanceCents;

  factory BookingPaymentComputed.fromJson(Map<String, dynamic> json) {
    return BookingPaymentComputed(
      totalPaidCents: json['total_paid_cents'] as int? ?? 0,
      totalDiscountCents: json['total_discount_cents'] as int? ?? 0,
      balanceCents: json['balance_cents'] as int? ?? 0,
    );
  }
}
