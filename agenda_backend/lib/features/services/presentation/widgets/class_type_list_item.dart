import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/extensions.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/class_type.dart';
import '../../../../core/services/tenant_time_service.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../agenda/providers/tenant_time_provider.dart';
import '../../../class_events/providers/class_events_providers.dart';

enum _ClassTypeAction { schedule, edit, duplicate, delete }

class ClassTypeListItem extends StatefulWidget {
  const ClassTypeListItem({
    super.key,
    required this.classType,
    required this.isLast,
    required this.isEvenRow,
    required this.isWide,
    required this.colorScheme,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSchedule,
    this.readOnly = false,
  });

  final ClassType classType;
  final bool isLast;
  final bool isEvenRow;
  final bool isWide;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onSchedule;
  final bool readOnly;

  @override
  State<ClassTypeListItem> createState() => _ClassTypeListItemState();
}

class _ClassTypeListItemState extends State<ClassTypeListItem> {
  bool _isHovered = false;

  Color? get _classColor {
    final hex = widget.classType.colorHex?.trim() ?? '';
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
    try {
      return ColorUtils.fromHex(hex);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactionColors = Theme.of(context).extension<AppInteractionColors>();
    final colorScheme = widget.colorScheme;
    final classColor = _classColor ?? colorScheme.tertiary;

    final baseColor = widget.isEvenRow
        ? (interactionColors?.alternatingRowFill ??
              colorScheme.onSurface.withOpacity(0.04))
        : Colors.transparent;
    final hoverFill =
        interactionColors?.hoverFill ??
        colorScheme.primaryContainer.withOpacity(0.1);
    final bgColor = _isHovered ? hoverFill : baseColor;

    final borderRadius = BorderRadius.only(
      bottomLeft: widget.isLast ? const Radius.circular(16) : Radius.zero,
      bottomRight: widget.isLast ? const Radius.circular(16) : Radius.zero,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra colorata sinistra
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: classColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: widget.isLast
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.classType.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Consumer(
                            builder: (context, ref, _) {
                              final timezone = ref.watch(
                                effectiveTenantTimezoneProvider,
                              );
                              final schedulesAsync = ref.watch(
                                allClassEventsByTypeProvider(
                                  widget.classType.id,
                                ),
                              );
                              final nowUtc =
                                  TenantTimeService.nowInTimezone(
                                    timezone,
                                  ).toUtc();

                              var futureCount = 0;
                              var expiredCount = 0;
                              int? durationMinutes;
                              String? priceText;

                              schedulesAsync.whenData((events) {
                                futureCount = events
                                    .where((event) => event.endsAtUtc.isAfter(nowUtc))
                                    .length;
                                expiredCount = events.length - futureCount;

                                final futureEvents = events
                                    .where((event) => event.endsAtUtc.isAfter(nowUtc))
                                    .toList()
                                  ..sort(
                                    (a, b) => a.startsAtUtc.compareTo(b.startsAtUtc),
                                  );
                                final representativeEvent = futureEvents.isNotEmpty
                                    ? futureEvents.first
                                    : (events.isNotEmpty
                                          ? ([...events]
                                                ..sort(
                                                  (a, b) =>
                                                      b.startsAtUtc.compareTo(
                                                        a.startsAtUtc,
                                                      ),
                                                ))
                                              .first
                                          : null);
                                if (representativeEvent != null) {
                                  durationMinutes = representativeEvent.endsAtUtc
                                      .difference(representativeEvent.startsAtUtc)
                                      .inMinutes;
                                  final cents = representativeEvent.priceCents;
                                  if (cents != null && cents > 0) {
                                    final currency =
                                        representativeEvent.currency ??
                                        PriceFormatter.effectiveCurrency(ref);
                                    priceText = PriceFormatter.format(
                                      context: context,
                                      amount: cents / 100.0,
                                      currencyCode: currency,
                                    );
                                  }
                                }
                              });

                              final hasData = schedulesAsync.hasValue;
                              final futureLabel = hasData
                                  ? '${context.l10n.classEventsFutureBadge}: $futureCount'
                                  : '${context.l10n.classEventsFutureBadge}: -';
                              final expiredLabel = hasData
                                  ? '${context.l10n.classEventsExpiredBadge}: $expiredCount'
                                  : '${context.l10n.classEventsExpiredBadge}: -';
                              final durationLabel = hasData && durationMinutes != null
                                  ? context.localizedDurationLabel(durationMinutes!)
                                  : null;
                              final effectivePriceText = hasData
                                  ? (priceText ?? context.l10n.priceNotAvailable)
                                  : null;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (durationLabel != null ||
                                      effectivePriceText != null)
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
                                              effectivePriceText != null)
                                            const SizedBox(width: 8),
                                          if (effectivePriceText != null)
                                            Text(
                                              effectivePriceText,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                                height: 1.1,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _ClassTypeBadge(label: futureLabel),
                                      _ClassTypeBadge(label: expiredLabel),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      trailing: UnconstrainedBox(
                        alignment: Alignment.centerRight,
                        child: widget.readOnly
                            ? null
                            : widget.isWide
                            ? _buildActionIcons(context)
                            : _PopupMenu(
                                onSchedule: widget.onSchedule,
                                onEdit: widget.onEdit,
                                onDuplicate: widget.onDuplicate,
                                onDelete: widget.onDelete,
                              ),
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

  Widget _buildActionIcons(BuildContext context) {
    return Row(
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
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}

class _ClassTypeBadge extends StatelessWidget {
  const _ClassTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.05),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PopupMenu extends StatelessWidget {
  const _PopupMenu({
    required this.onSchedule,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final VoidCallback onSchedule;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_ClassTypeAction>(
      icon: const Icon(Icons.more_vert, size: 20),
      borderRadius: BorderRadius.circular(10),
      onSelected: (action) {
        switch (action) {
          case _ClassTypeAction.schedule:
            onSchedule();
          case _ClassTypeAction.edit:
            onEdit();
          case _ClassTypeAction.duplicate:
            onDuplicate();
          case _ClassTypeAction.delete:
            onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ClassTypeAction.schedule,
          child: Row(
            children: [
              const Icon(Icons.event_available_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.classTypesActionScheduleClass),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _ClassTypeAction.edit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.actionEdit),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _ClassTypeAction.duplicate,
          child: Row(
            children: [
              const Icon(Icons.copy_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.duplicateAction),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ClassTypeAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
              const SizedBox(width: 8),
              Text(
                l10n.actionDelete,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
