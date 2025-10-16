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
    state = (start, end);
  }

  /// Resetta lo stato (nessun drag in corso)
  void clear() {
    state = null;
  }
}

/// Provider globale per accedere all'intervallo orario temporaneo
final tempDragTimeProvider =
    NotifierProvider<TempDragTimeNotifier, (DateTime, DateTime)?>(
      TempDragTimeNotifier.new,
    );
