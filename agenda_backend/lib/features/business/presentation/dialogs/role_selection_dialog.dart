import 'package:flutter/material.dart';
import 'package:agenda_backend/core/widgets/app_dividers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
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
      required List<int> allowedServiceIds,
      required List<int> allowedClassTypeIds,
    });

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
    this.currentServiceIds = const [],
    this.currentClassTypeIds = const [],
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
  final List<int> currentServiceIds;
  final List<int> currentClassTypeIds;
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
    _selectedServiceIds = widget.currentServiceIds.toSet();
    _selectedClassTypeIds = widget.currentClassTypeIds.toSet();
    _enforceSingleLocationForStaff();
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
              selectedServiceIds: _selectedServiceIds,
              selectedClassTypeIds: _selectedClassTypeIds,
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
              allowedServiceIds: _selectedServiceIds.toList(),
              allowedClassTypeIds: _selectedClassTypeIds.toList(),
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
    this.currentServiceIds = const [],
    this.currentClassTypeIds = const [],
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
  final List<int> currentServiceIds;
  final List<int> currentClassTypeIds;
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
    _selectedServiceIds = widget.currentServiceIds.toSet();
    _selectedClassTypeIds = widget.currentClassTypeIds.toSet();
    _enforceSingleLocationForStaff();
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
              selectedServiceIds: _selectedServiceIds,
              selectedClassTypeIds: _selectedClassTypeIds,
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
                      allowedServiceIds: _selectedServiceIds.toList(),
                      allowedClassTypeIds: _selectedClassTypeIds.toList(),
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

/// Sezione che permette di limitare la visibilità dell'operatore
/// a un sottoinsieme di servizi e/o tipi lezione, raggruppati per categoria.
/// Lista vuota = nessun filtro (vede tutto).
class ServiceFilterSection extends ConsumerWidget {
  const ServiceFilterSection({
    super.key,
    required this.services,
    required this.classTypes,
    required this.selectedServiceIds,
    required this.selectedClassTypeIds,
    required this.onServicesChanged,
    required this.onClassTypesChanged,
  });

  final List<Service> services;
  final List<ClassType> classTypes;
  final Set<int> selectedServiceIds;
  final Set<int> selectedClassTypeIds;
  final ValueChanged<Set<int>> onServicesChanged;
  final ValueChanged<Set<int>> onClassTypesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIt = Localizations.localeOf(context).languageCode == 'it';
    final categories = ref.watch(serviceCategoriesProvider);

    // Costruisce mappa categoryId → nome categoria
    final categoryNames = <int, String>{
      for (final c in categories) c.id: c.name,
    };

    // Raggruppa servizi per categoria
    final servicesByCategory = <int?, List<Service>>{};
    for (final s in services) {
      final catId = s.categoryId == 0 ? null : s.categoryId;
      servicesByCategory.putIfAbsent(catId, () => []).add(s);
    }

    // Raggruppa lezioni per categoria (serviceCategoryId)
    final classTypesByCategory = <int?, List<ClassType>>{};
    for (final ct in classTypes) {
      classTypesByCategory
          .putIfAbsent(ct.serviceCategoryId, () => [])
          .add(ct);
    }

    // Unione dei categoryId presenti (servizi + lezioni), ordina: categorie note
    // prima (nell'ordine del provider), poi null in fondo
    final allCategoryIds = <int?>{
      ...servicesByCategory.keys,
      ...classTypesByCategory.keys,
    }.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final ia = categories.indexWhere((c) => c.id == a);
        final ib = categories.indexWhere((c) => c.id == b);
        return ia.compareTo(ib);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              isIt ? 'Filtro visibilità servizi' : 'Service visibility filter',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isIt
              ? 'Lascia tutto deselezionato per accesso completo. Seleziona uno o più voci per limitare la visibilità.'
              : 'Leave everything unselected for full access. Select one or more items to restrict visibility.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        for (final catId in allCategoryIds) ...[
          const SizedBox(height: 12),
          // Header categoria
          Text(
            catId == null
                ? (isIt ? 'Senza categoria' : 'No category')
                : (categoryNames[catId] ?? ''),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Servizi della categoria
                for (final s in servicesByCategory[catId] ?? []) ...[
                  if ((servicesByCategory[catId]?.first.id ?? 0) != s.id ||
                      true) // divisore prima di ogni voce tranne la prima
                    Builder(builder: (ctx) {
                      final idx = [
                        ...(servicesByCategory[catId] ?? []),
                        ...(classTypesByCategory[catId] ?? []),
                      ].indexWhere((e) => e is Service && e.id == s.id);
                      return Column(children: [
                        if (idx > 0) const AppDivider(height: 1),
                        CheckboxListTile(
                          dense: true,
                          title: Text(s.name,
                              style: theme.textTheme.bodyMedium),
                          value: selectedServiceIds.contains(s.id),
                          onChanged: (checked) {
                            final next = Set<int>.from(selectedServiceIds);
                            checked == true
                                ? next.add(s.id)
                                : next.remove(s.id);
                            onServicesChanged(next);
                          },
                          controlAffinity:
                              ListTileControlAffinity.trailing,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ]);
                    }),
                ],
                // Lezioni della categoria
                for (final ct in classTypesByCategory[catId] ?? []) ...[
                  Builder(builder: (ctx) {
                    final servicesInCat =
                        servicesByCategory[catId] ?? [];
                    final classTypesInCat =
                        classTypesByCategory[catId] ?? [];
                    final allItems = [
                      ...servicesInCat,
                      ...classTypesInCat,
                    ];
                    final idx = allItems.indexWhere(
                        (e) => e is ClassType && e.id == ct.id);
                    return Column(children: [
                      if (idx > 0) const AppDivider(height: 1),
                      CheckboxListTile(
                        dense: true,
                        title: Text(ct.name,
                            style: theme.textTheme.bodyMedium),
                        secondary: Icon(Icons.sports_martial_arts,
                            size: 18,
                            color: colorScheme.onSurfaceVariant),
                        value:
                            selectedClassTypeIds.contains(ct.id),
                        onChanged: (checked) {
                          final next =
                              Set<int>.from(selectedClassTypeIds);
                          checked == true
                              ? next.add(ct.id)
                              : next.remove(ct.id);
                          onClassTypesChanged(next);
                        },
                        controlAffinity:
                            ListTileControlAffinity.trailing,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ]);
                  }),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
