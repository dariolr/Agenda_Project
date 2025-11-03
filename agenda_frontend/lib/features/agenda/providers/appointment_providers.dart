import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import 'business_providers.dart';
import 'location_providers.dart';

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  bool _initialized = false;

  @override
  List<Appointment> build() {
    if (!_initialized) {
      _initialized = true;
      state = _mockAppointments();
    }
    return state;
  }

  List<Appointment> _mockAppointments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final business = ref.read(currentBusinessProvider);

    return [
      Appointment(
        id: 1,
        bookingId: 5001,
        businessId: business.id,
        locationId: 101,
        staffId: 1,
        serviceId: 1,
        serviceVariantId: 1001,
        clientName: 'Anna Rossi',
        serviceName: 'Massaggio Relax',
        startTime: today.add(const Duration(hours: 9, minutes: 10)),
        endTime: today.add(const Duration(hours: 9, minutes: 35)),
        price: 45,
      ),
      Appointment(
        id: 2,
        bookingId: 5001,
        businessId: business.id,
        locationId: 101,
        staffId: 1,
        serviceId: 1,
        serviceVariantId: 1001,
        clientName: 'Anna Rossi',
        serviceName: 'Massaggio Relax',
        startTime: today.add(const Duration(hours: 9, minutes: 35)),
        endTime: today.add(const Duration(hours: 10, minutes: 30)),
        price: 45,
      ),
      Appointment(
        id: 3,
        bookingId: 5002,
        businessId: business.id,
        locationId: 101,
        staffId: 3,
        serviceId: 2,
        serviceVariantId: 2001,
        clientName: 'Paolo Verdi',
        serviceName: 'Massaggio Sportivo',
        startTime: today.add(const Duration(hours: 11)),
        endTime: today.add(const Duration(hours: 12)),
        price: 62,
      ),
      Appointment(
        id: 4,
        bookingId: 6001,
        businessId: business.id,
        locationId: 102,
        staffId: 2,
        serviceId: 1,
        serviceVariantId: 1002,
        clientName: 'Giulia Neri',
        serviceName: 'Massaggio Relax',
        startTime: today.add(const Duration(hours: 10)),
        endTime: today.add(const Duration(hours: 11)),
        price: 48,
      ),
      Appointment(
        id: 5,
        bookingId: 6002,
        businessId: business.id,
        locationId: 102,
        staffId: 5,
        serviceId: 2,
        serviceVariantId: 2002,
        clientName: 'Marco Gialli',
        serviceName: 'Massaggio Sportivo',
        startTime: today.add(const Duration(hours: 10, minutes: 15)),
        endTime: today.add(const Duration(hours: 11)),
        price: 65,
      ),
      Appointment(
        id: 6,
        bookingId: 6003,
        businessId: business.id,
        locationId: 102,
        staffId: 3,
        serviceId: 3,
        serviceVariantId: 3002,
        clientName: 'Chiara Blu',
        serviceName: 'Trattamento Viso',
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 15)),
        price: 58,
      ),
    ];
  }

  void moveAppointment({
    required int appointmentId,
    required int newStaffId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    state = [
      for (final appt in state)
        if (appt.id == appointmentId)
          appt.copyWith(staffId: newStaffId, startTime: newStart, endTime: newEnd)
        else
          appt,
    ];
    await Future.delayed(Duration.zero);
  }

  void deleteAppointment(int appointmentId) {
    state = [
      for (final appt in state)
        if (appt.id != appointmentId) appt,
    ];
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
  AppointmentsNotifier.new,
);

final appointmentsForCurrentLocationProvider = Provider<List<Appointment>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final appointments = ref.watch(appointmentsProvider);
  return [
    for (final appt in appointments)
      if (appt.locationId == location.id) appt,
  ];
});
