import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../app/widgets/staff_circle_avatar.dart';
import '../../../../../../core/models/staff.dart';
import '../../../../providers/highlighted_staff_provider.dart';
import '../../../../providers/layout_config_provider.dart';

class StaffHeaderRow extends ConsumerWidget {
  final List<Staff> staffList;
  final ScrollController
  scrollController; // non usato per scrollare qui, ma utile per offset/read
  final double columnWidth;
  final double hourColumnWidth; // NON usato per lasciare spazio iniziale

  const StaffHeaderRow({
    super.key,
    required this.staffList,
    required this.scrollController,
    required this.columnWidth,
    required this.hourColumnWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = ref.watch(layoutConfigProvider).headerHeight;
    final highlightedId = ref.watch(highlightedStaffIdProvider);

    // ⚠️ Nessuna SizedBox iniziale qui! Lo spazio per l'ora è già messo nel parent.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: staffList.asMap().entries.map((entry) {
        final index = entry.key;
        final staff = entry.value;
        final isLast = index == staffList.length - 1;
        final isHighlighted = highlightedId == staff.id;

        final initials = staff.initials;
        final displayName = staff.displayName;

        return Container(
          width: columnWidth,
          height: headerHeight,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: isLast
                    ? Colors.transparent
                    : Colors.grey.withOpacity(0.25),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: headerHeight * 0.18),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StaffCircleAvatar(
                  height: headerHeight * 0.78,
                  color: staff.color,
                  isHighlighted: isHighlighted,
                  initials: initials,
                ),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
