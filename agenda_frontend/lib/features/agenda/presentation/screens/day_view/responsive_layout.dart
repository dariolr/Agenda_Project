import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/config/layout_config.dart';

class ResponsiveLayout {
  final double columnWidth;
  final double slotHeight;
  final int maxVisibleStaff;
  final int totalSlots;

  const ResponsiveLayout({
    required this.columnWidth,
    required this.slotHeight,
    required this.maxVisibleStaff,
    required this.totalSlots,
  });

  static ResponsiveLayout of(
    BuildContext context, {
    required int staffCount,
    required LayoutConfig config,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final container = ProviderScope.containerOf(context, listen: false);
    final formFactor = container.read(formFactorProvider);

    // ──────────────────────────────────────────────
    // 📐 Calcolo larghezza colonne staff
    // ──────────────────────────────────────────────
    final dynamicMaxVisible = formFactor == AppFormFactor.mobile
        ? 2
        : config.computeMaxVisibleStaff(
            screenWidth,
            formFactor: formFactor,
          );
    final visibleStaff = staffCount.clamp(1, dynamicMaxVisible);

    final columnWidth = config.computeAdaptiveColumnWidth(
      screenWidth: screenWidth,
      visibleStaffCount: visibleStaff,
      formFactor: formFactor,
    );

    return ResponsiveLayout(
      columnWidth: columnWidth,
      slotHeight: config.slotHeight,
      maxVisibleStaff: dynamicMaxVisible,
      totalSlots: config.totalSlots,
    );
  }

  double get totalHeight => totalSlots * slotHeight;
}
