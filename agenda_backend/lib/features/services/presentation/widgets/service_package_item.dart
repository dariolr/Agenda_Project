import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service_package.dart';
import '../../../../core/utils/price_utils.dart';

class ServicePackageListItem extends ConsumerWidget {
  final ServicePackage package;
  final bool isLast;
  final bool isEvenRow;
  final bool isWide;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool readOnly;

  const ServicePackageListItem({
    super.key,
    required this.package,
    required this.isLast,
    required this.isEvenRow,
    required this.isWide,
    required this.colorScheme,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseColor = isEvenRow
        ? colorScheme.onSurface.withOpacity(0.04)
        : Colors.transparent;
    final bgColor = baseColor;
    final currency = PriceFormatter.effectiveCurrency(ref);
    final price = PriceFormatter.format(
      context: context,
      amount: package.effectivePrice,
      currencyCode: currency,
    );
    final durationLabel = context.localizedDurationLabel(
      package.effectiveDurationMinutes,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: isLast
                          ? const Radius.circular(16)
                          : Radius.zero,
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                    mouseCursor: SystemMouseCursors.click,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                durationLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                price,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!package.isActive || package.isBroken)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (!package.isActive)
                                  _StatusChip(
                                    label: context
                                        .l10n
                                        .servicePackageInactiveLabel,
                                    color: colorScheme.outline,
                                  ),
                                if (package.isBroken)
                                  _StatusChip(
                                    label:
                                        context.l10n.servicePackageBrokenLabel,
                                    color: colorScheme.error,
                                  ),
                              ],
                            ),
                          ),
                        if (!package.isBookableOnline)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              context.l10n.notBookableOnline,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.red[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    trailing: UnconstrainedBox(
                      alignment: Alignment.centerRight,
                      child: readOnly
                          ? null
                          : isWide
                          ? _buildActionIcons(context)
                          : _buildPopupMenu(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.l10n.actionEdit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: context.l10n.actionDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(context.l10n.actionEdit)),
        PopupMenuItem(value: 'delete', child: Text(context.l10n.actionDelete)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
