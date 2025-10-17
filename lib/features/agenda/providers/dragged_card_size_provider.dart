import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Tiene la dimensione (Size) della card attualmente trascinata.
/// Serve per calcolare correttamente la percentuale di overlap orizzontale.
class DraggedCardSizeNotifier extends Notifier<Size?> {
  @override
  Size? build() => null;

  void set(Size size) => state = size;
  void clear() => state = null;
}

final draggedCardSizeProvider =
    NotifierProvider<DraggedCardSizeNotifier, Size?>(
      DraggedCardSizeNotifier.new,
    );
