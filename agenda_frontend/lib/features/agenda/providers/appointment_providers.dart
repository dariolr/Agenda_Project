import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';

/// ✅ Gestione degli appuntamenti (mock persistente in memoria)
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

    return [
      // Staff 1
      Appointment(
        id: 1,
        idBooking: 101,
        staffId: 1,
        clientName: 'Anna Rossi',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 9, minutes: 10)),
        endTime: today.add(const Duration(hours: 9, minutes: 35)),
      ),
      Appointment(
        id: 2,
        idBooking: 102,
        staffId: 1,
        clientName: 'Anna Rossi',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 9, minutes: 35)),
        endTime: today.add(const Duration(hours: 10, minutes: 40)),
      ),
      Appointment(
        id: 3,
        idBooking: 103,
        staffId: 1,
        clientName: 'Paolo Verdi',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 11)),
        endTime: today.add(const Duration(hours: 12)),
      ),

      // Staff 2
      Appointment(
        id: 4,
        idBooking: 104,
        staffId: 2,
        clientName: 'Giulia Neri',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 10)),
        endTime: today.add(const Duration(hours: 11)),
      ),
      Appointment(
        id: 5,
        idBooking: 105,
        staffId: 2,
        clientName: 'Marco Gialli',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 10, minutes: 15)),
        endTime: today.add(const Duration(hours: 10, minutes: 45)),
      ),
      Appointment(
        id: 6,
        idBooking: 106,
        staffId: 2,
        clientName: 'Chiara Blu',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 15)),
      ),

      // Staff 3
      Appointment(
        id: 7,
        idBooking: 107,
        staffId: 3,
        clientName: 'Valentina',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 9)),
        endTime: today.add(const Duration(hours: 9, minutes: 45)),
      ),
      Appointment(
        id: 8,
        idBooking: 108,
        staffId: 3,
        clientName: 'Francesco',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 9, minutes: 30)),
        endTime: today.add(const Duration(hours: 10, minutes: 15)),
      ),
      Appointment(
        id: 9,
        idBooking: 109,
        staffId: 3,
        clientName: 'Elisa',
        serviceName: 'service name',
        startTime: today.add(const Duration(hours: 10, minutes: 30)),
        endTime: today.add(const Duration(hours: 11)),
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
      for (final a in state)
        if (a.id == appointmentId)
          a.copyWith(staffId: newStaffId, startTime: newStart, endTime: newEnd)
        else
          a,
    ];
    await Future.delayed(Duration.zero);
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
      AppointmentsNotifier.new,
    );
