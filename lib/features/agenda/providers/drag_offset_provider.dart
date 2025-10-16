import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Mantiene in memoria la distanza verticale (in pixel)
/// tra il punto di presa del mouse/dito e il bordo superiore della card.
///
/// Questo offset serve per calcolare in modo preciso la posizione
/// del bordo superiore della card durante il drag, così da poter
/// mostrare e salvare l'orario corretto.
class DragOffsetNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  /// Imposta la distanza verticale dal bordo superiore (in px)
  void set(double value) {
    state = value;
  }

  /// Resetta lo stato (nessun drag in corso)
  void clear() {
    state = null;
  }
}

/// Provider globale per l'offset verticale di presa durante il drag
final dragOffsetProvider = NotifierProvider<DragOffsetNotifier, double?>(
  DragOffsetNotifier.new,
);
