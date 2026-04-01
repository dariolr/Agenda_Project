import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/business.dart';
import '/core/models/location.dart';
import '/core/models/whatsapp_config.dart';
import '/core/models/whatsapp_location_mapping.dart';
import '/core/models/whatsapp_outbox_item.dart';
import '/core/network/network_providers.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/booking_notifications/providers/whatsapp_integration_provider.dart';

final whatsappLocationsByBusinessProvider =
    FutureProvider.family<List<Location>, int>((ref, businessId) async {
      final api = ref.read(apiClientProvider);
      final response = await api.getLocations(businessId);
      return response
          .map((raw) => Location.fromJson(Map<String, dynamic>.from(raw)))
          .where((location) => location.isActive)
          .toList(growable: false);
    });

class WhatsappManagementPanel extends ConsumerStatefulWidget {
  const WhatsappManagementPanel({
    super.key,
    required this.businessId,
    required this.requireBusinessSelection,
    required this.businesses,
    required this.selectedBusinessId,
    required this.onBusinessChanged,
  });

  final int? businessId;
  final bool requireBusinessSelection;
  final List<Business> businesses;
  final int? selectedBusinessId;
  final ValueChanged<int?> onBusinessChanged;

  @override
  ConsumerState<WhatsappManagementPanel> createState() =>
      _WhatsappManagementPanelState();
}

class _WhatsappManagementPanelState
    extends ConsumerState<WhatsappManagementPanel> {
  int? _testLocationId;
  final _testBookingIdController = TextEditingController();
  final _testClientIdController = TextEditingController();
  final _testRecipientController = TextEditingController();
  final _testTemplateController = TextEditingController(
    text: 'booking_reminder_24h',
  );
  final _testVariablesController = TextEditingController(
    text: '{"client_name":"Mario","date":"2026-03-25","time":"10:30"}',
  );

  bool _isRunningCheck = false;
  bool _isRunningWorker = false;
  bool _isQueueingTest = false;
  bool _isCreatingConfig = false;
  bool _isApplyingMappings = false;
  Map<String, bool>? _lastGoLiveChecks;
  String? _lastGoLiveScopeLabel;

  int? get _businessId => widget.businessId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfPossible();
    });
  }

  @override
  void didUpdateWidget(covariant WhatsappManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId) {
      _lastGoLiveChecks = null;
      _lastGoLiveScopeLabel = null;
      _loadIfPossible();
    }
  }

  @override
  void dispose() {
    _testBookingIdController.dispose();
    _testClientIdController.dispose();
    _testRecipientController.dispose();
    _testTemplateController.dispose();
    _testVariablesController.dispose();
    super.dispose();
  }

  Future<void> _loadIfPossible() async {
    final businessId = _businessId;
    if (businessId == null || businessId <= 0) return;
    await ref
        .read(whatsappIntegrationProvider.notifier)
        .loadBusinessWhatsappData(businessId);
  }

  String _statusLabel(BuildContext context, WhatsappConfigStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      WhatsappConfigStatus.active => l10n.whatsappStatusActive,
      WhatsappConfigStatus.inactive => l10n.whatsappStatusInactive,
      WhatsappConfigStatus.pending => l10n.whatsappStatusPending,
      WhatsappConfigStatus.error => l10n.whatsappStatusError,
    };
  }

  Color _statusColor(ThemeData theme, WhatsappConfigStatus status) {
    return switch (status) {
      WhatsappConfigStatus.active => Colors.green.shade700,
      WhatsappConfigStatus.inactive => theme.colorScheme.onSurfaceVariant,
      WhatsappConfigStatus.pending => Colors.orange.shade700,
      WhatsappConfigStatus.error => theme.colorScheme.error,
    };
  }

  String _outboxStatusLabel(BuildContext context, WhatsappOutboxStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      WhatsappOutboxStatus.queued => l10n.bookingNotificationsStatusPending,
      WhatsappOutboxStatus.sent => l10n.bookingNotificationsStatusSent,
      WhatsappOutboxStatus.delivered => l10n.whatsappOutboxDelivered,
      WhatsappOutboxStatus.read => l10n.whatsappOutboxRead,
      WhatsappOutboxStatus.failed => l10n.bookingNotificationsStatusFailed,
    };
  }

  Future<void> _runGoLiveCheck({int? locationId, String? scopeLabel}) async {
    final businessId = _businessId;
    if (businessId == null) return;
    setState(() => _isRunningCheck = true);
    try {
      final check = await ref
          .read(whatsappIntegrationProvider.notifier)
          .runGoLiveCheck(businessId: businessId, locationId: locationId);
      if (!mounted) return;
      setState(() {
        _lastGoLiveChecks = {
          'phone': check.phoneNumberActive,
          'webhook': check.webhookVerified,
          'template': check.templateApproved,
          'optin': check.optInActive,
        };
        _lastGoLiveScopeLabel = scopeLabel;
      });
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunningCheck = false);
      }
    }
  }

  Future<void> _runLocationGoLiveCheck(List<Location> locations) async {
    if (locations.isEmpty) return;
    final l10n = context.l10n;
    int selectedLocationId = locations.first.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(l10n.whatsappGoLiveCheckLocation),
              content: DropdownButtonFormField<int>(
                value: selectedLocationId,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.whatsappFieldLocation,
                ),
                items: locations
                    .map(
                      (location) => DropdownMenuItem<int>(
                        value: location.id,
                        child: Text(location.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setStateDialog(() => selectedLocationId = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.whatsappGoLiveCheckLocation),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final selectedLocation = locations
        .where((location) => location.id == selectedLocationId)
        .cast<Location?>()
        .firstWhere((location) => location != null, orElse: () => null);
    if (selectedLocation == null) return;

    await _runGoLiveCheck(
      locationId: selectedLocation.id,
      scopeLabel: '${l10n.whatsappFieldLocation}: ${selectedLocation.name}',
    );
  }

  Future<void> _runWorker() async {
    final businessId = _businessId;
    if (businessId == null) return;
    setState(() => _isRunningWorker = true);
    try {
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .runOutboxWorker(businessId);
      if (!mounted) return;
      await FeedbackDialog.showSuccess(
        context,
        title: context.l10n.whatsappSavedSuccessTitle,
        message: context.l10n.whatsappWorkerCompleted,
      );
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunningWorker = false);
      }
    }
  }

  Future<void> _showConfigDialog({WhatsappConfig? initial}) async {
    final businessId = _businessId;
    if (businessId == null) return;
    final l10n = context.l10n;

    final wabaController = TextEditingController(text: initial?.wabaId ?? '');
    final phoneController = TextEditingController(
      text: initial?.phoneNumberId ?? '',
    );
    final tokenController = TextEditingController(
      text: initial?.accessTokenEncrypted ?? '',
    );
    var status = initial?.status ?? WhatsappConfigStatus.pending;
    var isDefault = initial?.isDefault ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                initial == null
                    ? l10n.whatsappAddConfig
                    : l10n.whatsappEditConfig,
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.whatsappFieldPhoneNumberId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: wabaController,
                      decoration: InputDecoration(
                        labelText: l10n.whatsappFieldWabaId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tokenController,
                      decoration: InputDecoration(
                        labelText: l10n.whatsappFieldAccessToken,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<WhatsappConfigStatus>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: l10n.whatsappFieldStatus,
                        border: const OutlineInputBorder(),
                      ),
                      items: WhatsappConfigStatus.values
                          .map(
                            (value) => DropdownMenuItem<WhatsappConfigStatus>(
                              value: value,
                              child: Text(_statusLabel(context, value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() => status = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.whatsappFieldDefault),
                      value: isDefault,
                      onChanged: (value) =>
                          setStateDialog(() => isDefault = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final phone = phoneController.text.trim();
                    final waba = wabaController.text.trim();
                    final token = tokenController.text.trim();
                    if (phone.isEmpty || waba.isEmpty || token.isEmpty) {
                      await FeedbackDialog.showError(
                        context,
                        title: l10n.errorTitle,
                        message: l10n.whatsappValidationRequired,
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(l10n.actionSave),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    setState(() => _isCreatingConfig = true);
    try {
      final api = ref.read(apiClientProvider);
      if (initial == null) {
        await api.createBusinessWhatsappConfig(
          businessId: businessId,
          wabaId: wabaController.text.trim(),
          phoneNumberId: phoneController.text.trim(),
          accessTokenEncrypted: tokenController.text.trim(),
          status: whatsappConfigStatusToString(status),
          isDefault: isDefault,
        );
      } else {
        await api.updateBusinessWhatsappConfig(
          businessId: businessId,
          configId: initial.id,
          wabaId: wabaController.text.trim(),
          phoneNumberId: phoneController.text.trim(),
          accessTokenEncrypted: tokenController.text.trim(),
          status: whatsappConfigStatusToString(status),
          isDefault: isDefault,
        );
      }
      await _loadIfPossible();
      if (!mounted) return;
      await FeedbackDialog.showSuccess(
        context,
        title: l10n.whatsappSavedSuccessTitle,
        message: l10n.whatsappSavedSuccessMessage,
      );
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingConfig = false);
      }
    }
  }

  Future<void> _deleteConfig(WhatsappConfig config) async {
    final businessId = _businessId;
    if (businessId == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.whatsappDeleteConfigTitle),
        content: Text(l10n.whatsappDeleteConfigMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .deleteBusinessWhatsappConfig(
            businessId: businessId,
            configId: config.id,
          );
      await _loadIfPossible();
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: e.toString(),
      );
    }
  }

  Future<void> _setDefaultConfig(WhatsappConfig config) async {
    final businessId = _businessId;
    if (businessId == null) return;
    try {
      await ref
          .read(apiClientProvider)
          .updateBusinessWhatsappConfig(
            businessId: businessId,
            configId: config.id,
            isDefault: true,
          );
      await _loadIfPossible();
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: e.toString(),
      );
    }
  }

  Future<void> _applyLocationMapping({
    required Location location,
    required int? configId,
    required List<WhatsappLocationMapping> mappings,
  }) async {
    final businessId = _businessId;
    if (businessId == null) return;
    final existing = mappings
        .where((m) => m.locationId == location.id)
        .cast<WhatsappLocationMapping?>()
        .firstWhere((m) => m != null, orElse: () => null);

    setState(() => _isApplyingMappings = true);
    try {
      if (configId == null) {
        if (existing != null) {
          await ref
              .read(whatsappIntegrationProvider.notifier)
              .deleteLocationMapping(
                businessId: businessId,
                mappingId: existing.id,
              );
        }
      } else {
        await ref
            .read(whatsappIntegrationProvider.notifier)
            .upsertLocationMapping(
              businessId: businessId,
              locationId: location.id,
              whatsappConfigId: configId,
            );
      }
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplyingMappings = false);
      }
    }
  }

  Future<void> _queueTestMessage({required bool sendNow}) async {
    final businessId = _businessId;
    final locationId = _testLocationId;
    if (businessId == null || locationId == null) return;

    final bookingId = int.tryParse(_testBookingIdController.text.trim());
    final clientId = int.tryParse(_testClientIdController.text.trim());
    final recipient = _testRecipientController.text.trim();
    final template = _testTemplateController.text.trim();

    if (bookingId == null ||
        clientId == null ||
        recipient.isEmpty ||
        template.isEmpty) {
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.whatsappValidationRequired,
      );
      return;
    }

    Map<String, dynamic> payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(_testVariablesController.text.trim());
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      } else {
        throw const FormatException('Expected object');
      }
    } catch (_) {
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.whatsappInvalidJson,
      );
      return;
    }

    setState(() => _isQueueingTest = true);
    try {
      await ref
          .read(apiClientProvider)
          .setWhatsappOptIn(
            businessId: businessId,
            clientId: clientId,
            optIn: true,
          );

      final item = await ref
          .read(whatsappIntegrationProvider.notifier)
          .enqueueTemplateMessage(
            businessId: businessId,
            locationId: locationId,
            bookingId: bookingId,
            recipientPhone: recipient,
            templateName: template,
            variables: payload,
            optIn: true,
          );
      if (item != null && sendNow) {
        await ref
            .read(apiClientProvider)
            .sendWhatsappOutboxItem(businessId: businessId, outboxId: item.id);
      }
      await _loadIfPossible();
      if (!mounted) return;
      await FeedbackDialog.showSuccess(
        context,
        title: context.l10n.whatsappSavedSuccessTitle,
        message: sendNow
            ? context.l10n.whatsappQueuedAndSent
            : context.l10n.whatsappQueuedOnly,
      );
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isQueueingTest = false);
      }
    }
  }

  Future<void> _sendOrRetryOutbox(WhatsappOutboxItem item) async {
    final businessId = _businessId;
    if (businessId == null) return;
    try {
      if (item.status == WhatsappOutboxStatus.failed) {
        await ref
            .read(apiClientProvider)
            .retryWhatsappOutboxItem(businessId: businessId, outboxId: item.id);
      } else {
        await ref
            .read(apiClientProvider)
            .sendWhatsappOutboxItem(businessId: businessId, outboxId: item.id);
      }
      await _loadIfPossible();
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (widget.requireBusinessSelection && _businessId == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.whatsappSelectBusinessHint,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: widget.selectedBusinessId,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.profileSwitchBusiness,
                    ),
                    items: widget.businesses
                        .map(
                          (business) => DropdownMenuItem<int?>(
                            value: business.id,
                            child: Text(business.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: widget.onBusinessChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final businessId = _businessId!;
    final state = ref.watch(whatsappIntegrationProvider);
    final locationsAsync = ref.watch(
      whatsappLocationsByBusinessProvider(businessId),
    );
    final locationsLoaded = locationsAsync.maybeWhen(
      data: (_) => true,
      orElse: () => false,
    );
    final locations = locationsAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <Location>[],
    );
    final hasNoLocations = locationsLoaded && locations.isEmpty;
    final hasSingleLocation = locations.length == 1;
    final singleLocation = hasSingleLocation ? locations.first : null;
    if (singleLocation != null && _testLocationId != singleLocation.id) {
      _testLocationId = singleLocation.id;
    }
    final configs = state.configs;
    final hasActiveConfig = configs.any((config) => config.isActive);
    final outbox = state.outbox;
    final queuedCount = outbox
        .where((item) => item.status == WhatsappOutboxStatus.queued)
        .length;
    final failedCount = outbox
        .where((item) => item.status == WhatsappOutboxStatus.failed)
        .length;

    return RefreshIndicator(
      onRefresh: _loadIfPossible,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                label: l10n.whatsappStatsConfigs,
                value: '${configs.length}',
                icon: Icons.settings_rounded,
              ),
              if (!hasSingleLocation)
                _StatCard(
                  label: l10n.whatsappStatsMappings,
                  value: '${state.mappings.length}',
                  icon: Icons.alt_route_rounded,
                ),
              _StatCard(
                label: l10n.whatsappStatsQueued,
                value: '$queuedCount',
                icon: Icons.schedule_send_rounded,
              ),
              _StatCard(
                label: l10n.whatsappStatsFailed,
                value: '$failedCount',
                icon: Icons.error_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.whatsappPanelTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.whatsappPanelSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.isLoading ? null : _loadIfPossible,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.whatsappRefresh),
                      ),
                      FilledButton.icon(
                        onPressed: _isRunningCheck || !hasActiveConfig
                            ? null
                            : () => _runGoLiveCheck(
                                scopeLabel: l10n.whatsappGoLiveScopeBusiness,
                              ),
                        icon: _isRunningCheck
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: Text(l10n.whatsappGoLiveCheckBusiness),
                      ),
                      if (!hasSingleLocation)
                        locationsAsync.when(
                          data: (locations) => FilledButton.icon(
                          onPressed: _isRunningCheck || locations.isEmpty
                              || !hasActiveConfig
                              ? null
                              : () => _runLocationGoLiveCheck(locations),
                            icon: const Icon(Icons.place_outlined),
                            label: Text(l10n.whatsappGoLiveCheckLocation),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                        ),
                      FilledButton.tonalIcon(
                        onPressed: _isRunningWorker || !hasActiveConfig
                            ? null
                            : _runWorker,
                        icon: _isRunningWorker
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_circle_outline_rounded),
                        label: Text(l10n.whatsappRunWorker),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (hasNoLocations) ...[
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.whatsappNoLocationBannerTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.whatsappNoLocationBannerMessage),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => context.go('/altro/sedi?from_altro=1'),
                      icon: const Icon(Icons.add_business_outlined),
                      label: Text(l10n.whatsappCreateLocationCta),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _GoLiveChecksCard(
            checks: _lastGoLiveChecks,
            scopeLabel: _lastGoLiveScopeLabel,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.whatsappConfigsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _isCreatingConfig ? null : _showConfigDialog,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.whatsappAddConfig),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (configs.isEmpty)
                    Text(
                      l10n.whatsappNoConfigs,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...configs.map((config) {
                      final chipColor = _statusColor(theme, config.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        config.phoneNumberId,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: chipColor.withValues(
                                            alpha: 0.16,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(context, config.status),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: chipColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      if (config.isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.whatsappFieldDefault,
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('WABA: ${config.wabaId}'),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                IconButton(
                                  tooltip: l10n.actionEdit,
                                  onPressed: _isCreatingConfig
                                      ? null
                                      : () =>
                                            _showConfigDialog(initial: config),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: l10n.whatsappFieldDefault,
                                  onPressed: config.isDefault
                                      ? null
                                      : () => _setDefaultConfig(config),
                                  icon: const Icon(Icons.star_outline_rounded),
                                ),
                                IconButton(
                                  tooltip: l10n.actionDelete,
                                  onPressed: _isCreatingConfig
                                      ? null
                                      : () => _deleteConfig(config),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.whatsappLocationMappingTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  locationsAsync.when(
                    data: (locations) {
                      if (locations.isEmpty) {
                        return Text(
                          l10n.whatsappNoLocations,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      if (locations.length == 1) {
                        return Text(
                          l10n.whatsappSingleLocationMappingHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return Column(
                        children: locations
                            .map((location) {
                              final mapping = state.mappings
                                  .where((m) => m.locationId == location.id)
                                  .cast<WhatsappLocationMapping?>()
                                  .firstWhere(
                                    (m) => m != null,
                                    orElse: () => null,
                                  );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(location.name)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<int?>(
                                        value: mapping?.whatsappConfigId,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        items: [
                                          DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text(
                                              l10n.whatsappUnassigned,
                                            ),
                                          ),
                                          ...configs.map(
                                            (config) => DropdownMenuItem<int?>(
                                              value: config.id,
                                              child: Text(
                                                '${config.phoneNumberId} (${_statusLabel(context, config.status)})',
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: _isApplyingMappings
                                            ? null
                                            : (value) => _applyLocationMapping(
                                                location: location,
                                                configId: value,
                                                mappings: state.mappings,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(growable: false),
                      );
                    },
                    error: (error, _) => Text(error.toString()),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.whatsappTestSendTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (hasNoLocations) ...[
                    Text(
                      l10n.whatsappNoLocations,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => context.go('/altro/sedi?from_altro=1'),
                      icon: const Icon(Icons.add_business_outlined),
                      label: Text(l10n.whatsappCreateLocationCta),
                    ),
                  ] else ...[
                    locationsAsync.when(
                      data: (locations) {
                        final selectedValid =
                            _testLocationId != null &&
                            locations.any((l) => l.id == _testLocationId);
                        if (!selectedValid && locations.isNotEmpty) {
                          _testLocationId = locations.first.id;
                        }
                        if (locations.length == 1) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              '${l10n.whatsappFieldLocation}: ${locations.first.name}',
                            ),
                          );
                        }
                        return DropdownButtonFormField<int?>(
                          value: _testLocationId,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.whatsappFieldLocation,
                          ),
                          items: locations
                              .map(
                                (location) => DropdownMenuItem<int?>(
                                  value: location.id,
                                  child: Text(location.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) =>
                              setState(() => _testLocationId = value),
                        );
                      },
                      error: (_, __) => const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _testBookingIdController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: l10n.whatsappFieldBookingId,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _testClientIdController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: l10n.whatsappFieldClientId,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: TextField(
                            controller: _testRecipientController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: l10n.whatsappFieldRecipientPhone,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _testTemplateController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.whatsappFieldTemplateName,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _testVariablesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.whatsappFieldTemplateVariables,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isQueueingTest || !hasActiveConfig
                              ? null
                              : () => _queueTestMessage(sendNow: false),
                          icon: const Icon(Icons.outbox_outlined),
                          label: Text(l10n.whatsappQueueTest),
                        ),
                        FilledButton.icon(
                          onPressed: _isQueueingTest || !hasActiveConfig
                              ? null
                              : () => _queueTestMessage(sendNow: true),
                          icon: _isQueueingTest
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(l10n.whatsappQueueAndSendTest),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.whatsappOutboxTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (outbox.isEmpty)
                    Text(
                      l10n.whatsappOutboxEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...outbox.take(20).map((item) {
                      final canAction =
                          item.status == WhatsappOutboxStatus.queued ||
                          item.status == WhatsappOutboxStatus.failed;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${item.templateName} • ${item.recipientPhone}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_outboxStatusLabel(context, item.status)} • ${l10n.whatsappLastUpdate}: ${item.updatedAt?.toLocal().toString().split(".").first ?? "-"}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: canAction
                            ? TextButton.icon(
                                onPressed: () => _sendOrRetryOutbox(item),
                                icon: Icon(
                                  item.status == WhatsappOutboxStatus.failed
                                      ? Icons.refresh_rounded
                                      : Icons.send_rounded,
                                ),
                                label: Text(
                                  item.status == WhatsappOutboxStatus.failed
                                      ? l10n.whatsappRetryNow
                                      : l10n.whatsappSendNow,
                                ),
                              )
                            : null,
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleLarge),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoLiveChecksCard extends StatelessWidget {
  const _GoLiveChecksCard({required this.checks, required this.scopeLabel});

  final Map<String, bool>? checks;
  final String? scopeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final data = checks;
    final allOk = data != null && data.values.every((value) => value);

    Widget buildRow(String label, bool value) {
      return Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel_outlined,
            color: value ? Colors.green.shade700 : theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.whatsappGoLiveCheck,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (data == null)
              Text(
                l10n.whatsappGoLiveHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                allOk ? l10n.whatsappGoLiveReady : l10n.whatsappGoLiveNotReady,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: allOk
                      ? Colors.green.shade700
                      : theme.colorScheme.error,
                ),
              ),
              if (scopeLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  scopeLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              buildRow(
                l10n.whatsappCheckPhoneNumberActive,
                data['phone'] == true,
              ),
              const SizedBox(height: 6),
              buildRow(
                l10n.whatsappCheckWebhookVerified,
                data['webhook'] == true,
              ),
              const SizedBox(height: 6),
              buildRow(
                l10n.whatsappCheckTemplateApproved,
                data['template'] == true,
              ),
              const SizedBox(height: 6),
              buildRow(l10n.whatsappCheckOptInActive, data['optin'] == true),
            ],
          ],
        ),
      ),
    );
  }
}
