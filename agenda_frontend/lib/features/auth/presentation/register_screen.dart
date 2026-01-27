import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../booking/providers/business_provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  /// Route da cui l'utente è stato reindirizzato (es. 'my-bookings')
  final String? redirectFrom;

  const RegisterScreen({super.key, this.initialEmail, this.redirectFrom});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasAttemptedRegister = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Pulisci errori residui dopo che il widget è montato
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    });
    // Pre-compila l'email se passata dal login
    _initEmail();
  }

  void _initEmail() {
    final email = widget.initialEmail;
    debugPrint('RegisterScreen initialEmail: $email');
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Traduce il codice errore dall'API
  String _getErrorMessage(String? errorCode, dynamic l10n) {
    switch (errorCode) {
      case 'email_already_exists':
        return l10n.authErrorEmailAlreadyExists;
      case 'weak_password':
        return l10n.authErrorWeakPassword;
      case 'invalid_credentials':
        return l10n.authErrorInvalidCredentials;
      case 'account_disabled':
        return l10n.authErrorAccountDisabled;
      case 'token_expired':
        return l10n.authErrorTokenExpired;
      case 'token_invalid':
        return l10n.authErrorTokenInvalid;
      case 'session_revoked':
        return l10n.authErrorSessionRevoked;
      case 'invalid_reset_token':
        return l10n.authErrorInvalidResetToken;
      case 'reset_token_expired':
        return l10n.authErrorResetTokenExpired;
    }
    return l10n.authRegisterFailed;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _hasAttemptedRegister = true);

    // Ottieni il businessId - prima prova il provider sincrono
    var businessId = ref.read(currentBusinessIdProvider);

    // Se null, attendi che il business sia caricato (necessario quando
    // l'utente arriva direttamente sulla pagina via URL)
    if (businessId == null) {
      final businessAsync = await ref.read(currentBusinessProvider.future);
      businessId = businessAsync?.id;
    }

    if (businessId == null) {
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.authBusinessNotFound,
        );
      }
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .register(
          businessId: businessId,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );

    if (success && mounted) {
      // Segnala al browser che l'autofill è completato con successo
      TextInput.finishAutofillContext();
      final slug = ref.read(routeSlugProvider);

      // Se l'utente voleva vedere my-bookings, portalo lì
      if (widget.redirectFrom == 'my-bookings') {
        context.go('/$slug/my-bookings');
        return;
      }

      context.go('/$slug/booking');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            final slug = ref.read(routeSlugProvider);
            context.go('/$slug/booking');
          },
        ),
        title: Text(
          l10n.authRegisterTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Nome
                  TextFormField(
                    controller: _firstNameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    decoration: InputDecoration(
                      labelText: l10n.authFirstName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.authRequiredField;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Cognome
                  TextFormField(
                    controller: _lastNameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    decoration: InputDecoration(
                      labelText: l10n.authLastName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.authRequiredField;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: true,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.authEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
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

                  // Telefono (opzionale)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: '${l10n.authPhone} (opzionale)',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: l10n.authPassword,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.authRequiredField;
                      }
                      if (value.length < 6) {
                        return l10n.authInvalidPassword;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Conferma Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      labelText: l10n.authConfirmPassword,
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
                        return l10n.authPasswordMismatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Errore (mostrato solo dopo un tentativo di registrazione e dopo init)
                  if (_isInitialized &&
                      _hasAttemptedRegister &&
                      authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getErrorMessage(authState.errorCode, l10n),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bottone Registra
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.actionRegister),
                  ),
                  const SizedBox(height: 24),

                  // Link login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.authHaveAccount),
                      TextButton(
                        onPressed: () {
                          final slug = ref.read(routeSlugProvider);
                          context.go('/$slug/login');
                        },
                        child: Text(l10n.actionLogin),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
