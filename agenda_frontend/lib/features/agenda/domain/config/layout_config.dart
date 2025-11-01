import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';

/// Immutable snapshot of the current layout dimensions used by the agenda.
class LayoutConfig {
  // ──────────────────────────────────────────────
  // 📐 Costanti strutturali
  // ──────────────────────────────────────────────

  static const int hoursInDay = 24;
  static const List<int> slotDurationOptions = [15, 30, 60, 120];

  static const double horizontalPadding = 8;
  static const double verticalPadding = 4;
  static const double minColumnWidthMobile = 140;
  static const double minColumnWidthDesktop = 160;
  static const double borderRadius = 8;
  static const int maxVisibleStaff = 6;

  static const double defaultHourColumnWidth = 60;
  static const double defaultHeaderHeight = 50;
  static const double defaultSlotHeight = 30;

  static const LayoutConfig initial = LayoutConfig(
    slotHeight: defaultSlotHeight,
    headerHeight: defaultHeaderHeight,
    hourColumnWidth: defaultHourColumnWidth,
    minutesPerSlot: 15,
  );

  // ──────────────────────────────────────────────
  // 📏 Stato dinamico
  // ──────────────────────────────────────────────

  final double slotHeight;
  final double headerHeight;
  final double hourColumnWidth;
  final int minutesPerSlot;

  const LayoutConfig({
    required this.slotHeight,
    required this.headerHeight,
    required this.hourColumnWidth,
    required this.minutesPerSlot,
  });

  LayoutConfig copyWith({
    double? slotHeight,
    double? headerHeight,
    double? hourColumnWidth,
    int? minutesPerSlot,
  }) {
    return LayoutConfig(
      slotHeight: slotHeight ?? this.slotHeight,
      headerHeight: headerHeight ?? this.headerHeight,
      hourColumnWidth: hourColumnWidth ?? this.hourColumnWidth,
      minutesPerSlot: minutesPerSlot ?? this.minutesPerSlot,
    );
  }

  int get totalSlots => (hoursInDay * 60 ~/ minutesPerSlot);

  double get totalHeight => totalSlots * slotHeight;

  static bool isValidSlotDuration(int minutes) =>
      slotDurationOptions.contains(minutes);

  /// Calcola quanti staff possono essere mostrati in base alla larghezza schermo.
  int computeMaxVisibleStaff(
    double screenWidth, {
    required AppFormFactor formFactor,
  }) {
    final minWidth = formFactor == AppFormFactor.mobile
        ? minColumnWidthMobile
        : minColumnWidthDesktop;

    final availableWidth = screenWidth - hourColumnWidth;
    final maxStaff = (availableWidth / minWidth).floor();
    return maxStaff.clamp(1, maxVisibleStaff);
  }

  /// Calcola dinamicamente la larghezza di ogni colonna staff.
  double computeAdaptiveColumnWidth({
    required double screenWidth,
    required int visibleStaffCount,
    required AppFormFactor formFactor,
  }) {
    final minWidth = formFactor == AppFormFactor.mobile
        ? minColumnWidthMobile
        : minColumnWidthDesktop;

    if (visibleStaffCount <= 0) {
      return minWidth;
    }

    final availableWidth = screenWidth - hourColumnWidth;
    final idealWidth = availableWidth / visibleStaffCount;

    return idealWidth < minWidth ? minWidth : idealWidth;
  }

  /// Altezza header “responsive” basata sulla larghezza finestra.
  static double headerHeightFor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return headerHeightForWidth(width);
  }

  static double headerHeightForWidth(double width) {
    if (width >= 1024) return 56; // Desktop
    if (width >= 600) return 52; // Tablet
    return 48; // Mobile
  }
}
