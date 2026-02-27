import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/widgets/local_loading_overlay.dart';
import '../providers/auth_provider.dart';

/// Schermata per cambiare la password.
/// Se [targetUserId] è null, cambia la password dell'utente loggato (richiede password attuale).
/// Se [targetUserId] è non-null, il superadmin imposta direttamente la nuova password
/// senza bisogno della password attuale.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  final int? targetUserId;

  const ChangePasswordScreen({super.key, this.targetUserId});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool get _isAdminMode => widget.targetUserId != null;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isAdminMode) {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.setAdminUserPassword(
          userId: widget.targetUserId!,
          newPassword: _newPasswordController.text,
        );
      } else {
        final success = await ref.read(authProvider.notifier).changePassword(
              currentPassword: _currentPasswordController.text,
              newPassword: _newPasswordController.text,
            );
        if (!success) {
          setState(() => _isLoading = false);
          if (mounted) {
            await _showDialog('Errore', 'La password attuale non è corretta.');
          }
          return;
        }
      }

      setState(() => _isLoading = false);
      if (mounted) {
        await _showDialog(
          'Password modificata',
          'La password è stata modificata con successo.',
        );
        if (mounted) context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        await _showDialog('Errore', e.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        await _showDialog('Errore', e.toString());
      }
    }
  }

  Future<void> _showDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Cambia password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: LocalLoadingOverlay(
                isLoading: _isLoading,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 32),

                      // Password attuale (solo modalità normale)
                      if (!_isAdminMode) ...[
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password attuale',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscureCurrentPassword =
                                      !_obscureCurrentPassword,
                                );
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.authRequiredField;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Nuova password
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nuova password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(
                                () =>
                                    _obscureNewPassword = !_obscureNewPassword,
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authRequiredField;
                          }
                          if (value.length < 8) {
                            return 'La password deve avere almeno 8 caratteri';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(value) ||
                              !RegExp(r'[a-z]').hasMatch(value) ||
                              !RegExp(r'[0-9]').hasMatch(value)) {
                            return 'Deve contenere maiuscole, minuscole e numeri';
                          }
                          if (!_isAdminMode &&
                              value == _currentPasswordController.text) {
                            return 'La nuova password deve essere diversa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Conferma nuova password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Conferma nuova password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authRequiredField;
                          }
                          if (value != _newPasswordController.text) {
                            return 'Le password non corrispondono';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleChangePassword(),
                      ),
                      const SizedBox(height: 32),

                      FilledButton(
                        onPressed: _isLoading ? null : _handleChangePassword,
                        child: Text(l10n.actionConfirm),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
