import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/extensions.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../agenda/providers/location_providers.dart';
import '../../providers/services_provider.dart';

class ServiceItem extends ConsumerWidget {
  final Service service;
  final bool isLast;
  final bool isEvenRow;
  final bool isHovered;
  final bool isSelected;
  final bool isWide;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onCopyDirectLink;
  final VoidCallback onDelete;
  final bool readOnly;

  const ServiceItem({
    super.key,
    required this.service,
    required this.isLast,
    required this.isEvenRow,
    required this.isHovered,
    required this.isSelected,
    required this.isWide,
    required this.colorScheme,
    required this.onTap,
    required this.onEnter,
    required this.onExit,
    required this.onEdit,
    required this.onDuplicate,
    required this.onCopyDirectLink,
    required this.onDelete,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionColors = Theme.of(
      context,
    ).extension<AppInteractionColors>();
    final variant = ref.watch(serviceVariantByServiceIdProvider(service.id));
    final eligibleStaffIds = ref.watch(
      eligibleStaffForServiceProvider(service.id),
    );
    final eligibleStaffCount = eligibleStaffIds.length;
    final baseColor = isEvenRow
        ? (interactionColors?.alternatingRowFill ??
              colorScheme.onSurface.withOpacity(0.04))
        : Colors.transparent;

    final hoverFill =
        interactionColors?.hoverFill ??
        colorScheme.primaryContainer.withOpacity(0.1);
    final bgColor = (isHovered || isSelected) ? hoverFill : baseColor;

    final durationMinutes = variant?.durationMinutes;
    final extraMinutes =
        (variant?.processingTime ?? 0) + (variant?.blockedTime ?? 0);
    final totalMinutes = (durationMinutes ?? 0) + extraMinutes;
    final durationLabel = durationMinutes != null
        ? context.localizedDurationLabel(
            extraMinutes > 0 ? totalMinutes : durationMinutes,
          )
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: Material(
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
                      color: variant?.colorHex != null
                          ? ColorUtils.fromHex(variant!.colorHex!)
                          : colorScheme.primary,
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
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          if (eligibleStaffCount == 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.serviceEligibleStaffNone,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                          if (durationLabel != null ||
                              variant?.price != null ||
                              (variant?.isFree ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (durationLabel != null)
                                    Text(
                                      durationLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                        height: 1.1,
                                      ),
                                    ),
                                  if (durationLabel != null &&
                                      (variant?.price != null ||
                                          (variant?.isFree ?? false)))
                                    const SizedBox(width: 8),
                                  if (variant?.isFree ?? false)
                                    Text(
                                      context.l10n.freeLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                        height: 1.1,
                                      ),
                                    )
                                  else if (variant?.price != null)
                                    Text(
                                      service.isPriceStartingFrom
                                          ? '${context.l10n.priceStartingFromPrefix} ${PriceFormatter.formatVariant(context: context, ref: ref, variant: variant!)}'
                                          : PriceFormatter.formatVariant(
                                              context: context,
                                              ref: ref,
                                              variant: variant!,
                                            ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                        height: 1.1,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (!(variant?.isBookableOnline ?? true))
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
                            ? _buildActionIcons(context, ref)
                            : _buildPopupMenu(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(serviceVariantByServiceIdProvider(service.id));
    final isBookableOnline = variant?.isBookableOnline ?? true;
    final serviceLocationIds = ref
        .watch(serviceLocationIdsProvider(service.id))
        .value;
    final deletePresentation = _resolveDeletePresentation(
      context,
      ref,
      serviceLocationIds,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
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
          tooltip: context.l10n.closuresImportHolidaysCopyLinkAction,
          icon: Icon(
            Icons.link_outlined,
            color: (service.onlineVisibility == 'hidden' || !isBookableOnline)
                ? Theme.of(context).disabledColor
                : null,
          ),
          onPressed: (service.onlineVisibility == 'hidden' || !isBookableOnline)
              ? null
              : onCopyDirectLink,
        ),
        IconButton(
          tooltip: deletePresentation.tooltip,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref) {
    final serviceLocationIds = ref
        .watch(serviceLocationIdsProvider(service.id))
        .value;
    final deletePresentation = _resolveDeletePresentation(
      context,
      ref,
      serviceLocationIds,
    );

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'duplicate':
            onDuplicate();
            break;
          case 'copy_direct_link':
            onCopyDirectLink();
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
        PopupMenuItem(
          value: 'copy_direct_link',
          enabled:
              service.onlineVisibility != 'hidden' &&
              (ref
                      .watch(serviceVariantByServiceIdProvider(service.id))
                      ?.isBookableOnline ??
                  true),
          child: Text(context.l10n.closuresImportHolidaysCopyLinkAction),
        ),
        PopupMenuItem(value: 'delete', child: Text(deletePresentation.label)),
      ],
    );
  }

  ({String label, String tooltip}) _resolveDeletePresentation(
    BuildContext context,
    WidgetRef ref,
    List<int>? serviceLocationIds,
  ) {
    final serviceLocationCount = serviceLocationIds?.length ?? 1;
    if (serviceLocationCount <= 1) {
      return (
        label: context.l10n.deactivateServiceAction,
        tooltip: context.l10n.deactivateServiceAction,
      );
    }

    final visibleLocationIds = {
      for (final location in ref.watch(locationsProvider)) location.id,
    };
    final manageableServiceLocationCount =
        serviceLocationIds?.where(visibleLocationIds.contains).length ?? 1;
    if (manageableServiceLocationCount > 1) {
      return (
        label: context.l10n.chooseServiceRemovalScopeAction,
        tooltip: context.l10n.chooseServiceRemovalScopeTooltip,
      );
    }

    return (
      label: context.l10n.removeServiceFromLocationAction,
      tooltip: context.l10n.removeServiceFromLocationAction,
    );
  }
}
