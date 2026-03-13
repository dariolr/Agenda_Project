import '../../../core/models/booking_payment.dart';
import '../../../core/models/booking_payment_computed.dart';
import '../../../core/models/booking_payment_line.dart';
import '../../../core/models/service_variant.dart';
import 'service_item_data.dart';

const bookingPaymentAutoDiscountSourceTag = 'appointment_amount_adjustment';
const bookingPaymentManualDiscountSourceTag = 'manual';

int computeBaseTotalDueCents({
  required int referenceTotalCents,
  required int currentTotalCents,
}) {
  return currentTotalCents > referenceTotalCents
      ? currentTotalCents
      : referenceTotalCents;
}

int computeNonDiscountCoverageCents(BookingPayment payment) {
  return payment.lines
      .where((line) => line.type != BookingPaymentLineType.discount)
      .fold<int>(0, (sum, line) => sum + line.amountCents);
}

bool paymentExceedsCurrentDue({
  required BookingPayment payment,
  required int currentTotalCents,
}) {
  return computeNonDiscountCoverageCents(payment) > currentTotalCents;
}

int computeServiceItemsTotalCents({
  required List<ServiceItemData> items,
  required List<ServiceVariant> variants,
}) {
  return items.fold<int>(0, (sum, item) {
    if (item.serviceId == null || item.serviceId! <= 0) return sum;
    final variant = variants.cast<ServiceVariant?>().firstWhere(
      (v) => v?.serviceId == item.serviceId,
      orElse: () => null,
    );
    if (variant == null) return sum;
    return sum + ((item.price ?? variant.price) * 100).round();
  });
}

BookingPayment buildBookingPaymentPreview({
  required int bookingId,
  required int? clientId,
  required String currency,
  required int referenceTotalCents,
  required int currentTotalCents,
  BookingPayment? basePayment,
  bool isActive = true,
}) {
  final baseTotalDueCents = computeBaseTotalDueCents(
    referenceTotalCents: referenceTotalCents,
    currentTotalCents: currentTotalCents,
  );
  final desiredAutoDiscountCents =
      (baseTotalDueCents - currentTotalCents).clamp(0, 1 << 30);

  final seed =
      basePayment ??
      BookingPayment(
        bookingId: bookingId,
        clientId: clientId,
        isActive: isActive,
        currency: currency,
        totalDueCents: baseTotalDueCents,
        note: null,
        lines: const [],
        computed: const BookingPaymentComputed(
          totalPaidCents: 0,
          totalDiscountCents: 0,
          balanceCents: 0,
        ),
      );

  final preservedLines = seed.lines
      .where(
        (line) =>
            line.type != BookingPaymentLineType.discount ||
            line.meta?['source'] == bookingPaymentManualDiscountSourceTag,
      )
      .toList();

  if (desiredAutoDiscountCents > 0) {
    preservedLines.add(
      BookingPaymentLine(
        type: BookingPaymentLineType.discount,
        amountCents: desiredAutoDiscountCents,
        meta: const {'source': bookingPaymentAutoDiscountSourceTag},
      ),
    );
  }

  return BookingPayment(
    bookingId: seed.bookingId,
    clientId: seed.clientId,
    isActive: seed.isActive,
    currency: seed.currency,
    totalDueCents: baseTotalDueCents,
    note: seed.note,
    lines: preservedLines,
    computed: seed.computed,
  );
}
