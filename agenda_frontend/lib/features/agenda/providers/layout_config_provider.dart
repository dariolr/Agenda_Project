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
        hourColumnWidth: _deriveHourColumnWidth(context),
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

  double _deriveHourColumnWidth(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;

    final painter = TextPainter(
      text: TextSpan(text: '23:59', style: style),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();

    final baseWidth = painter.width;
    const extraPadding = LayoutConfig.horizontalPadding;
    const safety = 6.0; // margine ridotto oltre il testo

    final computed = baseWidth + extraPadding + safety;

    return computed.clamp(48.0, 80.0);
  }

  /// Aggiorna i minuti per slot in base alla scelta utente.
  void setMinutesPerSlot(int minutes) {
    if (!LayoutConfig.isValidSlotDuration(minutes)) {
      return;
    }

    if (state.minutesPerSlot == minutes) {
      return;
    }

    state = state.copyWith(minutesPerSlot: minutes);
  }

  /// Permette di scegliere se usare la larghezza uniforme sul picco di overlap.
  void setUseClusterMaxConcurrency(bool enabled) {
    if (state.useClusterMaxConcurrency == enabled) {
      return;
    }
    state = state.copyWith(useClusterMaxConcurrency: enabled);
  }

  /// Permette di scegliere se usare il colore del servizio per le card.
  void setUseServiceColors(bool enabled) {
    if (state.useServiceColorsForAppointments == enabled) {
      return;
    }
    state = state.copyWith(useServiceColorsForAppointments: enabled);
  }
}
