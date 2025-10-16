import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Tiene traccia dell’appuntamento attualmente trascinato.
/// Nessun delay: il fantasma scompare subito al rilascio.
class DraggedAppointmentIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// Imposta l'ID dell'appuntamento trascinato
  void set(int id) {
    state = id;
  }

  /// Cancella immediatamente il fantasma
  void clear() {
    state = null;
  }
}

final draggedAppointmentIdProvider =
    NotifierProvider<DraggedAppointmentIdNotifier, int?>(
      DraggedAppointmentIdNotifier.new,
    );
