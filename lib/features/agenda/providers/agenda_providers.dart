import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Notifier che tiene traccia della posizione globale del drag
class DragPositionNotifier extends Notifier<Offset?> {
  @override
  Offset? build() => null;

  /// Aggiorna la posizione del cursore
  void update(Offset position) => state = position;

  /// Resetta la posizione (quando il drag termina)
  void clear() => state = null;
}

/// 🔹 Provider globale per la posizione del drag
final dragPositionProvider = NotifierProvider<DragPositionNotifier, Offset?>(
  DragPositionNotifier.new,
);
