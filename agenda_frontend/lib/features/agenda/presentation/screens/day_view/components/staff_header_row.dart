import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../app/widgets/staff_circle_avatar.dart';
import '../../../../../../core/models/staff.dart';
import '../../../../domain/config/layout_config.dart';
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
    final avatarDefault = LayoutConfig.avatarSizeFor(context);
    // Ensure avatar is not larger than available header space to avoid overflow
    final avatarSize = math.min(avatarDefault, headerHeight * 0.55);
    final highlightedId = ref.watch(highlightedStaffIdProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: hourColumnWidth),
        ...staffList.asMap().entries.map((entry) {
          final index = entry.key;
          final staff = entry.value;
          final isLast = index == staffList.length - 1;
          final isHighlighted = highlightedId == staff.id;

          final initials = staff.initials;
          final displayName = staff.displayName;

          return Stack(
            children: [
              Container(
                width: columnWidth,
                height: headerHeight,
                padding: EdgeInsets.symmetric(horizontal: headerHeight * 0.08),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StaffCircleAvatar(
                        height: avatarSize,
                        color: staff.color,
                        isHighlighted: isHighlighted,
                        initials: initials,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey.withOpacity(0.0),
                          Colors.grey.withOpacity(0.25),
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
