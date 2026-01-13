import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

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

    final success = await ref
        .read(authProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        await FeedbackDialog.showSuccess(
          context,
          title: context.l10n.authChangePasswordTitle,
          message: context.l10n.authChangePasswordSuccess,
        );
        if (mounted) context.pop();
      } else {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.authChangePasswordError,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          l10n.authChangePasswordTitle,
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
                const SizedBox(height: 32),

                // Current password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.authCurrentPassword,
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

                // New password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.authNewPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        );
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
                    if (value == _currentPasswordController.text) {
                      return 'La nuova password deve essere diversa';
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
                    if (value != _newPasswordController.text) {
                      return l10n.authPasswordMismatch;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleChangePassword(),
                ),
                const SizedBox(height: 32),

                // Submit button
                FilledButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
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
