import 'package:flutter/material.dart';

import '../../../../../core/models/staff.dart';
import '../../../../../core/widgets/no_scrollbar_behavior.dart';
import '../widgets/agenda_dividers.dart';
import 'staff_header_row.dart';

class AgendaStaffHeader extends StatelessWidget {
  const AgendaStaffHeader({
    super.key,
    required this.staffList,
    required this.hourColumnWidth,
    required this.totalHeight,
    required this.headerHeight,
    required this.columnWidth,
    required this.scrollController,
  });

  final List<Staff> staffList;
  final double hourColumnWidth;
  final double totalHeight;
  final double headerHeight;
  final double columnWidth;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x1F000000), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    offset: const Offset(3, 0),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SizedBox(width: hourColumnWidth, height: double.infinity),
            ),
            AgendaVerticalDivider(
              height: totalHeight,
              thickness: 1,
              color: staffList.isEmpty
                  ? Colors.transparent
                  : staffList.first.color.withOpacity(0.10),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: const NoScrollbarBehavior(),
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: StaffHeaderRow(
                    staffList: staffList,
                    scrollController: scrollController,
                    columnWidth: columnWidth,
                    hourColumnWidth: hourColumnWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
