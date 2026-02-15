import '/core/models/class_booking.dart';
import '/core/models/class_event.dart';
import '/core/network/api_client.dart';

class ClassEventsRepository {
  const ClassEventsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ClassEvent>> listEvents({
    required int businessId,
    required DateTime fromUtc,
    required DateTime toUtc,
    int? locationId,
  }) {
    return _apiClient.getClassEvents(
      businessId: businessId,
      fromUtc: fromUtc,
      toUtc: toUtc,
      locationId: locationId,
    );
  }

  Future<ClassEvent> getEvent({
    required int businessId,
    required int classEventId,
  }) {
    return _apiClient.getClassEvent(
      businessId: businessId,
      classEventId: classEventId,
    );
  }

  Future<List<ClassBooking>> participants({
    required int businessId,
    required int classEventId,
  }) {
    return _apiClient.getClassEventParticipants(
      businessId: businessId,
      classEventId: classEventId,
    );
  }

  Future<ClassBooking> book({
    required int businessId,
    required int classEventId,
    int? customerId,
  }) {
    return _apiClient.bookClassEvent(
      businessId: businessId,
      classEventId: classEventId,
      customerId: customerId,
    );
  }

  Future<void> cancelBooking({
    required int businessId,
    required int classEventId,
    int? customerId,
  }) {
    return _apiClient.cancelClassEventBooking(
      businessId: businessId,
      classEventId: classEventId,
      customerId: customerId,
    );
  }

  Future<ClassEvent> create({
    required int businessId,
    required Map<String, dynamic> payload,
  }) {
    return _apiClient.createClassEvent(businessId: businessId, data: payload);
  }
}
