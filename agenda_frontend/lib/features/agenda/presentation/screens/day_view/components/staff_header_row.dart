import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../app/widgets/staff_circle_avatar.dart';
import '../../../../../../core/l10n/l10_extension.dart';
import '../../../../../../core/models/staff.dart';
import '../../../../../../core/widgets/app_dialogs.dart';
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          StaffCircleAvatar(
                            height: avatarSize,
                            color: staff.color,
                            isHighlighted: isHighlighted,
                            initials: initials,
                          ),
                          if (!staff.isBookableOnline)
                            Positioned.fill(
                              child: Align(
                                alignment: const Alignment(0.78, 0.78),
                                child: Transform.translate(
                                  offset: Offset(
                                    avatarSize * 0.02,
                                    avatarSize * 0.02,
                                  ),
                                  child: Tooltip(
                                    message: context.l10n
                                        .staffNotBookableOnlineTooltip,
                                    child: GestureDetector(
                                      onTap: () {
                                        showAppInfoDialog(
                                          context,
                                          title: Text(
                                            context.l10n
                                                .staffNotBookableOnlineTitle,
                                          ),
                                          content: Text(
                                            context.l10n
                                                .staffNotBookableOnlineMessage,
                                          ),
                                          closeLabel:
                                              context.l10n.actionClose,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.cloud_off_outlined,
                                          size: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
