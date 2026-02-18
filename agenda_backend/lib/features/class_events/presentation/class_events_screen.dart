import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/date_time_formats.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/models/location.dart';
import '/core/models/staff.dart';
import '/core/network/api_client.dart';
import '/core/widgets/app_bottom_sheet.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/date_range_provider.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/agenda/presentation/widgets/recurrence_picker.dart';
import '/features/agenda/presentation/widgets/recurrence_preview.dart';
import '/features/agenda/presentation/dialogs/recurrence_summary_dialog.dart';
import '/features/agenda/domain/config/layout_config.dart';
import '/features/staff/providers/staff_providers.dart';
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

class ClassEventsScreen extends ConsumerWidget {
  const ClassEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final classTypesAsync = ref.watch(classTypesWithInactiveProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final canManageClassTypes = ref.watch(currentUserCanManageServicesProvider);
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Expanded(
          child: classTypesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l10n.errorTitle)),
            data: (classTypes) {
              final filteredClassTypes = classTypes.where((type) {
                if (type.locationIds.isEmpty) return true;
                return type.locationIds.contains(currentLocation.id);
              }).toList();

              if (filteredClassTypes.isEmpty) {
                return Center(
                  child: Text(
                    l10n.classTypesEmpty,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filteredClassTypes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _ClassTypeCard(
                  key: ValueKey<int>(filteredClassTypes[index].id),
                  classType: filteredClassTypes[index],
                  canManageClassTypes: canManageClassTypes,
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
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;
  if (isDesktop) {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 520,
          child: _ClassTypeFormDialog(initial: initial),
        ),
      ),
    );
    return;
  }

  await AppBottomSheet.show<void>(
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
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;
  final currentLocation = ref.read(currentLocationProvider);
  final initialDate = ref.read(agendaDateProvider);

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 620,
          child: _CreateClassForm(
            initialClassTypeId: initialClassTypeId,
            initialLocationId: currentLocation.id,
            initialDate: initialDate,
            initialEvent: initialEvent,
          ),
        ),
      ),
    );
    return;
  }

  await AppBottomSheet.show<void>(
    context: context,
    builder: (_) => _CreateClassForm(
      initialClassTypeId: initialClassTypeId,
      initialLocationId: currentLocation.id,
      initialDate: initialDate,
      initialEvent: initialEvent,
    ),
  );
}

class _ClassTypeCard extends ConsumerWidget {
  const _ClassTypeCard({
    super.key,
    required this.classType,
    required this.canManageClassTypes,
  });

  final ClassType classType;
  final bool canManageClassTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mutationState = ref.watch(classTypeMutationControllerProvider);
    final isLoading = mutationState.isLoading;
    final upcomingCountAsync = ref.watch(
      upcomingClassEventsCountByTypeProvider(classType.id),
    );
    final allSchedulesAsync = ref.watch(
      allClassEventsByTypeProvider(classType.id),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final locations = ref.watch(locationsProvider);
    final businessContext = ref.watch(currentBusinessUserContextProvider).maybeWhen(
          data: (ctx) => ctx,
          orElse: () => null,
        );
    final locationNameById = {
      for (final location in locations) location.id: location.name,
    };
    final hasSingleBusinessLocation = locations.length <= 1;
    final hasSingleOperatorLocation =
        businessContext != null &&
        !businessContext.isSuperadmin &&
        businessContext.hasLocationScope &&
        businessContext.locationIds.length == 1;
    final shouldShowLocationsRow =
        !hasSingleBusinessLocation && !hasSingleOperatorLocation;
    final visibleLocationNames = classType.locationIds
        .map((id) => locationNameById[id])
        .whereType<String>()
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    classType.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ClassTypeStatusChip(isActive: classType.isActive),
              ],
            ),
            if ((classType.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                classType.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (shouldShowLocationsRow) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      classType.locationIds.isEmpty
                          ? l10n.allLocations
                          : visibleLocationNames.join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canManageClassTypes)
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => showCreateClassEventDialog(
                              context,
                              ref,
                              initialClassTypeId: classType.id,
                            ),
                    icon: const Icon(Icons.event_available_outlined),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.classTypesActionScheduleClass),
                        switch ((upcomingCountAsync, allSchedulesAsync)) {
                          (AsyncData<int> futureData, AsyncData<List<ClassEvent>> allData) =>
                            Builder(
                              builder: (_) {
                                final futureCount = futureData.value;
                                final expiredCount =
                                    (allData.value.length - futureCount).clamp(0, 1 << 30);
                                if (futureCount == 0 && expiredCount == 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Wrap(
                                    spacing: 6,
                                    children: [
                                      if (futureCount > 0)
                                        _ScheduleCountPill(
                                          label: l10n.classEventsFutureBadge,
                                          count: futureCount,
                                          textColor: colorScheme.onPrimary,
                                          backgroundColor: colorScheme.onPrimary.withOpacity(0.14),
                                        ),
                                      if (expiredCount > 0)
                                        _ScheduleCountPill(
                                          label: l10n.classEventsExpiredBadge,
                                          count: expiredCount,
                                          textColor: colorScheme.onPrimary,
                                          backgroundColor: colorScheme.onPrimary.withOpacity(0.22),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          _ => const SizedBox.shrink(),
                        },
                      ],
                    ),
                  ),
                if (canManageClassTypes)
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => showCreateClassTypeDialog(
                              context,
                              ref,
                              initial: classType,
                            ),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.actionEdit),
                  ),
                if (canManageClassTypes)
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _cloneClassType(context, ref, classType),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(l10n.duplicateAction),
                  ),
                if (canManageClassTypes)
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _deleteClassType(context, ref, classType),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.actionDelete),
                  ),
              ],
            ),
          ],
        ),
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

      await ref.read(classTypeMutationControllerProvider.notifier).create(
        name: candidateName,
        description: source.description,
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
      await ref.read(classTypeMutationControllerProvider.notifier).deleteType(
        classTypeId: classType.id,
      );
      if (!context.mounted) return;
      await FeedbackDialog.showSuccess(
        context,
        title: l10n.classTypesDeleteSuccessTitle,
        message: l10n.classTypesDeleteSuccessMessage,
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
    final fg = isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

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

class _ScheduleCountPill extends StatelessWidget {
  const _ScheduleCountPill({
    required this.label,
    required this.count,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final int count;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ClassTypeFormDialog extends ConsumerStatefulWidget {
  const _ClassTypeFormDialog({this.initial});

  final ClassType? initial;

  @override
  ConsumerState<_ClassTypeFormDialog> createState() => _ClassTypeFormDialogState();
}

class _ClassTypeFormDialogState extends ConsumerState<_ClassTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  late bool _allLocations;
  late Set<int> _selectedLocationIds;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
    _isActive = widget.initial?.isActive ?? true;
    _allLocations = (widget.initial?.locationIds.isEmpty ?? true);
    _selectedLocationIds = {...?widget.initial?.locationIds};
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
    final businessContext = ref.watch(currentBusinessUserContextProvider).maybeWhen(
          data: (ctx) => ctx,
          orElse: () => null,
        );
    final isLocationScopedOperator =
        businessContext != null &&
        !businessContext.isSuperadmin &&
        businessContext.hasLocationScope;
    final allowedLocationIds = isLocationScopedOperator
        ? businessContext.locationIds.toSet()
        : null;
    final visibleLocations = allowedLocationIds == null
        ? locations
        : locations.where((location) => allowedLocationIds.contains(location.id)).toList();
    final visibleLocationIds = visibleLocations.map((location) => location.id).toSet();
    final hasSingleVisibleLocation = visibleLocations.length == 1;
    final effectiveSelectedLocationIds = _selectedLocationIds
        .where(visibleLocationIds.contains)
        .toSet();
    final allLocationsEnabled = isLocationScopedOperator ? false : _allLocations;
    final shouldShowLocationsSelector =
        !allLocationsEnabled && !hasSingleVisibleLocation;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? l10n.classTypesEditTitle : l10n.classTypesCreateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: isLoading
                    ? null
                    : (value) => setState(() => _isActive = value),
                title: Text(l10n.classTypesFieldIsActive),
              ),
              if (!isLocationScopedOperator) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _allLocations,
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _allLocations = value),
                  title: Text(l10n.allLocations),
                ),
              ],
              if (shouldShowLocationsSelector) ...[
                const SizedBox(height: 8),
                _ClassTypeLocationsMultiSelect(
                  locations: visibleLocations,
                  selectedIds: effectiveSelectedLocationIds,
                  enabled: !isLoading,
                  onChanged: (ids) => setState(() {
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppOutlinedActionButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.actionCancel),
                  ),
                  const SizedBox(width: 8),
                  AppAsyncFilledButton(
                    isLoading: isLoading,
                    onPressed: _submit,
                    child: Text(l10n.actionSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final businessContext = ref.read(currentBusinessUserContextProvider).maybeWhen(
          data: (ctx) => ctx,
          orElse: () => null,
        );
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
        : locations.where((location) => allowedLocationIds.contains(location.id)).toList();
    final hasSingleVisibleLocation = visibleLocations.length == 1;
    final singleVisibleLocationId = hasSingleVisibleLocation
        ? visibleLocations.first.id
        : null;
    final effectiveSelectedLocationIds = _selectedLocationIds
        .where((id) => allowedLocationIds == null || allowedLocationIds.contains(id))
        .toSet();
    final allLocationsEnabled = isLocationScopedOperator ? false : _allLocations;
    final locationIdsForSubmit = allLocationsEnabled
        ? <int>[]
        : hasSingleVisibleLocation && singleVisibleLocationId != null
        ? <int>[singleVisibleLocationId]
        : effectiveSelectedLocationIds.toList();

    if (!_formKey.currentState!.validate()) return;
    if (!allLocationsEnabled && locationIdsForSubmit.isEmpty) {
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.operatorsScopeLocationsRequired,
      );
      return;
    }
    try {
      if (_isEdit) {
        await ref.read(classTypeMutationControllerProvider.notifier).updateType(
          classTypeId: widget.initial!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          isActive: _isActive,
          locationIds: locationIdsForSubmit,
        );
      } else {
        await ref.read(classTypeMutationControllerProvider.notifier).create(
          name: _nameController.text,
          description: _descriptionController.text,
          isActive: _isActive,
          locationIds: locationIdsForSubmit,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      await FeedbackDialog.showSuccess(
        context,
        title: _isEdit
            ? l10n.classTypesUpdateSuccessTitle
            : l10n.classTypesCreateSuccessTitle,
        message: _isEdit
            ? l10n.classTypesUpdateSuccessMessage
            : l10n.classTypesCreateSuccessMessage,
      );
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
    final listHeight = (locations.length * 72).clamp(72, 280).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.operatorsScopeSelectLocations,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: listHeight,
            child: ListView.separated(
              primary: false,
              itemCount: locations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
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
      ],
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
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController(text: '1');

  ClassEvent? _editingEvent;
  _CreateClassDraft? _preEditDraft;
  RecurrenceConfig? _recurrenceConfig;
  int? _classTypeId;
  int? _locationId;
  int? _staffId;
  bool _showSchedulingForm = false;
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _showExpiredSchedules = false;

  @override
  void initState() {
    super.initState();
    _editingEvent = widget.initialEvent;
    if (_editingEvent != null) {
      _showSchedulingForm = true;
      _applyEventToForm(_editingEvent!);
    } else {
      _classTypeId = widget.initialClassTypeId;
      _locationId = widget.initialLocationId;
      _date = DateTime(
        widget.initialDate.year,
        widget.initialDate.month,
        widget.initialDate.day,
      );
      _showSchedulingForm = false;
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
    final isFormMode = _showSchedulingForm || isEditMode;

    final classTypes = classTypesAsync.value ?? const <ClassType>[];
    final allStaff = staffAsync.value ?? const <Staff>[];
    final filteredLocations = _locationsForSelectedClassType(
      locations: locations,
      classTypes: classTypes,
      selectedClassTypeId: _classTypeId,
    );
    final staff = _staffForSelectedLocation(staffAsync.value ?? const <Staff>[]);

    if (classTypes.isNotEmpty && _classTypeId == null) {
      _classTypeId = classTypes.first.id;
    }
    if (filteredLocations.isEmpty) {
      _locationId = null;
    } else if (_locationId == null ||
        !filteredLocations.any((loc) => loc.id == _locationId)) {
      _locationId = filteredLocations.first.id;
    }
    _staffId = _resolveSelectedStaffId(staff);

    final schedulesAsync = _classTypeId == null
        ? const AsyncValue<List<ClassEvent>>.data(<ClassEvent>[])
        : ref.watch(allClassEventsByTypeProvider(_classTypeId!));
    final locationNameById = {for (final location in locations) location.id: location.name};
    final staffNameById = {for (final member in allStaff) member.id: member.displayName};
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditMode
                    ? l10n.classEventsEditTitle
                    : l10n.classEventsCreateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!isFormMode && !isEditMode) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _showSchedulingForm = true);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.classEventsNewScheduleButton),
                ),
              ],
              if (isEditMode) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.classEventsEditModeLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFormMode && classTypes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.classEventsNoClassTypes,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (isFormMode && !isEditMode && filteredLocations.length > 1) ...[
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
                          validator: (value) => value == null
                              ? l10n.classEventsValidationRequired
                              : null,
                        ),
                      ],
                      if (isFormMode && !isEditMode && staff.length > 1) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _staffId,
                          decoration: InputDecoration(
                            labelText: l10n.classEventsFieldStaff,
                            border: const OutlineInputBorder(),
                          ),
                          items: staff
                              .map(
                                (member) => DropdownMenuItem<int>(
                                  value: member.id,
                                  child: Text(member.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: isLoading
                              ? null
                              : (value) => setState(() => _staffId = value),
                          validator: (value) => value == null
                              ? l10n.classEventsValidationRequired
                              : null,
                        ),
                      ],
                      if (isFormMode && !isEditMode && staff.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.classEventsNoStaffForLocation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (isFormMode) const SizedBox(height: 12),
                      if (isFormMode && filteredLocations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l10n.classEventsNoLocationsForClassType,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (isFormMode)
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
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: l10n.classEventsFieldCapacity,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final parsed = int.tryParse(value ?? '');
                                if (parsed == null || parsed <= 0) {
                                  return l10n.classEventsValidationRequired;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isFormMode) const SizedBox(height: 12),
                      if (isFormMode)
                        Row(
                        children: [
                          Expanded(
                            child: _ScheduleTimeField(
                              label: l10n.classEventsFieldStartTime,
                              time: _startTime,
                              onTap: isLoading
                                  ? null
                                  : () => _pickTime(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ScheduleTimeField(
                              label: l10n.classEventsFieldEndTime,
                              time: _endTime,
                              onTap: isLoading
                                  ? null
                                  : () => _pickTime(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      if (isFormMode && !isEditMode) ...[
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
                          conflictSkipDescription:
                              l10n.classEventsRecurrenceConflictSkipDescription,
                          conflictForceDescription:
                              l10n.classEventsRecurrenceConflictForceDescription,
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
                      if (!isFormMode) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.classEventsSchedulesListTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        schedulesAsync.when(
                          loading: () => const LinearProgressIndicator(minHeight: 2),
                          error: (_, __) => Text(
                            l10n.errorTitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          data: (schedules) {
                            final nowUtc = DateTime.now().toUtc();
                            final hasFuture = schedules.any(
                              (event) => event.endsAtUtc.isAfter(nowUtc),
                            );
                            final hasExpired = schedules.any(
                              (event) => !event.endsAtUtc.isAfter(nowUtc),
                            );
                            final shouldShowToggle = hasFuture && hasExpired;
                            final displayedSchedules = shouldShowToggle && !_showExpiredSchedules
                                ? schedules
                                      .where((event) => event.endsAtUtc.isAfter(nowUtc))
                                      .toList()
                                : schedules;

                            if (displayedSchedules.isEmpty) {
                              return Text(
                                l10n.classEventsSchedulesListEmpty,
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            }

                            final listHeight = (displayedSchedules.length * 64)
                                .clamp(64, 240)
                                .toDouble();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (shouldShowToggle)
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
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SizedBox(
                                    height: listHeight,
                                    child: ListView.separated(
                                      primary: false,
                                      itemCount: displayedSchedules.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final schedule = displayedSchedules[index];
                                    final startsAtLocal =
                                        schedule.startsAtLocal ??
                                        schedule.startsAtUtc.toLocal();
                                    final endsAtLocal =
                                        schedule.endsAtLocal ??
                                        schedule.endsAtUtc.toLocal();
                                    final locationName =
                                        locationNameById[schedule.locationId] ?? '#${schedule.locationId}';
                                    final staffName =
                                        staffNameById[schedule.staffId] ?? '#${schedule.staffId}';
                                        return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      onTap: () {
                                        _preEditDraft ??= _captureCurrentDraft();
                                        setState(() {
                                          _showSchedulingForm = true;
                                          _editingEvent = schedule;
                                          _applyEventToForm(schedule);
                                        });
                                      },
                                      leading: const Icon(Icons.event_note_outlined, size: 20),
                                      title: Text(
                                        '${dateFormat.format(startsAtLocal)} • '
                                        '${timeFormat.format(startsAtLocal)} - ${timeFormat.format(endsAtLocal)}',
                                      ),
                                      subtitle: Text('$locationName • $staffName'),
                                      trailing: IconButton(
                                        tooltip: l10n.actionDelete,
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(
                                                l10n.classEventsSchedulesDeleteConfirmTitle,
                                              ),
                                              content: Text(
                                                l10n.classEventsSchedulesDeleteConfirmMessage,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(false),
                                                  child: Text(l10n.actionCancel),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(true),
                                                  child: Text(l10n.actionDelete),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed != true || !context.mounted) return;

                                          try {
                                            final businessId = ref.read(currentBusinessIdProvider);
                                            final repo = ref.read(classEventsRepositoryProvider);
                                            await repo.deleteEvent(
                                              businessId: businessId,
                                              classEventId: schedule.id,
                                            );
                                            ref.invalidate(classEventsProvider);
                                            if (_classTypeId != null) {
                                              ref.invalidate(
                                                allClassEventsByTypeProvider(_classTypeId!),
                                              );
                                              ref.invalidate(
                                                upcomingClassEventsByTypeProvider(_classTypeId!),
                                              );
                                              ref.invalidate(
                                                upcomingClassEventsCountByTypeProvider(_classTypeId!),
                                              );
                                            }
                                            if (!context.mounted) return;
                                            await FeedbackDialog.showSuccess(
                                              context,
                                              title: l10n.classEventsSchedulesDeleteSuccessTitle,
                                              message:
                                                  l10n.classEventsSchedulesDeleteSuccessMessage,
                                            );
                                          } catch (error) {
                                            if (!context.mounted) return;
                                            final message = error is ApiException
                                                ? error.message
                                                : l10n.classEventsCreateErrorMessage;
                                            await FeedbackDialog.showError(
                                              context,
                                              title: l10n.errorTitle,
                                              message: message,
                                            );
                                          }
                                        },
                                      ),
                                    );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppOutlinedActionButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (isEditMode) {
                              final upcomingCount = _readUpcomingCountSync();
                              setState(() {
                                if (upcomingCount != 1 && _preEditDraft != null) {
                                  _restoreDraft(_preEditDraft!);
                                }
                                _editingEvent = null;
                                _preEditDraft = null;
                                _showSchedulingForm = false;
                              });
                              return;
                            }
                            if (isFormMode) {
                              setState(() => _showSchedulingForm = false);
                              return;
                            }
                            Navigator.of(context).pop();
                          },
                    child: Text(isFormMode ? l10n.actionCancel : l10n.actionClose),
                  ),
                  if (isFormMode) ...[
                    const SizedBox(width: 8),
                    AppAsyncFilledButton(
                      isLoading: isLoading,
                      onPressed: _canSubmit(classTypes: classTypes, staff: staff)
                          ? _submit
                          : null,
                      child: Text(l10n.actionSave),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit({
    required List<ClassType> classTypes,
    required List<Staff> staff,
  }) {
    return classTypes.isNotEmpty && staff.isNotEmpty;
  }

  List<Staff> _staffForSelectedLocation(List<Staff> staff) {
    final locationId = _locationId;
    if (locationId == null) {
      return const [];
    }
    return staff
        .where(
          (member) =>
              member.locationIds.isEmpty || member.locationIds.contains(locationId),
        )
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  int? _resolveSelectedStaffId(List<Staff> staff) {
    if (staff.isEmpty) return null;
    final selected = _staffId;
    if (selected != null && staff.any((member) => member.id == selected)) {
      return selected;
    }
    return staff.first.id;
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
    return locations.where((location) => allowed.contains(location.id)).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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
      title: isStart ? l10n.classEventsFieldStartTime : l10n.classEventsFieldEndTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
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
          stepMinutes: 15,
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
              stepMinutes: 15,
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
        message: l10n.classEventsValidationRequired,
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
            'capacity_total': capacity,
          },
        );
        final refreshedDayEvents = await ref.refresh(classEventsProvider.future);
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
            refreshedDayEvents.any((event) => event.classTypeId == classTypeIdForRefresh) ==
                false) {
          ref.invalidate(upcomingClassEventsCountByTypeProvider(classTypeIdForRefresh));
        }
        if (!mounted) return;
        setState(() {
          if (refreshedUpcoming.length != 1 && _preEditDraft != null) {
            _restoreDraft(_preEditDraft!);
          }
          _editingEvent = null;
          _preEditDraft = null;
          _showSchedulingForm = false;
        });
        await FeedbackDialog.showSuccess(
          context,
          title: l10n.classEventsSchedulesUpdateSuccessTitle,
          message: l10n.classEventsSchedulesUpdateSuccessMessage,
        );
        return;
      } else if (_recurrenceConfig == null) {
        await ref.read(classEventCreateControllerProvider.notifier).create(
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
                  plannedIntervals.add(
                    (start: occurrenceStart, end: occurrenceEnd),
                  );
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

        if (!mounted) return;
        final excludedIndices = await RecurrencePreviewDialog.show(
          context,
          preview,
          titleText: l10n.classEventsRecurrencePreviewTitle,
          hintText: l10n.classEventsRecurrencePreviewHint,
          confirmLabelBuilder: (count) =>
              l10n.classEventsRecurrencePreviewConfirm(count),
          excludeConflictsByDefault: conflictStrategy == ConflictStrategy.skip,
        );
        if (excludedIndices == null) return;
        final excludedSet = excludedIndices.toSet();

        var createdCount = 0;
        var skippedCount = 0;
        Object? firstError;

        for (var i = 0; i < recurrenceDates.length; i++) {
          final recurrenceIndex = i + 1;
          if (excludedSet.contains(recurrenceIndex)) {
            skippedCount++;
            continue;
          }
          if (conflictStrategy == ConflictStrategy.skip &&
              (conflictByRecurrenceIndex[recurrenceIndex] ?? false)) {
            skippedCount++;
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
            skippedCount++;
            firstError ??= error;
            if (conflictStrategy == ConflictStrategy.force) {
              rethrow;
            }
          }
        }

        ref.invalidate(classEventsProvider);
        ref.invalidate(allClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(upcomingClassEventsByTypeProvider(_classTypeId!));
        ref.invalidate(upcomingClassEventsCountByTypeProvider(_classTypeId!));

        if (createdCount == 0 && firstError != null) {
          throw firstError;
        }

        if (mounted) {
          final isIt = Localizations.localeOf(context).languageCode == 'it';
          final recurrenceMessage = skippedCount > 0
              ? (isIt
                    ? 'Programmazioni create: $createdCount. Saltate: $skippedCount.'
                    : 'Schedules created: $createdCount. Skipped: $skippedCount.')
              : (isIt
                    ? 'Programmazioni create: $createdCount.'
                    : 'Schedules created: $createdCount.');
          await FeedbackDialog.showSuccess(
            context,
            title: l10n.classEventsCreateSuccessTitle,
            message: recurrenceMessage,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _showSchedulingForm = false;
      });
      if (_recurrenceConfig == null) {
        await FeedbackDialog.showSuccess(
          context,
          title: l10n.classEventsCreateSuccessTitle,
          message: l10n.classEventsCreateSuccessMessage,
        );
      }
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
    final startsAtLocal = event.startsAtLocal ?? event.startsAtUtc.toLocal();
    final endsAtLocal = event.endsAtLocal ?? event.endsAtUtc.toLocal();
    _classTypeId = event.classTypeId;
    _locationId = event.locationId;
    _staffId = event.staffId;
    _capacityController.text = event.capacityTotal.toString();
    _date = DateTime(
      startsAtLocal.year,
      startsAtLocal.month,
      startsAtLocal.day,
    );
    _startTime = TimeOfDay(hour: startsAtLocal.hour, minute: startsAtLocal.minute);
    _endTime = TimeOfDay(hour: endsAtLocal.hour, minute: endsAtLocal.minute);
    _recurrenceConfig = null;
  }

  _CreateClassDraft _captureCurrentDraft() {
    return _CreateClassDraft(
      classTypeId: _classTypeId,
      locationId: _locationId,
      staffId: _staffId,
      date: _date,
      startTime: _startTime,
      endTime: _endTime,
      capacityText: _capacityController.text,
      recurrenceConfig: _recurrenceConfig,
    );
  }

  void _restoreDraft(_CreateClassDraft draft) {
    _classTypeId = draft.classTypeId;
    _locationId = draft.locationId;
    _staffId = draft.staffId;
    _date = draft.date;
    _startTime = draft.startTime;
    _endTime = draft.endTime;
    _capacityController.text = draft.capacityText;
    _recurrenceConfig = draft.recurrenceConfig;
  }

  int _readUpcomingCountSync() {
    final classTypeId = _classTypeId;
    if (classTypeId == null) return 0;
    final async = ref.read(upcomingClassEventsByTypeProvider(classTypeId));
    return async.asData?.value.length ?? 0;
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
    final toLocal = recurrenceDates.last.add(duration).add(const Duration(days: 1));
    final events = await repo.listEvents(
      businessId: businessId,
      fromUtc: fromLocal.toUtc(),
      toUtc: toLocal.toUtc(),
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
    final occurrenceStartUtc = occurrenceStart.toUtc();
    final occurrenceEndUtc = occurrenceEnd.toUtc();

    final conflictsExisting = existingEvents.any((event) {
      final eventStart = event.startsAtUtc.toUtc();
      final eventEnd = event.endsAtUtc.toUtc();
      return occurrenceStartUtc.isBefore(eventEnd) &&
          eventStart.isBefore(occurrenceEndUtc);
    });
    if (conflictsExisting) return true;

    return plannedIntervals.any((interval) {
      final intervalStartUtc = interval.start.toUtc();
      final intervalEndUtc = interval.end.toUtc();
      return occurrenceStartUtc.isBefore(intervalEndUtc) &&
          intervalStartUtc.isBefore(occurrenceEndUtc);
    });
  }

}

class _CreateClassDraft {
  const _CreateClassDraft({
    required this.classTypeId,
    required this.locationId,
    required this.staffId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacityText,
    required this.recurrenceConfig,
  });

  final int? classTypeId;
  final int? locationId;
  final int? staffId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String capacityText;
  final RecurrenceConfig? recurrenceConfig;
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
  State<_ScheduleTimeGridPicker> createState() => _ScheduleTimeGridPickerState();
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
          time.hour == widget.initial.hour && time.minute == widget.initial.minute,
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
    final itemWidth = (availableWidth - (crossAxisCount - 1) * 6) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    final rowHeight = itemHeight + mainAxisSpacing;
    final targetRow = _selectedIndex ~/ crossAxisCount;

    final viewportHeight = _scrollController.position.viewportDimension;
    const headerOffset = 40.0;
    final targetOffset =
        (targetRow * rowHeight) - (viewportHeight / 2) + (rowHeight / 2) + headerOffset;
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
