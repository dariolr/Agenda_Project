import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../clients/providers/clients_providers.dart';
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

/// 🔹 Tiene traccia degli appuntamenti selezionati.
/// Include tutti quelli della stessa prenotazione e, se presente,
/// anche quelli dello stesso cliente esistente.
class SelectedAppointmentNotifier extends Notifier<SelectedAppointmentsState> {
  @override
  SelectedAppointmentsState build() => const SelectedAppointmentsState();

  SelectedAppointmentsState _selectionForAppointment(Appointment appointment) {
    final selectedIds = ref
        .read(appointmentsProvider.notifier)
        .getByBookingId(appointment.bookingId)
        .map((a) => a.id)
        .toSet();
    if (selectedIds.isEmpty) {
      // Fallback per card provenienti da viste non legate al provider del giorno
      // (es. settimana single-staff): mantieni almeno la card corrente selezionata.
      selectedIds.add(appointment.id);
    }

    final clientId = appointment.clientId;
    if (clientId != null) {
      final hasExistingClient = ref.read(clientsByIdProvider).containsKey(
        clientId,
      );
      if (hasExistingClient) {
        final allAppointments = ref
            .read(appointmentsProvider.notifier)
            .getByClientId(clientId);
        selectedIds.addAll(
          allAppointments
              .where((a) => a.clientId == clientId)
              .map((a) => a.id),
        );
      }
    }

    return SelectedAppointmentsState(
      bookingId: appointment.bookingId,
      appointmentIds: selectedIds,
    );
  }

  /// Seleziona in modo idempotente la card corrente con il suo gruppo correlato.
  /// Non effettua toggle.
  void selectByAppointment(Appointment appointment) {
    state = _selectionForAppointment(appointment);
  }

  /// Seleziona tutti gli appuntamenti collegati allo stesso booking
  /// dell'appuntamento dato.
  /// Se il cliente esiste (clientId valido in cache), include anche
  /// gli appuntamenti dello stesso cliente.
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
    selectByAppointment(appointment);
  }

  /// Deseleziona tutti gli appuntamenti
  void clear() => state = const SelectedAppointmentsState();
}

final selectedAppointmentProvider =
    NotifierProvider<SelectedAppointmentNotifier, SelectedAppointmentsState>(
      SelectedAppointmentNotifier.new,
    );
