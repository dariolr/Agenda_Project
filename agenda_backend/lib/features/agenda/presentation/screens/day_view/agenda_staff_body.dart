import 'package:flutter/material.dart';

import '../../../../../core/models/appointment.dart';
import '../../../../../core/models/staff.dart';
import '../../../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../domain/config/layout_config.dart';
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
    required this.staffColumnWidths,
    required this.isResizing,
    required this.dragLayerLink,
    required this.bodyKey,
    required this.isInteractionLocked,
  });

  final ScrollController verticalController;
  final ScrollController horizontalController;
  final List<Staff> staffList;
  final List<Appointment> appointments;
  final LayoutConfig layoutConfig;
  final double availableWidth;
  final List<double> staffColumnWidths;
  final bool isResizing;
  final LayerLink? dragLayerLink;
  final GlobalKey bodyKey;
  final bool isInteractionLocked;

  @override
  Widget build(BuildContext context) {
    // staffColumnWidths già calcolati dal parent (uniformi o per-staff con expand)
    final totalContentWidth = staffColumnWidths.fold(0.0, (sum, w) => sum + w);

    // final hourColumnWidth = layoutConfig.hourColumnWidth;

    Widget content = ScrollConfiguration(
      // mantiene l'assenza di scrollbar come prima
      behavior: const NoScrollbarBehavior(),
      child: SingleChildScrollView(
        controller: verticalController,
        physics: isResizing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                                columnWidth: staffColumnWidths[index],
                                isInteractionLocked: isInteractionLocked,
                                // Questo flag ora è ignorato all'interno di StaffColumn,
                                // ma lo manteniamo per compatibilità.
                                showRightBorder:
                                    staffList.length > 1 && !isLast,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
}
