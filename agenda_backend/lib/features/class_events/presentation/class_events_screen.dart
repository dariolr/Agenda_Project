import 'package:agenda_backend/core/widgets/app_dividers.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/widgets/client_circle_avatar.dart';
import '/app/widgets/staff_circle_avatar.dart';
import '/app/providers/form_factor_provider.dart';
import '/core/l10n/date_time_formats.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/appointment.dart';
import '/core/models/class_booking.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/models/location.dart';
import '/core/models/service_category.dart';
import '/core/models/staff.dart';
import '/core/network/api_client.dart';
import '/core/services/tenant_time_service.dart';
import '/core/utils/color_utils.dart';
import '/core/utils/service_color_palette.dart';
import '/core/widgets/app_bottom_sheet.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/app_dialogs.dart';
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
import '/features/clients/domain/clients.dart';
import '/features/clients/presentation/dialogs/client_edit_dialog.dart';
import '/features/clients/providers/clients_providers.dart';
import '/features/staff/providers/availability_exceptions_provider.dart';
import '/features/staff/providers/staff_planning_provider.dart';
import '/features/staff/providers/staff_providers.dart';
import '../../../core/models/recurrence_rule.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../data/class_events_repository.dart';
import '../providers/class_events_providers.dart';

String _resolveClassTypeErrorMessage(Object error, BuildContext context) {
  final l10n = context.l10n;
  if (error is ApiException) {
    if (error.statusCode == 403) {
      return l10n.apiErrorForbidden;
    }
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

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({required this.label, this.isMuted = false});

  final String label;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.1,
      color: isMuted
          ? colorScheme.onSurface.withOpacity(0.6)
          : colorScheme.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isMuted
            ? colorScheme.surfaceContainerHighest.withOpacity(0.55)
            : colorScheme.surfaceContainerHighest.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: textStyle),
    );
  }
}

Future<void> showCreateClassTypeDialog(
  BuildContext context,
  WidgetRef ref, {
  ClassType? initial,
  int? preselectedCategoryId,
}) async {
  final canManageServices = ref.read(currentUserCanManageServicesProvider);
  if (!canManageServices) {
    await FeedbackDialog.showError(
      context,
      title: context.l10n.errorTitle,
      message: context.l10n.apiErrorForbidden,
    );
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

Future<bool> showCreateClassEventDialog(
  BuildContext context,
  WidgetRef ref, {
  int? initialClassTypeId,
  ClassEvent? initialEvent,
  ClassEvent? prefillEvent,
  bool useRootNavigator = true,
  bool closeParentOnSave = false,
}) async {
  final currentLocation = ref.read(currentLocationProvider);
  final initialDate = ref.read(agendaDateProvider);

  final saved =
      await AppForm.show<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (_) => _CreateClassForm(
      initialClassTypeId: initialClassTypeId,
      initialLocationId: currentLocation.id,
      initialDate: initialDate,
      initialEvent: initialEvent,
      prefillEvent: prefillEvent,
    ),
  ) ==
  true;

  if (saved && closeParentOnSave && context.mounted) {
    Navigator.of(context).pop();
  }

  return saved;
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

  Future<void> _pickClassTypeColor(String fallbackColorHex) async {
    final initialColor =
        _tryParseHexColor(_selectedColorHex) ?? ColorUtils.fromHex(fallbackColorHex);
    var tempColor = initialColor;
    final selected = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) => tempColor = color,
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.72,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(tempColor),
              child: Text(context.l10n.actionConfirm),
            ),
          ],
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedColorHex = ColorUtils.toHex(selected));
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
    final businessPaletteSetting = ref
        .watch(currentBusinessProvider)
        .serviceColorPalette;
    final classTypePalette = serviceColorPaletteForSetting(
      businessPaletteSetting,
    );
    final fallbackColorHex = classTypePalette.isNotEmpty
        ? ColorUtils.toHex(classTypePalette.first)
        : '#CCCCCC';
    final selectedColorHexForUi =
        _selectedColorHex?.trim().isNotEmpty == true
        ? _selectedColorHex!
        : fallbackColorHex;
    final locationNameById = {
      for (final location in locations) location.id: location.name,
    };
    final staffNameById = {
      for (final member in allStaff) member.id: member.displayName,
    };
    final hasSelectedCategoryInList =
        _selectedServiceCategoryId == null ||
        serviceCategories.any((c) => c.id == _selectedServiceCategoryId);
    if (!_isEdit) {
      final validCategoryIds = serviceCategories
          .map((category) => category.id)
          .toSet();
      if (_selectedServiceCategoryId != null &&
          !validCategoryIds.contains(_selectedServiceCategoryId)) {
        _selectedServiceCategoryId = null;
      }
      if (_selectedServiceCategoryId == null && serviceCategories.length == 1) {
        _selectedServiceCategoryId = serviceCategories.first.id;
      }
    }
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
            selectedColorHex: selectedColorHexForUi,
            palette: classTypePalette,
            enabled: !isBusy,
            onChanged: (hex) => setState(() => _selectedColorHex = hex),
            onPickCustom: () => _pickClassTypeColor(fallbackColorHex),
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

                                  final confirmedChipLabel =
                                      '${l10n.classEventsParticipantsConfirmedTitle}: ${schedule.confirmedCount}/${schedule.capacityTotal}';
                                  final waitlistChipLabel =
                                      '${l10n.classEventsParticipantsWaitlistTitle}: ${schedule.waitlistCount}';
                                  final showCapacityPills =
                                      schedule.waitlistCount > 0 ||
                                      schedule.confirmedCount >=
                                          schedule.capacityTotal;

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
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$locationName • $staffName',
                                          style: isPast
                                              ? TextStyle(
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.35),
                                                )
                                              : null,
                                        ),
                                        if (showCapacityPills) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              _MiniInfoPill(
                                                label: confirmedChipLabel,
                                                isMuted: isPast,
                                              ),
                                              if (schedule.waitlistEnabled ||
                                                  schedule.waitlistCount > 0)
                                                _MiniInfoPill(
                                                  label: waitlistChipLabel,
                                                  isMuted: isPast,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isPast)
                                          IconButton(
                                            tooltip: l10n.actionEdit,
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                            ),
                                            onPressed: isBusy
                                                ? null
                                                : () =>
                                                      showCreateClassEventDialog(
                                                        context,
                                                        ref,
                                                        initialEvent: schedule,
                                                        useRootNavigator: false,
                                                        closeParentOnSave: true,
                                                      ),
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
                                            closeParentOnSave: true,
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
                      closeParentOnSave: true,
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
    await showCreateClassEventDialog(
      context,
      ref,
      initialClassTypeId: widget.initial!.id,
      prefillEvent: schedule,
      useRootNavigator: false,
      closeParentOnSave: true,
    );
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
    final businessPaletteSetting = ref
        .read(currentBusinessProvider)
        .serviceColorPalette;
    final classTypePalette = serviceColorPaletteForSetting(
      businessPaletteSetting,
    );
    final fallbackColorHex = classTypePalette.isNotEmpty
        ? ColorUtils.toHex(classTypePalette.first)
        : '#CCCCCC';
    final colorHexForSubmit =
        _selectedColorHex?.trim().isNotEmpty == true
        ? _selectedColorHex
        : fallbackColorHex;

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
              colorHex: colorHexForSubmit,
              serviceCategoryId: _selectedServiceCategoryId,
              locationIds: locationIdsForSubmit,
            );
      } else {
        await ref
            .read(classTypeMutationControllerProvider.notifier)
            .create(
              name: _nameController.text,
              description: _descriptionController.text,
              colorHex: colorHexForSubmit,
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
    required this.onPickCustom,
  });

  final String selectedColorHex;
  final List<Color> palette;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickCustom;

  @override
  Widget build(BuildContext context) {
    final selectedHex = selectedColorHex.trim().toUpperCase();
    final selectedColor = _tryParseHexColor(selectedHex);
    final paletteHexes = {
      for (final color in palette) ColorUtils.toHex(color).toUpperCase(),
    };
    final showCustomSelected =
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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: enabled ? onPickCustom : null,
          icon: const Icon(Icons.palette_outlined),
          label: Text(context.l10n.actionEdit),
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

  final Color color;
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
            color: color,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
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
    this.prefillEvent,
  });

  final int initialLocationId;
  final DateTime initialDate;
  final int? initialClassTypeId;
  final ClassEvent? initialEvent;
  final ClassEvent? prefillEvent;

  @override
  ConsumerState<_CreateClassForm> createState() => _CreateClassFormState();
}

class _ClassEventFormSnapshot {
  const _ClassEventFormSnapshot({
    required this.classTypeId,
    required this.locationId,
    required this.staffId,
    required this.date,
    required this.startTimeMinutes,
    required this.endTimeMinutes,
    required this.capacity,
    required this.price,
    required this.waitlistEnabled,
    required this.recurrenceFrequency,
    required this.recurrenceInterval,
    required this.recurrenceMaxOccurrences,
    required this.recurrenceEndDateIso,
    required this.recurrenceConflictStrategy,
  });

  final int? classTypeId;
  final int? locationId;
  final int? staffId;
  final DateTime date;
  final int startTimeMinutes;
  final int endTimeMinutes;
  final String capacity;
  final String price;
  final bool waitlistEnabled;
  final RecurrenceFrequency? recurrenceFrequency;
  final int? recurrenceInterval;
  final int? recurrenceMaxOccurrences;
  final String? recurrenceEndDateIso;
  final ConflictStrategy? recurrenceConflictStrategy;

  bool sameAs(_ClassEventFormSnapshot other) {
    return classTypeId == other.classTypeId &&
        locationId == other.locationId &&
        staffId == other.staffId &&
        date == other.date &&
        startTimeMinutes == other.startTimeMinutes &&
        endTimeMinutes == other.endTimeMinutes &&
        capacity == other.capacity &&
        price == other.price &&
        waitlistEnabled == other.waitlistEnabled &&
        recurrenceFrequency == other.recurrenceFrequency &&
        recurrenceInterval == other.recurrenceInterval &&
        recurrenceMaxOccurrences == other.recurrenceMaxOccurrences &&
        recurrenceEndDateIso == other.recurrenceEndDateIso &&
        recurrenceConflictStrategy == other.recurrenceConflictStrategy;
  }
}

class _StagedParticipant {
  const _StagedParticipant({
    required this.customerId,
    required this.displayName,
    required this.status,
  });

  final int customerId;
  final String displayName;
  final String status; // 'confirmed' | 'waitlisted'

  _StagedParticipant copyWith({String? status}) => _StagedParticipant(
    customerId: customerId,
    displayName: displayName,
    status: status ?? this.status,
  );
}

class _CreateClassFormState extends ConsumerState<_CreateClassForm> {
  static const int _timeStepMinutes = 15;
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  bool _didInitializeDependencies = false;
  bool _initialSnapshotCaptured = false;
  _ClassEventFormSnapshot? _initialSnapshot;

  // Staged participant state — local edits applied only on Save.
  List<_StagedParticipant>? _stagedParticipants;
  List<_StagedParticipant>? _originalParticipants;
  bool _participantsInitialized = false;

  ClassEvent? _editingEvent;
  ClassEvent? _prefillEvent;
  RecurrenceConfig? _recurrenceConfig;
  int? _classTypeId;
  int? _locationId;
  int? _staffId;
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  bool _waitlistEnabled = true;

  @override
  void initState() {
    super.initState();
    _editingEvent = widget.initialEvent;
    _prefillEvent = widget.prefillEvent;
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
    } else if (_prefillEvent != null) {
      _applyEventToForm(_prefillEvent!, includeDate: false);
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
    final classEventId = _editingEvent?.id;
    final participantsAsync = classEventId == null
        ? const AsyncData<List<ClassBooking>>(<ClassBooking>[])
        : ref.watch(classEventParticipantsProvider(classEventId));
    if (!_participantsInitialized && participantsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_participantsInitialized) {
          _initStagedParticipants(participantsAsync.value!);
        }
      });
    }
    const isParticipantsActionLoading = false;
    final businessId = ref.watch(currentBusinessIdProvider);

    final classTypes = classTypesAsync.value ?? const <ClassType>[];
    final classTypesForLocation = !isEditMode
        ? _classTypesForLocation(classTypes, widget.initialLocationId)
        : classTypes;
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

    if (classTypesForLocation.isNotEmpty && _classTypeId == null) {
      _classTypeId = classTypesForLocation.first.id;
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
    _captureInitialSnapshotIfNeeded(
      classTypesAsync: classTypesAsync,
      staffAsync: staffAsync,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleClose();
      },
      child: AppFormScaffold(
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

              // ── tipo lezione (solo creazione, se multiplo) ──
              if (!isEditMode && classTypesForLocation.length > 1) ...[
                DropdownButtonFormField<int>(
                  value: _classTypeId,
                  decoration: InputDecoration(
                    labelText: l10n.classEventsFieldClassType,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: classTypesForLocation
                      .map(
                        (ct) => DropdownMenuItem<int>(
                          value: ct.id,
                          child: Text(ct.name),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() {
                          _classTypeId = value;
                          _locationId = null;
                          _staffId = null;
                        }),
                  validator: (value) =>
                      value == null ? l10n.classEventsValidationRequired : null,
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
              const SizedBox(height: sectionGap),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(l10n.classEventsFieldWaitlistEnabled),
                value: _waitlistEnabled,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _waitlistEnabled = v),
              ),

              if (isEditMode && classEventId != null) ...[
                const SizedBox(height: sectionGap),
                _buildParticipantsSection(
                  participantsAsync: participantsAsync,
                  isActionLoading: isParticipantsActionLoading,
                ),
              ],

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
            onPressed: isLoading ? null : _handleClose,
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
      ),
    );
  }

  Future<void> _handleClose() async {
    final shouldProceed = await _confirmDiscardChangesIfNeeded();
    if (!shouldProceed || !mounted) return;
    Navigator.of(context).pop(false);
  }

  Future<bool> _confirmDiscardChangesIfNeeded() async {
    if (!_hasUnsavedChanges) return true;
    final l10n = context.l10n;
    return showConfirmDialog(
      context,
      title: Text(l10n.discardChangesTitle),
      content: Text(l10n.discardChangesMessage),
      confirmLabel: l10n.actionDiscard,
      cancelLabel: l10n.actionKeepEditing,
      danger: true,
    );
  }

  void _initStagedParticipants(List<ClassBooking> bookings) {
    if (_participantsInitialized) return;
    final confirmed = bookings
        .where((b) => b.isConfirmed)
        .map(
          (b) => _StagedParticipant(
            customerId: b.customerId,
            displayName: b.customerDisplayName,
            status: 'confirmed',
          ),
        )
        .toList();
    final waitlisted =
        (bookings.where((b) => b.isWaitlisted).toList()..sort(
              (a, b) => (a.waitlistPosition ?? 9999).compareTo(
                b.waitlistPosition ?? 9999,
              ),
            ))
            .map(
              (b) => _StagedParticipant(
                customerId: b.customerId,
                displayName: b.customerDisplayName,
                status: 'waitlisted',
              ),
            )
            .toList();
    final staged = [...confirmed, ...waitlisted];
    setState(() {
      _stagedParticipants = staged;
      _originalParticipants = staged
          .map(
            (p) => _StagedParticipant(
              customerId: p.customerId,
              displayName: p.displayName,
              status: p.status,
            ),
          )
          .toList();
      _participantsInitialized = true;
    });
  }

  bool get _participantsDirty {
    final orig = _originalParticipants;
    final staged = _stagedParticipants;
    if (orig == null || staged == null) return false;
    if (orig.length != staged.length) return true;
    for (var i = 0; i < orig.length; i++) {
      if (orig[i].customerId != staged[i].customerId) return true;
      if (orig[i].status != staged[i].status) return true;
    }
    return false;
  }

  bool get _hasUnsavedChanges {
    final initial = _initialSnapshot;
    if (!_initialSnapshotCaptured || initial == null) return false;
    return !_buildSnapshot().sameAs(initial) || _participantsDirty;
  }

  void _captureInitialSnapshotIfNeeded({
    required AsyncValue<List<ClassType>> classTypesAsync,
    required AsyncValue<List<Staff>> staffAsync,
  }) {
    if (_initialSnapshotCaptured) return;
    if (classTypesAsync.isLoading || staffAsync.isLoading) return;
    _initialSnapshot = _buildSnapshot();
    _initialSnapshotCaptured = true;
  }

  _ClassEventFormSnapshot _buildSnapshot() {
    final recurrence = _recurrenceConfig;
    final normalizedDate = DateTime(_date.year, _date.month, _date.day);
    final recurrenceEndDate = recurrence?.endDate;
    final recurrenceEndDateIso = recurrenceEndDate == null
        ? null
        : '${recurrenceEndDate.year.toString().padLeft(4, '0')}-${recurrenceEndDate.month.toString().padLeft(2, '0')}-${recurrenceEndDate.day.toString().padLeft(2, '0')}';
    return _ClassEventFormSnapshot(
      classTypeId: _classTypeId,
      locationId: _locationId,
      staffId: _staffId,
      date: normalizedDate,
      startTimeMinutes: _toDayMinutes(_startTime),
      endTimeMinutes: _toDayMinutes(_endTime),
      capacity: _capacityController.text.trim(),
      price: _priceController.text.trim(),
      waitlistEnabled: _waitlistEnabled,
      recurrenceFrequency: recurrence?.frequency,
      recurrenceInterval: recurrence?.intervalValue,
      recurrenceMaxOccurrences: recurrence?.maxOccurrences,
      recurrenceEndDateIso: recurrenceEndDateIso,
      recurrenceConflictStrategy: recurrence?.conflictStrategy,
    );
  }

  Widget _buildParticipantsSection({
    required AsyncValue<List<ClassBooking>> participantsAsync,
    required bool isActionLoading,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = ref.watch(formFactorProvider) == AppFormFactor.mobile;
    final staged = _stagedParticipants ?? const <_StagedParticipant>[];
    final isBootstrappingParticipants =
        !_participantsInitialized &&
        !participantsAsync.isLoading &&
        participantsAsync.hasValue &&
        !participantsAsync.hasError;
    final confirmed = staged.where((p) => p.status == 'confirmed').toList();
    final waitlisted = staged.where((p) => p.status == 'waitlisted').toList();
    final activeCustomerIds = staged.map((p) => p.customerId).toSet();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.classEventsParticipantsTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              AppOutlinedActionButton(
                onPressed: isActionLoading
                    ? null
                    : () => _addClassBooking(
                        targetStatus: 'confirmed',
                        excludedCustomerIds: activeCustomerIds,
                      ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: isCompact
                    ? const Icon(Icons.add, size: 18)
                    : Text('+ ${l10n.classEventsParticipantsAddConfirmed}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (participantsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (isBootstrappingParticipants)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (participantsAsync.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.classEventsParticipantsLoadError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          if (_participantsInitialized) ...[
            _buildParticipantGroup(
              title: l10n.classEventsParticipantsConfirmedTitle,
              emptyLabel: l10n.classEventsParticipantsEmptyConfirmed,
              participants: confirmed,
              isActionLoading: isActionLoading,
              showWaitlistActions: false,
              showTitle: false,
            ),
            const SizedBox(height: 8),
            const AppDivider(height: 1),
            const SizedBox(height: 8),
            _buildParticipantGroup(
              title: l10n.classEventsParticipantsWaitlistTitle,
              emptyLabel: _waitlistEnabled
                  ? l10n.classEventsParticipantsEmptyWaitlist
                  : l10n.classEventsWaitlistDisabledHint,
              participants: waitlisted,
              isActionLoading: isActionLoading,
              showWaitlistActions: true,
              headerAction: _waitlistEnabled
                  ? AppOutlinedActionButton(
                      onPressed: isActionLoading
                          ? null
                          : () => _addClassBooking(
                              targetStatus: 'waitlisted',
                              excludedCustomerIds: activeCustomerIds,
                            ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: isCompact
                          ? const Icon(Icons.add, size: 18)
                          : Text(
                              '+ ${l10n.classEventsParticipantsAddWaitlist}',
                            ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantGroup({
    required String title,
    required String emptyLabel,
    required List<_StagedParticipant> participants,
    required bool isActionLoading,
    required bool showWaitlistActions,
    bool showTitle = true,
    Widget? headerAction,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clientsById = ref.watch(clientsByIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (participants.isEmpty)
          Text(emptyLabel, style: theme.textTheme.bodySmall)
        else
          ...participants.indexed.map(((int, _StagedParticipant) entry) {
            final (index, participant) = entry;
            final name = participant.displayName.isNotEmpty
                ? participant.displayName
                : l10n.classEventsParticipantCustomer(participant.customerId);
            final waitlistSuffix = showWaitlistActions
                ? ' • #${index + 1}'
                : '';
            final client = clientsById[participant.customerId];
            final initials = participant.displayName.trim().isNotEmpty
                ? initialsFromName(participant.displayName, maxChars: 2)
                : '?';

            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              onTap: isActionLoading
                  ? null
                  : () => _openParticipantClientEdit(participant.customerId),
              leading: ClientCircleAvatar(
                height: 28,
                clientColorHex: client?.colorHex,
                isHighlighted: false,
                initials: initials,
              ),
              title: Text(name, overflow: TextOverflow.ellipsis),
              subtitle: waitlistSuffix.isNotEmpty
                  ? Text(waitlistSuffix.trim())
                  : null,
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (showWaitlistActions)
                    (index > 0)
                        ? IconButton(
                            tooltip: l10n.classEventsParticipantsPriorityUp,
                            onPressed: isActionLoading
                                ? null
                                : () => _stageMoveWaitlistPriority(
                                    customerId: participant.customerId,
                                    moveUp: true,
                                  ),
                            icon: const Icon(Icons.arrow_drop_up, size: 20),
                          )
                        : const SizedBox(width: 40, height: 40),
                  if (showWaitlistActions)
                    (index < participants.length - 1)
                        ? IconButton(
                            tooltip: l10n.classEventsParticipantsPriorityDown,
                            onPressed: isActionLoading
                                ? null
                                : () => _stageMoveWaitlistPriority(
                                    customerId: participant.customerId,
                                    moveUp: false,
                                  ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                          )
                        : const SizedBox(width: 40, height: 40),
                  if (showWaitlistActions)
                    IconButton(
                      tooltip: l10n.classEventsParticipantsPromoteAction,
                      onPressed: isActionLoading
                          ? null
                          : () => _stageStatusChange(
                              customerId: participant.customerId,
                              targetStatus: 'confirmed',
                            ),
                      icon: const Icon(Icons.arrow_upward, size: 18),
                    )
                  else if (_waitlistEnabled)
                    IconButton(
                      tooltip: l10n.classEventsParticipantsDemoteAction,
                      onPressed: isActionLoading
                          ? null
                          : () => _stageDemoteToWaitlist(
                              customerId: participant.customerId,
                            ),
                      icon: const Icon(Icons.arrow_downward, size: 18),
                    ),
                  IconButton(
                    tooltip: l10n.classEventsParticipantsRemoveAction,
                    onPressed: isActionLoading
                        ? null
                        : () => _stageRemoveParticipant(
                            customerId: participant.customerId,
                          ),
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: colorScheme.error,
                      size: 18,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _addClassBooking({
    required String targetStatus,
    required Set<int> excludedCustomerIds,
  }) async {
    final result = await _pickClientForClassBooking(
      excludedCustomerIds: excludedCustomerIds,
    );
    if (result == null || !mounted) return;
    setState(() {
      final staged = List<_StagedParticipant>.from(_stagedParticipants ?? []);
      staged.removeWhere((p) => p.customerId == result.id);
      staged.add(
        _StagedParticipant(
          customerId: result.id,
          displayName: result.name,
          status: targetStatus,
        ),
      );
      _stagedParticipants = staged;
    });
  }

  Future<void> _openParticipantClientEdit(int customerId) async {
    final client = ref.read(clientsByIdProvider)[customerId];
    if (client == null) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.classEventsParticipantsLoadError,
      );
      return;
    }

    final updatedClient = await showClientEditDialog(
      context,
      ref,
      client: client,
    );
    if (updatedClient == null || !mounted) return;

    setState(() {
      _stagedParticipants = (_stagedParticipants ?? const <_StagedParticipant>[])
          .map(
            (p) => p.customerId == updatedClient.id
                ? _StagedParticipant(
                    customerId: p.customerId,
                    displayName: updatedClient.name,
                    status: p.status,
                  )
                : p,
          )
          .toList();
    });
  }

  void _stageStatusChange({
    required int customerId,
    required String targetStatus,
  }) {
    setState(() {
      _stagedParticipants = (_stagedParticipants ?? []).map((p) {
        if (p.customerId == customerId) return p.copyWith(status: targetStatus);
        return p;
      }).toList();
    });
  }

  void _stageDemoteToWaitlist({required int customerId}) {
    final staged = List<_StagedParticipant>.from(_stagedParticipants ?? []);
    final demoted = staged.firstWhere((p) => p.customerId == customerId);
    // First waitlisted in current order, excluding the one being demoted.
    final waitlistedOthers = staged.where(
      (p) => p.status == 'waitlisted' && p.customerId != customerId,
    );
    final firstWaitlisted = waitlistedOthers.isEmpty
        ? null
        : waitlistedOthers.first;
    staged.removeWhere((p) => p.customerId == customerId);
    if (firstWaitlisted != null) {
      final idx = staged.indexWhere(
        (p) => p.customerId == firstWaitlisted.customerId,
      );
      if (idx >= 0) staged[idx] = staged[idx].copyWith(status: 'confirmed');
    }
    staged.add(demoted.copyWith(status: 'waitlisted'));
    setState(() => _stagedParticipants = staged);
  }

  void _stageRemoveParticipant({required int customerId}) {
    setState(() {
      _stagedParticipants = (_stagedParticipants ?? [])
          .where((p) => p.customerId != customerId)
          .toList();
    });
  }

  void _stageMoveWaitlistPriority({
    required int customerId,
    required bool moveUp,
  }) {
    final staged = List<_StagedParticipant>.from(
      _stagedParticipants ?? const [],
    );
    if (staged.isEmpty) return;

    final currentGlobalIndex = staged.indexWhere(
      (p) => p.customerId == customerId,
    );
    if (currentGlobalIndex < 0) return;
    if (staged[currentGlobalIndex].status != 'waitlisted') return;

    final waitlistIndexes = <int>[];
    for (var i = 0; i < staged.length; i++) {
      if (staged[i].status == 'waitlisted') {
        waitlistIndexes.add(i);
      }
    }
    final waitlistPosition = waitlistIndexes.indexOf(currentGlobalIndex);
    if (waitlistPosition < 0) return;

    final targetWaitlistPosition = moveUp
        ? waitlistPosition - 1
        : waitlistPosition + 1;
    if (targetWaitlistPosition < 0 ||
        targetWaitlistPosition >= waitlistIndexes.length) {
      return;
    }

    final targetGlobalIndex = waitlistIndexes[targetWaitlistPosition];
    final currentParticipant = staged[currentGlobalIndex];
    staged[currentGlobalIndex] = staged[targetGlobalIndex];
    staged[targetGlobalIndex] = currentParticipant;
    setState(() => _stagedParticipants = staged);
  }

  Future<_ClassBookingClientPickerResult?> _pickClientForClassBooking({
    required Set<int> excludedCustomerIds,
  }) async {
    Future<_ClassBookingClientPickerResult?> openClientPicker() {
      final formFactor = ref.read(formFactorProvider);
      if (formFactor == AppFormFactor.desktop) {
        return showDialog<_ClassBookingClientPickerResult?>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => DismissibleDialog(
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 600,
                  maxWidth: 720,
                  maxHeight: 600,
                ),
                child: _ClassBookingClientPickerSheet(
                  excludedCustomerIds: excludedCustomerIds,
                ),
              ),
            ),
          ),
        );
      }

      return AppBottomSheet.show<_ClassBookingClientPickerResult?>(
        context: context,
        useRootNavigator: true,
        padding: EdgeInsets.zero,
        heightFactor: AppBottomSheet.defaultHeightFactor,
        builder: (_) => _ClassBookingClientPickerSheet(
          excludedCustomerIds: excludedCustomerIds,
        ),
      );
    }

    while (true) {
      final result = await openClientPicker();
      if (result == null) return null;

      if (result.isCreateNew) {
        if (!mounted) return null;
        Client? initialClient;
        final prefillName = result.name.trim();
        if (prefillName.isNotEmpty) {
          final nameParts = Client.splitFullName(prefillName);
          initialClient = Client(
            id: 0,
            businessId: 0,
            firstName: nameParts.firstName,
            lastName: nameParts.lastName,
            createdAt: ref.read(tenantNowProvider),
          );
        }
        final newClient = await showClientEditDialog(
          context,
          ref,
          client: initialClient,
        );
        if (newClient != null) {
          return _ClassBookingClientPickerResult(newClient.id, newClient.name);
        }
        continue;
      }

      return result;
    }
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

  List<ClassType> _classTypesForLocation(
    List<ClassType> classTypes,
    int locationId,
  ) {
    return classTypes
        .where(
          (ct) => ct.locationIds.isEmpty || ct.locationIds.contains(locationId),
        )
        .toList();
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
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          child: CalendarDatePicker(
            initialDate: _date,
            firstDate: now.subtract(const Duration(days: 365)),
            lastDate: now.add(const Duration(days: 365 * 2)),
            onDateChanged: (value) => Navigator.of(context).pop(value),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
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
        final oldStartMinutes = _toDayMinutes(_startTime);
        final oldEndMinutes = _toDayMinutes(_endTime);
        final newStartMinutes = _toDayMinutes(picked);
        final shiftDelta = newStartMinutes - oldStartMinutes;
        const maxDayMinutes = (24 * 60) - 1;
        final minEndMinutes = (newStartMinutes + _timeStepMinutes).clamp(
          0,
          maxDayMinutes,
        );
        final shiftedEndMinutes = (oldEndMinutes + shiftDelta).clamp(
          minEndMinutes,
          maxDayMinutes,
        );

        _startTime = picked;
        _endTime = _fromDayMinutes(shiftedEndMinutes);
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
    _endTime = _fromDayMinutes(safeStartMinutes + 90);
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

    // Capacity validations only apply when editing an existing event.
    if (_editingEvent != null) {
      final staged = _stagedParticipants ?? const <_StagedParticipant>[];
      final confirmedCount = staged
          .where((p) => p.status == 'confirmed')
          .length;
      if (capacity < confirmedCount) {
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: l10n.classEventsValidationCapacityBelowConfirmed,
        );
        return;
      }

      final waitlisted = staged.where((p) => p.status == 'waitlisted').toList();
      final freeSpots = capacity - confirmedCount;
      if (waitlisted.isNotEmpty && freeSpots > 0) {
        final shouldPromote = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.classEventsPromoteWaitlistTitle),
            content: Text(l10n.classEventsPromoteWaitlistMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.actionNo),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.actionYes),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (shouldPromote == true) {
          final toPromote = waitlisted.take(freeSpots).toList();
          setState(() {
            _stagedParticipants = staged.map((p) {
              if (toPromote.any((w) => w.customerId == p.customerId)) {
                return p.copyWith(status: 'confirmed');
              }
              return p;
            }).toList();
          });
        }
      }
    }

    final priceCents = _parsePriceCents();
    final currency = ref.read(effectiveCurrencyProvider);

    try {
      if (_editingEvent != null) {
        final eventId = _editingEvent!.id;
        final businessId = ref.read(currentBusinessIdProvider);
        final repo = ref.read(classEventsRepositoryProvider);
        final classTypeIdForRefresh = _classTypeId!;
        await repo.update(
          businessId: businessId,
          classEventId: eventId,
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
        if (!mounted) return;
        // Apply staged participant diff.
        final orig = _originalParticipants ?? const <_StagedParticipant>[];
        final staged = _stagedParticipants ?? const <_StagedParticipant>[];
        final origMap = {for (final p in orig) p.customerId: p.status};
        final stagedMap = {for (final p in staged) p.customerId: p.status};
        // Removals first (frees up capacity for new additions).
        for (final p in orig) {
          if (!mounted) break;
          if (!stagedMap.containsKey(p.customerId)) {
            await repo.cancelBooking(
              businessId: businessId,
              classEventId: eventId,
              customerId: p.customerId,
            );
          }
        }
        // Additions and status changes.
        for (final p in staged) {
          if (!mounted) break;
          if (origMap[p.customerId] != p.status) {
            await repo.book(
              businessId: businessId,
              classEventId: eventId,
              customerId: p.customerId,
              targetStatus: p.status,
            );
          }
        }
        if (!mounted) return;
        final origWaitlistedCustomerIds = orig
            .where((p) => p.status == 'waitlisted')
            .map((p) => p.customerId)
            .toList();
        final waitlistedCustomerIds = staged
            .where((p) => p.status == 'waitlisted')
            .map((p) => p.customerId)
            .toList();

        final sameWaitlistPool =
            origWaitlistedCustomerIds.length == waitlistedCustomerIds.length &&
            origWaitlistedCustomerIds.toSet().containsAll(
              waitlistedCustomerIds,
            ) &&
            waitlistedCustomerIds.toSet().containsAll(
              origWaitlistedCustomerIds,
            );
        final waitlistOrderChanged =
            sameWaitlistPool &&
            !List.generate(
              waitlistedCustomerIds.length,
              (i) => waitlistedCustomerIds[i] == origWaitlistedCustomerIds[i],
            ).every((same) => same);

        if (waitlistOrderChanged) {
          await repo.reorderWaitlist(
            businessId: businessId,
            classEventId: eventId,
            customerIds: waitlistedCustomerIds,
          );
        }
        if (!mounted) return;
        ref.invalidate(classEventDetailProvider(eventId));
        ref.invalidate(classEventParticipantsProvider(eventId));
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
        Navigator.of(context).pop(true);
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
        Navigator.of(context).pop(true);
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
      Navigator.of(context).pop(true);
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

  void _applyEventToForm(ClassEvent event, {bool includeDate = true}) {
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
    if (includeDate) {
      _date = DateTime(
        startsAtLocal.year,
        startsAtLocal.month,
        startsAtLocal.day,
      );
    }
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

class _ClassBookingClientPickerResult {
  const _ClassBookingClientPickerResult(this.id, this.name);

  final int id;
  final String name;

  bool get isCreateNew => id == -2;
}

class _ClassBookingClientPickerSheet extends ConsumerStatefulWidget {
  const _ClassBookingClientPickerSheet({required this.excludedCustomerIds});

  final Set<int> excludedCustomerIds;

  @override
  ConsumerState<_ClassBookingClientPickerSheet> createState() =>
      _ClassBookingClientPickerSheetState();
}

class _ClassBookingClientPickerSheetState
    extends ConsumerState<_ClassBookingClientPickerSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final searchState = ref.watch(clientPickerSearchProvider);
    final clients = searchState.clients
        .where((c) => !widget.excludedCustomerIds.contains(c.id))
        .toList();
    final isLoading = searchState.isLoading;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectClientTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: l10n.searchClientPlaceholder,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) {
                    ref
                        .read(clientPickerSearchProvider.notifier)
                        .setSearchQuery(value);
                  },
                ),
              ],
            ),
          ),
          const AppDivider(),
          ListTile(
            leading: StaffCircleAvatar(
              height: 32,
              color: theme.colorScheme.onSurfaceVariant,
              isHighlighted: false,
              initials: '',
              child: Icon(
                Icons.person_add_outlined,
                color: theme.colorScheme.onSurface,
                size: 18,
              ),
            ),
            title: Text(l10n.createNewClient),
            onTap: () {
              Navigator.of(context).pop(
                _ClassBookingClientPickerResult(
                  -2,
                  _searchController.text.trim(),
                ),
              );
            },
          ),
          const AppDivider(),
          Expanded(
            child: isLoading && clients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null && clients.isEmpty
                ? Center(
                    child: Text(
                      l10n.classEventsParticipantsLoadError,
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : clients.isEmpty
                ? Center(
                    child: Text(
                      l10n.clientsEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        leading: ClientCircleAvatar(
                          height: 32,
                          clientColorHex: client.colorHex,
                          isHighlighted: false,
                          initials: client.name.isNotEmpty
                              ? initialsFromName(client.name, maxChars: 2)
                              : '?',
                        ),
                        title: Text(client.name),
                        subtitle: client.phone != null
                            ? Text(
                                client.phone!,
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).pop(
                            _ClassBookingClientPickerResult(
                              client.id,
                              client.name,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
