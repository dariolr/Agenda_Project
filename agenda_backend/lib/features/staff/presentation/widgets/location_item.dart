import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/staff.dart';
import '../../../services/presentation/widgets/empty_state.dart';
import 'staff_item.dart';

class LocationItem extends StatelessWidget {
  const LocationItem({
    super.key,
    required this.location,
    required this.staff,
    required this.isWide,
    required this.onAddStaff,
    required this.onEditLocation,
    required this.onDeleteLocation,
    required this.onEditStaff,
    required this.onDuplicateStaff,
    required this.onDeleteStaff,
    this.onManageResources,
    this.headerTrailing,
    this.staffListOverride,
    this.showDefaultActions = true,
    this.readOnly = false,
  });

  final Location location;
  final List<Staff> staff;
  final bool isWide;
  final VoidCallback onAddStaff;
  final VoidCallback onEditLocation;
  final VoidCallback onDeleteLocation;
  final ValueChanged<Staff> onEditStaff;
  final ValueChanged<Staff> onDuplicateStaff;
  final ValueChanged<Staff> onDeleteStaff;
  final VoidCallback? onManageResources;
  final Widget? headerTrailing;
  final Widget? staffListOverride;
  final bool showDefaultActions;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmptyLocation = staff.isEmpty;
    final locationBorderColor = colorScheme.outlineVariant.withOpacity(0.16);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: locationBorderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: locationBorderColor),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              location.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ID: ${location.id}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (location.address != null &&
                          location.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            location.address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.black54,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDefaultActions && !readOnly) ...[
                      IconButton(
                        tooltip: context.l10n.teamAddStaff,
                        icon: const Icon(Icons.person_add_alt_1),
                        onPressed: onAddStaff,
                      ),
                      if (onManageResources != null)
                        IconButton(
                          tooltip: context.l10n.resourcesTitle,
                          icon: const Icon(Icons.inventory_2_outlined),
                          onPressed: onManageResources,
                        ),
                      IconButton(
                        tooltip: context.l10n.actionEdit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEditLocation,
                      ),
                      if (isEmptyLocation)
                        IconButton(
                          tooltip: context.l10n.actionDelete,
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: onDeleteLocation,
                        ),
                    ],
                    if (headerTrailing != null) headerTrailing!,
                  ],
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child:
                staffListOverride ??
                (isEmptyLocation
                    ? ServicesEmptyState(
                        message: context.l10n.teamNoStaffInLocation,
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < staff.length; i++)
                            StaffItem(
                              staff: staff[i],
                              isLast: i == staff.length - 1,
                              isEvenRow: i.isEven,
                              isWide: isWide,
                              readOnly: readOnly,
                              onEdit: () => onEditStaff(staff[i]),
                              onDuplicate: () => onDuplicateStaff(staff[i]),
                              onDelete: () => onDeleteStaff(staff[i]),
                            ),
                        ],
                      )),
          ),
        ],
      ),
    );
  }
}
