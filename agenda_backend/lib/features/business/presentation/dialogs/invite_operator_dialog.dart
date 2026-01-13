import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../../core/widgets/form_loading_overlay.dart';
import '../../providers/business_users_provider.dart';

/// Dialog per invitare un nuovo operatore (desktop).
class InviteOperatorDialog extends ConsumerStatefulWidget {
  const InviteOperatorDialog({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<InviteOperatorDialog> createState() =>
      _InviteOperatorDialogState();
}

class _InviteOperatorDialogState extends ConsumerState<InviteOperatorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormDialog(
      title: Text(l10n.operatorsInviteTitle),
      content: FormLoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.operatorsInviteSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.operatorsInviteEmail,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.validationRequired;
                  }
                  if (!_isValidEmail(value)) {
                    return l10n.validationInvalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.operatorsInviteRole,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _RoleSelector(
                selectedRole: _selectedRole,
                onChanged: (role) => setState(() => _selectedRole = role),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(l10n.operatorsInviteSend),
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final invitation = await ref
        .read(businessUsersProvider(widget.businessId).notifier)
        .createInvitation(
          email: _emailController.text.trim(),
          role: _selectedRole,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (invitation != null) {
      Navigator.of(context).pop();
      _showSuccessDialog(context, invitation.email, invitation.token);
    }
  }

  void _showSuccessDialog(BuildContext context, String email, String? token) {
    final l10n = context.l10n;
    FeedbackDialog.showSuccess(
      context,
      title: l10n.operatorsInviteTitle,
      message: l10n.operatorsInviteSuccess(email),
      actionLabel: token != null ? 'Copia link' : null,
      onAction: token != null
          ? () {
              final url = 'https://agenda.example.com/invite/$token';
              Clipboard.setData(ClipboardData(text: url));
            }
          : null,
    );
  }
}

/// Bottom sheet per invitare un nuovo operatore (mobile/tablet).
class InviteOperatorSheet extends ConsumerStatefulWidget {
  const InviteOperatorSheet({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<InviteOperatorSheet> createState() =>
      _InviteOperatorSheetState();
}

class _InviteOperatorSheetState extends ConsumerState<InviteOperatorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FormLoadingOverlay(
      isLoading: _isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            l10n.operatorsInviteTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.operatorsInviteSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.operatorsInviteEmail,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.validationRequired;
                      }
                      if (!_isValidEmail(value)) {
                        return l10n.validationInvalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.operatorsInviteRole,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _RoleSelector(
                    selectedRole: _selectedRole,
                    onChanged: (role) => setState(() => _selectedRole = role),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(l10n.actionCancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Text(l10n.operatorsInviteSend),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final invitation = await ref
        .read(businessUsersProvider(widget.businessId).notifier)
        .createInvitation(
          email: _emailController.text.trim(),
          role: _selectedRole,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (invitation != null) {
      Navigator.of(context).pop();
      _showSuccessDialog(context, invitation.email, invitation.token);
    }
  }

  void _showSuccessDialog(BuildContext context, String email, String? token) {
    final l10n = context.l10n;
    FeedbackDialog.showSuccess(
      context,
      title: l10n.operatorsInviteTitle,
      message: l10n.operatorsInviteSuccess(email),
      actionLabel: token != null ? 'Copia link' : null,
      onAction: token != null
          ? () {
              final url = 'https://agenda.example.com/invite/$token';
              Clipboard.setData(ClipboardData(text: url));
            }
          : null,
    );
  }
}

/// Widget per selezionare un ruolo.
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        _RoleOption(
          role: 'admin',
          label: l10n.operatorsRoleAdmin,
          description: 'Accesso completo, può gestire operatori',
          icon: Icons.admin_panel_settings,
          isSelected: selectedRole == 'admin',
          onTap: () => onChanged('admin'),
        ),
        const SizedBox(height: 8),
        _RoleOption(
          role: 'manager',
          label: l10n.operatorsRoleManager,
          description: 'Gestisce agenda e clienti',
          icon: Icons.manage_accounts,
          isSelected: selectedRole == 'manager',
          onTap: () => onChanged('manager'),
        ),
        const SizedBox(height: 8),
        _RoleOption(
          role: 'staff',
          label: l10n.operatorsRoleStaff,
          description: 'Visualizza e gestisce solo i propri appuntamenti',
          icon: Icons.person,
          isSelected: selectedRole == 'staff',
          onTap: () => onChanged('staff'),
        ),
      ],
    );
  }
}

/// Singola opzione ruolo.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String role;
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
