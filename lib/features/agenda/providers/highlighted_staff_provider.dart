import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Notifier che tiene traccia dello staff attualmente evidenziato durante il drag
class HighlightedStaffIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// Imposta l’ID dello staff attualmente evidenziato
  void set(int? id) => state = id;

  /// Resetta lo staff evidenziato
  void clear() => state = null;
}

/// 🔹 Provider globale per lo staff evidenziato
final highlightedStaffIdProvider =
    NotifierProvider<HighlightedStaffIdNotifier, int?>(
      HighlightedStaffIdNotifier.new,
    );
