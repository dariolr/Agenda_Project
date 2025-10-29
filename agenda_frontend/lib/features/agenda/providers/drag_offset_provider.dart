import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Distanza verticale (in px) tra il punto di presa e il bordo superiore della card
class DragOffsetNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  void set(double value) => state = value;
  void clear() => state = null;
}

final dragOffsetProvider = NotifierProvider<DragOffsetNotifier, double?>(
  DragOffsetNotifier.new,
);

/// 🔹 Distanza orizzontale (in px) tra il punto di presa e il bordo sinistro della card
class DragOffsetXNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  void set(double value) => state = value;
  void clear() => state = null;
}

final dragOffsetXProvider = NotifierProvider<DragOffsetXNotifier, double?>(
  DragOffsetXNotifier.new,
);
