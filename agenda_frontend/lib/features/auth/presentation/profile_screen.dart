import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/initials_utils.dart';
import '../providers/auth_provider.dart';

/// Schermata profilo utente per il frontend clienti.
/// Permette di visualizzare e modificare i propri dati.
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
  bool _marketingOptIn = false;
  bool _profilingOptIn = false;
  String _preferredChannel = 'none';

  bool _isLoading = false;
  bool _isEditing = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _marketingOptIn = user?.marketingOptIn ?? false;
    _profilingOptIn = user?.profilingOptIn ?? false;
    _preferredChannel = user?.preferredChannel ?? 'none';
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

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            marketingOptIn: _marketingOptIn,
            profilingOptIn: _profilingOptIn,
            preferredChannel: _preferredChannel,
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _success = 'Profilo aggiornato con successo';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _cancelEditing() {
    final user = ref.read(authProvider).user;
    setState(() {
      _firstNameController.text = user?.firstName ?? '';
      _lastNameController.text = user?.lastName ?? '';
      _emailController.text = user?.email ?? '';
      _phoneController.text = user?.phone ?? '';
      _marketingOptIn = user?.marketingOptIn ?? false;
      _profilingOptIn = user?.profilingOptIn ?? false;
      _preferredChannel = user?.preferredChannel ?? 'none';
      _isEditing = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
          l10n.profileTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifica',
              onPressed: () => setState(() => _isEditing = true),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      _getInitials(user?.firstName, user?.lastName),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Messaggi
                if (_success != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _success!,
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                              ? 'Attenzione: cambiando email dovrai usarla per il login'
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
                      const SizedBox(height: 16),

                      // Telefono
                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: l10n.authPhone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.profilePreferencesSection,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _marketingOptIn,
                        onChanged: _isEditing
                            ? (value) => setState(() => _marketingOptIn = value)
                            : null,
                        title: Text(l10n.profileMarketingConsent),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _profilingOptIn,
                        onChanged: _isEditing
                            ? (value) => setState(() => _profilingOptIn = value)
                            : null,
                        title: Text(l10n.profileProfilingConsent),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _preferredChannel,
                        decoration: InputDecoration(
                          labelText: l10n.profilePreferredChannel,
                          prefixIcon: const Icon(Icons.forum_outlined),
                        ),
                        items: const [
                          'none',
                          'whatsapp',
                          'sms',
                          'email',
                          'phone',
                        ].map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(_preferredChannelLabel(value, l10n)),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? (value) {
                                if (value == null) return;
                                setState(() => _preferredChannel = value);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bottoni
                if (_isEditing) ...[
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
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : Text(l10n.actionConfirm),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Link cambio password
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_outline),
                    label: Text(l10n.authChangePassword),
                    onPressed: () {
                      final slug = ref.read(routeSlugProvider);
                      context.push('/$slug/change-password');
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    return InitialsUtils.fromName(
      '${firstName ?? ''} ${lastName ?? ''}'.trim(),
      maxChars: 2,
    );
  }

  static String _preferredChannelLabel(String channel, dynamic l10n) {
    switch (channel) {
      case 'whatsapp':
        return l10n.profileChannelWhatsapp;
      case 'sms':
        return l10n.profileChannelSms;
      case 'email':
        return l10n.profileChannelEmail;
      case 'phone':
        return l10n.profileChannelPhone;
      case 'none':
      default:
        return l10n.profileChannelNone;
    }
  }
}
