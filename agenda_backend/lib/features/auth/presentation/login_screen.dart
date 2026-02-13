import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/global_loading_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/services/credentials_provider.dart';
import '../../../core/utils/app_version.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../../core/widgets/global_loading_overlay.dart';
import '../providers/auth_provider.dart';

/// Schermata di login per il gestionale.
/// Richiede autenticazione per accedere al sistema.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _credentialsLoaded = false;
  String? _errorMessage;

  String get _postLoginRoute {
    final redirect = widget.redirectTo;
    if (redirect != null && redirect.startsWith('/')) {
      return redirect;
    }
    return '/agenda';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // In debug mode, usa credenziali di test se non ci sono credenziali salvate
    if (kDebugMode && !_credentialsLoaded) {
      _emailController.text = 'dariolarosa@hotmail.com';
      _passwordController.text = 'Abc123@@';
    }

    try {
      final storage = ref.read(credentialsStorageProvider);
      final credentials = await storage.getSavedCredentials();

      if (credentials.email != null && credentials.password != null) {
        if (mounted) {
          setState(() {
            _emailController.text = credentials.email!;
            _passwordController.text = credentials.password!;
            _rememberMe = true;
            _credentialsLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    ref.read(globalLoadingProvider.notifier).show();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(email: email, password: password);

      if (!mounted) return;

      if (success) {
        // Salva o cancella le credenziali in base alla scelta dell'utente
        final storage = ref.read(credentialsStorageProvider);
        if (_rememberMe) {
          await storage.saveCredentials(email, password);
        } else {
          await storage.clearCredentials();
        }

        if (!mounted) return;

        // Segnala al browser che l'autofill è completato con successo
        // Questo triggera la richiesta di salvataggio credenziali
        TextInput.finishAutofillContext();
        context.go(_postLoginRoute);
      } else {
        final authState = ref.read(authProvider);
        final isNetwork = authState.errorCode == 'network_error';
        final details = authState.errorDetails;
        setState(() {
          _errorMessage = isNetwork
              ? '${context.l10n.authNetworkError}${details != null ? '\n[$details]' : ''}'
              : context.l10n.authLoginFailed;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '${context.l10n.authNetworkError}\n[${e.runtimeType}]';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ref.read(globalLoadingProvider.notifier).hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Osserva solo per redirect se autenticato
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && mounted) {
        context.go(_postLoginRoute);
      }
    });

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlobalLoadingOverlay(
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo e titolo
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 72,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.authLoginSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        enableSuggestions: true,
                        // Email + username per miglior compatibilità autofill Safari iOS
                        autofillHints: const [
                          AutofillHints.email,
                          AutofillHints.username,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.authEmail,
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authRequiredField;
                          }
                          if (!value.contains('@')) {
                            return l10n.authInvalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: l10n.authPassword,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
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
                          if (value.length < 6) {
                            return l10n.authPasswordTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Remember me e forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? true);
                                },
                              ),
                              Text(
                                l10n.authRememberMe,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _showForgotPasswordInfo(context),
                            child: Text(l10n.authForgotPassword),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Errore
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Bottone Login
                      FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n.authLogin),
                      ),
                      const SizedBox(height: 32),

                      // Footer
                      Text(
                        l10n.authLoginFooter,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Versione app
                      Text(
                        'v${getAppVersion()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
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

  void _showForgotPasswordInfo(BuildContext context) {
    final l10n = context.l10n;
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.authResetPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.authResetPasswordMessage),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.authEmail,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              // Chiudi il dialog prima di fare la chiamata
              Navigator.of(dialogContext).pop();

              final success = await ref
                  .read(authProvider.notifier)
                  .forgotPassword(email: email);

              if (!context.mounted) return;

              if (success) {
                await FeedbackDialog.showSuccess(
                  context,
                  title: l10n.authResetPasswordTitle,
                  message: l10n.authResetPasswordSuccess,
                );
              } else {
                await FeedbackDialog.showError(
                  context,
                  title: l10n.errorTitle,
                  message: l10n.authResetPasswordError,
                );
              }
            },
            child: Text(l10n.authResetPasswordSend),
          ),
        ],
      ),
    );
  }
}
