import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/config/layout_config.dart';

part 'layout_config_provider.g.dart';

/// Mantiene aggiornata la configurazione del layout agenda (slot/header/hour column).
@riverpod
class LayoutConfigNotifier extends _$LayoutConfigNotifier {
  Timer? _resizeDebounce;

  @override
  LayoutConfig build() {
    ref.onDispose(() {
      _resizeDebounce?.cancel();
    });
    return LayoutConfig.initial;
  }

  /// Aggiorna dinamicamente l’altezza degli slot e dell’header
  /// in base alle dimensioni della finestra.
  void updateFromContext(BuildContext context) {
    _resizeDebounce?.cancel();

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    _resizeDebounce = Timer(const Duration(milliseconds: 100), () {
      final next = state.copyWith(
        slotHeight: _deriveSlotHeight(screenHeight),
        headerHeight: _deriveHeaderHeight(screenWidth),
        hourColumnWidth: _deriveHourColumnWidth(screenWidth),
      );

      if (next != state) {
        state = next;
      }
    });
  }

  double _deriveSlotHeight(double screenHeight) {
    if (screenHeight < 700) {
      return LayoutConfig.defaultSlotHeight * 0.8;
    }
    if (screenHeight > 1200) {
      return LayoutConfig.defaultSlotHeight * 1.2;
    }
    return LayoutConfig.defaultSlotHeight;
  }

  double _deriveHeaderHeight(double screenWidth) =>
      LayoutConfig.headerHeightForWidth(screenWidth);

  double _deriveHourColumnWidth(double screenWidth) {
    if (screenWidth >= 1024) {
      return 60;
    }
    if (screenWidth >= 600) {
      return 55;
    }
    return 50;
  }
}
