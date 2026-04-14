import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agenda_backend/core/widgets/app_dividers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/date_time_formats.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/appointment.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/models/location.dart';
import '/core/models/staff.dart';
import '/core/network/api_client.dart';
import '/core/services/tenant_time_service.dart';
import '/core/utils/color_utils.dart';
import '/core/widgets/app_bottom_sheet.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/app_form.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/appointment_providers.dart';
import '/features/agenda/providers/date_range_provider.dart';
import '/features/agenda/providers/layout_config_provider.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/agenda/providers/staff_slot_availability_provider.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '/features/agenda/presentation/widgets/recurrence_picker.dart';
import '/features/agenda/presentation/widgets/recurrence_preview.dart';
import '/features/agenda/presentation/dialogs/recurrence_summary_dialog.dart';
import '/features/agenda/presentation/utils/recurrence_flow_utils.dart';
import '/features/agenda/domain/config/layout_config.dart';
import '/features/business/providers/location_closures_provider.dart';
import '/features/staff/providers/staff_providers.dart';
import '/features/staff/providers/availability_exceptions_provider.dart';
import '/features/staff/providers/staff_planning_provider.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../../core/models/recurrence_rule.dart';
import '../data/class_events_repository.dart';
import '../providers/class_events_providers.dart';

String _resolveClassTypeErrorMessage(Object error, BuildContext context) {
  final l10n = context.l10n;
  if (error is ApiException) {
    if (error.code == 'class_type_in_use') {
      return l10n.classTypesDeleteInUseErrorMessage;
    }
    return error.message;
  }
  return l10n.classTypesMutationErrorMessage;
}

Color? _tryParseHexColor(String? hex) {
  final value = hex?.trim() ?? '';
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
    return null;
  }
  try {
    return ColorUtils.fromHex(value);
  } catch (_) {
    return null;
  }
}

class ClassEventsScreen extends ConsumerWidget {
  const ClassEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final businessId = ref.watch(currentBusinessIdProvider);
    final classTypesAsync = ref.watch(classTypesWithInactiveProvider);
    final canManageClassTypes = ref.watch(currentUserCanManageServicesProvider);
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Expanded(
          child: businessId <= 0
              ? const Center(child: CircularProgressIndicator())
              : classTypesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(child: Text(l10n.errorTitle)),
                  data: (classTypes) {
                    if (classTypes.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.classTypesEmpty,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: classTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: _ClassTypeCard(
                            key: ValueKey<int>(classTypes[index].id),
                            classType: classTypes[index],
                            canManageClassTypes: canManageClassTypes,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Future<void> showCreateClassTypeDialog(
  BuildContext context,
  WidgetRef ref, {
  ClassType? initial,
}) async {
  await AppForm.show<void>(
    context: context,
    builder: (_) => _ClassTypeFormDialog(initial: initial),
  );
}

Future<void> showCreateClassEventDialog(
  BuildContext context,
  WidgetRef ref, {
  int? initialClassTypeId,
  ClassEvent? initialEvent,
}) async {
  final currentLocation = ref.read(currentLocationProvider);
  final initialDate = ref.read(agendaDateProvider);

  await AppForm.show<void>(
    context: context,
    builder: (_) => _CreateClassForm(
      initialClassTypeId: initialClassTypeId,
      initialLocationId: currentLocation.id,
      initialDate: initialDate,
      initialEvent: initialEvent,
    ),
  );
}

class _ClassTypeCard extends ConsumerStatefulWidget {
  const _ClassTypeCard({
    super.key,
    required this.classType,
    required this.canManageClassTypes,
  });

  final ClassType classType;
  final bool canManageClassTypes;

  @override
  ConsumerState<_ClassTypeCard> createState() => _ClassTypeCardState();
}

enum _ClassTypeQuickAction { edit, duplicate, delete }

class _ClassTypeCardState extends ConsumerState<_ClassTypeCard> {
  bool _showExpiredSchedules = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mutationState = ref.watch(classTypeMutationControllerProvider);
    final isLoading = mutationState.isLoading;
    final upcomingCountAsync = ref.watch(
      upcomingClassEventsCountByTypeProvider(widget.classType.id),
    );
    final allSchedulesAsync = ref.watch(
      allClassEventsByTypeProvider(widget.classType.id),
    );
    final allStaff = ref.watch(allStaffProvider).value ?? const <Staff>[];
    final colorScheme = Theme.of(context).colorScheme;
    final locations = ref.watch(locationsProvider);
    final businessContext = ref
        .watch(currentBusinessUserContextProvider)
        .maybeWhen(data: (ctx) => ctx, orElse: () => null);
    final locationNameById = {
      for (final location in locations) location.id: location.name,
    };
    final staffNameById = {
      for (final staff in allStaff) staff.id: staff.displayName,
    };
    final hasSingleBusinessLocation = locations.length <= 1;
    final hasSingleOperatorLocation =
        businessContext != null &&
        !businessContext.isSuperadmin &&
        businessContext.hasLocationScope &&
        businessContext.locationIds.length == 1;
    final shouldShowLocationsRow =
        !hasSingleBusinessLocation && !hasSingleOperatorLocation;
    final scopedLocationNames = widget.classType.locationIds
        .map((id) => locationNameById[id])
        .whereType<String>()
        .toList();
    final visibleLocationNames = widget.classType.locationIds.isEmpty
        ? locations.map((location) => location.name).toList()
        : scopedLocationNames;
    final futureCount = upcomingCountAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final allSchedulesCount = allSchedulesAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => null,
    );
    final hasSchedules = allSchedulesAsync.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );
    final expiredCount =
        futureCount != null && allSchedulesCount != null
        ? (allSchedulesCount - futureCount).clamp(0, 1 << 30)
        : null;
    final canOpenEdit = widget.canManageClassTypes && !isLoading;
    final borderColor = _isHovering
        ? colorScheme.primary.withOpacity(0.45)
        : colorScheme.outline.withOpacity(0.2);
    final classColor = _tryParseHexColor(widget.classType.colorHex);

    return MouseRegion(
      cursor: canOpenEdit ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Card(
        elevation: _isHovering ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canOpenEdit
              ? () => showCreateClassTypeDialog(
                  context,
                  ref,
                  initial: widget.classType,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
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
                Expanded(
                  child: Text(
                    widget.classType.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ClassTypeStatusChip(isActive: widget.classType.isActive),
              ],
            ),
            if ((widget.classType.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.classType.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (shouldShowLocationsRow) ...[
              const SizedBox(height: 10),
              _buildLocationsBlock(
                context: context,
                locationNames: visibleLocationNames,
                isAllLocations: widget.classType.locationIds.isEmpty,
              ),
            ],
            const SizedBox(height: 10),
            if (widget.canManageClassTypes)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => showCreateClassEventDialog(
                            context,
                            ref,
                            initialClassTypeId: widget.classType.id,
                          ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(l10n.classTypesActionScheduleClass),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: PopupMenuButton<_ClassTypeQuickAction>(
                        enabled: !isLoading,
                        splashRadius: 20,
                        borderRadius: BorderRadius.circular(10),
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (action) async {
                          switch (action) {
                            case _ClassTypeQuickAction.edit:
                              await showCreateClassTypeDialog(
                                context,
                                ref,
                                initial: widget.classType,
                              );
                              break;
                            case _ClassTypeQuickAction.duplicate:
                              await _cloneClassType(
                                context,
                                ref,
                                widget.classType,
                              );
                              break;
                            case _ClassTypeQuickAction.delete:
                              await _deleteClassType(
                                context,
                                ref,
                                widget.classType,
                              );
                              break;
                          }
                        },
                        itemBuilder: (menuContext) => [
                          PopupMenuItem<_ClassTypeQuickAction>(
                            value: _ClassTypeQuickAction.edit,
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.actionEdit),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<_ClassTypeQuickAction>(
                            value: _ClassTypeQuickAction.duplicate,
                            child: Row(
                              children: [
                                const Icon(Icons.copy_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.duplicateAction),
                              ],
                            ),
                          ),
                          PopupMenuItem<_ClassTypeQuickAction>(
                            value: _ClassTypeQuickAction.delete,
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
                    ),
                  ),
                ],
              ),
            if ((futureCount != null && futureCount > 0) ||
                (expiredCount != null && expiredCount > 0)) ...[
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: [
                    if (futureCount != null && futureCount > 0)
                      _buildMetadataChip(
                        context: context,
                        icon: Icons.schedule_outlined,
                        label: '${l10n.classEventsFutureBadge}: $futureCount',
                      ),
                    if (expiredCount != null && expiredCount > 0)
                      _buildMetadataChip(
                        context: context,
                        icon: Icons.history_outlined,
                        label: '${l10n.classEventsExpiredBadge}: $expiredCount',
                      ),
                  ],
                ),
              ),
            ],
            if (hasSchedules) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  maintainState: true,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.event_note_outlined, size: 18),
                  title: Text(
                    l10n.classEventsSchedulesListTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  children: [
                    allSchedulesAsync.when(
                      loading: () => const LinearProgressIndicator(minHeight: 2),
                      error: (_, __) => Text(
                        l10n.errorTitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                      ),
                      data: (schedules) {
                        final timezone = ref.watch(effectiveTenantTimezoneProvider);
                        final nowUtc =
                            TenantTimeService.nowInTimezone(timezone).toUtc();
                        final futureSchedules = schedules
                            .where((event) => event.endsAtUtc.isAfter(nowUtc))
                            .toList();
                        final hasExpiredSchedules =
                            futureSchedules.length != schedules.length;
                        final displayedSchedules = _showExpiredSchedules
                            ? schedules
                            : futureSchedules;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasExpiredSchedules)
                              SwitchListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.classEventsShowExpiredSchedules,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                value: _showExpiredSchedules,
                                onChanged: (value) {
                                  setState(() => _showExpiredSchedules = value);
                                },
                              ),
                            if (displayedSchedules.isEmpty)
                              Text(
                                l10n.classEventsNoScheduledDates,
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            else
                              _buildSchedulesList(
                                context: context,
                                schedules: displayedSchedules,
                                timezone: timezone,
                                locationNameById: locationNameById,
                                staffNameById: staffNameById,
                                colorScheme: colorScheme,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulesList({
    required BuildContext context,
    required List<ClassEvent> schedules,
    required String timezone,
    required Map<int, String> locationNameById,
    required Map<int, String> staffNameById,
    required ColorScheme colorScheme,
  }) {
    final listHeight = (schedules.length * 60)
        .clamp(96, 280)
        .toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: listHeight,
        child: ListView.separated(
          primary: false,
          itemCount: schedules.length,
          separatorBuilder: (_, __) => const AppDivider(height: 1),
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final startsAtLocal =
                schedule.startsAtLocal ??
                TenantTimeService.fromUtcToTenant(schedule.startsAtUtc, timezone);
            final endsAtLocal =
                schedule.endsAtLocal ??
                TenantTimeService.fromUtcToTenant(schedule.endsAtUtc, timezone);
            final locationName =
                locationNameById[schedule.locationId] ??
                '#${schedule.locationId}';
            final staffName =
                staffNameById[schedule.staffId] ?? '#${schedule.staffId}';
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today_outlined, size: 16),
              ),
              title: Text(
                '${DateFormat('dd/MM/yyyy').format(startsAtLocal)} • ${DtFmt.hm(context, startsAtLocal.hour, startsAtLocal.minute)} - ${DtFmt.hm(context, endsAtLocal.hour, endsAtLocal.minute)}',
              ),
              subtitle: Text('$locationName • $staffName'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetadataChip({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
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

  Widget _buildLocationsBlock({
    required BuildContext context,
    required List<String> locationNames,
    required bool isAllLocations,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final items = locationNames;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.place_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                isAllLocations
                    ? '${context.l10n.classTypesLocationsSelectionTitle} • ${context.l10n.allLocations}'
                    : context.l10n.classTypesLocationsSelectionTitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(context.l10n.allLocations, style: textTheme.bodySmall)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final name in items)
                  Chip(
                    label: Text(name, style: textTheme.bodySmall),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    backgroundColor: colorScheme.surface.withOpacity(0.8),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _cloneClassType(
    BuildContext context,
    WidgetRef ref,
    ClassType source,
  ) async {
    final l10n = context.l10n;
    try {
      final allTypes = await ref.read(classTypesWithInactiveProvider.future);
      final existingNames = allTypes
          .map((type) => type.name.trim().toLowerCase())
          .toSet();
      final baseName = '${source.name.trim()} ${l10n.classTypesCloneSuffix}';
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
            description: source.description,
            colorHex: source.colorHex,
            isActive: source.isActive,
            locationIds: source.locationIds,
          );
      if (!context.mounted) return;
      await FeedbackDialog.showSuccess(
        context,
        title: l10n.classTypesCloneSuccessTitle,
        message: l10n.classTypesCloneSuccessMessage,
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = _resolveClassTypeErrorMessage(error, context);
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: message,
      );
    }
  }

  Future<void> _deleteClassType(
    BuildContext context,
    WidgetRef ref,
    ClassType classType,
  ) async {
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
          .deleteType(classTypeId: classType.id);
    } catch (error) {
      if (!context.mounted) return;
      final message = _resolveClassTypeErrorMessage(error, context);
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: message,
      );
    }
  }
}

class _ClassTypeStatusChip extends StatelessWidget {
  const _ClassTypeStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    final bg = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final fg = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? l10n.classTypesStatusActive : l10n.classTypesStatusInactive,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class _ClassTypeFormDialog extends ConsumerStatefulWidget {
  const _ClassTypeFormDialog({this.initial});

  final ClassType? initial;

  @override
  ConsumerState<_ClassTypeFormDialog> createState() =>
      _ClassTypeFormDialogState();
}

class _ClassTypeFormDialogState extends ConsumerState<_ClassTypeFormDialog> {
  static const List<Color> _classTypePalette = [
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF039BE5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFC0CA33),
    Color(0xFFFDD835),
    Color(0xFFFFB300),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
  ];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  late Set<int> _selectedLocationIds;
  String? _selectedColorHex;
  bool _hasChangedLocationSelection = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
    _isActive = widget.initial?.isActive ?? true;
    _selectedLocationIds = {...?widget.initial?.locationIds};
    _selectedColorHex = widget.initial?.colorHex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mutationState = ref.watch(classTypeMutationControllerProvider);
    final isLoading = mutationState.isLoading;
    final locations = ref.watch(locationsProvider);
    final businessContext = ref
        .watch(currentBusinessUserContextProvider)
        .maybeWhen(data: (ctx) => ctx, orElse: () => null);
    final isLocationScopedOperator =
        businessContext != null &&
        !businessContext.isSuperadmin &&
        businessContext.hasLocationScope;
    final allowedLocationIds = isLocationScopedOperator
        ? businessContext.locationIds.toSet()
        : null;
    final visibleLocations = allowedLocationIds == null
        ? locations
        : locations
              .where((location) => allowedLocationIds.contains(location.id))
              .toList();
    final visibleLocationIds = visibleLocations
        .map((location) => location.id)
        .toSet();
    final hasSingleVisibleLocation = visibleLocations.length == 1;
    final initialSelection =
        !_hasChangedLocationSelection &&
            _selectedLocationIds.isEmpty &&
            visibleLocations.length > 1
        ? visibleLocationIds
        : _selectedLocationIds;
    final effectiveSelectedLocationIds = initialSelection
        .where(visibleLocationIds.contains)
        .toSet();
    final shouldShowLocationsSelector = !hasSingleVisibleLocation;

    final content = Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: l10n.classTypesFieldName,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return l10n.classEventsValidationRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            enabled: !isLoading,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.classTypesFieldDescriptionOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          _ClassTypeColorPicker(
            selectedColorHex: _selectedColorHex,
            palette: _classTypePalette,
            enabled: !isLoading,
            onChanged: (hex) => setState(() => _selectedColorHex = hex),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: isLoading
                ? null
                : (value) => setState(() => _isActive = value),
            title: Text(l10n.classTypesFieldIsActive),
          ),
          if (shouldShowLocationsSelector) ...[
            const SizedBox(height: 8),
            _ClassTypeLocationsMultiSelect(
              locations: visibleLocations,
              selectedIds: effectiveSelectedLocationIds,
              enabled: !isLoading,
              onChanged: (ids) => setState(() {
                _hasChangedLocationSelection = true;
                _selectedLocationIds
                  ..clear()
                  ..addAll(ids);
              }),
            ),
            if (effectiveSelectedLocationIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.operatorsScopeLocationsRequired,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );

    return AppFormScaffold(
      title: Text(
        _isEdit ? l10n.classTypesEditTitle : l10n.classTypesCreateTitle,
      ),
      content: content,
      actions: [
        AppOutlinedActionButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppAsyncFilledButton(
          isLoading: isLoading,
          onPressed: _submit,
          child: Text(l10n.actionSave),
        ),
      ],
      isLoading: isLoading,
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final businessContext = ref
        .read(currentBusinessUserContextProvider)
        .maybeWhen(data: (ctx) => ctx, orElse: () => null);
    final isLocationScopedOperator =
        businessContext != null &&
        !businessContext.isSuperadmin &&
        businessContext.hasLocationScope;
    final allowedLocationIds = isLocationScopedOperator
        ? businessContext.locationIds.toSet()
        : null;
    final locations = ref.read(locationsProvider);
    final visibleLocations = allowedLocationIds == null
        ? locations
        : locations
              .where((location) => allowedLocationIds.contains(location.id))
              .toList();
    final hasSingleVisibleLocation = visibleLocations.length == 1;
    final singleVisibleLocationId = hasSingleVisibleLocation
        ? visibleLocations.first.id
        : null;
    final rawSelectedIds =
        !_hasChangedLocationSelection &&
            _selectedLocationIds.isEmpty &&
            visibleLocations.length > 1
        ? visibleLocations.map((location) => location.id).toSet()
        : _selectedLocationIds;
    final effectiveSelectedLocationIds = rawSelectedIds
        .where(
          (id) => allowedLocationIds == null || allowedLocationIds.contains(id),
        )
        .toSet();
    final locationIdsForSubmit =
        hasSingleVisibleLocation && singleVisibleLocationId != null
        ? <int>[singleVisibleLocationId]
        : effectiveSelectedLocationIds.toList();

    if (!_formKey.currentState!.validate()) return;
    if (locationIdsForSubmit.isEmpty) {
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.operatorsScopeLocationsRequired,
      );
      return;
    }
    try {
      if (_isEdit) {
        await ref
            .read(classTypeMutationControllerProvider.notifier)
            .updateType(
              classTypeId: widget.initial!.id,
              name: _nameController.text,
              description: _descriptionController.text,
              colorHex: _selectedColorHex,
              isActive: _isActive,
              locationIds: locationIdsForSubmit,
            );
      } else {
        await ref
            .read(classTypeMutationControllerProvider.notifier)
            .create(
              name: _nameController.text,
              description: _descriptionController.text,
              colorHex: _selectedColorHex,
              isActive: _isActive,
              locationIds: locationIdsForSubmit,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = _resolveClassTypeErrorMessage(error, context);
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: message,
      );
    }
  }
}

class _ClassTypeLocationsMultiSelect extends StatelessWidget {
  const _ClassTypeLocationsMultiSelect({
    required this.locations,
    required this.selectedIds,
    required this.enabled,
    required this.onChanged,
  });

  final List<Location> locations;
  final Set<int> selectedIds;
  final bool enabled;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final listHeight = (locations.length * 72).clamp(144, 360).toDouble();
    final allLocationIds = locations.map((location) => location.id).toSet();
    final allSelected =
        locations.isNotEmpty && selectedIds.containsAll(allLocationIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.classTypesLocationsSelectionTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            OutlinedButton.icon(
              onPressed: !enabled
                  ? null
                  : () => onChanged(allSelected ? <int>{} : allLocationIds),
              icon: Icon(
                allSelected ? Icons.deselect_outlined : Icons.select_all,
                size: 16,
              ),
              label: Text(
                allSelected ? l10n.actionDeselectAll : l10n.actionSelectAll,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.classTypesLocationsSelectionHelper,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: listHeight,
            child: Scrollbar(
              thumbVisibility: locations.length > 4,
              child: ListView.separated(
                primary: false,
                itemCount: locations.length,
                separatorBuilder: (_, __) => const AppDivider(height: 1),
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return _ClassTypeLocationCheckboxTile(
                    location: location,
                    isSelected: selectedIds.contains(location.id),
                    enabled: enabled,
                    onChanged: (selected) {
                      final newIds = Set<int>.from(selectedIds);
                      if (selected) {
                        newIds.add(location.id);
                      } else {
                        newIds.remove(location.id);
                      }
                      onChanged(newIds);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassTypeColorPicker extends StatelessWidget {
  const _ClassTypeColorPicker({
    required this.selectedColorHex,
    required this.palette,
    required this.enabled,
    required this.onChanged,
  });

  final String? selectedColorHex;
  final List<Color> palette;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedHex = selectedColorHex?.trim().toUpperCase();
    final selectedColor = _tryParseHexColor(selectedHex);
    final paletteHexes = {
      for (final color in palette) ColorUtils.toHex(color).toUpperCase(),
    };
    final showCustomSelected =
        selectedHex != null &&
        selectedHex.isNotEmpty &&
        selectedColor != null &&
        !paletteHexes.contains(selectedHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.teamStaffColorLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ClassTypeColorDot(
              color: null,
              selected: selectedHex == null || selectedHex.isEmpty,
              enabled: enabled,
              onTap: () => onChanged(null),
            ),
            for (final color in palette)
              _ClassTypeColorDot(
                color: color,
                selected: selectedHex == ColorUtils.toHex(color).toUpperCase(),
                enabled: enabled,
                onTap: () => onChanged(ColorUtils.toHex(color)),
              ),
            if (showCustomSelected)
              _ClassTypeColorDot(
                color: selectedColor,
                selected: true,
                enabled: enabled,
                onTap: () => onChanged(selectedHex),
              ),
          ],
        ),
      ],
    );
  }
}

class _ClassTypeColorDot extends StatelessWidget {
  const _ClassTypeColorDot({
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected ? scheme.primary : scheme.outline;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: color == null
              ? Icon(
                  Icons.block,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }
}

class _ClassTypeLocationCheckboxTile extends StatelessWidget {
  const _ClassTypeLocationCheckboxTile({
    required this.location,
    required this.isSelected,
    required this.enabled,
    required this.onChanged,
  });

  final Location location;
  final bool isSelected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: enabled ? (value) => onChanged(value ?? false) : null,
      title: Text(location.name),
      subtitle: location.address != null
          ? Text(
              location.address!,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      secondary: const Icon(Icons.store_outlined),
      controlAffinity: ListTileControlAffinity.trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _CreateClassForm extends ConsumerStatefulWidget {
  const _CreateClassForm({
    required this.initialLocationId,
    required this.initialDate,
    this.initialClassTypeId,
    this.initialEvent,
  });

  final int initialLocationId;
  final DateTime initialDate;
  final int? initialClassTypeId;
  final ClassEvent? initialEvent;

  @override
  ConsumerState<_CreateClassForm> createState() => _CreateClassFormState();
}

class _CreateClassFormState extends ConsumerState<_CreateClassForm> {
  static const int _timeStepMinutes = 15;
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();

  ClassEvent? _editingEvent;
  RecurrenceConfig? _recurrenceConfig;
  int? _classTypeId;
  int? _locationId;
  int? _staffId;
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _editingEvent = widget.initialEvent;
    if (_editingEvent != null) {
      _applyEventToForm(_editingEvent!);
    } else {
      _classTypeId = widget.initialClassTypeId;
      _locationId = widget.initialLocationId;
      _date = DateTime(
        widget.initialDate.year,
        widget.initialDate.month,
        widget.initialDate.day,
      );
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classTypesAsync = ref.watch(classTypesProvider);
    final staffAsync = ref.watch(allStaffProvider);
    final locations = ref.watch(locationsProvider);
    final createState = ref.watch(classEventCreateControllerProvider);
    final isLoading = createState.isLoading;
    final l10n = context.l10n;
    final isEditMode = _editingEvent != null;
    final businessId = ref.watch(currentBusinessIdProvider);

    final classTypes = classTypesAsync.value ?? const <ClassType>[];
    final allStaff = staffAsync.value ?? const <Staff>[];
    final filteredLocations = _locationsForSelectedClassType(
      locations: locations,
      classTypes: classTypes,
      selectedClassTypeId: _classTypeId,
    );
    final staff = _staffForSelectedLocation(
      staffAsync.value ?? const <Staff>[],
    );
    final staffNameById = {
      for (final member in allStaff) member.id: member.displayName,
    };
    final activeStaffIdSet = staff.map((member) => member.id).toSet();
    final editingStaffId = _editingEvent?.staffId;
    final hasInactiveAssignedOption =
        isEditMode &&
        editingStaffId != null &&
        !activeStaffIdSet.contains(editingStaffId);
    final inactiveAssignedStaffId =
        hasInactiveAssignedOption ? editingStaffId : null;
    final selectableStaffIds = <int>{...activeStaffIdSet};
    if (inactiveAssignedStaffId != null) {
      selectableStaffIds.add(inactiveAssignedStaffId);
    }

    if (classTypes.isNotEmpty && _classTypeId == null) {
      _classTypeId = classTypes.first.id;
    }
    if (filteredLocations.isEmpty) {
      _locationId = null;
    } else if (_locationId == null ||
        !filteredLocations.any((loc) => loc.id == _locationId)) {
      _locationId = filteredLocations.first.id;
    }
    _staffId = _resolveSelectedStaffId(
      staff: staff,
      selectableStaffIds: selectableStaffIds,
      isEditMode: isEditMode,
      editingStaffId: editingStaffId,
    );
    final inactiveAssignedName = inactiveAssignedStaffId == null
        ? null
        : staffNameById[inactiveAssignedStaffId];
    final inactiveAssignedLabel =
        inactiveAssignedStaffId != null
        ? ((inactiveAssignedName?.trim().isNotEmpty ?? false)
              ? '${inactiveAssignedName!.trim()} (${l10n.classTypesStatusInactive})'
              : l10n.classEventsStaffInactiveOption(inactiveAssignedStaffId))
        : null;
    final staffDropdownItems = <({int id, String label, bool isInactive})>[
      if (inactiveAssignedStaffId != null && inactiveAssignedLabel != null)
        (
          id: inactiveAssignedStaffId,
          label: inactiveAssignedLabel,
          isInactive: true,
        ),
      ...staff.map(
        (member) => (
          id: member.id,
          label: member.displayName,
          isInactive: false,
        ),
      ),
    ];
    final requiresStaffReplacement =
        isEditMode &&
        inactiveAssignedStaffId != null &&
        _staffId == inactiveAssignedStaffId;

    final selectedDayAppointmentsAsync = _locationId != null && businessId > 0
        ? ref.watch(
            appointmentsForLocationDayProvider((
              day: _date,
              locationId: _locationId!,
              businessId: businessId,
            )),
          )
        : const AsyncData<List<Appointment>>(<Appointment>[]);
    final hasAppointmentConflict = selectedDayAppointmentsAsync.maybeWhen(
      data: (appointments) =>
          _countOverlappingAppointmentsForSelection(appointments) > 0,
      orElse: () => false,
    );

    return AppFormScaffold(
      title: Text(
        isEditMode ? l10n.classEventsEditTitle : l10n.classEventsCreateTitle,
      ),
      isLoading: isLoading,
      mobileExpandToAvailableHeight: true,
      content: Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditMode) ...[
              Text(
                l10n.classEventsEditModeLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            if (classTypesAsync.isLoading || staffAsync.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (classTypesAsync.hasError || staffAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.errorTitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (classTypes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.classEventsNoClassTypes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (!isEditMode && filteredLocations.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _locationId,
                decoration: InputDecoration(
                  labelText: l10n.classEventsFieldLocation,
                  border: const OutlineInputBorder(),
                ),
                items: filteredLocations
                    .map(
                      (location) => DropdownMenuItem<int>(
                        value: location.id,
                        child: Text(location.name),
                      ),
                    )
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) => setState(() {
                        _locationId = value;
                        _staffId = null;
                      }),
                validator: (value) =>
                    value == null ? l10n.classEventsValidationRequired : null,
              ),
            ],
            if ((!isEditMode ? staff.length > 1 : staffDropdownItems.length > 1)) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _staffId,
                decoration: InputDecoration(
                  labelText: l10n.classEventsFieldStaff,
                  border: const OutlineInputBorder(),
                ),
                items: staffDropdownItems
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) => setState(() => _staffId = value),
                validator: (value) {
                  if (value == null) {
                    return l10n.classEventsValidationRequired;
                  }
                  if (isEditMode &&
                      editingStaffId != null &&
                      hasInactiveAssignedOption &&
                      value == editingStaffId) {
                    return l10n.classEventsStaffInactiveChangeRequired;
                  }
                  return null;
                },
              ),
            ],
            if (requiresStaffReplacement)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.classEventsStaffInactiveChangeRequired,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (!isEditMode && staff.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.classEventsNoStaffForLocation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            if (filteredLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.classEventsNoLocationsForClassType,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: l10n.classEventsFieldDate,
                    value: _formatDate(_date),
                    icon: Icons.calendar_today_outlined,
                    onTap: isLoading ? null : _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.classEventsFieldCapacity,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return l10n.classEventsValidationCapacityMin;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScheduleTimeField(
                    label: l10n.classEventsFieldStartTime,
                    time: _startTime,
                    onTap: isLoading ? null : () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScheduleTimeField(
                    label: l10n.classEventsFieldEndTime,
                    time: _endTime,
                    onTap: isLoading ? null : () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            if (hasAppointmentConflict) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Text(
                  l10n.bookingUnavailableTimeWarningService,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (!isEditMode) ...[
              const SizedBox(height: 12),
              RecurrencePicker(
                startDate: DateTime(
                  _date.year,
                  _date.month,
                  _date.day,
                  _startTime.hour,
                  _startTime.minute,
                ),
                title: l10n.classEventsRepeatSchedule,
                initialConfig: _recurrenceConfig,
                onChanged: (config) {
                  setState(() => _recurrenceConfig = config);
                },
              ),
              if (_recurrenceConfig != null) ...[
                const SizedBox(height: 8),
                RecurrencePreview(
                  startDate: DateTime(
                    _date.year,
                    _date.month,
                    _date.day,
                    _startTime.hour,
                    _startTime.minute,
                  ),
                  config: _recurrenceConfig!,
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        AppOutlinedActionButton(
          onPressed: isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppAsyncFilledButton(
          isLoading: isLoading,
          onPressed: _canSubmit(
            classTypes: classTypes,
            staff: staff,
            requiresStaffReplacement: requiresStaffReplacement,
          )
              ? _submit
              : null,
          child: Text(
            !isEditMode && _recurrenceConfig != null
                ? l10n.actionPreview
                : l10n.actionSave,
          ),
        ),
      ],
    );
  }

  bool _canSubmit({
    required List<ClassType> classTypes,
    required List<Staff> staff,
    required bool requiresStaffReplacement,
  }) {
    return classTypes.isNotEmpty &&
        staff.isNotEmpty &&
        _staffId != null &&
        !requiresStaffReplacement;
  }

  List<Staff> _staffForSelectedLocation(List<Staff> staff) {
    final locationId = _locationId;
    if (locationId == null) {
      return const [];
    }
    return staff
        .where(
          (member) =>
              member.locationIds.isEmpty ||
              member.locationIds.contains(locationId),
        )
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  int? _resolveSelectedStaffId({
    required List<Staff> staff,
    required Set<int> selectableStaffIds,
    required bool isEditMode,
    required int? editingStaffId,
  }) {
    if (selectableStaffIds.isEmpty) return null;
    final selected = _staffId;
    if (selected != null && selectableStaffIds.contains(selected)) {
      return selected;
    }
    if (!isEditMode && staff.length == 1) {
      return staff.first.id;
    }
    if (isEditMode &&
        editingStaffId != null &&
        selectableStaffIds.contains(editingStaffId)) {
      return editingStaffId;
    }
    return null;
  }

  List<Location> _locationsForSelectedClassType({
    required List<Location> locations,
    required List<ClassType> classTypes,
    required int? selectedClassTypeId,
  }) {
    if (selectedClassTypeId == null) {
      return locations;
    }
    final selected = classTypes.where((type) => type.id == selectedClassTypeId);
    if (selected.isEmpty) {
      return locations;
    }
    final locationIds = selected.first.locationIds;
    if (locationIds.isEmpty) {
      return locations;
    }
    final allowed = locationIds.toSet();
    return locations
        .where((location) => allowed.contains(location.id))
        .toList();
  }

  Future<void> _pickDate() async {
    final now = ref.read(tenantNowProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final l10n = context.l10n;
    final picked = await _showTimeSelection(
      initial: initial,
      title: isStart
          ? l10n.classEventsFieldStartTime
          : l10n.classEventsFieldEndTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        if (_toDayMinutes(_endTime) <= _toDayMinutes(_startTime)) {
          _endTime = _nextTimeSlot(_startTime);
        }
      } else {
        _endTime = picked;
        if (_toDayMinutes(_endTime) <= _toDayMinutes(_startTime)) {
          final endMinutes = _toDayMinutes(_endTime);
          final previousSlot = endMinutes - _timeStepMinutes;
          if (previousSlot >= 0) {
            _startTime = _fromDayMinutes(previousSlot);
          } else {
            _startTime = const TimeOfDay(hour: 0, minute: 0);
            _endTime = _fromDayMinutes(_timeStepMinutes);
          }
        }
      }
    });
  }

  int _toDayMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  TimeOfDay _fromDayMinutes(int totalMinutes) {
    final clamped = totalMinutes.clamp(0, (24 * 60) - 1);
    return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
  }

  TimeOfDay _nextTimeSlot(TimeOfDay time) {
    final nextMinutes = _toDayMinutes(time) + _timeStepMinutes;
    return _fromDayMinutes(nextMinutes);
  }

  Future<TimeOfDay?> _showTimeSelection({
    required TimeOfDay initial,
    required String title,
  }) async {
    final formFactor = ref.read(formFactorProvider);
    if (formFactor != AppFormFactor.desktop) {
      return AppBottomSheet.show<TimeOfDay>(
        context: context,
        padding: EdgeInsets.zero,
        heightFactor: AppBottomSheet.defaultHeightFactor,
        builder: (ctx) => _ScheduleTimeGridPicker(
          initial: initial,
          stepMinutes: _timeStepMinutes,
          title: title,
        ),
      );
    }

    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _ScheduleTimeGridPicker(
              initial: initial,
              stepMinutes: _timeStepMinutes,
              title: title,
              useSafeArea: false,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_classTypeId == null || _locationId == null || _staffId == null) return;

    final startLocal = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endLocal = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!endLocal.isAfter(startLocal)) {
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classEventsValidationEndAfterStart,
      );
      return;
    }

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    if (capacity <= 0) {
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classEventsValidationCapacityMin,
      );
      return;
    }

    try {
      if (_editingEvent != null) {
        final businessId = ref.read(currentBusinessIdProvider);
        final repo = ref.read(classEventsRepositoryProvider);
        final classTypeIdForRefresh = _classTypeId!;
        await repo.update(
          businessId: businessId,
          classEventId: _editingEvent!.id,
          payload: {
            'starts_at': _toApiLocalDateTime(startLocal),
            'ends_at': _toApiLocalDateTime(endLocal),
            'staff_id': _staffId,
            'capacity_total': capacity,
          },
        );
        final refreshedDayEvents = await ref.refresh(
          classEventsProvider.future,
        );
        ref.invalidate(classEventsForRangeProvider);
        ref.invalidate(classEventsForCurrentLocationDayProvider);
        final refreshedUpcoming = await ref.refresh(
          upcomingClassEventsByTypeProvider(classTypeIdForRefresh).future,
        );
        final _ = await ref.refresh(
          allClassEventsByTypeProvider(classTypeIdForRefresh).future,
        );
        final refreshedCount = await ref.refresh(
          upcomingClassEventsCountByTypeProvider(classTypeIdForRefresh).future,
        );
        if (refreshedCount != refreshedUpcoming.length ||
            refreshedDayEvents.any(
                  (event) => event.classTypeId == classTypeIdForRefresh,
                ) ==
                false) {
          ref.invalidate(
            upcomingClassEventsCountByTypeProvider(classTypeIdForRefresh),
          );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      } else if (_recurrenceConfig == null) {
        await ref
            .read(classEventCreateControllerProvider.notifier)
            .create(
              classTypeId: _classTypeId!,
              startsAtIsoUtc: _toApiLocalDateTime(startLocal),
              endsAtIsoUtc: _toApiLocalDateTime(endLocal),
              locationId: _locationId!,
              staffId: _staffId!,
              capacityTotal: capacity,
            );
        ref.invalidate(upcomingClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(allClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(upcomingClassEventsCountByTypeProvider(_classTypeId!));
      } else {
        final businessId = ref.read(currentBusinessIdProvider);
        final repo = ref.read(classEventsRepositoryProvider);
        final recurrenceDates = _recurrenceConfig!.calculateOccurrences(
          startLocal,
        );
        final duration = endLocal.difference(startLocal);
        final conflictStrategy = _recurrenceConfig!.conflictStrategy;
        final existingEvents = await _loadExistingEventsForRecurrence(
          repo: repo,
          businessId: businessId,
          recurrenceDates: recurrenceDates,
          duration: duration,
        );
        final plannedIntervals = <({DateTime start, DateTime end})>[];
        final conflictByRecurrenceIndex = <int, bool>{};
        final previewDates = <PreviewDateItem>[
          for (var i = 0; i < recurrenceDates.length; i++)
            PreviewDateItem(
              recurrenceIndex: i + 1,
              startTime: recurrenceDates[i],
              endTime: recurrenceDates[i].add(duration),
              hasConflict: (() {
                final occurrenceStart = recurrenceDates[i];
                final occurrenceEnd = occurrenceStart.add(duration);
                final hasConflict = _hasStaffConflict(
                  occurrenceStart: occurrenceStart,
                  occurrenceEnd: occurrenceEnd,
                  existingEvents: existingEvents,
                  plannedIntervals: plannedIntervals,
                );
                if (!hasConflict) {
                  plannedIntervals.add((
                    start: occurrenceStart,
                    end: occurrenceEnd,
                  ));
                }
                conflictByRecurrenceIndex[i + 1] = hasConflict;
                return hasConflict;
              })(),
            ),
        ];
        final preview = RecurringPreviewResult(
          totalDates: previewDates.length,
          dates: previewDates,
        );
        await _ensureRecurringAvailabilityContext(
          recurrenceDates: recurrenceDates,
        );
        final unavailableIndices = _computeRecurringUnavailableIndices(
          preview: preview,
          durationMinutes: duration.inMinutes,
        );
        final adjustedPreview = RecurringPreviewResult(
          totalDates: preview.totalDates,
          dates: preview.dates
              .map(
                (date) => PreviewDateItem(
                  recurrenceIndex: date.recurrenceIndex,
                  startTime: date.startTime,
                  endTime: date.endTime,
                  hasConflict: date.hasConflict,
                  isUnavailable: unavailableIndices.contains(
                    date.recurrenceIndex,
                  ),
                ),
              )
              .toList(),
        );

        if (!mounted) return;
        final excludedIndices = await showRecurrenceExclusionDialog(
          context: context,
          preview: adjustedPreview,
          titleText: l10n.classEventsRecurrencePreviewTitle,
          hintText: l10n.classEventsRecurrencePreviewHint,
          confirmLabelBuilder: (count) =>
              l10n.classEventsRecurrencePreviewConfirm(count),
          excludeConflictsByDefault: true,
        );
        if (excludedIndices == null) return;
        final excludedSet = excludedIndices.toSet();

        var createdCount = 0;
        Object? firstError;

        for (var i = 0; i < recurrenceDates.length; i++) {
          final recurrenceIndex = i + 1;
          if (excludedSet.contains(recurrenceIndex)) {
            continue;
          }
          if (conflictStrategy == ConflictStrategy.skip &&
              (conflictByRecurrenceIndex[recurrenceIndex] ?? false)) {
            continue;
          }
          final occurrenceStart = recurrenceDates[i];
          final occurrenceEnd = occurrenceStart.add(duration);
          try {
            await repo.create(
              businessId: businessId,
              payload: {
                'class_type_id': _classTypeId!,
                'starts_at': _toApiLocalDateTime(occurrenceStart),
                'ends_at': _toApiLocalDateTime(occurrenceEnd),
                'location_id': _locationId!,
                'staff_id': _staffId!,
                'capacity_total': capacity,
              },
            );
            createdCount++;
          } catch (error) {
            firstError ??= error;
            if (conflictStrategy == ConflictStrategy.force) {
              rethrow;
            }
          }
        }

        ref.invalidate(classEventsProvider);
        ref.invalidate(classEventsForRangeProvider);
        ref.invalidate(classEventsForCurrentLocationDayProvider);
        ref.invalidate(allClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(upcomingClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(upcomingClassEventsCountByTypeProvider(_classTypeId!));

        if (createdCount == 0 && firstError != null) {
          throw firstError;
        }

      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : l10n.classEventsCreateErrorMessage;
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: message,
      );
    }
  }

  void _applyEventToForm(ClassEvent event) {
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final startsAtLocal =
        event.startsAtLocal ??
        TenantTimeService.fromUtcToTenant(event.startsAtUtc, timezone);
    final endsAtLocal =
        event.endsAtLocal ??
        TenantTimeService.fromUtcToTenant(event.endsAtUtc, timezone);
    _classTypeId = event.classTypeId;
    _locationId = event.locationId;
    _staffId = event.staffId;
    _capacityController.text = event.capacityTotal.toString();
    _date = DateTime(
      startsAtLocal.year,
      startsAtLocal.month,
      startsAtLocal.day,
    );
    _startTime = TimeOfDay(
      hour: startsAtLocal.hour,
      minute: startsAtLocal.minute,
    );
    _endTime = TimeOfDay(hour: endsAtLocal.hour, minute: endsAtLocal.minute);
    _recurrenceConfig = null;
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _toApiLocalDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }

  int _countOverlappingAppointmentsForSelection(
    List<Appointment> appointments,
  ) {
    if (_staffId == null || _locationId == null) {
      return 0;
    }

    final startLocal = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endLocal = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!endLocal.isAfter(startLocal)) {
      return 0;
    }

    return appointments.where((appointment) {
      if (appointment.staffId != _staffId ||
          appointment.locationId != _locationId) {
        return false;
      }
      return startLocal.isBefore(appointment.endTime) &&
          appointment.startTime.isBefore(endLocal);
    }).length;
  }

  Future<List<ClassEvent>> _loadExistingEventsForRecurrence({
    required ClassEventsRepository repo,
    required int businessId,
    required List<DateTime> recurrenceDates,
    required Duration duration,
  }) async {
    if (recurrenceDates.isEmpty || _staffId == null) {
      return const <ClassEvent>[];
    }

    final fromLocal = recurrenceDates.first.subtract(const Duration(days: 1));
    final toLocal = recurrenceDates.last
        .add(duration)
        .add(const Duration(days: 1));
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final events = await repo.listEvents(
      businessId: businessId,
      fromUtc: TenantTimeService.tenantLocalToUtc(fromLocal, timezone),
      toUtc: TenantTimeService.tenantLocalToUtc(toLocal, timezone),
    );

    return events.where((event) {
      if (event.status.toUpperCase() == 'CANCELLED') return false;
      return event.staffId == _staffId;
    }).toList();
  }

  bool _hasStaffConflict({
    required DateTime occurrenceStart,
    required DateTime occurrenceEnd,
    required List<ClassEvent> existingEvents,
    required List<({DateTime start, DateTime end})> plannedIntervals,
  }) {
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final occurrenceStartUtc = TenantTimeService.tenantLocalToUtc(
      occurrenceStart,
      timezone,
    );
    final occurrenceEndUtc = TenantTimeService.tenantLocalToUtc(
      occurrenceEnd,
      timezone,
    );

    final conflictsExisting = existingEvents.any((event) {
      final eventStart = event.startsAtUtc.toUtc();
      final eventEnd = event.endsAtUtc.toUtc();
      return occurrenceStartUtc.isBefore(eventEnd) &&
          eventStart.isBefore(occurrenceEndUtc);
    });
    if (conflictsExisting) return true;

    return plannedIntervals.any((interval) {
      final intervalStartUtc = TenantTimeService.tenantLocalToUtc(
        interval.start,
        timezone,
      );
      final intervalEndUtc = TenantTimeService.tenantLocalToUtc(
        interval.end,
        timezone,
      );
      return occurrenceStartUtc.isBefore(intervalEndUtc) &&
          intervalStartUtc.isBefore(occurrenceEndUtc);
    });
  }

  Set<int> _computeRecurringUnavailableIndices({
    required RecurringPreviewResult preview,
    required int durationMinutes,
  }) {
    final unavailableIndices = <int>{};
    final staffId = _staffId;
    final locationId = _locationId;
    if (preview.dates.isEmpty ||
        staffId == null ||
        locationId == null ||
        durationMinutes <= 0) {
      return unavailableIndices;
    }

    final layout = ref.read(layoutConfigProvider);
    for (final date in preview.dates) {
      final day = DateUtils.dateOnly(date.startTime);
      final isClosed = ref.read(
        isDateClosedForLocationProvider((date: day, locationId: locationId)),
      );
      if (isClosed) {
        unavailableIndices.add(date.recurrenceIndex);
        continue;
      }

      final available = ref.read(
        staffSlotAvailabilityForDateProvider((staffId: staffId, date: day)),
      );
      if (available.isEmpty) {
        unavailableIndices.add(date.recurrenceIndex);
        continue;
      }

      final startMinutes = date.startTime.hour * 60 + date.startTime.minute;
      final endMinutes = startMinutes + durationMinutes;
      final startSlot = startMinutes ~/ layout.minutesPerSlot;
      final endSlot = (endMinutes / layout.minutesPerSlot).ceil();
      var occurrenceUnavailable = false;
      for (int slot = startSlot; slot < endSlot; slot++) {
        if (!available.contains(slot)) {
          occurrenceUnavailable = true;
          break;
        }
      }
      if (occurrenceUnavailable) {
        unavailableIndices.add(date.recurrenceIndex);
      }
    }

    return unavailableIndices;
  }

  Future<void> _ensureRecurringAvailabilityContext({
    required List<DateTime> recurrenceDates,
  }) async {
    final staffId = _staffId;
    if (staffId == null || recurrenceDates.isEmpty) return;

    final fromDate = DateUtils.dateOnly(recurrenceDates.first);
    final toDate = DateUtils.dateOnly(recurrenceDates.last);

    try {
      await ref.read(locationClosuresProvider.future);
    } catch (_) {
      // Se fallisce il preload, usiamo i dati già presenti in cache.
    }

    final planningNotifier = ref.read(staffPlanningsProvider.notifier);
    final exceptionsNotifier = ref.read(availabilityExceptionsProvider.notifier);
    await Future.wait([
      planningNotifier.loadPlanningsForStaff(staffId),
      exceptionsNotifier.loadExceptionsForStaff(
        staffId,
        fromDate: fromDate,
        toDate: toDate,
      ),
    ]);
  }
}

class _ScheduleTimeField extends StatelessWidget {
  const _ScheduleTimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          isDense: true,
          enabled: !isDisabled,
        ),
        child: Text(
          '$hour:$minute',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDisabled
                ? theme.colorScheme.onSurface.withOpacity(0.5)
                : null,
          ),
        ),
      ),
    );
  }
}

class _ScheduleTimeGridPicker extends StatefulWidget {
  const _ScheduleTimeGridPicker({
    required this.initial,
    required this.stepMinutes,
    required this.title,
    this.useSafeArea = true,
  });

  final TimeOfDay initial;
  final int stepMinutes;
  final String title;
  final bool useSafeArea;

  @override
  State<_ScheduleTimeGridPicker> createState() =>
      _ScheduleTimeGridPickerState();
}

class _ScheduleTimeGridPickerState extends State<_ScheduleTimeGridPicker> {
  late final ScrollController _scrollController;
  late final List<TimeOfDay> _entries;
  late final int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _entries = <TimeOfDay>[
      for (int m = 0; m < LayoutConfig.hoursInDay * 60; m += widget.stepMinutes)
        TimeOfDay(hour: m ~/ 60, minute: m % 60),
    ];
    _selectedIndex = _entries.indexWhere(
      (time) =>
          time.hour == widget.initial.hour &&
          time.minute == widget.initial.minute,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients || _selectedIndex < 0) return;

    const crossAxisCount = 4;
    const mainAxisSpacing = 6.0;
    const childAspectRatio = 2.7;
    const padding = 12.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - padding * 2;
    final itemWidth =
        (availableWidth - (crossAxisCount - 1) * 6) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    final rowHeight = itemHeight + mainAxisSpacing;
    final targetRow = _selectedIndex ~/ crossAxisCount;

    final viewportHeight = _scrollController.position.viewportDimension;
    const headerOffset = 40.0;
    final targetOffset =
        (targetRow * rowHeight) -
        (viewportHeight / 2) +
        (rowHeight / 2) +
        headerOffset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.7,
              ),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final time = _entries[index];
                final isSelected = index == _selectedIndex;
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : null,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Navigator.pop(context, time),
                  child: Text(DtFmt.hm(context, time.hour, time.minute)),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!widget.useSafeArea) return content;
    return SafeArea(child: content);
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(icon),
        ),
        child: Text(value),
      ),
    );
  }
}
