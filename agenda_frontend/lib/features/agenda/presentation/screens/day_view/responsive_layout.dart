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

  static ResponsiveLayout of(
    BuildContext context, {
    required int staffCount,
    required LayoutConfig config,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    // ──────────────────────────────────────────────
    // 📐 Calcolo larghezza colonne staff
    // ──────────────────────────────────────────────
    final dynamicMaxVisible = config.computeMaxVisibleStaff(screenWidth);
    final availableWidth = screenWidth - config.hourColumnWidth;
    final rawWidth = availableWidth / staffCount.clamp(1, dynamicMaxVisible);

    // 🔸 Solo limite minimo: niente limite massimo
    final columnWidth = rawWidth < LayoutConfig.minColumnWidth
        ? LayoutConfig.minColumnWidth
        : rawWidth;

    return ResponsiveLayout(
      columnWidth: columnWidth,
      slotHeight: config.slotHeight,
      maxVisibleStaff: dynamicMaxVisible,
    );
  }

  double get totalHeight => LayoutConfig.totalSlots * slotHeight;
}
