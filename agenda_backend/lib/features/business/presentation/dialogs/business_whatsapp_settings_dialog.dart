import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/business_whatsapp_settings.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/whatsapp_config.dart';
import '../../../../core/models/whatsapp_template.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../../booking_notifications/providers/whatsapp_integration_provider.dart';

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
  static const _messageTypes = [
    'booking_confirmation',
    'booking_reminder',
    'booking_cancellation',
    'booking_reschedule',
    'class_booking_confirmation',
    'class_booking_reminder',
    'class_booking_cancellation',
    'test',
  ];

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
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .loadBusinessWhatsappData(widget.businessId);
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
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .loadBusinessWhatsappData(widget.businessId);

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

  Future<void> _showTemplateDialog({WhatsappTemplate? template}) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(
      text: template?.templateName ?? '',
    );
    final bodyController = TextEditingController(
      text: template?.bodyPreview ?? '',
    );
    var messageType = template?.messageType ?? 'booking_reminder';
    var languageCode = template?.languageCode ?? 'it';
    var status = template?.status ?? 'approved';
    var isGlobal = template != null && template.businessId == null;

    final saved = await AppForm.show<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            template == null
                ? l10n.whatsappTemplateCreateTitle
                : l10n.whatsappTemplateEditTitle,
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.whatsappFieldTemplateName,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: messageType,
                  decoration: InputDecoration(
                    labelText: l10n.whatsappTemplateMessageTypeLabel,
                  ),
                  items: _messageTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) => messageType = value ?? messageType,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: languageCode,
                  decoration: InputDecoration(
                    labelText: l10n.whatsappTemplateLanguageLabel,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'it', child: Text('it')),
                    DropdownMenuItem(value: 'en', child: Text('en')),
                  ],
                  onChanged: (value) => languageCode = value ?? languageCode,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: l10n.whatsappFieldStatus,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('draft')),
                    DropdownMenuItem(
                      value: 'submitted',
                      child: Text('submitted'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'disabled',
                      child: Text('disabled'),
                    ),
                    DropdownMenuItem(value: 'pending', child: Text('pending')),
                    DropdownMenuItem(value: 'paused', child: Text('paused')),
                  ],
                  onChanged: (value) => status = value ?? status,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.whatsappTemplateBodyPreviewLabel,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile.adaptive(
                  value: isGlobal,
                  onChanged: (value) =>
                      setDialogState(() => isGlobal = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.whatsappTemplateGlobalLabel),
                  subtitle: Text(l10n.whatsappTemplateGlobalHelper),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .upsertTemplate(
            businessId: widget.businessId,
            templateId: template?.id,
            templateName: nameController.text.trim(),
            languageCode: languageCode,
            messageType: messageType,
            status: status,
            isGlobal: isGlobal,
            bodyPreview: bodyController.text.trim(),
          );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveAssignment({
    required int? locationId,
    required String messageType,
    required int? templateId,
  }) async {
    if (templateId == null) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .upsertTemplateAssignment(
            businessId: widget.businessId,
            locationId: locationId,
            messageType: messageType,
            languageCode: 'it',
            whatsappTemplateId: templateId,
          );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  WhatsappConfig? _templateSettingsConfig(WhatsappIntegrationState state) {
    final defaultConfig = state.configs
        .where((config) => config.isDefault)
        .cast<WhatsappConfig?>()
        .firstWhere((config) => config != null, orElse: () => null);
    if (defaultConfig != null) return defaultConfig;

    final activeConfig = state.configs
        .where((config) => config.isActive)
        .cast<WhatsappConfig?>()
        .firstWhere((config) => config != null, orElse: () => null);
    if (activeConfig != null) return activeConfig;

    return state.configs.cast<WhatsappConfig?>().firstWhere(
      (config) => config != null,
      orElse: () => null,
    );
  }

  Future<void> _updateTemplateMetaSettings(
    WhatsappConfig config, {
    bool? templateAutoSubmitEnabled,
    String? templateDefaultLanguage,
    String? templateDefaultCategory,
  }) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .updateBusinessWhatsappConfig(
            businessId: widget.businessId,
            configId: config.id,
            templateAutoSubmitEnabled: templateAutoSubmitEnabled,
            templateDefaultLanguage: templateDefaultLanguage,
            templateDefaultCategory: templateDefaultCategory,
          );
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .loadBusinessWhatsappData(widget.businessId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitDefaultTemplate() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(whatsappIntegrationProvider.notifier)
          .submitDefaultTemplate(businessId: widget.businessId);
      if (!mounted) return;

      final status = (result['status'] ?? '').toString();
      final reason = (result['reason'] ?? '').toString();
      final errorMessage = (result['error_message'] ?? '').toString();
      final template = result['template'] is Map
          ? Map<String, dynamic>.from(result['template'] as Map)
          : const <String, dynamic>{};
      final templateName = (template['template_name'] ?? '').toString();
      final details = <String>[
        if (status.isNotEmpty)
          '${context.l10n.whatsappTemplateSubmitStatus}: $status',
        if (templateName.isNotEmpty)
          '${context.l10n.whatsappTemplateSubmitTemplate}: $templateName',
        if (reason.isNotEmpty)
          '${context.l10n.whatsappTemplateSubmitReason}: $reason',
        if (errorMessage.isNotEmpty) errorMessage,
      ].join('\n');

      if (status == 'error') {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.whatsappTemplateSubmitErrorTitle,
          message: details.isEmpty
              ? context.l10n.whatsappTemplateSubmitErrorMessage
              : details,
        );
        return;
      }

      await FeedbackDialog.showSuccess(
        context,
        title: context.l10n.whatsappTemplateSubmitSuccessTitle,
        message: details.isEmpty
            ? context.l10n.whatsappTemplateSubmitSuccessMessage
            : details,
      );
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.whatsappTemplateSubmitErrorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  int? _selectedTemplateId(
    WhatsappIntegrationState state, {
    required int? locationId,
    required String messageType,
  }) {
    return state.templateAssignments
        .where(
          (assignment) =>
              assignment.locationId == locationId &&
              assignment.messageType == messageType &&
              assignment.languageCode == 'it',
        )
        .map((assignment) => assignment.whatsappTemplateId)
        .cast<int?>()
        .firstWhere((value) => value != null, orElse: () => null);
  }

  int? _assignmentId(
    WhatsappIntegrationState state, {
    required int? locationId,
    required String messageType,
  }) {
    return state.templateAssignments
        .where(
          (assignment) =>
              assignment.locationId == locationId &&
              assignment.messageType == messageType &&
              assignment.languageCode == 'it',
        )
        .map((assignment) => assignment.id)
        .cast<int?>()
        .firstWhere((value) => value != null, orElse: () => null);
  }

  Future<void> _deleteAssignment(int? assignmentId) async {
    if (assignmentId == null) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .deleteTemplateAssignment(
            businessId: widget.businessId,
            assignmentId: assignmentId,
          );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canUseLocationMapping = _locations.length > 1;
    final whatsappState = ref.watch(whatsappIntegrationProvider);
    final templateSettingsConfig = _templateSettingsConfig(whatsappState);
    final templateLanguageOptions = <String>{
      'it',
      'en',
      if (templateSettingsConfig != null)
        templateSettingsConfig.templateDefaultLanguage,
    }.where((value) => value.trim().isNotEmpty).toList(growable: false);

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
                  const SizedBox(height: 16),
                  ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.settings_phone_outlined),
                    title: Text(l10n.whatsappConfigsTitle),
                    children: [
                      if (whatsappState.configs.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(l10n.whatsappNoConfigs),
                        )
                      else
                        for (final config in whatsappState.configs)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              config.displayPhoneNumber ?? config.phoneNumberId,
                            ),
                            subtitle: Text(
                              '${l10n.whatsappFieldStatus}: ${config.status.name}',
                            ),
                            trailing: config.isDefault
                                ? const Icon(Icons.star_outline)
                                : null,
                          ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.whatsappTemplatesSectionTitle),
                    children: [
                      if (templateSettingsConfig == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(l10n.whatsappNoConfigs),
                        )
                      else ...[
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value:
                              templateSettingsConfig.templateAutoSubmitEnabled,
                          onChanged: _isSaving
                              ? null
                              : (value) => _updateTemplateMetaSettings(
                                  templateSettingsConfig,
                                  templateAutoSubmitEnabled: value,
                                ),
                          title: Text(l10n.whatsappTemplateAutoSubmitEnabled),
                          subtitle: Text(l10n.whatsappTemplateAutoSubmitHint),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: templateSettingsConfig
                                    .templateDefaultLanguage,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.whatsappTemplateDefaultLanguage,
                                  border: const OutlineInputBorder(),
                                ),
                                items: templateLanguageOptions
                                    .map(
                                      (language) => DropdownMenuItem(
                                        value: language,
                                        child: Text(language),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        _updateTemplateMetaSettings(
                                          templateSettingsConfig,
                                          templateDefaultLanguage: value,
                                        );
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: templateSettingsConfig
                                    .templateDefaultCategory,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.whatsappTemplateDefaultCategory,
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'utility',
                                    child: Text(
                                      l10n.whatsappTemplateCategoryUtility,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'marketing',
                                    child: Text(
                                      l10n.whatsappTemplateCategoryMarketing,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'authentication',
                                    child: Text(
                                      l10n.whatsappTemplateCategoryAuthentication,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'service',
                                    child: Text(
                                      l10n.whatsappTemplateCategoryService,
                                    ),
                                  ),
                                ],
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        _updateTemplateMetaSettings(
                                          templateSettingsConfig,
                                          templateDefaultCategory: value,
                                        );
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.whatsappTemplateDefaultsHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed:
                                  _isSaving || templateSettingsConfig == null
                                  ? null
                                  : _submitDefaultTemplate,
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: Text(l10n.whatsappTemplateSubmitAction),
                            ),
                            TextButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _showTemplateDialog(),
                              icon: const Icon(Icons.add_outlined),
                              label: Text(l10n.whatsappTemplateAddAction),
                            ),
                          ],
                        ),
                      ),
                      if (whatsappState.templates.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(l10n.whatsappTemplatesEmpty),
                        )
                      else
                        for (final template in whatsappState.templates)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(template.templateName),
                            subtitle: Text(
                              '${template.messageType ?? '-'} · ${template.languageCode} · ${template.status} · ${template.businessId == null ? l10n.whatsappTemplateGlobalBadge : l10n.whatsappTemplateBusinessBadge}',
                            ),
                            trailing: IconButton(
                              tooltip: l10n.actionEdit,
                              onPressed: _isSaving
                                  ? null
                                  : () =>
                                        _showTemplateDialog(template: template),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.rule_folder_outlined),
                    title: Text(l10n.whatsappTemplateAssignmentsSectionTitle),
                    children: [
                      for (final messageType in _messageTypes)
                        _TemplateAssignmentRow(
                          label: messageType,
                          templates: whatsappState.templates,
                          selectedTemplateId: _selectedTemplateId(
                            whatsappState,
                            locationId: null,
                            messageType: messageType,
                          ),
                          onChanged: (templateId) => _saveAssignment(
                            locationId: null,
                            messageType: messageType,
                            templateId: templateId,
                          ),
                          onClear: () => _deleteAssignment(
                            _assignmentId(
                              whatsappState,
                              locationId: null,
                              messageType: messageType,
                            ),
                          ),
                        ),
                      if (_locations.isNotEmpty) ...[
                        const Divider(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.whatsappLocationOverridesTitle,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        for (final location in _locations)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(location.name),
                            children: [
                              for (final messageType in _messageTypes)
                                _TemplateAssignmentRow(
                                  label: messageType,
                                  templates: whatsappState.templates,
                                  selectedTemplateId: _selectedTemplateId(
                                    whatsappState,
                                    locationId: location.id,
                                    messageType: messageType,
                                  ),
                                  onChanged: (templateId) => _saveAssignment(
                                    locationId: location.id,
                                    messageType: messageType,
                                    templateId: templateId,
                                  ),
                                  onClear: () => _deleteAssignment(
                                    _assignmentId(
                                      whatsappState,
                                      locationId: location.id,
                                      messageType: messageType,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ],
                  ),
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

class _TemplateAssignmentRow extends StatelessWidget {
  const _TemplateAssignmentRow({
    required this.label,
    required this.templates,
    required this.selectedTemplateId,
    required this.onChanged,
    required this.onClear,
  });

  final String label;
  final List<WhatsappTemplate> templates;
  final int? selectedTemplateId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final approvedTemplates = templates
        .where(
          (template) =>
              template.isApproved &&
              template.languageCode == 'it' &&
              (template.messageType == null || template.messageType == label),
        )
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              value:
                  approvedTemplates.any(
                    (template) => template.id == selectedTemplateId,
                  )
                  ? selectedTemplateId
                  : null,
              isExpanded: true,
              items: approvedTemplates
                  .map(
                    (template) => DropdownMenuItem<int>(
                      value: template.id,
                      child: Text(
                        template.templateName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: approvedTemplates.isEmpty ? null : onChanged,
            ),
          ),
          IconButton(
            tooltip: context.l10n.actionDelete,
            onPressed: selectedTemplateId == null ? null : onClear,
            icon: const Icon(Icons.close_outlined),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showBusinessWhatsappSettingsDialog(
  BuildContext context, {
  required int businessId,
  required String businessName,
}) {
  return AppForm.show<bool>(
    context: context,
    builder: (context) => BusinessWhatsappSettingsDialog(
      businessId: businessId,
      businessName: businessName,
    ),
  );
}
