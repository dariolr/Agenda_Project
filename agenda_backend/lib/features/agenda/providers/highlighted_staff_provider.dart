import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Tiene traccia dello staff evidenziato durante il drag
class HighlightedStaffIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? id) => state = id;
  void clear() => state = null;
}

final highlightedStaffIdProvider =
    NotifierProvider<HighlightedStaffIdNotifier, int?>(
      HighlightedStaffIdNotifier.new,
    );
