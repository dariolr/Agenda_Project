import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_scroll_provider.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/layout_config_provider.dart';
import '../widgets/agenda_dividers.dart';
import 'hour_column.dart';
import 'responsive_layout.dart';
import 'staff_column.dart';
import 'staff_header_row.dart';

class MultiStaffDayView extends ConsumerWidget {
  final List<Staff> staffList;

  const MultiStaffDayView({super.key, required this.staffList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider);
    final scrollState = ref.watch(agendaScrollProvider(staffList));
    final layout = ResponsiveLayout.of(context, staffCount: staffList.length);
    final slotHeight = ref.watch(layoutConfigProvider);

    final totalContentHeight = LayoutConfig.totalSlots * slotHeight;
    final hourWidth = LayoutConfig.hourColumnWidth;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 3,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: LayoutConfig.headerHeight,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                ),
                child: StaffHeaderRow(
                  staffList: staffList,
                  scrollController: scrollState.horizontalScrollCtrl,
                  columnWidth: layout.columnWidth,
                  hourColumnWidth: hourWidth,
                ),
              ),
            ),

            Expanded(
              child: ScrollConfiguration(
                behavior: const NoScrollbarBehavior(),
                child: SingleChildScrollView(
                  controller: scrollState.verticalScrollCtrl,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: hourWidth, child: const HourColumn()),
                      AgendaVerticalDivider(height: totalContentHeight),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollState.horizontalScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: staffList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final staff = entry.value;
                              final isLast = index == staffList.length - 1;
                              final staffAppointments = appointments
                                  .where((a) => a.staffId == staff.id)
                                  .toList();

                              return StaffColumn(
                                staff: staff,
                                appointments: staffAppointments,
                                columnWidth: layout.columnWidth,
                                showRightBorder:
                                    staffList.length > 1 && !isLast,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
