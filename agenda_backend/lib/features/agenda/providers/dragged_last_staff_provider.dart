import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Tiene traccia dell'ultima colonna staff attraversata durante il drag.
class DraggedLastStaffNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int staffId) => state = staffId;
  void clear() => state = null;
}

final draggedLastStaffIdProvider =
    NotifierProvider<DraggedLastStaffNotifier, int?>(
      DraggedLastStaffNotifier.new,
    );
