import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/business_whatsapp_settings.dart';
import '../../../../core/models/location.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/local_loading_overlay.dart';

class BusinessWhatsappSettingsDialog extends ConsumerStatefulWidget {
  const BusinessWhatsappSettingsDialog({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final int businessId;
  final String businessName;

  @override
  ConsumerState<BusinessWhatsappSettingsDialog> createState() =>
      _BusinessWhatsappSettingsDialogState();
}

class _BusinessWhatsappSettingsDialogState
    extends ConsumerState<BusinessWhatsappSettingsDialog> {
  BusinessWhatsappSettings? _settings;
  List<Location> _locations = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _whatsappEnabled = false;
  bool _messagesEnabled = false;
  bool _allowLocationMapping = false;
  String _existingClientsOptInPolicy = 'explicit_only';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final settings = await ref
          .read(apiClientProvider)
          .getBusinessWhatsappSettings(widget.businessId);
      final rawLocations = await ref
          .read(apiClientProvider)
          .getLocations(widget.businessId);
      final locations = rawLocations
          .map((raw) => Location.fromJson(Map<String, dynamic>.from(raw)))
          .where((location) => location.isActive)
          .toList(growable: false);
      if (!mounted) return;
      final canUseLocationMapping = locations.length > 1;
      setState(() {
        _settings = settings;
        _locations = locations;
        _whatsappEnabled = settings.whatsappEnabled;
        _messagesEnabled = settings.whatsappEnabled && settings.messagesEnabled;
        _allowLocationMapping =
            settings.whatsappEnabled &&
            canUseLocationMapping &&
            settings.allowLocationMapping;
        _existingClientsOptInPolicy = settings.existingClientsOptInPolicy;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updateAdminBusinessWhatsappSettings(
            businessId: widget.businessId,
            payload: {
              'whatsapp_enabled': _whatsappEnabled,
              'messages_enabled': _whatsappEnabled && _messagesEnabled,
              'allow_location_mapping':
                  _whatsappEnabled &&
                  _locations.length > 1 &&
                  _allowLocationMapping,
              'default_channel_mode': _allowLocationMapping
                  ? 'location_mapping'
                  : 'business_default',
              'existing_clients_opt_in_policy': _whatsappEnabled
                  ? _existingClientsOptInPolicy
                  : 'explicit_only',
              'status': _whatsappEnabled ? 'enabled' : 'not_enabled',
            },
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  void _setWhatsappEnabled(bool value) {
    setState(() {
      _whatsappEnabled = value;
      if (!value) {
        _messagesEnabled = false;
        _allowLocationMapping = false;
        _existingClientsOptInPolicy = 'explicit_only';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canUseLocationMapping = _locations.length > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: LocalLoadingOverlay(
        isLoading: _isLoading || _isSaving,
        child: AlertDialog(
          title: Text(l10n.businessWhatsappSettingsDialogTitle),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.businessName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SwitchListTile.adaptive(
                    value: _whatsappEnabled,
                    onChanged: _isLoading ? null : _setWhatsappEnabled,
                    secondary: const Icon(Icons.chat_outlined),
                    title: Text(l10n.businessWhatsappEnabledLabel),
                    subtitle: Text(l10n.businessWhatsappEnabledHelper),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: _messagesEnabled,
                    onChanged: !_whatsappEnabled || _isLoading
                        ? null
                        : (value) => setState(() => _messagesEnabled = value),
                    secondary: const Icon(Icons.schedule_send_outlined),
                    title: Text(l10n.businessWhatsappMessagesEnabledLabel),
                    subtitle: Text(l10n.businessWhatsappMessagesEnabledHelper),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (canUseLocationMapping)
                    SwitchListTile.adaptive(
                      value: _allowLocationMapping,
                      onChanged: !_whatsappEnabled || _isLoading
                          ? null
                          : (value) =>
                                setState(() => _allowLocationMapping = value),
                      secondary: const Icon(Icons.alt_route_outlined),
                      title: Text(l10n.businessWhatsappLocationMappingLabel),
                      subtitle: Text(
                        l10n.businessWhatsappLocationMappingHelper,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.businessWhatsappExistingClientsOptInPolicyLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  RadioListTile<String>.adaptive(
                    value: 'explicit_only',
                    groupValue: _existingClientsOptInPolicy,
                    onChanged: !_whatsappEnabled || _isLoading
                        ? null
                        : (value) => setState(
                            () => _existingClientsOptInPolicy = value!,
                          ),
                    title: Text(
                      l10n.businessWhatsappExistingClientsExplicitOnlyLabel,
                    ),
                    subtitle: Text(
                      l10n.businessWhatsappExistingClientsExplicitOnlyHelper,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>.adaptive(
                    value: 'assume_existing_consented',
                    groupValue: _existingClientsOptInPolicy,
                    onChanged: !_whatsappEnabled || _isLoading
                        ? null
                        : (value) => setState(
                            () => _existingClientsOptInPolicy = value!,
                          ),
                    title: Text(
                      l10n.businessWhatsappExistingClientsAssumeConsentedLabel,
                    ),
                    subtitle: Text(
                      l10n.businessWhatsappExistingClientsAssumeConsentedHelper,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_settings != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.whatsappFieldStatus}: ${_settings!.status}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: _isLoading || _isSaving ? null : _save,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showBusinessWhatsappSettingsDialog(
  BuildContext context, {
  required int businessId,
  required String businessName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => BusinessWhatsappSettingsDialog(
      businessId: businessId,
      businessName: businessName,
    ),
  );
}
