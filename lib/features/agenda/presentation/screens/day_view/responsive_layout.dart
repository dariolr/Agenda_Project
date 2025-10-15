import 'package:flutter/material.dart';

import '../../../domain/config/layout_config.dart';

class ResponsiveLayout {
  final double columnWidth;
  final double slotHeight;
  final int maxVisibleStaff;

  const ResponsiveLayout({
    required this.columnWidth,
    required this.slotHeight,
    required this.maxVisibleStaff,
  });

  static ResponsiveLayout of(BuildContext context, {required int staffCount}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ──────────────────────────────────────────────
    // 📐 Calcolo larghezza colonne staff
    // ──────────────────────────────────────────────
    final dynamicMaxVisible = LayoutConfig.computeMaxVisibleStaff(screenWidth);

    final availableWidth = screenWidth - LayoutConfig.hourColumnWidth;
    final rawWidth = availableWidth / staffCount.clamp(1, dynamicMaxVisible);

    // 🔸 Solo limite minimo: niente limite massimo
    final columnWidth = rawWidth < LayoutConfig.minColumnWidth
        ? LayoutConfig.minColumnWidth
        : rawWidth;

    // ──────────────────────────────────────────────
    // ⏱️ Calcolo altezza slot dinamica
    // ──────────────────────────────────────────────
    double slotHeight = LayoutConfig.slotHeight;

    if (screenHeight < 700) {
      slotHeight = LayoutConfig.slotHeight * 0.8;
    } else if (screenHeight > 1200) {
      slotHeight = LayoutConfig.slotHeight * 1.2;
    }

    slotHeight = slotHeight.roundToDouble();

    // 🔁 Aggiorna LayoutConfig globale
    LayoutConfig.updateSlotHeight(slotHeight);

    return ResponsiveLayout(
      columnWidth: columnWidth,
      slotHeight: slotHeight,
      maxVisibleStaff: dynamicMaxVisible,
    );
  }

  double get totalHeight => LayoutConfig.totalSlots * slotHeight;
}
