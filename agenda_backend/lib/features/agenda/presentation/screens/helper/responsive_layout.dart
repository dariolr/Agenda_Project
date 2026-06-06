import 'dart:math' as math;

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
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
    double? availableWidth,
    double columnWidthScale = 1.0,
    int mobileMaxColumns = 3,
  }) {
    final screenWidth = availableWidth ?? MediaQuery.of(context).size.width;
    final container = ProviderScope.containerOf(context, listen: false);
    final formFactor = container.read(formFactorProvider);

    // ──────────────────────────────────────────────
    // 📐 Calcolo larghezza colonne staff
    // ──────────────────────────────────────────────
    final effectiveMinWidth = formFactor == AppFormFactor.mobile
        ? LayoutConfig.minColumnWidthMobile
        : LayoutConfig.minColumnWidthDesktop * columnWidthScale;

    final dynamicMaxVisible = formFactor == AppFormFactor.mobile
        ? mobileMaxColumns.clamp(1, 3)
        : (screenWidth / effectiveMinWidth)
              .floor()
              .clamp(1, LayoutConfig.maxVisibleStaff);
    final visibleStaff = staffCount.clamp(1, dynamicMaxVisible);

    final idealWidth = screenWidth / visibleStaff;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final snappedIdealWidth = devicePixelRatio > 0
        ? (idealWidth * devicePixelRatio).floorToDouble() / devicePixelRatio
        : idealWidth;
    final resolvedColumnWidth = math.max(snappedIdealWidth, effectiveMinWidth);

    return ResponsiveLayout(
      columnWidth: resolvedColumnWidth,
      slotHeight: config.slotHeight,
      maxVisibleStaff: dynamicMaxVisible,
      totalSlots: config.totalSlots,
    );
  }

  double get totalHeight => totalSlots * slotHeight;
}
