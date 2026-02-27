import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/initials_utils.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../../core/widgets/local_loading_overlay.dart';
import '../../agenda/providers/business_providers.dart';
import '../../business/providers/business_users_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/current_business_user_provider.dart';

/// Schermata profilo utente.
/// Permette di visualizzare e modificare i propri dati (nome, cognome, email, telefono).
/// Quando l'utente è superadmin, mostra e permette di modificare il profilo
/// dell'owner/admin del business selezionato.
/// Note: This screen is displayed inside ScaffoldWithNavigation,
/// so it should NOT have its own Scaffold/AppBar.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isLoading = false;
  bool _isEditing = false;
  // Traccia l'userId dell'owner per cui i controller sono stati popolati.
  // Quando cambia (cambio business), i controller vengono re-inizializzati.
  int? _initializedOwnerUserId;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final businessOwner = ref.read(businessOwnerProvider);
    final isOwnerMode = businessOwner != null;

    try {
      if (isOwnerMode) {
        final currentBusinessId = ref.read(currentBusinessIdProvider);
        final apiClient = ref.read(apiClientProvider);
        await apiClient.updateAdminUserProfile(
          userId: businessOwner.userId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
        );
        await ref
            .read(businessUsersProvider(currentBusinessId).notifier)
            .refresh();
      } else {
        await ref
            .read(authProvider.notifier)
            .updateProfile(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            );
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        FeedbackDialog.showSuccess(
          context,
          title: context.l10n.profileUpdateSuccess,
          message: '',
        );
      }
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.message,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.toString(),
        );
      }
    }
  }

  void _cancelEditing() {
    final businessOwner = ref.read(businessOwnerProvider);
    if (businessOwner != null) {
      setState(() {
        _firstNameController.text = businessOwner.firstName;
        _lastNameController.text = businessOwner.lastName;
        _emailController.text = businessOwner.email;
        _isEditing = false;
      });
    } else {
      final user = ref.read(authProvider).user;
      setState(() {
        _firstNameController.text = user?.firstName ?? '';
        _lastNameController.text = user?.lastName ?? '';
        _emailController.text = user?.email ?? '';
        _phoneController.text = user?.phone ?? '';
        _isEditing = false;
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final businessOwner = ref.watch(businessOwnerProvider);
    final isOwnerMode = businessOwner != null;

    // Popola i controller quando l'owner cambia (primo caricamento o cambio business)
    if (isOwnerMode && businessOwner.userId != _initializedOwnerUserId) {
      _initializedOwnerUserId = businessOwner.userId;
      if (_isEditing) _isEditing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _firstNameController.text = businessOwner.firstName;
            _lastNameController.text = businessOwner.lastName;
            _emailController.text = businessOwner.email;
            _phoneController.text = '';
          });
        }
      });
    }

    // Dati da visualizzare nell'header
    final displayFirstName =
        isOwnerMode ? businessOwner.firstName : user?.firstName;
    final displayLastName =
        isOwnerMode ? businessOwner.lastName : user?.lastName;
    final displayEmail = isOwnerMode ? businessOwner.email : user?.email ?? '';

    return Column(
      children: [
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: LocalLoadingOverlay(
                  isLoading: _isLoading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            _getInitials(displayFirstName, displayLastName),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nome utente
                      Center(
                        child: Text(
                          '${displayFirstName ?? ''} ${displayLastName ?? ''}'
                              .trim(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          displayEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      // Badge ruolo
                      if (isOwnerMode) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business_center_outlined,
                                  size: 16,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  businessOwner.roleLabel,
                                  style: TextStyle(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (user?.isSuperadmin == true) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 16,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Superadmin',
                                  style: TextStyle(
                                    color: colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Nome
                            TextFormField(
                              controller: _firstNameController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: l10n.authFirstName,
                                prefixIcon: const Icon(Icons.person_outline),
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

                            // Cognome
                            TextFormField(
                              controller: _lastNameController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: l10n.authLastName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: l10n.authEmail,
                                prefixIcon: const Icon(Icons.email_outlined),
                                helperText: _isEditing
                                    ? l10n.profileEmailChangeWarning
                                    : null,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.authRequiredField;
                                }
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return l10n.authInvalidEmail;
                                }
                                return null;
                              },
                            ),

                            // Telefono (solo per utente non-superadmin)
                            if (!isOwnerMode) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                enabled: _isEditing,
                                decoration: InputDecoration(
                                  labelText: l10n.authPhone,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (!_isEditing) ...[
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _isEditing = true),
                              child: Text(l10n.actionEdit),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ],
                      // Bottoni modifica
                      if (_isEditing) ...[
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _cancelEditing,
                                child: Text(l10n.actionCancel),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppAsyncFilledButton(
                                onPressed: _isLoading ? null : _saveChanges,
                                isLoading: _isLoading,
                                child: Text(l10n.actionSave),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 36),

                      // Azioni account
                      _ActionTile(
                        icon: Icons.lock_outline,
                        title: l10n.profileChangePassword,
                        onTap: () => context.push(
                          '/change-password',
                          extra: isOwnerMode ? businessOwner.userId : null,
                        ),
                      ),

                      _ActionTile(
                        icon: Icons.logout,
                        title: l10n.authLogout,
                        onTap: _logout,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return InitialsUtils.fromName(fullName, maxChars: 2);
  }
}

/// Tile per le azioni del profilo
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
