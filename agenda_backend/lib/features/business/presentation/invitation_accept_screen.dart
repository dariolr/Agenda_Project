import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/business_users_provider.dart';

class InvitationAcceptScreen extends ConsumerStatefulWidget {
  const InvitationAcceptScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InvitationAcceptScreen> createState() =>
      _InvitationAcceptScreenState();
}

class _InvitationAcceptScreenState
    extends ConsumerState<InvitationAcceptScreen> {
  bool _isLoading = true;
  bool _isAccepting = false;
  bool _isDeclining = false;
  bool _isRegistering = false;
  bool _isRegisterDialogOpen = false;
  bool _accepted = false;
  bool _declined = false;
  bool _isInvalidInvitation = false;
  String? _errorMessage;
  Map<String, dynamic>? _invitation;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInvitation);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final business = _invitation?['business'];
    final businessName = business is Map<String, dynamic>
        ? (business['name'] as String?)
        : null;
    final role = (_invitation?['role'] as String?) ?? '';
    final email = (_invitation?['email'] as String?) ?? '';
    final invitedUserExists = _invitation?['user_exists'] as bool?;
    final showLoginAction = invitedUserExists != false;
    final showRegisterAction = invitedUserExists != true;
    final isPhone = MediaQuery.sizeOf(context).width < 520;
    final expiresAtRaw = _invitation?['expires_at'] as String?;
    final roleLabel = _roleLabel(role, context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: _isLoading
                      ? _buildLoading(context)
                      : _isInvalidInvitation
                      ? _buildInvalid(context)
                      : (_accepted || _declined)
                      ? _buildSuccess(context)
                      : Column(
                          key: const ValueKey('invitation-content'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.invitationAcceptTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.invitationAcceptIntro(
                                businessName ?? '-',
                                roleLabel,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            if (_errorMessage != null) ...[
                              _ErrorBanner(message: _errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            _SectionBox(
                              children: [
                                _InfoRow(
                                  icon: Icons.badge_outlined,
                                  label: l10n.operatorsInviteRole,
                                  value: roleLabel,
                                ),
                                Divider(
                                  height: 20,
                                  thickness: 0.5,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.45),
                                ),
                                _InfoRow(
                                  icon: Icons.alternate_email,
                                  label: l10n.operatorsInviteEmail,
                                  value: email,
                                ),
                                if (expiresAtRaw != null) ...[
                                  Divider(
                                    height: 20,
                                    thickness: 0.5,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                  _InfoRow(
                                    icon: Icons.event_outlined,
                                    label: _expiresLabel(context),
                                    value: l10n.operatorsExpires(
                                      _formatLocalizedDateTime(
                                        context,
                                        expiresAtRaw,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!isAuthenticated) ...[
                              const SizedBox(height: 12),
                              if (showLoginAction)
                                Text(
                                  l10n.invitationAcceptHintExistingAccount,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              if (showLoginAction && showRegisterAction)
                                const SizedBox(height: 4),
                              if (showRegisterAction)
                                Text(
                                  l10n.invitationAcceptHintNoAccount,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                            ],
                            const SizedBox(height: 20),
                            if (!isAuthenticated)
                              _buildUnauthenticatedActions(
                                context,
                                isPhone: isPhone,
                                showLoginAction: showLoginAction,
                                showRegisterAction: showRegisterAction,
                              )
                            else
                              _buildAuthenticatedActions(
                                context,
                                isPhone: isPhone,
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

  Widget _buildUnauthenticatedActions(
    BuildContext context, {
    required bool isPhone,
    required bool showLoginAction,
    required bool showRegisterAction,
  }) {
    final l10n = context.l10n;

    final loginButton = FilledButton.tonal(
      onPressed:
          _isDeclining ||
              _isRegistering ||
              _isRegisterDialogOpen ||
              _isAccepting
          ? null
          : () async {
              setState(() {
                _isAccepting = true;
                _errorMessage = null;
              });
              try {
                await ref
                    .read(businessUsersRepositoryProvider)
                    .acceptInvitationPublic(widget.token);
              } on ApiException catch (e) {
                if (!mounted) return;
                setState(() {
                  _errorMessage = _mapApiErrorToMessage(context, e);
                  _isAccepting = false;
                });
                return;
              } catch (_) {
                if (!mounted) return;
                setState(() {
                  _errorMessage = context.l10n.invitationAcceptErrorGeneric;
                  _isAccepting = false;
                });
                return;
              }
              if (!mounted) return;
              setState(() {
                _isAccepting = false;
                _accepted = true;
              });
              if (!context.mounted) return;
              final redirect = Uri.encodeComponent(
                '/invitation/${widget.token}',
              );
              context.go('/login?redirect=$redirect');
            },
      child: Text(
        _isAccepting
            ? l10n.invitationAcceptInProgress
            : l10n.invitationAcceptAndLoginAction,
        textAlign: TextAlign.center,
      ),
    );

    final registerButton = FilledButton.tonal(
      onPressed: _isDeclining || _isRegistering
          ? null
          : () {
              _showRegisterDialog();
            },
      child: Text(
        _isRegistering
            ? l10n.invitationRegisterInProgress
            : l10n.invitationRegisterAction,
        textAlign: TextAlign.center,
      ),
    );

    final declineButton = OutlinedButton(
      onPressed: _isDeclining
          ? null
          : () {
              _declineInvitation();
            },
      child: Text(
        _isDeclining
            ? l10n.invitationDeclineInProgress
            : l10n.invitationDeclineButton,
        textAlign: TextAlign.center,
      ),
    );

    final buttons = <Widget>[
      if (showLoginAction) loginButton,
      if (showRegisterAction) registerButton,
      declineButton,
    ];

    if (isPhone && buttons.length == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [buttons[0], const SizedBox(height: 8), buttons[1]],
      );
    }

    return Row(
      children: [
        if (showLoginAction) Expanded(child: loginButton),
        if (showLoginAction) const SizedBox(width: 8),
        if (showRegisterAction) Expanded(child: registerButton),
        if (showRegisterAction) const SizedBox(width: 8),
        Expanded(child: declineButton),
      ],
    );
  }

  Widget _buildAuthenticatedActions(
    BuildContext context, {
    required bool isPhone,
  }) {
    final l10n = context.l10n;

    final acceptButton = FilledButton(
      onPressed: (_isAccepting || _isDeclining)
          ? null
          : () {
              _acceptInvitation();
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAccepting) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              _isAccepting
                  ? l10n.invitationAcceptInProgress
                  : l10n.invitationAcceptButton,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    final declineButton = OutlinedButton(
      onPressed: (_isAccepting || _isDeclining)
          ? null
          : () {
              _declineInvitation();
            },
      child: Text(
        _isDeclining
            ? l10n.invitationDeclineInProgress
            : l10n.invitationDeclineButton,
        textAlign: TextAlign.center,
      ),
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [acceptButton, const SizedBox(height: 8), declineButton],
      );
    }

    return Row(
      children: [
        Expanded(child: acceptButton),
        const SizedBox(width: 10),
        Expanded(child: declineButton),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      key: const ValueKey('invitation-loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.invitationAcceptLoading,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final l10n = context.l10n;
    if (_declined) {
      return Column(
        key: const ValueKey('invitation-success-declined'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.invitationDeclineSuccessTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(l10n.invitationDeclineSuccessMessage),
        ],
      );
    }

    return Column(
      key: const ValueKey('invitation-success-accepted'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.invitationAcceptSuccessTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(l10n.invitationAcceptSuccessMessage),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.go('/agenda'),
          child: Text(l10n.invitationAcceptGoAgenda),
        ),
      ],
    );
  }

  Future<void> _loadInvitation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ref
          .read(businessUsersRepositoryProvider)
          .getInvitationByToken(widget.token);

      if (!mounted) return;
      setState(() {
        _invitation = data;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final isInvalid = _isInvalidInvitationError(e);
      setState(() {
        _isInvalidInvitation = isInvalid;
        _errorMessage = isInvalid
            ? context.l10n.invitationAcceptErrorInvalid
            : _mapApiErrorToMessage(context, e);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.invitationAcceptErrorGeneric;
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation() async {
    if (_isAccepting || _accepted) return;
    if (!ref.read(authProvider).isAuthenticated) {
      setState(() {
        _errorMessage = context.l10n.invitationAcceptLoginRequired;
      });
      return;
    }

    final invitedEmail =
        (_invitation?['email'] as String?)?.trim().toLowerCase() ?? '';
    final authState = ref.read(authProvider);
    final currentUser = authState.user;
    final loggedEmail = currentUser is User
        ? currentUser.email.trim().toLowerCase()
        : '';

    if (invitedEmail.isNotEmpty &&
        loggedEmail.isNotEmpty &&
        loggedEmail != invitedEmail) {
      await ref.read(authProvider.notifier).logout(silent: true);
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.invitationAcceptErrorEmailMismatch;
      });
      return;
    }

    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(businessUsersRepositoryProvider)
          .acceptInvitation(widget.token);
      if (!mounted) return;
      setState(() {
        _accepted = true;
        _declined = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_isInvalidInvitationError(e)) {
        setState(() {
          _isInvalidInvitation = true;
        });
        return;
      }
      setState(() {
        _errorMessage = _mapApiErrorToMessage(context, e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.invitationAcceptErrorGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  Future<void> _declineInvitation() async {
    if (_isDeclining || _accepted || _declined) return;

    setState(() {
      _isDeclining = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(businessUsersRepositoryProvider)
          .declineInvitation(widget.token);
      if (!mounted) return;
      setState(() {
        _declined = true;
        _accepted = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_isInvalidInvitationError(e)) {
        setState(() {
          _isInvalidInvitation = true;
        });
        return;
      }
      setState(() {
        _errorMessage = _mapApiErrorToMessage(context, e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.invitationAcceptErrorGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeclining = false;
        });
      }
    }
  }

  Future<void> _showRegisterDialog() async {
    final l10n = context.l10n;
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? localError;

    setState(() {
      _isRegisterDialogOpen = true;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isRegistering,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.invitationRegisterTitle),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: l10n.formFirstName,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.validationRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: l10n.formLastName,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.authPassword,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.validationRequired;
                          }
                          final policyError = _passwordPolicyError(value, l10n);
                          if (policyError != null) {
                            return policyError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.invitationRegisterPasswordConfirm,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.validationRequired;
                          }
                          if (value != passwordController.text) {
                            return l10n.invitationRegisterPasswordMismatch;
                          }
                          return null;
                        },
                      ),
                      if (localError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          localError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isRegistering
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: _isRegistering
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setDialogState(() {
                            localError = null;
                          });
                          final ok = await _registerInvitation(
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            password: passwordController.text,
                            confirmPassword: confirmPasswordController.text,
                          );
                          if (!mounted) return;
                          if (ok && dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          } else {
                            setDialogState(() {
                              localError = _errorMessage;
                            });
                          }
                        },
                  child: Text(l10n.invitationRegisterAction),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {
        _isRegisterDialogOpen = false;
      });
    }
  }

  Future<bool> _registerInvitation({
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
  }) async {
    if (_isRegistering) return false;
    final policyError = _passwordPolicyError(password, context.l10n);
    if (policyError != null) {
      setState(() {
        _errorMessage = policyError;
      });
      return false;
    }
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = context.l10n.invitationRegisterPasswordMismatch;
      });
      return false;
    }
    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(businessUsersRepositoryProvider)
          .registerInvitation(
            token: widget.token,
            firstName: firstName,
            lastName: lastName,
            password: password,
          );
      if (!mounted) return false;
      setState(() {
        _accepted = true;
        _declined = false;
      });
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      setState(() {
        _errorMessage = _mapApiErrorToMessage(context, e);
      });
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _errorMessage = context.l10n.invitationAcceptErrorGeneric;
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  String _mapApiErrorToMessage(BuildContext context, ApiException e) {
    final l10n = context.l10n;
    final msg = e.message.toLowerCase();
    if (e.code == 'invitation_email_already_registered') {
      return l10n.invitationRegisterExistingUser;
    }
    if (e.code == 'invitation_account_not_found') {
      return l10n.invitationAcceptRequiresRegistration;
    }

    if (msg.contains('invitation not found')) {
      return l10n.invitationAcceptErrorInvalid;
    }
    if (msg.contains('expired')) {
      return l10n.invitationAcceptErrorExpired;
    }
    if (msg.contains('no longer valid')) {
      return l10n.invitationAcceptErrorInvalid;
    }
    if (msg.contains('different email')) {
      return l10n.invitationAcceptErrorEmailMismatch;
    }

    return l10n.invitationAcceptErrorGeneric;
  }

  bool _isInvalidInvitationError(ApiException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('invitation not found') ||
        msg.contains('expired') ||
        msg.contains('no longer valid');
  }

  String? _passwordPolicyError(String password, L10n l10n) {
    if (password.length < 8) {
      return l10n.invitationRegisterPasswordTooShort;
    }
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    if (!hasUppercase || !hasLowercase || !hasNumber) {
      return l10n.invitationRegisterPasswordWeak;
    }
    return null;
  }

  String _roleLabel(String role, BuildContext context) {
    final l10n = context.l10n;
    return switch (role) {
      'admin' => l10n.operatorsRoleAdmin,
      'manager' => l10n.operatorsRoleManager,
      'staff' => l10n.operatorsRoleStaff,
      'viewer' =>
        Localizations.localeOf(context).languageCode == 'it'
            ? 'Visualizzatore'
            : 'Viewer',
      _ => role,
    };
  }

  String _formatLocalizedDateTime(BuildContext context, String raw) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parsed =
        DateTime.tryParse(raw) ?? DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;
    return DateFormat.yMMMMd(locale).add_Hm().format(parsed);
  }

  String _expiresLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it'
        ? 'Scadenza'
        : 'Expiration';
  }

  Widget _buildInvalid(BuildContext context) {
    return Column(
      key: const ValueKey('invitation-invalid'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.invitationAcceptErrorInvalid,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}
