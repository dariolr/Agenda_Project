import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../providers/auth_provider.dart';

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
        await FeedbackDialog.showSuccess(
          context,
          title: context.l10n.authResetPasswordConfirmTitle,
          message: context.l10n.authResetPasswordConfirmSuccess,
        );
        // Redirect al login del business
        if (mounted) {
          final slug = ref.read(routeSlugProvider);
          if (slug != null) {
            context.go('/$slug/login');
          } else {
            context.go('/');
          }
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: _resolveResetPasswordError(context, e.code),
        );
      }
    } catch (e) {
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.authResetPasswordConfirmError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _resolveResetPasswordError(BuildContext context, String errorCode) {
    final l10n = context.l10n;
    switch (errorCode) {
      case 'invalid_reset_token':
        return l10n.authErrorInvalidResetToken;
      case 'reset_token_expired':
        return l10n.authErrorResetTokenExpired;
      case 'weak_password':
        return l10n.authErrorWeakPassword;
    }
    return l10n.authResetPasswordConfirmError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.authResetPasswordConfirmTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Icon
                Icon(
                  Icons.lock_reset,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  l10n.authResetPasswordConfirmMessage,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // New password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.authNewPassword,
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
                    if (value.length < 8) {
                      return l10n.authPasswordTooShort;
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value) ||
                        !RegExp(r'[a-z]').hasMatch(value) ||
                        !RegExp(r'[0-9]').hasMatch(value)) {
                      return l10n.authPasswordRequirements;
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
                  onFieldSubmitted: (_) => _handleResetPassword(),
                ),
                const SizedBox(height: 32),

                // Submit button
                FilledButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.actionConfirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
