import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/api_client.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../providers/business_providers.dart';

/// Dialog per creare un nuovo business (solo superadmin).
/// Richiede l'email dell'admin che riceverà una mail di benvenuto.
class CreateBusinessDialog extends ConsumerStatefulWidget {
  const CreateBusinessDialog({super.key});

  @override
  ConsumerState<CreateBusinessDialog> createState() =>
      _CreateBusinessDialogState();
}

class _CreateBusinessDialogState extends ConsumerState<CreateBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _autoGenerateSlug = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _adminEmailController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_autoGenerateSlug) {
      _slugController.text = _generateSlug(_nameController.text);
    }
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(businessRepositoryProvider);

      await repository.createBusiness(
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        adminEmail: _adminEmailController.text.trim().isEmpty
            ? null
            : _adminEmailController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // Invalida il provider per ricaricare la lista
      ref.invalidate(businessesProvider);

      // Attendi un frame per permettere al provider di invalidarsi
      await Future.delayed(Duration.zero);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      debugPrint('❌ CreateBusiness ApiException: ${e.code} - ${e.message}');
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('❌ CreateBusiness Error: $e');
      debugPrint('$st');
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
      title: const Text('Nuovo Business'),
      content: SizedBox(
        width: 400,
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
                // Nome
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    hintText: 'es. Salone Bellezza',
                    prefixIcon: Icon(Icons.business),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Il nome è obbligatorio';
                    }
                    if (value.trim().length < 2) {
                      return 'Il nome deve avere almeno 2 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Slug
                TextFormField(
                  controller: _slugController,
                  decoration: InputDecoration(
                    labelText: 'Slug URL *',
                    hintText: 'es. salone-bellezza',
                    prefixIcon: const Icon(Icons.link),
                    helperText: 'Usato per URL: prenota.romeolab.it/slug',
                    suffixIcon: _autoGenerateSlug
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Modifica manualmente',
                            onPressed: () {
                              setState(() => _autoGenerateSlug = false);
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.auto_fix_high),
                            tooltip: 'Genera automaticamente',
                            onPressed: () {
                              setState(() {
                                _autoGenerateSlug = true;
                                _slugController.text = _generateSlug(
                                  _nameController.text,
                                );
                              });
                            },
                          ),
                  ),
                  onChanged: (_) {
                    if (_autoGenerateSlug) {
                      setState(() => _autoGenerateSlug = false);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lo slug è obbligatorio';
                    }
                    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                      return 'Solo lettere minuscole, numeri e trattini';
                    }
                    if (value.length < 3) {
                      return 'Lo slug deve avere almeno 3 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email Admin (opzionale - può essere assegnato dopo)
                TextFormField(
                  controller: _adminEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Amministratore',
                    hintText: 'es. mario.rossi@email.it',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                    helperText:
                        'Opzionale: riceverà email per configurare account',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    // Solo valida se inserito
                    if (value != null && value.trim().isNotEmpty) {
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Email non valida';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email Business (opzionale)
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Business',
                    hintText: 'es. info@salone.it',
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: 'Contatto pubblico del business',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Email non valida';
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
                    hintText: 'es. +39 123 456 7890',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Text(
                  '* Campi obbligatori',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crea Business'),
        ),
      ],
    );
  }
}

/// Mostra il dialog per creare un nuovo business.
Future<bool?> showCreateBusinessDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const CreateBusinessDialog(),
  );
}
