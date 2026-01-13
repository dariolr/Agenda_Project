import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/pending_booking_storage.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/providers/business_provider.dart';
import '../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Pulisci eventuali errori residui quando si entra nella pagina
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('LOGIN initState - clearing error');
      debugPrint(
        'LOGIN initState - authState before clear: ${ref.read(authProvider)}',
      );
      ref.read(authProvider.notifier).clearError();
      debugPrint(
        'LOGIN initState - authState after clear: ${ref.read(authProvider)}',
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('LOGIN _handleLogin called');
    debugPrint('LOGIN email: ${_emailController.text}');
    debugPrint('LOGIN password length: ${_passwordController.text.length}');

    if (!_formKey.currentState!.validate()) {
      debugPrint('LOGIN form validation FAILED');
      return;
    }
    debugPrint('LOGIN form validation OK');

    // Attendi che il business sia caricato
    int? businessId = ref.read(currentBusinessIdProvider);
    debugPrint('LOGIN businessId (sync): $businessId');

    if (businessId == null) {
      // Il business potrebbe non essere ancora caricato, aspettiamo
      debugPrint('LOGIN waiting for business to load...');
      try {
        final business = await ref.read(currentBusinessProvider.future);
        businessId = business?.id;
        debugPrint('LOGIN businessId (async): $businessId');
      } catch (e) {
        debugPrint('LOGIN business load failed: $e');
      }
    }

    if (businessId == null) {
      debugPrint('LOGIN businessId is NULL - showing error');
      // Se non c'è un business, mostra errore
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.authLoginFailed,
        );
      }
      return;
    }

    debugPrint('LOGIN calling API...');
    final success = await ref
        .read(authProvider.notifier)
        .login(
          businessId: businessId,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    debugPrint('LOGIN API returned: success=$success');

    if (success && mounted) {
      // Segnala al browser che l'autofill è completato con successo
      // Questo triggera la richiesta di salvataggio credenziali
      TextInput.finishAutofillContext();

      final slug = ref.read(routeSlugProvider);

      // Verifica se c'è una prenotazione in sospeso (da token scaduto)
      if (await PendingBookingStorage.hasPendingBooking()) {
        // Ripristina la prenotazione e vai al riepilogo
        final restored = await ref
            .read(bookingFlowProvider.notifier)
            .restorePendingBooking();
        if (restored && mounted) {
          debugPrint(
            'LOGIN pending booking restored - going to booking (summary step)',
          );
          context.go('/$slug/booking');
          return;
        }
      }

      // Nessuna prenotazione in sospeso - vai al booking normale
      if (mounted) {
        context.go('/$slug/booking');
      }
    }
  }

  String _resolveAuthErrorMessage(BuildContext context, AuthState authState) {
    final l10n = context.l10n;
    switch (authState.errorCode) {
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
      case 'email_already_exists':
        return l10n.authErrorEmailAlreadyExists;
      case 'weak_password':
        return l10n.authErrorWeakPassword;
      case 'invalid_reset_token':
        return l10n.authErrorInvalidResetToken;
      case 'reset_token_expired':
        return l10n.authErrorResetTokenExpired;
    }
    return authState.errorMessage ?? l10n.authLoginFailed;
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
          l10n.authLoginTitle,
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
                  const SizedBox(height: 32),

                  // Logo o icona
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 32),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    // Non usare autofocus: interferisce con autofill su Safari iOS
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
                      // Nel login non validiamo la lunghezza minima,
                      // sarà l'API a rispondere con credenziali non valide
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Password dimenticata
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showResetPasswordDialog(context, ref),
                      child: Text(l10n.authForgotPassword),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Errore
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
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
                              _resolveAuthErrorMessage(context, authState),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bottone Login
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.actionLogin),
                  ),
                  const SizedBox(height: 24),

                  // Link registrazione
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.authNoAccount),
                      TextButton(
                        onPressed: () {
                          final slug = ref.read(routeSlugProvider);
                          final email = _emailController.text.trim();
                          if (email.isNotEmpty) {
                            context.go(
                              '/$slug/register?email=${Uri.encodeComponent(email)}',
                            );
                          } else {
                            context.go('/$slug/register');
                          }
                        },
                        child: Text(l10n.actionRegister),
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

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final l10n = context.l10n;
    final parentContext = context;

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
              decoration: InputDecoration(
                labelText: l10n.authEmail,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              // Chiudi il dialog prima di fare la chiamata
              Navigator.pop(dialogContext);

              // Ottieni businessId - se non disponibile, prova ad aspettare
              var businessId = ref.read(currentBusinessIdProvider);

              // Se businessId è null, attendi il caricamento del business
              if (businessId == null) {
                final businessAsync = await ref.read(
                  currentBusinessProvider.future,
                );
                businessId = businessAsync?.id;
              }

              // Verifica businessId
              if (businessId == null) {
                if (parentContext.mounted) {
                  await FeedbackDialog.showError(
                    parentContext,
                    title: l10n.errorTitle,
                    message: l10n.authResetPasswordError,
                  );
                }
                return;
              }

              try {
                await ref
                    .read(authProvider.notifier)
                    .resetPassword(businessId: businessId, email: email);

                if (parentContext.mounted) {
                  await FeedbackDialog.showSuccess(
                    parentContext,
                    title: l10n.authResetPasswordTitle,
                    message: l10n.authResetPasswordSuccess,
                  );
                }
              } on ApiException catch (e) {
                if (parentContext.mounted) {
                  // Messaggio specifico se email non trovata
                  final message = e.code == 'email_not_found'
                      ? l10n.authResetPasswordEmailNotFound
                      : l10n.authResetPasswordError;
                  await FeedbackDialog.showError(
                    parentContext,
                    title: l10n.errorTitle,
                    message: message,
                  );
                }
              } catch (e) {
                if (parentContext.mounted) {
                  await FeedbackDialog.showError(
                    parentContext,
                    title: l10n.errorTitle,
                    message: l10n.authResetPasswordError,
                  );
                }
              }
            },
            child: Text(l10n.authResetPasswordSend),
          ),
        ],
      ),
    );
  }
}
