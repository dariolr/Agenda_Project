import 'package:agenda_backend/core/widgets/app_dividers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/date_time_formats.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/appointment.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/models/location.dart';
import '/core/models/service_category.dart';
import '/core/models/staff.dart';
import '/core/network/api_client.dart';
import '/core/services/tenant_time_service.dart';
import '/core/utils/color_utils.dart';
import '/core/widgets/app_bottom_sheet.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/app_form.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/domain/config/layout_config.dart';
import '/features/agenda/presentation/dialogs/recurrence_summary_dialog.dart';
import '/features/agenda/presentation/utils/recurrence_flow_utils.dart';
import '/features/agenda/presentation/widgets/recurrence_picker.dart';
import '/features/agenda/presentation/widgets/recurrence_preview.dart';
import '/features/agenda/providers/appointment_providers.dart';
import '/features/agenda/providers/date_range_provider.dart';
import '/features/agenda/providers/layout_config_provider.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/agenda/providers/staff_slot_availability_provider.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '/features/business/providers/location_closures_provider.dart';
import '/features/staff/providers/availability_exceptions_provider.dart';
import '/features/staff/providers/staff_planning_provider.dart';
import '/features/staff/providers/staff_providers.dart';
import '/features/auth/providers/auth_provider.dart';
import '../../../core/models/recurrence_rule.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../data/class_events_repository.dart';
import '../providers/class_events_providers.dart';

String _resolveClassTypeErrorMessage(Object error, BuildContext context) {
  final l10n = context.l10n;
  if (error is ApiException) {
    if (error.statusCode == 403) {
      return l10n.classTypesCreateSuperadminOnlyMessage;
    }
    if (error.code == 'class_type_in_use') {
      return l10n.classTypesDeleteInUseErrorMessage;
    }
    return error.message;
  }
  return l10n.classTypesMutationErrorMessage;
}

Future<void> _showClassTypesCreateSuperadminOnlyFeedback(
  BuildContext context,
) async {
  final l10n = context.l10n;
  await FeedbackDialog.showError(
    context,
    title: l10n.errorTitle,
    message: l10n.classTypesCreateSuperadminOnlyMessage,
  );
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

Future<void> showCreateClassTypeDialog(
  BuildContext context,
  WidgetRef ref, {
  ClassType? initial,
  int? preselectedCategoryId,
}) async {
  final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
  if (initial == null && !isSuperadmin) {
    await _showClassTypesCreateSuperadminOnlyFeedback(context);
    return;
  }
  await AppForm.show<void>(
    context: context,
    builder: (_) => _ClassTypeFormDialog(
      initial: initial,
      preselectedCategoryId: preselectedCategoryId,
    ),
  );
}

Future<void> showCreateClassEventDialog(
  BuildContext context,
  WidgetRef ref, {
  int? initialClassTypeId,
  ClassEvent? initialEvent,
  bool useRootNavigator = true,
}) async {
  final currentLocation = ref.read(currentLocationProvider);
  final initialDate = ref.read(agendaDateProvider);

  await AppForm.show<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (_) => _CreateClassForm(
      initialClassTypeId: initialClassTypeId,
      initialLocationId: currentLocation.id,
      initialDate: initialDate,
      initialEvent: initialEvent,
    ),
  );
}

class _ClassTypeFormDialog extends ConsumerStatefulWidget {
  const _ClassTypeFormDialog({this.initial, this.preselectedCategoryId});

  final ClassType? initial;
  final int? preselectedCategoryId;

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
  late Set<int> _selectedLocationIds;
  String? _selectedColorHex;
  int? _selectedServiceCategoryId;
  bool _hasChangedLocationSelection = false;
  bool _showExpiredSchedules = false;
  bool _isScheduleActionLoading = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
    _selectedLocationIds = {...?widget.initial?.locationIds};
    _selectedColorHex = widget.initial?.colorHex;
    _selectedServiceCategoryId =
        widget.initial?.serviceCategoryId ?? widget.preselectedCategoryId;
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
    final isBusy = isLoading || _isScheduleActionLoading;
    final locations = ref.watch(locationsProvider);
    final allStaff = ref.watch(allStaffProvider).value ?? const <Staff>[];
    final serviceCategories = ref
        .watch(classTypeServiceCategoriesProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <ServiceCategory>[],
        );
    final allSchedulesAsync = _isEdit
        ? ref.watch(allClassEventsByTypeProvider(widget.initial!.id))
        : const AsyncData<List<ClassEvent>>(<ClassEvent>[]);
    final timezone = ref.watch(effectiveTenantTimezoneProvider);
    final locationNameById = {
      for (final location in locations) location.id: location.name,
    };
    final staffNameById = {
      for (final member in allStaff) member.id: member.displayName,
    };
    final hasSelectedCategoryInList =
        _selectedServiceCategoryId == null ||
        serviceCategories.any((c) => c.id == _selectedServiceCategoryId);
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
            enabled: !isBusy,
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            enabled: !isBusy,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.classTypesFieldDescriptionOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: _selectedServiceCategoryId,
            decoration: InputDecoration(
              labelText: l10n.fieldCategoryRequiredLabel,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null) {
                return l10n.classEventsValidationRequired;
              }
              return null;
            },
            items: [
              if (!hasSelectedCategoryInList &&
                  _selectedServiceCategoryId != null)
                DropdownMenuItem<int?>(
                  value: _selectedServiceCategoryId,
                  child: Text('#${_selectedServiceCategoryId!}'),
                ),
              for (final category in serviceCategories)
                DropdownMenuItem<int?>(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: isBusy
                ? null
                : (value) => setState(() => _selectedServiceCategoryId = value),
          ),
          const SizedBox(height: 16),
          _ClassTypeColorPicker(
            selectedColorHex: _selectedColorHex,
            palette: _classTypePalette,
            enabled: !isBusy,
            onChanged: (hex) => setState(() => _selectedColorHex = hex),
          ),
          if (shouldShowLocationsSelector) ...[
            const SizedBox(height: 16),
            _ClassTypeLocationsMultiSelect(
              locations: visibleLocations,
              selectedIds: effectiveSelectedLocationIds,
              enabled: !isBusy,
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
          if (_isEdit)
            allSchedulesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (schedules) {
                if (schedules.isEmpty) return const SizedBox.shrink();
                final nowUtc = TenantTimeService.nowInTimezone(
                  timezone,
                ).toUtc();
                final futureSchedules = schedules
                    .where((event) => event.endsAtUtc.isAfter(nowUtc))
                    .toList();
                final hasExpiredSchedules =
                    futureSchedules.length != schedules.length;
                final displayedSchedules = _showExpiredSchedules
                    ? schedules
                    : futureSchedules;
                final colorScheme = Theme.of(context).colorScheme;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l10n.classEventsSchedulesListTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.35),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasExpiredSchedules)
                            SwitchListTile.adaptive(
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
                            SizedBox(
                              height: (displayedSchedules.length * 60)
                                  .clamp(96, 280)
                                  .toDouble(),
                              child: ListView.separated(
                                primary: false,
                                itemCount: displayedSchedules.length,
                                separatorBuilder: (_, __) =>
                                    const AppDivider(height: 1),
                                itemBuilder: (context, index) {
                                  final schedule = displayedSchedules[index];
                                  final startsAtLocal =
                                      schedule.startsAtLocal ??
                                      TenantTimeService.fromUtcToTenant(
                                        schedule.startsAtUtc,
                                        timezone,
                                      );
                                  final endsAtLocal =
                                      schedule.endsAtLocal ??
                                      TenantTimeService.fromUtcToTenant(
                                        schedule.endsAtUtc,
                                        timezone,
                                      );
                                  final locationName =
                                      locationNameById[schedule.locationId] ??
                                      '#${schedule.locationId}';
                                  final staffName =
                                      staffNameById[schedule.staffId] ??
                                      '#${schedule.staffId}';
                                  final isPast = schedule.endsAtUtc.isBefore(
                                    nowUtc,
                                  );

                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(
                                      '${DateFormat('dd/MM/yyyy').format(startsAtLocal)} • ${DtFmt.hm(context, startsAtLocal.hour, startsAtLocal.minute)} - ${DtFmt.hm(context, endsAtLocal.hour, endsAtLocal.minute)}',
                                      style: isPast
                                          ? TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.45),
                                            )
                                          : null,
                                    ),
                                    subtitle: Text(
                                      '$locationName • $staffName',
                                      style: isPast
                                          ? TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.35),
                                            )
                                          : null,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: l10n.actionEdit,
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          onPressed: (!isPast && !isBusy)
                                              ? () =>
                                                    showCreateClassEventDialog(
                                                      context,
                                                      ref,
                                                      initialEvent: schedule,
                                                      useRootNavigator: false,
                                                    )
                                              : null,
                                        ),
                                        IconButton(
                                          tooltip: l10n.duplicateAction,
                                          icon: const Icon(
                                            Icons.copy_outlined,
                                            size: 18,
                                          ),
                                          onPressed: isBusy
                                              ? null
                                              : () => _duplicateSchedule(
                                                  schedule,
                                                ),
                                        ),
                                        IconButton(
                                          tooltip: l10n.actionDelete,
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: colorScheme.error,
                                          ),
                                          onPressed: isBusy
                                              ? null
                                              : () => _deleteSchedule(schedule),
                                        ),
                                      ],
                                    ),
                                    onTap: (!isPast && !isBusy)
                                        ? () => showCreateClassEventDialog(
                                            context,
                                            ref,
                                            initialEvent: schedule,
                                            useRootNavigator: false,
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
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
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        if (_isEdit)
          AppAsyncOutlinedButton(
            isLoading: isBusy,
            onPressed: _submit,
            child: Text(l10n.actionSave),
          ),
        if (_isEdit)
          AppFilledButton(
            onPressed: isBusy
                ? null
                : () async {
                    final classTypeId = widget.initial!.id;
                    await showCreateClassEventDialog(
                      context,
                      ref,
                      initialClassTypeId: classTypeId,
                      useRootNavigator: false,
                    );
                    if (!mounted) return;
                    setState(() => _showExpiredSchedules = true);
                    ref.invalidate(allClassEventsByTypeProvider(classTypeId));
                    ref.invalidate(
                      upcomingClassEventsByTypeProvider(classTypeId),
                    );
                    ref.invalidate(
                      upcomingClassEventsCountByTypeProvider(classTypeId),
                    );
                  },
            child: Text(l10n.classTypesActionNewSchedule),
          ),
        if (!_isEdit)
          AppAsyncFilledButton(
            isLoading: isBusy,
            onPressed: _submit,
            child: Text(l10n.actionSave),
          ),
      ],
      isLoading: isBusy,
    );
  }

  Future<void> _duplicateSchedule(ClassEvent schedule) async {
    if (!mounted || widget.initial == null) return;
    final l10n = context.l10n;
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final startsAtLocal =
        schedule.startsAtLocal ??
        TenantTimeService.fromUtcToTenant(schedule.startsAtUtc, timezone);
    final endsAtLocal =
        schedule.endsAtLocal ??
        TenantTimeService.fromUtcToTenant(schedule.endsAtUtc, timezone);

    try {
      if (mounted) setState(() => _isScheduleActionLoading = true);
      final businessId = ref.read(currentBusinessIdProvider);
      final repo = ref.read(classEventsRepositoryProvider);
      await repo.create(
        businessId: businessId,
        payload: {
          'class_type_id': widget.initial!.id,
          'starts_at': _toApiLocalDateTime(startsAtLocal),
          'ends_at': _toApiLocalDateTime(endsAtLocal),
          'location_id': schedule.locationId,
          'staff_id': schedule.staffId,
          'capacity_total': schedule.capacityTotal,
          'waitlist_enabled': schedule.waitlistEnabled,
        },
      );
      _invalidateScheduleProviders(widget.initial!.id);
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
    } finally {
      if (mounted) setState(() => _isScheduleActionLoading = false);
    }
  }

  Future<void> _deleteSchedule(ClassEvent schedule) async {
    if (!mounted || widget.initial == null) return;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classEventsSchedulesDeleteConfirmTitle),
        content: Text(l10n.classEventsSchedulesDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      if (mounted) setState(() => _isScheduleActionLoading = true);
      final businessId = ref.read(currentBusinessIdProvider);
      final repo = ref.read(classEventsRepositoryProvider);
      await repo.deleteEvent(businessId: businessId, classEventId: schedule.id);
      _invalidateScheduleProviders(widget.initial!.id);
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
    } finally {
      if (mounted) setState(() => _isScheduleActionLoading = false);
    }
  }

  void _invalidateScheduleProviders(int classTypeId) {
    ref.invalidate(classEventsProvider);
    ref.invalidate(classEventsForRangeProvider);
    ref.invalidate(classEventsForCurrentLocationDayProvider);
    ref.invalidate(allClassEventsByTypeProvider(classTypeId));
    ref.invalidate(upcomingClassEventsByTypeProvider(classTypeId));
    ref.invalidate(upcomingClassEventsCountByTypeProvider(classTypeId));
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
              serviceCategoryId: _selectedServiceCategoryId,
              locationIds: locationIdsForSubmit,
            );
      } else {
        await ref
            .read(classTypeMutationControllerProvider.notifier)
            .create(
              name: _nameController.text,
              description: _descriptionController.text,
              colorHex: _selectedColorHex,
              serviceCategoryId: _selectedServiceCategoryId,
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 288),
            child: Scrollbar(
              thumbVisibility: locations.length > 4,
              child: ListView.separated(
                primary: false,
                shrinkWrap: true,
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
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: color == null
              ? Icon(Icons.block, size: 14, color: scheme.onSurfaceVariant)
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
    return SwitchListTile.adaptive(
      value: isSelected,
      onChanged: enabled ? onChanged : null,
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
  final _priceController = TextEditingController();
  bool _didInitializeDependencies = false;

  ClassEvent? _editingEvent;
  RecurrenceConfig? _recurrenceConfig;
  int? _classTypeId;
  int? _locationId;
  int? _staffId;
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _waitlistEnabled = true;

  @override
  void initState() {
    super.initState();
    _editingEvent = widget.initialEvent;
    _classTypeId = widget.initialClassTypeId;
    _locationId = widget.initialLocationId;
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeDependencies) {
      return;
    }
    _didInitializeDependencies = true;
    // Reset the create controller in case a previous operation left it in a
    // stuck AsyncLoading state (e.g. network hang while the form was closed).
    ref.invalidate(classEventCreateControllerProvider);
    if (_editingEvent != null) {
      _applyEventToForm(_editingEvent!);
    } else {
      _initializeDefaultTimesForCreate();
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _priceController.dispose();
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
    final inactiveAssignedStaffId = hasInactiveAssignedOption
        ? editingStaffId
        : null;
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
    final inactiveAssignedLabel = inactiveAssignedStaffId != null
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
        (member) =>
            (id: member.id, label: member.displayName, isInactive: false),
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

    const double gap = 20;
    const double sectionGap = 32;
    final colorScheme = Theme.of(context).colorScheme;
    final currencySymbol = NumberFormat.currency(
      name: ref.watch(effectiveCurrencyProvider),
    ).currencySymbol;

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
            // ── stato caricamento / errori ──
            if (classTypesAsync.isLoading || staffAsync.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: LinearProgressIndicator(),
              ),
            if (classTypesAsync.hasError || staffAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: Text(
                  l10n.errorTitle,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),

            // ── etichetta modifica ──
            if (isEditMode) ...[
              Text(
                l10n.classEventsEditModeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: gap),
            ],

            // ── sede (solo creazione, se multipla) ──
            if (!isEditMode && filteredLocations.length > 1) ...[
              DropdownButtonFormField<int>(
                value: _locationId,
                decoration: InputDecoration(
                  labelText: l10n.classEventsFieldLocation,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.place_outlined),
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
              const SizedBox(height: gap),
            ],
            if (filteredLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: Text(
                  l10n.classEventsNoLocationsForClassType,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            // ── staff (se multiplo) ──
            if (!isEditMode
                ? staff.length > 1
                : staffDropdownItems.length > 1) ...[
              DropdownButtonFormField<int>(
                value: _staffId,
                decoration: InputDecoration(
                  labelText: l10n.classEventsFieldStaff,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
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
                  if (value == null) return l10n.classEventsValidationRequired;
                  if (isEditMode &&
                      editingStaffId != null &&
                      hasInactiveAssignedOption &&
                      value == editingStaffId) {
                    return l10n.classEventsStaffInactiveChangeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: gap),
            ],
            if (requiresStaffReplacement)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: Text(
                  l10n.classEventsStaffInactiveChangeRequired,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ),
            if (!isEditMode && staff.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: Text(
                  l10n.classEventsNoStaffForLocation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (classTypes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: Text(
                  l10n.classEventsNoClassTypes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            // ══ Sezione: Quando ══
            _PickerField(
              label: l10n.classEventsFieldDate,
              value: _formatDate(_date),
              icon: Icons.calendar_today_outlined,
              onTap: isLoading ? null : _pickDate,
            ),
            const SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: _ScheduleTimeField(
                    label: l10n.classEventsFieldStartTime,
                    time: _startTime,
                    onTap: isLoading ? null : () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: gap),
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
              const SizedBox(height: gap),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.error),
                ),
                child: Text(
                  l10n.bookingUnavailableTimeWarningService,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],

            // ══ Sezione: Dettagli ══
            const SizedBox(height: sectionGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.classEventsFieldCapacity,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.people_outline),
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
                const SizedBox(width: gap),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.classEventsFieldPrice,
                      border: const OutlineInputBorder(),
                      prefixText: '$currencySymbol ',
                      hintText: l10n.classEventsFieldPriceFreeHint,
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(l10n.classEventsFieldWaitlistEnabled),
              value: _waitlistEnabled,
              onChanged: isLoading
                  ? null
                  : (v) => setState(() => _waitlistEnabled = v),
            ),

            if (!isEditMode) ...[
              const SizedBox(height: gap),
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
        if (isEditMode)
          AppAsyncDangerButton(
            onPressed: _deleteCurrentEvent,
            child: Text(l10n.actionDelete),
          ),
        AppOutlinedActionButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppAsyncFilledButton(
          isLoading: isLoading,
          onPressed:
              _canSubmit(
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

  void _initializeDefaultTimesForCreate() {
    final now = ref.read(tenantNowProvider);
    final sameDayAsToday =
        _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    if (!sameDayAsToday) return;

    final nowMinutes = now.hour * 60 + now.minute;
    final roundedStartMinutes = _roundUpToStepMinutes(nowMinutes);
    final maxStartMinutes = (24 * 60) - (_timeStepMinutes * 2);
    final safeStartMinutes = roundedStartMinutes.clamp(0, maxStartMinutes);
    _startTime = _fromDayMinutes(safeStartMinutes);
    _endTime = _fromDayMinutes(safeStartMinutes + _timeStepMinutes);
  }

  int _roundUpToStepMinutes(int totalMinutes) {
    final remainder = totalMinutes % _timeStepMinutes;
    if (remainder == 0) return totalMinutes;
    return totalMinutes + (_timeStepMinutes - remainder);
  }

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

  Future<void> _deleteCurrentEvent() async {
    final event = _editingEvent;
    if (event == null || !mounted) return;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classEventsSchedulesDeleteConfirmTitle),
        content: Text(l10n.classEventsSchedulesDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final repo = ref.read(classEventsRepositoryProvider);
      await repo.deleteEvent(businessId: businessId, classEventId: event.id);
      ref.invalidate(classEventsProvider);
      ref.invalidate(classEventsForRangeProvider);
      ref.invalidate(classEventsForCurrentLocationDayProvider);
      ref.invalidate(allClassEventsByTypeProvider(event.classTypeId));
      ref.invalidate(upcomingClassEventsByTypeProvider(event.classTypeId));
      ref.invalidate(upcomingClassEventsCountByTypeProvider(event.classTypeId));
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

    final priceCents = _parsePriceCents();
    final currency = ref.read(effectiveCurrencyProvider);

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
            'waitlist_enabled': _waitlistEnabled,
            'price_cents': priceCents,
            if (priceCents != null) 'currency': currency,
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
              waitlistEnabled: _waitlistEnabled,
              priceCents: priceCents,
              currency: priceCents != null ? currency : null,
            );
        ref.invalidate(upcomingClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(allClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(upcomingClassEventsCountByTypeProvider(_classTypeId!));
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
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
                'waitlist_enabled': _waitlistEnabled,
                'price_cents': priceCents,
                if (priceCents != null) 'currency': currency,
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
    _priceController.text = event.priceCents != null
        ? (event.priceCents! / 100).toStringAsFixed(2)
        : '';
    _waitlistEnabled = event.waitlistEnabled;
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

  int? _parsePriceCents() {
    final raw = _priceController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 0) return null;
    return (parsed * 100).round();
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
    final exceptionsNotifier = ref.read(
      availabilityExceptionsProvider.notifier,
    );
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
