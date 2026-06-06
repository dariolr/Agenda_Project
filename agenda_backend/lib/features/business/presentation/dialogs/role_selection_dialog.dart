import 'package:flutter/material.dart';
import 'package:agenda_backend/core/widgets/app_dividers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/models/class_type.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/staff.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../services/providers/service_categories_provider.dart';

typedef RoleScopeSaveCallback =
    Future<void> Function({
      required String role,
      required String scopeType,
      required List<int> locationIds,
      required List<int>? allowedServiceIds,
      required List<int>? allowedClassTypeIds,
    });

/// Modalità di accesso per una categoria di filtro.
/// all = Tutti (null in DB), none = Nessuno ([] in DB), selected = Solo selezionati ([..] in DB).
enum AccessMode { all, none, selected }

/// Dialog per selezionare un ruolo (desktop).
class RoleSelectionDialog extends StatefulWidget {
  const RoleSelectionDialog({
    super.key,
    required this.currentRole,
    required this.currentScopeType,
    required this.currentLocationIds,
    required this.locations,
    required this.userName,
    required this.userEmail,
    required this.onSave,
    this.currentServiceIds,
    this.currentClassTypeIds,
    this.services = const [],
    this.classTypes = const [],
    this.linkedStaffId,
    this.staffList = const [],
  });

  final String currentRole;
  final String currentScopeType;
  final List<int> currentLocationIds;
  final List<Location> locations;
  final String userName;
  final String userEmail;
  final RoleScopeSaveCallback onSave;
  final List<int>? currentServiceIds;
  final List<int>? currentClassTypeIds;
  final List<Service> services;
  final List<ClassType> classTypes;
  /// Staff collegato all'operatore (solo per role=staff)
  final int? linkedStaffId;
  final List<Staff> staffList;

  @override
  State<RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<RoleSelectionDialog> {
  late String _selectedRole;
  late String _selectedScopeType;
  late Set<int> _selectedLocationIds;
  late AccessMode _serviceMode;
  late AccessMode _classTypeMode;
  late Set<int> _selectedServiceIds;
  late Set<int> _selectedClassTypeIds;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
    _selectedScopeType = widget.currentScopeType.isNotEmpty
        ? widget.currentScopeType
        : 'business';
    _selectedLocationIds = widget.currentLocationIds.toSet();
    _serviceMode = _modeFromList(widget.currentServiceIds);
    _classTypeMode = _modeFromList(widget.currentClassTypeIds);
    _selectedServiceIds = widget.currentServiceIds?.toSet() ?? {};
    _selectedClassTypeIds = widget.currentClassTypeIds?.toSet() ?? {};
    _enforceSingleLocationForStaff();
  }

  static AccessMode _modeFromList(List<int>? ids) {
    if (ids == null) return AccessMode.all;
    if (ids.isEmpty) return AccessMode.none;
    return AccessMode.selected;
  }

  List<int>? _resolveFilterIds(AccessMode mode, Set<int> selected) {
    return switch (mode) {
      AccessMode.all => null,
      AccessMode.none => const [],
      AccessMode.selected => selected.toList(),
    };
  }

  void _enforceSingleLocationForStaff() {
    if (_selectedRole == 'staff' &&
        _selectedScopeType == 'locations' &&
        _selectedLocationIds.length > 1) {
      final keep = _selectedLocationIds.last;
      _selectedLocationIds
        ..clear()
        ..add(keep);
    }
  }

  List<Service> _filteredServices() {
    if (_selectedRole != 'staff') return widget.services;
    final staff = widget.staffList
        .where((s) => s.id == widget.linkedStaffId)
        .firstOrNull;
    if (staff == null) return [];
    return widget.services
        .where((s) => staff.serviceIds.contains(s.id))
        .toList();
  }

  bool _showServiceFilter(List<Service> filtered) {
    if (_selectedRole == 'admin' || _selectedRole == 'owner') return false;
    if (_selectedRole != 'staff') {
      return widget.services.isNotEmpty || widget.classTypes.isNotEmpty;
    }
    return widget.linkedStaffId != null &&
        (filtered.isNotEmpty || widget.classTypes.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredServices = _filteredServices();

    return AppFormDialog(
      title: Text(l10n.operatorsEditRole),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifica il ruolo di ${widget.userName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.userEmail,
            enabled: false,
            decoration: InputDecoration(
              labelText: l10n.operatorsInviteEmail,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 24),
          _RoleRadioList(
            selectedRole: _selectedRole,
            onChanged: (role) => setState(() {
              _selectedRole = role;
              _enforceSingleLocationForStaff();
            }),
          ),
          // Sezione scope solo se più di una location
          if (widget.locations.length > 1) ...[
            const SizedBox(height: 24),
            const AppDivider(),
            const SizedBox(height: 16),
            _ScopeTypeSelector(
              selectedScopeType: _selectedScopeType,
              onChanged: (scope) => setState(() {
                _selectedScopeType = scope;
                if (scope == 'business') {
                  _selectedLocationIds.clear();
                }
                _enforceSingleLocationForStaff();
              }),
            ),
            if (_selectedScopeType == 'locations') ...[
              const SizedBox(height: 16),
              _LocationsMultiSelect(
                locations: widget.locations,
                selectedIds: _selectedLocationIds,
                onChanged: (ids) => setState(() {
                  _selectedLocationIds.clear();
                  if (_selectedRole == 'staff') {
                    if (ids.isNotEmpty) {
                      _selectedLocationIds.add(ids.last);
                    }
                  } else {
                    _selectedLocationIds.addAll(ids);
                  }
                }),
              ),
            ],
          ],
          if (_showServiceFilter(filteredServices)) ...[
            const SizedBox(height: 24),
            const AppDivider(),
            const SizedBox(height: 16),
            ServiceFilterSection(
              services: filteredServices,
              classTypes: widget.classTypes,
              serviceMode: _serviceMode,
              classTypeMode: _classTypeMode,
              selectedServiceIds: _selectedServiceIds,
              selectedClassTypeIds: _selectedClassTypeIds,
              onServiceModeChanged: (mode) => setState(() {
                _serviceMode = mode;
                if (mode != AccessMode.selected) _selectedServiceIds = {};
              }),
              onClassTypeModeChanged: (mode) => setState(() {
                _classTypeMode = mode;
                if (mode != AccessMode.selected) _selectedClassTypeIds = {};
              }),
              onServicesChanged: (ids) =>
                  setState(() => _selectedServiceIds = ids),
              onClassTypesChanged: (ids) =>
                  setState(() => _selectedClassTypeIds = ids),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_selectedScopeType == 'locations' &&
                _selectedLocationIds.isEmpty) {
              FeedbackDialog.showError(
                context,
                title: l10n.errorTitle,
                message: l10n.operatorsScopeLocationsRequired,
              );
              return;
            }
            if (_selectedRole == 'staff' &&
                _selectedScopeType == 'locations' &&
                _selectedLocationIds.length > 1) {
              final isIt = Localizations.localeOf(context).languageCode == 'it';
              FeedbackDialog.showError(
                context,
                title: l10n.errorTitle,
                message: isIt
                    ? 'Per il ruolo Staff puoi selezionare una sola sede.'
                    : 'For Staff role you can select only one location.',
              );
              return;
            }
            widget.onSave(
              role: _selectedRole,
              scopeType: _selectedScopeType,
              locationIds: _selectedLocationIds.toList(),
              allowedServiceIds: _resolveFilterIds(_serviceMode, _selectedServiceIds),
              allowedClassTypeIds: _resolveFilterIds(_classTypeMode, _selectedClassTypeIds),
            );
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

/// Bottom sheet per selezionare un ruolo (mobile/tablet).
class RoleSelectionSheet extends StatefulWidget {
  const RoleSelectionSheet({
    super.key,
    required this.currentRole,
    required this.currentScopeType,
    required this.currentLocationIds,
    required this.locations,
    required this.userName,
    required this.userEmail,
    required this.onSave,
    this.currentServiceIds,
    this.currentClassTypeIds,
    this.services = const [],
    this.classTypes = const [],
    this.linkedStaffId,
    this.staffList = const [],
  });

  final String currentRole;
  final String currentScopeType;
  final List<int> currentLocationIds;
  final List<Location> locations;
  final String userName;
  final String userEmail;
  final RoleScopeSaveCallback onSave;
  final List<int>? currentServiceIds;
  final List<int>? currentClassTypeIds;
  final List<Service> services;
  final List<ClassType> classTypes;
  final int? linkedStaffId;
  final List<Staff> staffList;

  @override
  State<RoleSelectionSheet> createState() => _RoleSelectionSheetState();
}

class _RoleSelectionSheetState extends State<RoleSelectionSheet> {
  late String _selectedRole;
  late String _selectedScopeType;
  late Set<int> _selectedLocationIds;
  late AccessMode _serviceMode;
  late AccessMode _classTypeMode;
  late Set<int> _selectedServiceIds;
  late Set<int> _selectedClassTypeIds;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
    _selectedScopeType = widget.currentScopeType.isNotEmpty
        ? widget.currentScopeType
        : 'business';
    _selectedLocationIds = widget.currentLocationIds.toSet();
    _serviceMode = _modeFromList(widget.currentServiceIds);
    _classTypeMode = _modeFromList(widget.currentClassTypeIds);
    _selectedServiceIds = widget.currentServiceIds?.toSet() ?? {};
    _selectedClassTypeIds = widget.currentClassTypeIds?.toSet() ?? {};
    _enforceSingleLocationForStaff();
  }

  static AccessMode _modeFromList(List<int>? ids) {
    if (ids == null) return AccessMode.all;
    if (ids.isEmpty) return AccessMode.none;
    return AccessMode.selected;
  }

  List<int>? _resolveFilterIds(AccessMode mode, Set<int> selected) {
    return switch (mode) {
      AccessMode.all => null,
      AccessMode.none => const [],
      AccessMode.selected => selected.toList(),
    };
  }

  void _enforceSingleLocationForStaff() {
    if (_selectedRole == 'staff' &&
        _selectedScopeType == 'locations' &&
        _selectedLocationIds.length > 1) {
      final keep = _selectedLocationIds.last;
      _selectedLocationIds
        ..clear()
        ..add(keep);
    }
  }

  List<Service> _filteredServices() {
    if (_selectedRole != 'staff') return widget.services;
    final staff = widget.staffList
        .where((s) => s.id == widget.linkedStaffId)
        .firstOrNull;
    if (staff == null) return [];
    return widget.services
        .where((s) => staff.serviceIds.contains(s.id))
        .toList();
  }

  bool _showServiceFilter(List<Service> filtered) {
    if (_selectedRole == 'admin' || _selectedRole == 'owner') return false;
    if (_selectedRole != 'staff') {
      return widget.services.isNotEmpty || widget.classTypes.isNotEmpty;
    }
    return widget.linkedStaffId != null &&
        (filtered.isNotEmpty || widget.classTypes.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredServices = _filteredServices();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            l10n.operatorsEditRole,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Modifica il ruolo di ${widget.userName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.userEmail,
            enabled: false,
            decoration: InputDecoration(
              labelText: l10n.operatorsInviteEmail,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _RoleRadioList(
            selectedRole: _selectedRole,
            onChanged: (role) => setState(() {
              _selectedRole = role;
              _enforceSingleLocationForStaff();
            }),
          ),
          // Sezione scope solo se più di una location
          if (widget.locations.length > 1) ...[
            const SizedBox(height: 24),
            const AppDivider(),
            const SizedBox(height: 16),
            _ScopeTypeSelector(
              selectedScopeType: _selectedScopeType,
              onChanged: (scope) => setState(() {
                _selectedScopeType = scope;
                if (scope == 'business') {
                  _selectedLocationIds.clear();
                }
                _enforceSingleLocationForStaff();
              }),
            ),
            if (_selectedScopeType == 'locations') ...[
              const SizedBox(height: 16),
              _LocationsMultiSelect(
                locations: widget.locations,
                selectedIds: _selectedLocationIds,
                onChanged: (ids) => setState(() {
                  _selectedLocationIds.clear();
                  if (_selectedRole == 'staff') {
                    if (ids.isNotEmpty) {
                      _selectedLocationIds.add(ids.last);
                    }
                  } else {
                    _selectedLocationIds.addAll(ids);
                  }
                }),
              ),
            ],
          ],
          if (_showServiceFilter(filteredServices)) ...[
            const SizedBox(height: 24),
            const AppDivider(),
            const SizedBox(height: 16),
            ServiceFilterSection(
              services: filteredServices,
              classTypes: widget.classTypes,
              serviceMode: _serviceMode,
              classTypeMode: _classTypeMode,
              selectedServiceIds: _selectedServiceIds,
              selectedClassTypeIds: _selectedClassTypeIds,
              onServiceModeChanged: (mode) => setState(() {
                _serviceMode = mode;
                if (mode != AccessMode.selected) _selectedServiceIds = {};
              }),
              onClassTypeModeChanged: (mode) => setState(() {
                _classTypeMode = mode;
                if (mode != AccessMode.selected) _selectedClassTypeIds = {};
              }),
              onServicesChanged: (ids) =>
                  setState(() => _selectedServiceIds = ids),
              onClassTypesChanged: (ids) =>
                  setState(() => _selectedClassTypeIds = ids),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.actionCancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_selectedScopeType == 'locations' &&
                        _selectedLocationIds.isEmpty) {
                      FeedbackDialog.showError(
                        context,
                        title: l10n.errorTitle,
                        message: l10n.operatorsScopeLocationsRequired,
                      );
                      return;
                    }
                    if (_selectedRole == 'staff' &&
                        _selectedScopeType == 'locations' &&
                        _selectedLocationIds.length > 1) {
                      final isIt =
                          Localizations.localeOf(context).languageCode == 'it';
                      FeedbackDialog.showError(
                        context,
                        title: l10n.errorTitle,
                        message: isIt
                            ? 'Per il ruolo Staff puoi selezionare una sola sede.'
                            : 'For Staff role you can select only one location.',
                      );
                      return;
                    }
                    widget.onSave(
                      role: _selectedRole,
                      scopeType: _selectedScopeType,
                      locationIds: _selectedLocationIds.toList(),
                      allowedServiceIds: _resolveFilterIds(_serviceMode, _selectedServiceIds),
                      allowedClassTypeIds: _resolveFilterIds(_classTypeMode, _selectedClassTypeIds),
                    );
                  },
                  child: Text(l10n.actionSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lista di radio button per la selezione del ruolo.
class _RoleRadioList extends StatelessWidget {
  const _RoleRadioList({required this.selectedRole, required this.onChanged});

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        _RoleRadioTile(
          value: 'admin',
          groupValue: selectedRole,
          onChanged: onChanged,
          title: l10n.operatorsRoleAdmin,
          subtitle: l10n.operatorsRoleAdminDesc,
          icon: Icons.admin_panel_settings,
        ),
        _RoleRadioTile(
          value: 'manager',
          groupValue: selectedRole,
          onChanged: onChanged,
          title: l10n.operatorsRoleManager,
          subtitle: l10n.operatorsRoleManagerDesc,
          icon: Icons.manage_accounts,
        ),
        _RoleRadioTile(
          value: 'staff',
          groupValue: selectedRole,
          onChanged: onChanged,
          title: l10n.operatorsRoleStaff,
          subtitle: l10n.operatorsRoleStaffDesc,
          icon: Icons.person,
        ),
        _RoleRadioTile(
          value: 'viewer',
          groupValue: selectedRole,
          onChanged: onChanged,
          title: l10n.operatorsRoleViewer,
          subtitle: l10n.operatorsRoleViewerDesc,
          icon: Icons.visibility_outlined,
        ),
      ],
    );
  }
}

/// Singola riga radio per ruolo.
class _RoleRadioTile extends StatelessWidget {
  const _RoleRadioTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
            ),
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget per selezionare il tipo di scope (business o locations).
class _ScopeTypeSelector extends StatelessWidget {
  const _ScopeTypeSelector({
    required this.selectedScopeType,
    required this.onChanged,
  });

  final String selectedScopeType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.operatorsScopeTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _ScopeOption(
          scopeType: 'business',
          label: l10n.operatorsScopeBusiness,
          description: l10n.operatorsScopeBusinessDesc,
          icon: Icons.business,
          isSelected: selectedScopeType == 'business',
          onTap: () => onChanged('business'),
        ),
        const SizedBox(height: 8),
        _ScopeOption(
          scopeType: 'locations',
          label: l10n.operatorsScopeLocations,
          description: l10n.operatorsScopeLocationsDesc,
          icon: Icons.location_on,
          isSelected: selectedScopeType == 'locations',
          onTap: () => onChanged('locations'),
        ),
      ],
    );
  }
}

/// Singola opzione scope.
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.scopeType,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String scopeType;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isSelected ? colorScheme.primary : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

/// Widget per la selezione multipla delle location.
class _LocationsMultiSelect extends StatelessWidget {
  const _LocationsMultiSelect({
    required this.locations,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<Location> locations;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

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
          child: Column(
            children: [
              for (var i = 0; i < locations.length; i++) ...[
                if (i > 0) const AppDivider(height: 1),
                _LocationCheckboxTile(
                  location: locations[i],
                  isSelected: selectedIds.contains(locations[i].id),
                  onChanged: (selected) {
                    final newIds = Set<int>.from(selectedIds);
                    if (selected) {
                      newIds.add(locations[i].id);
                    } else {
                      newIds.remove(locations[i].id);
                    }
                    onChanged(newIds);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Singola checkbox per location.
class _LocationCheckboxTile extends StatelessWidget {
  const _LocationCheckboxTile({
    required this.location,
    required this.isSelected,
    required this.onChanged,
  });

  final Location location;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: isSelected,
      onChanged: onChanged,
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

/// Sezione che permette di configurare la visibilità dell'operatore
/// su servizi e tipi lezione con 3 opzioni per categoria:
/// Tutti (null), Nessuno ([]), Solo selezionati ([1,2]).
class ServiceFilterSection extends ConsumerWidget {
  const ServiceFilterSection({
    super.key,
    required this.services,
    required this.classTypes,
    required this.serviceMode,
    required this.classTypeMode,
    required this.selectedServiceIds,
    required this.selectedClassTypeIds,
    required this.onServiceModeChanged,
    required this.onClassTypeModeChanged,
    required this.onServicesChanged,
    required this.onClassTypesChanged,
  });

  final List<Service> services;
  final List<ClassType> classTypes;
  final AccessMode serviceMode;
  final AccessMode classTypeMode;
  final Set<int> selectedServiceIds;
  final Set<int> selectedClassTypeIds;
  final ValueChanged<AccessMode> onServiceModeChanged;
  final ValueChanged<AccessMode> onClassTypeModeChanged;
  final ValueChanged<Set<int>> onServicesChanged;
  final ValueChanged<Set<int>> onClassTypesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final categories = ref.watch(serviceCategoriesProvider);

    final categoryNames = <int, String>{
      for (final c in categories) c.id: c.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (services.isNotEmpty) ...[
          const SizedBox(height: 4),
          _FilterCategorySection(
            label: l10n.operatorsAccessibleServices,
            mode: serviceMode,
            onModeChanged: onServiceModeChanged,
            l10n: l10n,
            theme: theme,
            child: serviceMode == AccessMode.selected
                ? _ItemCheckboxList(
                    items: _groupByCategory(
                      services.map((s) => (id: s.id, name: s.name, catId: s.categoryId == 0 ? null : s.categoryId, icon: null as IconData?)).toList(),
                      categories,
                      categoryNames,
                    ),
                    selectedIds: selectedServiceIds,
                    onChanged: onServicesChanged,
                    theme: theme,
                    colorScheme: colorScheme,
                  )
                : null,
          ),
        ],
        if (classTypes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _FilterCategorySection(
            label: l10n.operatorsAccessibleClassTypes,
            mode: classTypeMode,
            onModeChanged: onClassTypeModeChanged,
            l10n: l10n,
            theme: theme,
            child: classTypeMode == AccessMode.selected
                ? _ItemCheckboxList(
                    items: _groupByCategory(
                      classTypes.map((ct) => (id: ct.id, name: ct.name, catId: ct.serviceCategoryId, icon: Icons.sports_martial_arts as IconData?)).toList(),
                      categories,
                      categoryNames,
                    ),
                    selectedIds: selectedClassTypeIds,
                    onChanged: onClassTypesChanged,
                    theme: theme,
                    colorScheme: colorScheme,
                  )
                : null,
          ),
        ],
      ],
    );
  }

  static List<({int? catId, String catName, List<({int id, String name, IconData? icon})> items})> _groupByCategory(
    List<({int id, String name, int? catId, IconData? icon})> items,
    List<dynamic> categories,
    Map<int, String> categoryNames,
  ) {
    final byCategory = <int?, List<({int id, String name, IconData? icon})>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.catId, () => []).add((id: item.id, name: item.name, icon: item.icon));
    }
    final sortedCatIds = byCategory.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final ia = categories.indexWhere((c) => c.id == a);
        final ib = categories.indexWhere((c) => c.id == b);
        return ia.compareTo(ib);
      });
    return [
      for (final catId in sortedCatIds)
        (
          catId: catId,
          catName: catId == null ? '' : (categoryNames[catId] ?? ''),
          items: byCategory[catId]!,
        ),
    ];
  }
}

class _FilterCategorySection extends StatelessWidget {
  const _FilterCategorySection({
    required this.label,
    required this.mode,
    required this.onModeChanged,
    required this.l10n,
    required this.theme,
    this.child,
  });

  final String label;
  final AccessMode mode;
  final ValueChanged<AccessMode> onModeChanged;
  final L10n l10n;
  final ThemeData theme;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        SegmentedButton<AccessMode>(
          segments: [
            ButtonSegment(value: AccessMode.all, label: Text(l10n.filterAll)),
            ButtonSegment(value: AccessMode.none, label: Text(l10n.operatorsAccessNone)),
            ButtonSegment(value: AccessMode.selected, label: Text(l10n.operatorsAccessSelected)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => onModeChanged(s.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (child != null) ...[
          const SizedBox(height: 8),
          child!,
        ],
      ],
    );
  }
}

class _ItemCheckboxList extends StatelessWidget {
  const _ItemCheckboxList({
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    required this.theme,
    required this.colorScheme,
  });

  final List<({int? catId, String catName, List<({int id, String name, IconData? icon})> items})> items;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in items) ...[
          if (group.catName.isNotEmpty) ...[
            Text(group.catName, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
          ],
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0) const AppDivider(height: 1),
                  CheckboxListTile(
                    dense: true,
                    title: Text(group.items[i].name, style: theme.textTheme.bodyMedium),
                    secondary: group.items[i].icon != null
                        ? Icon(group.items[i].icon, size: 18, color: colorScheme.onSurfaceVariant)
                        : null,
                    value: selectedIds.contains(group.items[i].id),
                    onChanged: (checked) {
                      final next = Set<int>.from(selectedIds);
                      checked == true ? next.add(group.items[i].id) : next.remove(group.items[i].id);
                      onChanged(next);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
