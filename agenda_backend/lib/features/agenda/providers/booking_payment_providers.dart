import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking_payment.dart';
import '../../../core/models/booking_payment_computed.dart';
import '../../../core/network/network_providers.dart';
import '../data/booking_payment_repository.dart';

final bookingPaymentRepositoryProvider = Provider<BookingPaymentRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingPaymentRepository(apiClient: apiClient);
});

final bookingPaymentProvider = FutureProvider.family<BookingPayment?, int>((
  ref,
  bookingId,
) async {
  final repository = ref.watch(bookingPaymentRepositoryProvider);
  return repository.getBookingPayment(bookingId: bookingId);
});

class BookingPaymentController {
  const BookingPaymentController({
    required BookingPaymentRepository repository,
    required this.bookingId,
  }) : _repository = repository;

  final BookingPaymentRepository _repository;
  final int bookingId;

  Future<BookingPayment?> load() {
    return _repository.getBookingPayment(bookingId: bookingId);
  }

  Future<BookingPayment> save(BookingPayment payment) {
    return _repository.upsertBookingPayment(
      bookingId: bookingId,
      payment: payment,
    );
  }

  BookingPayment defaultValue({
    required int totalDueCents,
    required String currency,
  }) {
    return BookingPayment(
      bookingId: bookingId,
      clientId: null,
      isActive: false,
      currency: currency,
      totalDueCents: totalDueCents,
      note: null,
      lines: const [],
      computed: BookingPaymentComputed(
        totalPaidCents: 0,
        totalDiscountCents: 0,
        balanceCents: totalDueCents,
      ),
    );
  }
}

final bookingPaymentControllerProvider =
    Provider.family<BookingPaymentController, int>((ref, bookingId) {
      final repository = ref.watch(bookingPaymentRepositoryProvider);
      return BookingPaymentController(
        repository: repository,
        bookingId: bookingId,
      );
    });
