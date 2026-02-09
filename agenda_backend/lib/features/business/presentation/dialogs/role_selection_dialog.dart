import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/feedback_dialog.dart';

typedef RoleScopeSaveCallback =
    Future<void> Function({
      required String role,
      required String scopeType,
      required List<int> locationIds,
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
    required this.onSave,
  });

  final String currentRole;
  final String currentScopeType;
  final List<int> currentLocationIds;
  final List<Location> locations;
  final String userName;
  final RoleScopeSaveCallback onSave;

  @override
  State<RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<RoleSelectionDialog> {
  late String _selectedRole;
  late String _selectedScopeType;
  late Set<int> _selectedLocationIds;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
    _selectedScopeType = widget.currentScopeType.isNotEmpty
        ? widget.currentScopeType
        : 'business';
    _selectedLocationIds = widget.currentLocationIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          const SizedBox(height: 24),
          _RoleRadioList(
            selectedRole: _selectedRole,
            onChanged: (role) => setState(() => _selectedRole = role),
          ),
          // Sezione scope solo se più di una location
          if (widget.locations.length > 1) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _ScopeTypeSelector(
              selectedScopeType: _selectedScopeType,
              onChanged: (scope) => setState(() {
                _selectedScopeType = scope;
                if (scope == 'business') {
                  _selectedLocationIds.clear();
                }
              }),
            ),
            if (_selectedScopeType == 'locations') ...[
              const SizedBox(height: 16),
              _LocationsMultiSelect(
                locations: widget.locations,
                selectedIds: _selectedLocationIds,
                onChanged: (ids) => setState(() {
                  _selectedLocationIds
                    ..clear()
                    ..addAll(ids);
                }),
              ),
            ],
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
            widget.onSave(
              role: _selectedRole,
              scopeType: _selectedScopeType,
              locationIds: _selectedLocationIds.toList(),
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
    required this.onSave,
  });

  final String currentRole;
  final String currentScopeType;
  final List<int> currentLocationIds;
  final List<Location> locations;
  final String userName;
  final RoleScopeSaveCallback onSave;

  @override
  State<RoleSelectionSheet> createState() => _RoleSelectionSheetState();
}

class _RoleSelectionSheetState extends State<RoleSelectionSheet> {
  late String _selectedRole;
  late String _selectedScopeType;
  late Set<int> _selectedLocationIds;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
    _selectedScopeType = widget.currentScopeType.isNotEmpty
        ? widget.currentScopeType
        : 'business';
    _selectedLocationIds = widget.currentLocationIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.max,
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
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role options
                _RoleRadioList(
                  selectedRole: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),
                // Sezione scope solo se più di una location
                if (widget.locations.length > 1) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ScopeTypeSelector(
                    selectedScopeType: _selectedScopeType,
                    onChanged: (scope) => setState(() {
                      _selectedScopeType = scope;
                      if (scope == 'business') {
                        _selectedLocationIds.clear();
                      }
                    }),
                  ),
                  if (_selectedScopeType == 'locations') ...[
                    const SizedBox(height: 16),
                    _LocationsMultiSelect(
                      locations: widget.locations,
                      selectedIds: _selectedLocationIds,
                      onChanged: (ids) => setState(() {
                        _selectedLocationIds
                          ..clear()
                          ..addAll(ids);
                      }),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
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
                  widget.onSave(
                    role: _selectedRole,
                    scopeType: _selectedScopeType,
                    locationIds: _selectedLocationIds.toList(),
                  );
                },
                child: Text(l10n.actionSave),
              ),
            ),
          ],
        ),
      ],
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
    final isIt = Localizations.localeOf(context).languageCode == 'it';
    final viewerLabel = isIt ? 'Visualizzatore' : 'Viewer';
    final viewerDesc = isIt
        ? 'Può solo visualizzare appuntamenti e calendario. Nessuna modifica.'
        : 'Can only view appointments and calendar. No changes allowed.';

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
          title: viewerLabel,
          subtitle: viewerDesc,
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
                if (i > 0) const Divider(height: 1),
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
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) => onChanged(value ?? false),
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
