import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/l10n/date_time_formats.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/models/staff.dart';
import '/core/services/tenant_time_service.dart';
import '/core/utils/color_utils.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/app_dividers.dart';
import '/core/widgets/app_form.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '/features/auth/providers/auth_provider.dart';
import '/features/auth/providers/current_business_user_provider.dart';
import '/features/staff/providers/staff_providers.dart';
import '../providers/class_events_providers.dart';
import 'class_events_screen.dart';

Future<void> showClassTypeEventsSummaryForm(
  BuildContext context,
  WidgetRef ref, {
  required ClassType classType,
}) async {
  await AppForm.show<void>(
    context: context,
    builder: (_) => _ClassTypeEventsSummaryForm(classType: classType),
  );
}

Color? _tryParseColor(String? hex) {
  final value = hex?.trim() ?? '';
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) return null;
  try {
    return ColorUtils.fromHex(value);
  } catch (_) {
    return null;
  }
}

/// Schermata dedicata agli eventi di un singolo ClassType.
/// Raggiunta toccando un tipo classe nella schermata servizi.
class ClassTypeEventsScreen extends ConsumerStatefulWidget {
  const ClassTypeEventsScreen({super.key, required this.classType});

  final ClassType classType;

  @override
  ConsumerState<ClassTypeEventsScreen> createState() =>
      _ClassTypeEventsScreenState();
}

class _ClassTypeEventsScreenState extends ConsumerState<ClassTypeEventsScreen> {
  bool _showExpired = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final canManage = ref.watch(currentUserCanManageServicesProvider);
    final classColor = _tryParseColor(widget.classType.colorHex);

    final upcomingAsync = ref.watch(
      upcomingClassEventsByTypeProvider(widget.classType.id),
    );
    final allAsync = ref.watch(
      allClassEventsByTypeProvider(widget.classType.id),
    );
    final timezone = ref.watch(effectiveTenantTimezoneProvider);
    final locations = ref.watch(locationsProvider);
    final allStaff = ref.watch(allStaffProvider).value ?? const <Staff>[];

    final locationNameById = {for (final l in locations) l.id: l.name};
    final staffNameById = {for (final s in allStaff) s.id: s.displayName};

    final upcoming = upcomingAsync.value ?? const <ClassEvent>[];
    final all = allAsync.value ?? const <ClassEvent>[];
    final expired = all.where((e) {
      final nowUtc = TenantTimeService.nowInTimezone(timezone).toUtc();
      return e.endsAtUtc.isBefore(nowUtc);
    }).toList();
    final displayed = _showExpired ? all : upcoming;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (classColor != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: classColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.classType.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (canManage) ...[
            IconButton(
              tooltip: l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showCreateClassTypeDialog(
                context,
                ref,
                initial: widget.classType,
              ),
            ),
            PopupMenuButton<_Action>(
              borderRadius: BorderRadius.circular(10),
              onSelected: (action) async {
                switch (action) {
                  case _Action.duplicate:
                    await _duplicate(context);
                  case _Action.delete:
                    await _delete(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _Action.duplicate,
                  child: Row(
                    children: [
                      const Icon(Icons.copy_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.duplicateAction),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _Action.delete,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.actionDelete,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => showCreateClassEventDialog(
                context,
                ref,
                initialClassTypeId: widget.classType.id,
              ),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(l10n.classTypesActionScheduleClass),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Descrizione
          if ((widget.classType.description ?? '').trim().isNotEmpty) ...[
            Text(
              widget.classType.description!.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // Contatori
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (upcoming.isNotEmpty)
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: '${l10n.classEventsFutureBadge}: ${upcoming.length}',
                  color: colorScheme.secondaryContainer,
                ),
              if (expired.isNotEmpty)
                _InfoChip(
                  icon: Icons.history_outlined,
                  label: '${l10n.classEventsExpiredBadge}: ${expired.length}',
                  color: colorScheme.surfaceContainerHighest,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Toggle past events
          if (expired.isNotEmpty)
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.classEventsShowExpiredSchedules,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _showExpired,
              onChanged: (v) => setState(() => _showExpired = v),
            ),

          // Lista eventi
          if (upcomingAsync.isLoading || allAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (displayed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  l10n.classEventsNoScheduledDates,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  primary: false,
                  shrinkWrap: true,
                  itemCount: displayed.length,
                  separatorBuilder: (_, __) => const AppDivider(height: 1),
                  itemBuilder: (context, index) {
                    return _EventTile(
                      event: displayed[index],
                      timezone: timezone,
                      locationNameById: locationNameById,
                      staffNameById: staffNameById,
                      canManage: canManage,
                      onEdit: () => showCreateClassEventDialog(
                        context,
                        ref,
                        initialEvent: displayed[index],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _duplicate(BuildContext context) async {
    final l10n = context.l10n;
    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    if (!isSuperadmin) {
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classTypesCreateSuperadminOnlyMessage,
      );
      return;
    }
    try {
      final allTypes = await ref.read(classTypesProvider.future);
      final existingNames = allTypes
          .map((t) => t.name.trim().toLowerCase())
          .toSet();
      final baseName =
          '${widget.classType.name.trim()} ${l10n.classTypesCloneSuffix}';
      var candidateName = baseName;
      var counter = 2;
      while (existingNames.contains(candidateName.toLowerCase())) {
        candidateName = '$baseName $counter';
        counter++;
      }
      await ref
          .read(classTypeMutationControllerProvider.notifier)
          .create(
            name: candidateName,
            description: widget.classType.description,
            colorHex: widget.classType.colorHex,
            serviceCategoryId: widget.classType.serviceCategoryId,
            locationIds: widget.classType.locationIds,
          );
      if (!context.mounted) return;
      FeedbackDialog.showSuccess(
        context,
        title: l10n.classTypesCloneSuccessTitle,
        message: l10n.classTypesCloneSuccessMessage,
      );
    } catch (_) {
      if (!context.mounted) return;
      FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classTypesMutationErrorMessage,
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classTypesDeleteConfirmTitle),
        content: Text(l10n.classTypesDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(classTypeMutationControllerProvider.notifier)
          .deleteType(classTypeId: widget.classType.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classTypesDeleteInUseErrorMessage,
      );
    }
  }
}

enum _Action { duplicate, delete }

class _ClassTypeEventsSummaryForm extends ConsumerStatefulWidget {
  const _ClassTypeEventsSummaryForm({required this.classType});

  final ClassType classType;

  @override
  ConsumerState<_ClassTypeEventsSummaryForm> createState() =>
      _ClassTypeEventsSummaryFormState();
}

class _ClassTypeEventsSummaryFormState
    extends ConsumerState<_ClassTypeEventsSummaryForm> {
  bool _showExpired = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final canManage = ref.watch(currentUserCanManageServicesProvider);
    final classColor = _tryParseColor(widget.classType.colorHex);
    final upcomingAsync = ref.watch(
      upcomingClassEventsByTypeProvider(widget.classType.id),
    );
    final allAsync = ref.watch(
      allClassEventsByTypeProvider(widget.classType.id),
    );
    final timezone = ref.watch(effectiveTenantTimezoneProvider);
    final locations = ref.watch(locationsProvider);
    final allStaff = ref.watch(allStaffProvider).value ?? const <Staff>[];

    final locationNameById = {for (final l in locations) l.id: l.name};
    final enabledLocationNames = widget.classType.locationIds.isEmpty
        ? locations.map((location) => location.name).toList()
        : widget.classType.locationIds
              .map((id) => locationNameById[id])
              .whereType<String>()
              .toList();
    final staffNameById = {for (final s in allStaff) s.id: s.displayName};
    final upcoming = upcomingAsync.value ?? const <ClassEvent>[];
    final all = allAsync.value ?? const <ClassEvent>[];
    final expired = all.where((e) {
      final nowUtc = TenantTimeService.nowInTimezone(timezone).toUtc();
      return e.endsAtUtc.isBefore(nowUtc);
    }).toList();
    final displayed = _showExpired ? all : upcoming;

    return AppFormScaffold(
      title: Row(
        children: [
          if (classColor != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: classColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(widget.classType.name, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [
        AppOutlinedActionButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionClose),
        ),
        if (canManage)
          AppFilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              showCreateClassEventDialog(
                context,
                ref,
                initialClassTypeId: widget.classType.id,
              );
            },
            child: Text(l10n.classTypesActionScheduleClass),
          ),
      ],
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.classType.description ?? '').trim().isNotEmpty) ...[
              Text(
                widget.classType.description!.trim(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.classType.locationIds.isEmpty
                  ? '${l10n.classTypesLocationsSelectionTitle} • ${l10n.allLocations}'
                  : l10n.classTypesLocationsSelectionTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (enabledLocationNames.isEmpty)
              Text(
                l10n.allLocations,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final name in enabledLocationNames)
                    Chip(
                      label: Text(name),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                      backgroundColor: colorScheme.surface.withOpacity(0.8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (upcoming.isNotEmpty)
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label: '${l10n.classEventsFutureBadge}: ${upcoming.length}',
                    color: colorScheme.secondaryContainer,
                  ),
                if (expired.isNotEmpty)
                  _InfoChip(
                    icon: Icons.history_outlined,
                    label: '${l10n.classEventsExpiredBadge}: ${expired.length}',
                    color: colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (expired.isNotEmpty)
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.classEventsShowExpiredSchedules,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _showExpired,
                onChanged: (v) => setState(() => _showExpired = v),
              ),
            if (upcomingAsync.isLoading || allAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (displayed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.classEventsNoScheduledDates,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    primary: false,
                    shrinkWrap: true,
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) => const AppDivider(height: 1),
                    itemBuilder: (context, index) => _EventTile(
                      event: displayed[index],
                      timezone: timezone,
                      locationNameById: locationNameById,
                      staffNameById: staffNameById,
                      canManage: canManage,
                      onEdit: () => showCreateClassEventDialog(
                        context,
                        ref,
                        initialEvent: displayed[index],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.timezone,
    required this.locationNameById,
    required this.staffNameById,
    required this.canManage,
    required this.onEdit,
  });

  final ClassEvent event;
  final String timezone;
  final Map<int, String> locationNameById;
  final Map<int, String> staffNameById;
  final bool canManage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startsAtLocal =
        event.startsAtLocal ??
        TenantTimeService.fromUtcToTenant(event.startsAtUtc, timezone);
    final endsAtLocal =
        event.endsAtLocal ??
        TenantTimeService.fromUtcToTenant(event.endsAtUtc, timezone);
    final locationName =
        locationNameById[event.locationId] ?? '#${event.locationId}';
    final staffName = staffNameById[event.staffId] ?? '#${event.staffId}';
    final nowUtc = DateTime.now().toUtc();
    final isPast = event.endsAtUtc.isBefore(nowUtc);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPast
              ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
              : colorScheme.primaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isPast ? Icons.history_outlined : Icons.calendar_today_outlined,
          size: 16,
          color: isPast
              ? colorScheme.onSurfaceVariant
              : colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        '${DateFormat('dd/MM/yyyy').format(startsAtLocal)} • '
        '${DtFmt.hm(context, startsAtLocal.hour, startsAtLocal.minute)}'
        ' - ${DtFmt.hm(context, endsAtLocal.hour, endsAtLocal.minute)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isPast ? colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Text(
        '$locationName • $staffName',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: canManage && !isPast
          ? IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
            )
          : null,
    );
  }
}
