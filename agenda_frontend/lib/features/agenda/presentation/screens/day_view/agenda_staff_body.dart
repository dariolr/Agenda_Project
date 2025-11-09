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

    final totalContentWidth = layout.columnWidth * staffList.length;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

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
                        physics: const ClampingScrollPhysics(),
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: totalContentWidth,
                          child: Stack(
                            children: [
                              // 🔹 Colonne staff (come prima)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: staffList.asMap().entries.map((
                                  entry,
                                ) {
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
                                    // Questo flag ora è ignorato all'interno di StaffColumn,
                                    // ma lo manteniamo per compatibilità.
                                    showRightBorder:
                                        staffList.length > 1 && !isLast,
                                  );
                                }).toList(),
                              ),

                              // 🔹 Overlay con le linee di separazione tra colonne
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _StaffColumnSeparatorPainter(
                                      columnWidth: layout.columnWidth,
                                      staffCount: staffList.length,
                                      scrollController: horizontalController,
                                      devicePixelRatio: devicePixelRatio,
                                      color: Colors.grey.withOpacity(0.5),
                                      strokeWidth: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

    const edgeSlack = 0.0;
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

/// 🔹 Painter per le linee verticali di separazione tra colonne staff.
/// - Disegna solo separatori interni (tra le colonne, non ai bordi).
/// - Skippa la linea che cade esattamente sotto il bordo sinistro
///   della viewport (per evitare il "bordino" della colonna precedente).
class _StaffColumnSeparatorPainter extends CustomPainter {
  final double columnWidth;
  final int staffCount;
  final ScrollController scrollController;
  final double devicePixelRatio;
  final Color color;
  final double strokeWidth;

  _StaffColumnSeparatorPainter({
    required this.columnWidth,
    required this.staffCount,
    required this.scrollController,
    required this.devicePixelRatio,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: scrollController);

  @override
  void paint(Canvas canvas, Size size) {
    if (staffCount <= 1 || columnWidth <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    final height = size.height;
    final offset = scrollController.hasClients ? scrollController.offset : 0.0;

    // tolleranza per confrontare offset e posizione linea
    const epsilon = 0.5;

    for (var i = 1; i < staffCount; i++) {
      double x = i * columnWidth;

      // Se la linea coincide con il bordo sinistro della viewport,
      // la saltiamo per evitare il "bordino" della colonna precedente.
      if ((x - offset).abs() < epsilon) {
        continue;
      }

      // Snap alla griglia dei pixel per evitare blur su web
      x = (x * devicePixelRatio).roundToDouble() / devicePixelRatio;

      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaffColumnSeparatorPainter oldDelegate) {
    return oldDelegate.columnWidth != columnWidth ||
        oldDelegate.staffCount != staffCount ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.devicePixelRatio != devicePixelRatio ||
        oldDelegate.scrollController != scrollController;
  }
}
