import 'package:flutter/material.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/extensions.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/staff.dart';
import '../../../services/providers/services_provider.dart';

class StaffItem extends ConsumerStatefulWidget {
  const StaffItem({
    super.key,
    required this.staff,
    required this.isLast,
    required this.isEvenRow,
    required this.isWide,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    this.trailingOverride,
  });

  final Staff staff;
  final bool isLast;
  final bool isEvenRow;
  final bool isWide;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Widget? trailingOverride;

  @override
  ConsumerState<StaffItem> createState() => _StaffItemState();
}

class _StaffItemState extends ConsumerState<StaffItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final interactionColors =
        Theme.of(context).extension<AppInteractionColors>();
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = widget.isEvenRow
        ? (interactionColors?.alternatingRowFill ??
            colorScheme.onSurface.withOpacity(0.04))
        : Colors.transparent;
    final hoverFill = interactionColors?.hoverFill ??
        colorScheme.primaryContainer.withOpacity(0.1);
    final bgColor = _isHovered ? hoverFill : baseColor;

    final eligibleServices = ref.watch(
      eligibleServicesForStaffProvider(widget.staff.id),
    );
    final eligibleServicesCount = eligibleServices.length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            bottomLeft: widget.isLast ? const Radius.circular(16) : Radius.zero,
            bottomRight:
                widget.isLast ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          minVerticalPadding: 0,
          leading: StaffCircleAvatar(
            height: 36,
            color: widget.staff.color,
            isHighlighted: false,
            initials: widget.staff.initials,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.staff.displayName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              if (eligibleServicesCount == 0) ...[
                const SizedBox(height: 2),
                Text(
                  context.l10n.teamEligibleServicesNone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              if (!widget.staff.isBookableOnline) ...[
                const SizedBox(height: 2),
                Text(
                  context.l10n.staffNotBookableOnlineTooltip,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
          onTap: widget.onEdit,
          mouseCursor: SystemMouseCursors.click,
          trailing: widget.trailingOverride ??
              (widget.isWide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: context.l10n.actionEdit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          tooltip: context.l10n.duplicateAction,
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: widget.onDuplicate,
                        ),
                        IconButton(
                          tooltip: context.l10n.actionDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    )
                  : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') widget.onEdit();
                        if (value == 'duplicate') widget.onDuplicate();
                        if (value == 'delete') widget.onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(context.l10n.actionEdit),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text(context.l10n.duplicateAction),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.l10n.actionDelete),
                        ),
                      ],
                    )),
        ),
      ),
    );
  }
}
