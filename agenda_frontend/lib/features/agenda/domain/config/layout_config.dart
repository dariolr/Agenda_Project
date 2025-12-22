import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';

/// Immutable snapshot of the current layout dimensions used by the agenda.
class LayoutConfig {
  // ──────────────────────────────────────────────
  // 📐 Costanti strutturali
  // ──────────────────────────────────────────────

  static const int hoursInDay = 24;
  static const List<int> slotDurationOptions = [15, 30, 60, 120];
  static const int minutesPerSlotConst = 15;

  static const double horizontalPadding = 8;
  static const double verticalPadding = 4;
  static const double columnInnerPadding = 2;
  static const double minColumnWidthMobile = 140;
  static const double minColumnWidthDesktop = 160;
  static const double borderRadius = 8;
  static const double borderWidth = 1;
  static const int maxVisibleStaff = 6;

  /// Larghezza della fascia laterale per il pulsante "+" sugli slot occupati
  static const double addButtonStripWidth = 28;

  static const double defaultHourColumnWidth = 60;
  static const double defaultHeaderHeight = 50;
  static const double defaultSlotHeight = 30;

  static const LayoutConfig initial = LayoutConfig(
    slotHeight: defaultSlotHeight,
    headerHeight: defaultHeaderHeight,
    hourColumnWidth: defaultHourColumnWidth,
    minutesPerSlot: minutesPerSlotConst,
    useClusterMaxConcurrency: true,
    useServiceColorsForAppointments: true,
    enableOccupiedSlotStrip: false,
    showTopbarAddLabel: false,
  );

  // ──────────────────────────────────────────────
  // 📏 Stato dinamico
  // ──────────────────────────────────────────────

  final double slotHeight;
  final double headerHeight;
  final double hourColumnWidth;
  final int minutesPerSlot;
  final bool useClusterMaxConcurrency;
  final bool useServiceColorsForAppointments;

  /// Se true, riserva una fascia laterale quando ci sono slot completamente occupati.
  /// Permette di cliccare sullo spazio libero per creare nuovi appuntamenti.
  final bool enableOccupiedSlotStrip;

  /// Se true, il pulsante "Aggiungi" in topbar mostra anche la label.
  final bool showTopbarAddLabel;

  const LayoutConfig({
    required this.slotHeight,
    required this.headerHeight,
    required this.hourColumnWidth,
    required this.minutesPerSlot,
    required this.useClusterMaxConcurrency,
    required this.useServiceColorsForAppointments,
    required this.enableOccupiedSlotStrip,
    required this.showTopbarAddLabel,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LayoutConfig) return false;
    return slotHeight == other.slotHeight &&
        headerHeight == other.headerHeight &&
        hourColumnWidth == other.hourColumnWidth &&
        minutesPerSlot == other.minutesPerSlot &&
        useClusterMaxConcurrency == other.useClusterMaxConcurrency &&
        useServiceColorsForAppointments ==
            other.useServiceColorsForAppointments &&
        enableOccupiedSlotStrip == other.enableOccupiedSlotStrip &&
        showTopbarAddLabel == other.showTopbarAddLabel;
  }

  @override
  int get hashCode => Object.hash(
    slotHeight,
    headerHeight,
    hourColumnWidth,
    minutesPerSlot,
    useClusterMaxConcurrency,
    useServiceColorsForAppointments,
    enableOccupiedSlotStrip,
    showTopbarAddLabel,
  );

  LayoutConfig copyWith({
    double? slotHeight,
    double? headerHeight,
    double? hourColumnWidth,
    int? minutesPerSlot,
    bool? useClusterMaxConcurrency,
    bool? useServiceColorsForAppointments,
    bool? enableOccupiedSlotStrip,
    bool? showTopbarAddLabel,
  }) {
    return LayoutConfig(
      slotHeight: slotHeight ?? this.slotHeight,
      headerHeight: headerHeight ?? this.headerHeight,
      hourColumnWidth: hourColumnWidth ?? this.hourColumnWidth,
      minutesPerSlot: minutesPerSlot ?? this.minutesPerSlot,
      useClusterMaxConcurrency:
          useClusterMaxConcurrency ?? this.useClusterMaxConcurrency,
      useServiceColorsForAppointments:
          useServiceColorsForAppointments ??
          this.useServiceColorsForAppointments,
      enableOccupiedSlotStrip:
          enableOccupiedSlotStrip ?? this.enableOccupiedSlotStrip,
      showTopbarAddLabel: showTopbarAddLabel ?? this.showTopbarAddLabel,
    );
  }

  int get totalSlots => (hoursInDay * 60 ~/ minutesPerSlot);

  double get totalHeight => totalSlots * slotHeight;

  static bool isValidSlotDuration(int minutes) =>
      slotDurationOptions.contains(minutes);

  /// Calcola quanti staff possono essere mostrati in base alla larghezza schermo.
  int computeMaxVisibleStaff(
    double contentWidth, {
    required AppFormFactor formFactor,
  }) {
    final minWidth = formFactor == AppFormFactor.mobile
        ? minColumnWidthMobile
        : minColumnWidthDesktop;

    final usableWidth = contentWidth.clamp(0, double.infinity);
    final maxStaff = (usableWidth / minWidth).floor();
    return maxStaff.clamp(1, maxVisibleStaff);
  }

  /// Calcola dinamicamente la larghezza di ogni colonna staff.
  double computeAdaptiveColumnWidth({
    required double contentWidth,
    required int visibleStaffCount,
    required AppFormFactor formFactor,
  }) {
    final minWidth = formFactor == AppFormFactor.mobile
        ? minColumnWidthMobile
        : minColumnWidthDesktop;

    if (visibleStaffCount <= 0) {
      return minWidth;
    }

    final usableWidth = contentWidth.clamp(0, double.infinity);
    final idealWidth = usableWidth / visibleStaffCount;

    return idealWidth < minWidth ? minWidth : idealWidth;
  }

  /// Altezza header “responsive” basata sulla larghezza finestra.
  static double headerHeightFor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return headerHeightForWidth(width);
  }

  static double headerHeightForWidth(double width) {
    if (width >= 1024) return 110; // Desktop
    if (width >= 600) return 95; // Tablet
    return 80; // Mobile
  }

  /// Dimensione avatar staff "responsive" basata sulla larghezza finestra.
  static double avatarSizeFor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return avatarSizeForWidth(width);
  }

  static double avatarSizeForWidth(double width) {
    if (width >= 1024) return 65; // Desktop
    if (width >= 600) return 57; // Tablet
    return 52; // Mobile
  }
}
