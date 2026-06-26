import '../../../core/network/api_client.dart';
import '../domain/booking_form_for_booking.dart';
import '../domain/booking_form_models.dart';

class BookingFormsRepository {
  BookingFormsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<BookingForm>> list(int businessId) async {
    final response = await _apiClient.get(
      '/v1/businesses/$businessId/booking-forms',
    );
    return (response['forms'] as List<dynamic>? ?? const [])
        .map((item) => BookingForm.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookingForm> show(int businessId, int formId) async {
    final response = await _apiClient.get(
      '/v1/businesses/$businessId/booking-forms/$formId',
    );
    return BookingForm.fromJson(response['form'] as Map<String, dynamic>);
  }

  Future<BookingForm> saveForm(
    int businessId, {
    int? formId,
    required Map<String, dynamic> data,
  }) async {
    final response = formId == null
        ? await _apiClient.post(
            '/v1/businesses/$businessId/booking-forms',
            data: data,
          )
        : await _apiClient.patch(
            '/v1/businesses/$businessId/booking-forms/$formId',
            data: data,
          );
    return BookingForm.fromJson(response['form'] as Map<String, dynamic>);
  }

  Future<BookingForm> addField(
    int businessId,
    int formId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/v1/businesses/$businessId/booking-forms/$formId/fields',
      data: data,
    );
    return BookingForm.fromJson(response['form'] as Map<String, dynamic>);
  }

  Future<BookingForm> updateField(
    int businessId,
    int formId,
    int fieldId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      '/v1/businesses/$businessId/booking-forms/$formId/fields/$fieldId',
      data: data,
    );
    return BookingForm.fromJson(response['form'] as Map<String, dynamic>);
  }

  Future<BookingForm> deactivateField(
    int businessId,
    int formId,
    int fieldId,
  ) async {
    final response = await _apiClient.delete(
      '/v1/businesses/$businessId/booking-forms/$formId/fields/$fieldId',
    );
    return BookingForm.fromJson(response['form'] as Map<String, dynamic>);
  }

  Future<BookingForm> reorderFields(
    int businessId,
    int formId,
    List<int> fieldIds,
  ) async {
    final response = await _apiClient.put(
      '/v1/businesses/$businessId/booking-forms/$formId/fields/reorder',
      data: {'field_ids': fieldIds},
    );
    return BookingForm.fromJson(response['form'] as Map<String, dynamic>);
  }

  Future<List<BookingForm>> reorderForms(
    int businessId,
    List<int> formIds,
  ) async {
    final response = await _apiClient.put(
      '/v1/businesses/$businessId/booking-forms/reorder',
      data: {'form_ids': formIds},
    );
    return (response['forms'] as List<dynamic>? ?? const [])
        .map((item) => BookingForm.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteForm(int businessId, int formId) async {
    await _apiClient.delete('/v1/businesses/$businessId/booking-forms/$formId');
  }

  /// Moduli applicabili a una prenotazione, con i valori correnti dei campi.
  Future<List<BookingFormForBooking>> getBookingForms(
    int businessId,
    int bookingId,
  ) async {
    final response = await _apiClient.get(
      '/v1/businesses/$businessId/bookings/$bookingId/forms',
    );
    return (response['forms'] as List<dynamic>? ?? const [])
        .map((item) =>
            BookingFormForBooking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Salva (sostituisce) le risposte ai moduli di una prenotazione.
  /// [submissions] = [{form_id, answers: [{field_id, value}]}].
  Future<void> saveBookingForms(
    int businessId,
    int bookingId,
    List<Map<String, dynamic>> submissions,
  ) async {
    await _apiClient.put(
      '/v1/businesses/$businessId/bookings/$bookingId/form-submissions',
      data: {'submissions': submissions},
    );
  }

  /// Sostituisce tutte le regole di visualizzazione del modulo.
  /// OR tra regole, AND tra le condizioni della stessa regola.
  Future<BookingForm> replaceRules(
    int businessId,
    int formId,
    List<BookingFormRule> rules,
  ) async {
    final response = await _apiClient.put(
      '/v1/businesses/$businessId/booking-forms/$formId/rules',
      data: {'rules': rules.map((item) => item.toJson()).toList()},
    );
    return BookingForm.fromJson(response['form'] as Map<String, dynamic>);
  }
}
