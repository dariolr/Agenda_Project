import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/utils/price_utils.dart';

class ServiceItem extends ConsumerWidget {
  final Service service;
  final bool isLast;
  final bool isOddRow;
  final bool isHovered;
  final bool isSelected;
  final bool isWide;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ServiceItem({
    super.key,
    required this.service,
    required this.isLast,
    required this.isOddRow,
    required this.isHovered,
    required this.isSelected,
    required this.isWide,
    required this.colorScheme,
    required this.onTap,
    required this.onEnter,
    required this.onExit,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseColor = (isOddRow)
        ? colorScheme.onSurface.withOpacity(0.04)
        : Colors.transparent;

    final bgColor = (isHovered || isSelected)
        ? colorScheme.primaryContainer.withOpacity(0.1)
        : baseColor;

    return MouseRegion(
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!service.isBookableOnline)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      context.l10n.notBookableOnline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: service.description != null
                ? Text(
                    service.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (service.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      context.l10n.freeLabel,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Text(
                    PriceFormatter.formatService(
                      context: context,
                      ref: ref,
                      service: service,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                const SizedBox(width: 8),
                if (isWide) _buildActionIcons(context) else _buildPopupMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: context.l10n.actionEdit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: context.l10n.duplicateAction,
          icon: const Icon(Icons.copy_outlined),
          onPressed: onDuplicate,
        ),
        IconButton(
          tooltip: context.l10n.actionDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'duplicate':
            onDuplicate();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(context.l10n.actionEdit)),
        PopupMenuItem(
          value: 'duplicate',
          child: Text(context.l10n.duplicateAction),
        ),
        PopupMenuItem(value: 'delete', child: Text(context.l10n.actionDelete)),
      ],
    );
  }
}
