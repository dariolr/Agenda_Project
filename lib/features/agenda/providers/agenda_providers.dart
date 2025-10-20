import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Notifier che tiene traccia della posizione globale del drag
class DragPositionNotifier extends Notifier<Offset?> {
  @override
  Offset? build() => null;

  void update(Offset position) => state = position;

  /// ✅ Nuovo metodo pubblico per aggiornare lo stato interpolato
  void set(Offset newValue) => state = newValue;

  void clear() => state = null;
}

final dragPositionProvider = NotifierProvider<DragPositionNotifier, Offset?>(
  DragPositionNotifier.new,
);
