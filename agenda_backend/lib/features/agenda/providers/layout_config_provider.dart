import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/preferences_service.dart';
import '../domain/config/agenda_theme.dart';
import '../domain/config/layout_config.dart';
import 'business_providers.dart';
import 'location_providers.dart';

part 'layout_config_provider.g.dart';

/// Mantiene aggiornata la configurazione del layout agenda (slot/header/hour column).
@riverpod
class LayoutConfigNotifier extends _$LayoutConfigNotifier {
  Timer? _resizeDebounce;
  static const _minSlotHeightScale = 0.6;
  static const _maxSlotHeightScale = 1.6;

  @override
  LayoutConfig build() {
    ref.onDispose(() {
      _resizeDebounce?.cancel();
    });
    final businessId = ref.watch(currentBusinessIdProvider);
    final locationId = ref.watch(currentLocationIdProvider);
    final prefs = ref.watch(preferencesServiceProvider);
    final slotHeightScale = (businessId > 0 && locationId > 0)
        ? prefs
              .getAgendaSlotHeightScale(businessId, locationId: locationId)
              .clamp(_minSlotHeightScale, _maxSlotHeightScale)
        : LayoutConfig.defaultSlotHeightScale;

    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.implicitView;
    final logicalSize = view != null
        ? Size(
            view.physicalSize.width / view.devicePixelRatio,
            view.physicalSize.height / view.devicePixelRatio,
          )
        : ui.window.physicalSize / ui.window.devicePixelRatio;

    final initialHeaderHeight = logicalSize.width > 0
        ? LayoutConfig.headerHeightForWidth(logicalSize.width)
        : LayoutConfig.defaultHeaderHeight;
    final initialHourWidth = _initialHourColumnWidth();

    return LayoutConfig.initial.copyWith(
      slotHeightScale: slotHeightScale,
      headerHeight: initialHeaderHeight,
      slotHeight: LayoutConfig.slotHeightForMinutesPerSlot(
        LayoutConfig.minutesPerSlotConst,
        slotHeightScale: slotHeightScale,
      ),
      hourColumnWidth: initialHourWidth,
    );
  }

  /// Aggiorna header e colonna oraria in base alla finestra.
  ///
  /// La scala verticale agenda non dipende dalla viewport.
  void updateFromContext(BuildContext context) {
    _resizeDebounce?.cancel();

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    _resizeDebounce = Timer(const Duration(milliseconds: 100), () {
      final next = state.copyWith(
        slotHeight: LayoutConfig.slotHeightForMinutesPerSlot(
          state.minutesPerSlot,
          slotHeightScale: state.slotHeightScale,
        ),
        headerHeight: _deriveHeaderHeight(screenWidth),
        hourColumnWidth: _deriveHourColumnWidth(context),
      );

      if (next != state) {
        state = next;
      }
    });
  }

  double _deriveHeaderHeight(double screenWidth) =>
      LayoutConfig.headerHeightForWidth(screenWidth);

  double _initialHourColumnWidth() {
    const textDirection = TextDirection.ltr;
    const style = AgendaTheme.hourTextStyle;
    return _computeHourColumnWidth(style, textDirection);
  }

  double _deriveHourColumnWidth(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.bodyMedium ?? AgendaTheme.hourTextStyle;
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;

    return _computeHourColumnWidth(style, textDirection);
  }

  double _computeHourColumnWidth(TextStyle style, TextDirection textDirection) {
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

    state = state.copyWith(
      minutesPerSlot: minutes,
      slotHeight: LayoutConfig.slotHeightForMinutesPerSlot(
        minutes,
        slotHeightScale: state.slotHeightScale,
      ),
    );
  }

  void setSlotHeightScale(double scale) {
    final nextScale = scale.clamp(_minSlotHeightScale, _maxSlotHeightScale);
    if ((state.slotHeightScale - nextScale).abs() < 0.0001) {
      return;
    }
    state = state.copyWith(
      slotHeightScale: nextScale,
      slotHeight: LayoutConfig.slotHeightForMinutesPerSlot(
        state.minutesPerSlot,
        slotHeightScale: nextScale,
      ),
    );
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

  /// Permette di mostrare la label del pulsante "Aggiungi" in topbar.
  void setShowTopbarAddLabel(bool enabled) {
    if (state.showTopbarAddLabel == enabled) {
      return;
    }
    state = state.copyWith(showTopbarAddLabel: enabled);
  }
}
