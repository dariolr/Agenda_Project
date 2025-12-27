import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import 'appointment_providers.dart';

class SelectedAppointmentsState {
  const SelectedAppointmentsState({
    this.bookingId,
    this.appointmentIds = const <int>{},
  });

  final int? bookingId;
  final Set<int> appointmentIds;

  bool contains(int appointmentId) => appointmentIds.contains(appointmentId);
  bool get isEmpty => appointmentIds.isEmpty;
}

/// 🔹 Tiene traccia degli appuntamenti selezionati (tutti quelli della stessa prenotazione)
class SelectedAppointmentNotifier extends Notifier<SelectedAppointmentsState> {
  @override
  SelectedAppointmentsState build() => const SelectedAppointmentsState();

  /// Seleziona tutti gli appuntamenti collegati allo stesso booking dell'appuntamento dato.
  /// Se già selezionati, deseleziona tutto.
  void toggleByAppointment(Appointment appointment) {
    final current = state;
    final alreadySelected =
        current.bookingId == appointment.bookingId &&
        current.contains(appointment.id);
    if (alreadySelected) {
      clear();
      return;
    }

    final allAppointments = ref.read(appointmentsProvider).value ?? [];
    final bookingAppointments = allAppointments
        .where((a) => a.bookingId == appointment.bookingId)
        .map((a) => a.id)
        .toSet();

    state = SelectedAppointmentsState(
      bookingId: appointment.bookingId,
      appointmentIds: bookingAppointments,
    );
  }

  /// Deseleziona tutti gli appuntamenti
  void clear() => state = const SelectedAppointmentsState();
}

final selectedAppointmentProvider =
    NotifierProvider<SelectedAppointmentNotifier, SelectedAppointmentsState>(
      SelectedAppointmentNotifier.new,
    );
