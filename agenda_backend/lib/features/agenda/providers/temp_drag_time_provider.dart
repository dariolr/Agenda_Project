import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Mantiene in memoria temporanea l'intervallo orario stimato
/// (start, end) dell'appuntamento durante il drag.
/// Viene aggiornato in tempo reale dalla StaffColumn mentre l'utente trascina
/// e letto da AppointmentCard per mostrare orari live.
class TempDragTimeNotifier extends Notifier<(DateTime, DateTime)?> {
  @override
  (DateTime, DateTime)? build() => null;

  /// Imposta un nuovo intervallo orario (start, end)
  void setTimes(DateTime start, DateTime end) {
    // aggiorna solo se cambia effettivamente lo slot di riferimento
    if (state == null ||
        state!.$1.minute != start.minute ||
        state!.$1.hour != start.hour) {
      state = (start, end);
    }
  }

  /// Resetta lo stato (nessun drag in corso)
  void clear() => state = null;
}

final tempDragTimeProvider =
    NotifierProvider<TempDragTimeNotifier, (DateTime, DateTime)?>(
      TempDragTimeNotifier.new,
    );
