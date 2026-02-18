import '/core/models/class_booking.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/network/api_client.dart';

class ClassEventsRepository {
  const ClassEventsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ClassEvent>> listEvents({
    required int businessId,
    required DateTime fromUtc,
    required DateTime toUtc,
    int? locationId,
    int? classTypeId,
  }) {
    return _apiClient.getClassEvents(
      businessId: businessId,
      fromUtc: fromUtc,
      toUtc: toUtc,
      locationId: locationId,
      classTypeId: classTypeId,
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

  Future<ClassEvent> update({
    required int businessId,
    required int classEventId,
    required Map<String, dynamic> payload,
  }) {
    return _apiClient.updateClassEvent(
      businessId: businessId,
      classEventId: classEventId,
      data: payload,
    );
  }

  Future<void> deleteEvent({
    required int businessId,
    required int classEventId,
  }) {
    return _apiClient.deleteClassEvent(
      businessId: businessId,
      classEventId: classEventId,
    );
  }

  Future<List<ClassType>> listClassTypes({
    required int businessId,
    bool includeInactive = false,
  }) {
    return _apiClient.getClassTypes(
      businessId: businessId,
      includeInactive: includeInactive,
    );
  }

  Future<ClassType> createClassType({
    required int businessId,
    required Map<String, dynamic> payload,
  }) {
    return _apiClient.createClassType(businessId: businessId, data: payload);
  }

  Future<ClassType> updateClassType({
    required int businessId,
    required int classTypeId,
    required Map<String, dynamic> payload,
  }) {
    return _apiClient.updateClassType(
      businessId: businessId,
      classTypeId: classTypeId,
      data: payload,
    );
  }

  Future<void> deleteClassType({
    required int businessId,
    required int classTypeId,
  }) {
    return _apiClient.deleteClassType(
      businessId: businessId,
      classTypeId: classTypeId,
    );
  }
}
