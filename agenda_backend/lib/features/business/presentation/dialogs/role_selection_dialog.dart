import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_dialogs.dart';

/// Dialog per selezionare un ruolo (desktop).
class RoleSelectionDialog extends StatefulWidget {
  const RoleSelectionDialog({
    super.key,
    required this.currentRole,
    required this.userName,
    required this.onRoleSelected,
  });

  final String currentRole;
  final String userName;
  final ValueChanged<String> onRoleSelected;

  @override
  State<RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<RoleSelectionDialog> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => widget.onRoleSelected(_selectedRole),
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
    required this.userName,
    required this.onRoleSelected,
  });

  final String currentRole;
  final String userName;
  final ValueChanged<String> onRoleSelected;

  @override
  State<RoleSelectionSheet> createState() => _RoleSelectionSheetState();
}

class _RoleSelectionSheetState extends State<RoleSelectionSheet> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
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
        const SizedBox(height: 24),

        // Role options
        _RoleRadioList(
          selectedRole: _selectedRole,
          onChanged: (role) => setState(() => _selectedRole = role),
        ),

        // Actions
        const SizedBox(height: 24),
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
                onPressed: () => widget.onRoleSelected(_selectedRole),
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

    return Column(
      children: [
        _RoleRadioTile(
          value: 'admin',
          groupValue: selectedRole,
          onChanged: onChanged,
          title: l10n.operatorsRoleAdmin,
          subtitle: 'Accesso completo, può gestire operatori',
          icon: Icons.admin_panel_settings,
        ),
        _RoleRadioTile(
          value: 'manager',
          groupValue: selectedRole,
          onChanged: onChanged,
          title: l10n.operatorsRoleManager,
          subtitle: 'Gestisce agenda e clienti',
          icon: Icons.manage_accounts,
        ),
        _RoleRadioTile(
          value: 'staff',
          groupValue: selectedRole,
          onChanged: onChanged,
          title: l10n.operatorsRoleStaff,
          subtitle: 'Visualizza e gestisce solo i propri appuntamenti',
          icon: Icons.person,
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
