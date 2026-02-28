import '../../../core/models/booking_payment.dart';
import '../../../core/network/api_client.dart';

class BookingPaymentRepository {
  const BookingPaymentRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<BookingPayment?> getBookingPayment({required int bookingId}) async {
    try {
      final response = await _apiClient.getBookingPayment(bookingId: bookingId);
      return BookingPayment.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<BookingPayment> upsertBookingPayment({
    required int bookingId,
    required BookingPayment payment,
  }) async {
    final response = await _apiClient.upsertBookingPayment(
      bookingId: bookingId,
      payload: payment.toUpsertJson(),
    );
    return BookingPayment.fromJson(response);
  }
}
