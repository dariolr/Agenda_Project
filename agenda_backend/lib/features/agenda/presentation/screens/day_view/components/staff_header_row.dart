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
import '../../../../../staff/presentation/dialogs/staff_dialog.dart';

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
                  child: _StaffHeaderCell(
                    initials: initials,
                    displayName: displayName,
                    avatarSize: avatarSize,
                    isHighlighted: isHighlighted,
                    isBookableOnline: staff.isBookableOnline,
                    color: staff.color,
                    onEdit: () => showStaffDialog(
                      context,
                      ref,
                      initial: staff,
                    ),
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

class _StaffHeaderCell extends StatefulWidget {
  const _StaffHeaderCell({
    required this.initials,
    required this.displayName,
    required this.avatarSize,
    required this.isHighlighted,
    required this.isBookableOnline,
    required this.color,
    required this.onEdit,
  });

  final String initials;
  final String displayName;
  final double avatarSize;
  final bool isHighlighted;
  final bool isBookableOnline;
  final Color color;
  final VoidCallback onEdit;

  @override
  State<_StaffHeaderCell> createState() => _StaffHeaderCellState();
}

class _StaffHeaderCellState extends State<_StaffHeaderCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onEdit,
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    StaffCircleAvatar(
                      height: widget.avatarSize,
                      color: widget.color,
                      isHighlighted: widget.isHighlighted || _isHovered,
                      initials: widget.initials,
                    ),
                    if (!widget.isBookableOnline)
                      Positioned.fill(
                        child: Align(
                          alignment: const Alignment(0.78, 0.78),
                          child: Transform.translate(
                            offset: Offset(
                              widget.avatarSize * 0.02,
                              widget.avatarSize * 0.02,
                            ),
                            child: Tooltip(
                              message:
                                  context.l10n.staffNotBookableOnlineTooltip,
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
                                    closeLabel: context.l10n.actionClose,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_off_outlined,
                                    size: 14,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                  widget.displayName,
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
      ),
    );
  }
}
