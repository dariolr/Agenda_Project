import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/config/layout_config.dart';

part 'layout_config_provider.g.dart';

/// Provider responsabile di mantenere aggiornata la configurazione del layout
/// (in particolare l’altezza degli slot e dell’header)
@riverpod
class LayoutConfigNotifier extends _$LayoutConfigNotifier {
  Timer? _resizeDebounce;

  @override
  double build() {
    ref.onDispose(() {
      _resizeDebounce?.cancel();
    });
    return LayoutConfig.slotHeight;
  }

  /// Aggiorna dinamicamente l’altezza degli slot e dell’header
  /// in base alle dimensioni della finestra
  void updateFromContext(BuildContext context) {
    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 100), () {
      final size = MediaQuery.of(context).size;
      final screenHeight = size.height;
      final screenWidth = size.width;

      // 🔹 Calcolo dinamico dell’altezza degli slot
      double newSlotHeight = LayoutConfig.slotHeight;
      if (screenHeight < 700) {
        newSlotHeight = 30 * 0.8;
      } else if (screenHeight > 1200) {
        newSlotHeight = 30 * 1.2;
      } else {
        newSlotHeight = 30;
      }

      // 🔹 Calcolo dinamico dell’altezza dell’header
      double newHeaderHeight;
      if (screenWidth >= 1024) {
        newHeaderHeight = 56; // Desktop
      } else if (screenWidth >= 600) {
        newHeaderHeight = 52; // Tablet
      } else {
        newHeaderHeight = 48; // Mobile
      }

      // 🔹 Aggiorna LayoutConfig globale
      LayoutConfig.updateSlotHeight(newSlotHeight);
      LayoutConfig.updateHeaderHeight(newHeaderHeight);

      // 🔹 Aggiorna stato provider se necessario
      if (newSlotHeight != state) {
        state = newSlotHeight;
      }
      debugPrint(
        '🔁 Layout updated → slotHeight: $newSlotHeight | headerHeight: $newHeaderHeight',
      );
    });
  }
}
