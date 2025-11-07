import 'package:flutter/material.dart';

import '../../../../../core/models/appointment.dart';
import '../../../../../core/models/staff.dart';
import '../../../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../domain/config/layout_config.dart';
import 'responsive_layout.dart';
import 'staff_column.dart';

class AgendaStaffBody extends StatelessWidget {
  const AgendaStaffBody({
    super.key,
    required this.verticalController,
    required this.horizontalController,
    required this.staffList,
    required this.appointments,
    required this.layoutConfig,
    required this.availableWidth,
    required this.isResizing,
    required this.dragLayerLink,
    required this.bodyKey,
    this.onHorizontalEdge,
  });

  final ScrollController verticalController;
  final ScrollController horizontalController;
  final List<Staff> staffList;
  final List<Appointment> appointments;
  final LayoutConfig layoutConfig;
  final double availableWidth;
  final bool isResizing;
  final LayerLink? dragLayerLink;
  final GlobalKey bodyKey;
  final ValueChanged<AxisDirection>? onHorizontalEdge;

  @override
  Widget build(BuildContext context) {
    final layout = ResponsiveLayout.of(
      context,
      staffCount: staffList.length,
      config: layoutConfig,
      availableWidth: availableWidth,
    );

    // final hourColumnWidth = layoutConfig.hourColumnWidth;

    Widget content = ScrollConfiguration(
      // mantiene l'assenza di scrollbar come prima
      behavior: const NoScrollbarBehavior(),
      child: SingleChildScrollView(
        controller: verticalController,
        physics: isResizing ? const NeverScrollableScrollPhysics() : null,
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const NoScrollbarBehavior(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleHorizontalNotification,
                      child: SingleChildScrollView(
                        controller: horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: staffList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final staff = entry.value;
                            final isLast = index == staffList.length - 1;
                            final staffAppointments = appointments
                                .where(
                                  (appointment) =>
                                      appointment.staffId == staff.id,
                                )
                                .toList();

                            return StaffColumn(
                              staff: staff,
                              appointments: staffAppointments,
                              columnWidth: layout.columnWidth,
                              showRightBorder: staffList.length > 1 && !isLast,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            //CurrentTimeLine(hourColumnWidth: hourColumnWidth),
          ],
        ),
      ),
    );

    if (dragLayerLink != null) {
      content = CompositedTransformTarget(
        key: bodyKey,
        link: dragLayerLink!,
        child: content,
      );
    } else {
      content = KeyedSubtree(key: bodyKey, child: content);
    }

    return content;
  }

  bool _handleHorizontalNotification(ScrollNotification notification) {
    if (onHorizontalEdge == null) return false;
    if (notification.metrics.axis != Axis.horizontal) return false;

    const edgeSlack = 8.0;
    final metrics = notification.metrics;

    if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        onHorizontalEdge?.call(AxisDirection.left);
      } else if (notification.overscroll > 0) {
        onHorizontalEdge?.call(AxisDirection.right);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final delta = notification.dragDetails!.primaryDelta ?? 0;
      final atStart = metrics.pixels <= metrics.minScrollExtent + edgeSlack;
      final atEnd = metrics.pixels >= metrics.maxScrollExtent - edgeSlack;

      if (atStart && delta > 0) {
        onHorizontalEdge?.call(AxisDirection.left);
      } else if (atEnd && delta < 0) {
        onHorizontalEdge?.call(AxisDirection.right);
      }
    }

    return false;
  }
}
