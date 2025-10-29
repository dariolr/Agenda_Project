import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Tiene traccia dell'ID dell'appuntamento selezionato (clic singolo)
class SelectedAppointmentNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// Seleziona un appuntamento; se è già selezionato, lo deseleziona
  void toggle(int id) {
    if (state == id) {
      state = null;
    } else {
      state = id;
    }
  }

  /// Deseleziona tutto
  void clear() => state = null;
}

final selectedAppointmentProvider =
    NotifierProvider<SelectedAppointmentNotifier, int?>(
      SelectedAppointmentNotifier.new,
    );
