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

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    _resizeDebounce = Timer(const Duration(milliseconds: 100), () {
      // 🔹 Calcolo dinamico slot height
      double newSlotHeight;
      if (screenHeight < 700) {
        newSlotHeight = 30 * 0.8;
      } else if (screenHeight > 1200) {
        newSlotHeight = 30 * 1.2;
      } else {
        newSlotHeight = 30;
      }

      // 🔹 Calcolo dinamico header height
      double newHeaderHeight;
      if (screenWidth >= 1024) {
        newHeaderHeight = 56;
      } else if (screenWidth >= 600) {
        newHeaderHeight = 52;
      } else {
        newHeaderHeight = 48;
      }

      // 🔹 Calcolo dinamico hour column width
      double newHourWidth;
      if (screenWidth >= 1024) {
        newHourWidth = 60;
      } else if (screenWidth >= 600) {
        newHourWidth = 55;
      } else {
        newHourWidth = 50;
      }
      // ──────────────────────────────────────────────
      // ⚙️ Confronta i valori precedenti
      // ──────────────────────────────────────────────
      final slotChanged = newSlotHeight != LayoutConfig.slotHeight;
      final headerChanged = newHeaderHeight != LayoutConfig.headerHeight;
      final hourChanged = newHourWidth != LayoutConfig.hourColumnWidth;

      // ──────────────────────────────────────────────
      // 🧩 Aggiorna il LayoutConfig globale
      // ──────────────────────────────────────────────
      LayoutConfig.updateSlotHeight(newSlotHeight);
      LayoutConfig.updateHeaderHeight(newHeaderHeight);
      LayoutConfig.updateHourColumnWidth(newHourWidth);

      if (slotChanged || headerChanged || hourChanged) {
        // 👇 piccolo trucco per forzare rebuild anche se il valore è identico
        if (newSlotHeight == state) {
          state = newSlotHeight + 0.0001;
          state = newSlotHeight;
        } else {
          state = newSlotHeight;
        }
      }
      debugPrint('Width: $screenWidth → hourColumnWidth: $newHourWidth');
    });
  }
}
