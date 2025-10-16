import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/highlighted_staff_provider.dart';

class StaffHeaderRow extends ConsumerWidget {
  final List<Staff> staffList;
  final ScrollController scrollController;
  final double columnWidth;
  final double hourColumnWidth;

  const StaffHeaderRow({
    super.key,
    required this.staffList,
    required this.scrollController,
    required this.columnWidth,
    required this.hourColumnWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = LayoutConfig.headerHeight;
    final highlightedId = ref.watch(highlightedStaffIdProvider);

    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          SizedBox(width: hourColumnWidth, height: headerHeight),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: staffList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final staff = entry.value;
                  final isLast = index == staffList.length - 1;
                  final isHighlighted = highlightedId == staff.id;

                  return Container(
                    width: columnWidth,
                    height: headerHeight,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? staff.color.withOpacity(0.18)
                          : staff.color.withOpacity(0.10),
                      border: Border(
                        right: BorderSide(
                          color: isLast
                              ? Colors.transparent
                              : Colors.grey.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    child: Text(
                      staff.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
