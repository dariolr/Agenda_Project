import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/business.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/form_loading_overlay.dart';
import '../../providers/business_providers.dart';

/// Dialog per modificare un business esistente (solo superadmin).
class EditBusinessDialog extends ConsumerStatefulWidget {
  const EditBusinessDialog({super.key, required this.business});

  final Business business;

  @override
  ConsumerState<EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends ConsumerState<EditBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _adminEmailController;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _slugController = TextEditingController(text: widget.business.slug ?? '');
    _emailController = TextEditingController(text: widget.business.email ?? '');
    _phoneController = TextEditingController(text: widget.business.phone ?? '');
    _adminEmailController = TextEditingController(
      text: widget.business.adminEmail ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(businessRepositoryProvider);

      // Determina se admin email è cambiata
      final newAdminEmail = _adminEmailController.text.trim();
      final oldAdminEmail = widget.business.adminEmail ?? '';
      final adminEmailChanged =
          newAdminEmail.isNotEmpty &&
          newAdminEmail.toLowerCase() != oldAdminEmail.toLowerCase();

      await repository.updateBusiness(
        businessId: widget.business.id,
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        adminEmail: adminEmailChanged ? newAdminEmail : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Modifica Business'),
      content: SizedBox(
        width: 400,
        child: FormLoadingOverlay(
          isLoading: _isLoading,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nome business
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Business *',
                    hintText: 'es. Salone Maria',
                    prefixIcon: Icon(Icons.business),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.authRequiredField;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Slug
                TextFormField(
                  controller: _slugController,
                  decoration: const InputDecoration(
                    labelText: 'Slug URL *',
                    hintText: 'es. salone-maria',
                    prefixIcon: Icon(Icons.link),
                    helperText: 'Usato per URL pubblico',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.authRequiredField;
                    }
                    // Validate slug format
                    final slugRegex = RegExp(r'^[a-z0-9-]+$');
                    if (!slugRegex.hasMatch(value.trim())) {
                      return 'Solo lettere minuscole, numeri e trattini';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'es. info@salone.it',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return l10n.authInvalidEmail;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefono
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefono',
                    hintText: 'es. +39 333 1234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                // Divider e sezione admin
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Amministratore',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cambiando l\'email admin, verrà inviato un invito al nuovo amministratore.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Email Admin (opzionale)
                TextFormField(
                  controller: _adminEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email Admin',
                    hintText: 'es. admin@salone.it',
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                    helperText: widget.business.adminEmail != null
                        ? 'Attuale: ${widget.business.adminEmail}'
                        : 'Opzionale: riceverà email per configurare account',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    // Solo valida se inserito
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return l10n.authInvalidEmail;
                      }
                    }
                    return null;
                  },
                ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

/// Mostra il dialog per modificare un business.
/// Ritorna `true` se il business è stato modificato, `false` altrimenti.
Future<bool?> showEditBusinessDialog(BuildContext context, Business business) {
  return showDialog<bool>(
    context: context,
    builder: (context) => EditBusinessDialog(business: business),
  );
}
