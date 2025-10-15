import 'package:flutter/material.dart';

class LayoutConfig {
  // ──────────────────────────────────────────────
  // 📐 DIMENSIONI STRUTTURALI
  // ──────────────────────────────────────────────

  static const double hourColumnWidth = 70;

  /// Altezza iniziale di default della barra header
  static double _headerHeight = 50;

  /// Getter per l’altezza corrente dell’header
  static double get headerHeight => _headerHeight;

  /// Aggiorna dinamicamente l’altezza dell’header
  static void updateHeaderHeight(double newHeight) {
    _headerHeight = newHeight;
  }

  static const int hoursInDay = 24;

  static const double horizontalPadding = 8;
  static const double verticalPadding = 4;

  /// 🔹 Larghezza minima garantita per ogni colonna staff
  static const double minColumnWidth = 180;

  /// 🔹 [maxColumnWidth] rimosso: le colonne si espandono liberamente

  static const double borderRadius = 8;

  // ──────────────────────────────────────────────
  // ⏱️ CONFIGURAZIONE SLOT TEMPORALI
  // ──────────────────────────────────────────────

  static const int minutesPerSlot = 30;

  static double _slotHeight = 30;

  static double get slotHeight => _slotHeight;

  static int get totalSlots => (hoursInDay * 60 ~/ minutesPerSlot);

  static double get totalHeight => totalSlots * _slotHeight;

  static void updateSlotHeight(double newHeight) {
    _slotHeight = newHeight;
  }

  // ──────────────────────────────────────────────
  // ⚙️ CALCOLI DINAMICI
  // ──────────────────────────────────────────────

  /// Calcola quanti staff possono essere mostrati in base alla larghezza schermo
  static int computeMaxVisibleStaff(double screenWidth) {
    final availableWidth = screenWidth - hourColumnWidth;
    final maxStaff = (availableWidth / minColumnWidth).floor();
    return maxStaff.clamp(1, 6);
  }

  /// 🔸 Calcola dinamicamente la larghezza di ogni colonna staff
  /// per riempire tutto lo spazio disponibile senza superare un minimo.
  static double computeAdaptiveColumnWidth({
    required double screenWidth,
    required int visibleStaffCount,
  }) {
    if (visibleStaffCount <= 0) return minColumnWidth;

    final availableWidth = screenWidth - hourColumnWidth;
    final idealWidth = availableWidth / visibleStaffCount;

    // 👇 Solo limite minimo
    return idealWidth < minColumnWidth ? minColumnWidth : idealWidth;
  }

  /// Altezza header “responsive” basata sulla larghezza finestra.
  static double headerHeightFor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 56; // Desktop
    if (width >= 600) return 52; // Tablet
    return 48; // Mobile
  }
}
