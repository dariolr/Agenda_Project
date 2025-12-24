import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Mantiene l'intervallo originale (start, end) della card che sta per
/// essere trascinata. Serve per evitare fallback arbitrari durante il ghost.
class DraggedBaseRangeNotifier extends Notifier<(DateTime, DateTime)?> {
  @override
  (DateTime, DateTime)? build() => null;

  void set(DateTime start, DateTime end) => state = (start, end);
  void clear() => state = null;
}

final draggedBaseRangeProvider =
    NotifierProvider<DraggedBaseRangeNotifier, (DateTime, DateTime)?>(
      DraggedBaseRangeNotifier.new,
    );
