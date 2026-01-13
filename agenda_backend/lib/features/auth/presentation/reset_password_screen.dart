import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/widgets/form_loading_overlay.dart';
import '../providers/auth_provider.dart';

/// Schermata per impostare nuova password da link email.
/// Usata per inviti admin e reset password dimenticata.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({required this.token, super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Stato per la verifica iniziale del token
  bool _isVerifyingToken = true;
  bool _tokenValid = false;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    try {
      await ref.read(authProvider.notifier).verifyResetToken(widget.token);
      if (mounted) {
        setState(() {
          _isVerifyingToken = false;
          _tokenValid = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingToken = false;
          _tokenValid = false;
        });
        // Mostra dialog bloccante e poi redirect
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Link non valido'),
            content: const Text(
              'Il link è scaduto o è già stato utilizzato.\n\n'
              'Richiedi un nuovo invito al superadmin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Vai al login'),
              ),
            ],
          ),
        );
        if (mounted) {
          context.go('/login');
        }
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .resetPasswordWithToken(
            token: widget.token,
            newPassword: _passwordController.text,
          );

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Password impostata'),
            content: const Text(
              'La tua password è stata impostata con successo.\nOra puoi effettuare il login.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Errore'),
            content: const Text(
              'Il link è scaduto o non valido.\nRichiedi un nuovo invito al superadmin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // Mostra loading mentre verifica il token
    if (_isVerifyingToken) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifica link in corso...',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    // Se il token non è valido, mostra schermata vuota (il dialog farà redirect)
    if (!_tokenValid) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // Token valido: mostra il form
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: FormLoadingOverlay(
                isLoading: _isLoading,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Icon
                    Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Imposta la tua password',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Message
                    Text(
                      'Scegli una password sicura per accedere al tuo gestionale.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // New password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Nuova password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Conferma password',
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
                        if (value != _passwordController.text) {
                          return 'Le password non corrispondono';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleResetPassword(),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleResetPassword,
                      child: const Text('Imposta password'),
                    ),

                    const SizedBox(height: 16),

                    // Back to login
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Torna al login'),
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
