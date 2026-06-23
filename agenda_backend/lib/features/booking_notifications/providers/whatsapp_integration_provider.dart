import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/whatsapp_location_mapping.dart';
import '/core/models/business_whatsapp_settings.dart';
import '/core/models/whatsapp_config.dart';
import '/core/models/whatsapp_embedded_signup_result.dart';
import '/core/models/whatsapp_go_live_check.dart';
import '/core/models/whatsapp_outbox_item.dart';
import '/core/models/whatsapp_template.dart';
import '/core/models/whatsapp_template_assignment.dart';
import '/core/network/api_client.dart';
import '/core/network/network_providers.dart';

class WhatsappIntegrationState {
  final int? loadedBusinessId;
  final List<WhatsappConfig> configs;
  final List<WhatsappLocationMapping> mappings;
  final List<WhatsappOutboxItem> outbox;
  final List<WhatsappTemplate> templates;
  final List<WhatsappTemplateAssignment> templateAssignments;
  final BusinessWhatsappSettings? settings;
  final bool isLoading;
  final String? error;

  const WhatsappIntegrationState({
    this.loadedBusinessId,
    this.configs = const [],
    this.mappings = const [],
    this.outbox = const [],
    this.templates = const [],
    this.templateAssignments = const [],
    this.settings,
    this.isLoading = false,
    this.error,
  });

  WhatsappIntegrationState copyWith({
    int? loadedBusinessId,
    bool clearLoadedBusinessId = false,
    List<WhatsappConfig>? configs,
    List<WhatsappLocationMapping>? mappings,
    List<WhatsappOutboxItem>? outbox,
    List<WhatsappTemplate>? templates,
    List<WhatsappTemplateAssignment>? templateAssignments,
    BusinessWhatsappSettings? settings,
    bool clearSettings = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WhatsappIntegrationState(
      loadedBusinessId: clearLoadedBusinessId
          ? null
          : (loadedBusinessId ?? this.loadedBusinessId),
      configs: configs ?? this.configs,
      mappings: mappings ?? this.mappings,
      outbox: outbox ?? this.outbox,
      templates: templates ?? this.templates,
      templateAssignments: templateAssignments ?? this.templateAssignments,
      settings: clearSettings ? null : (settings ?? this.settings),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final whatsappIntegrationProvider =
    NotifierProvider<WhatsappIntegrationNotifier, WhatsappIntegrationState>(
      WhatsappIntegrationNotifier.new,
    );

class WhatsappIntegrationNotifier extends Notifier<WhatsappIntegrationState> {
  final Set<String> _processedWebhookEventIds = <String>{};

  @override
  WhatsappIntegrationState build() => const WhatsappIntegrationState();

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> loadBusinessWhatsappData(int businessId) async {
    state = state.copyWith(
      loadedBusinessId: businessId,
      configs: const [],
      mappings: const [],
      outbox: const [],
      templates: const [],
      templateAssignments: const [],
      clearSettings: true,
      isLoading: true,
      clearError: true,
    );
    try {
      final results = await Future.wait<dynamic>([
        _api.getBusinessWhatsappSettings(businessId),
        _api.getBusinessWhatsappConfigs(businessId),
        _api.getWhatsappLocationMappings(businessId),
        _api.getWhatsappOutbox(businessId: businessId, limit: 100, offset: 0),
        _api.getWhatsappTemplates(businessId),
        _api.getWhatsappTemplateAssignments(businessId),
      ]);
      state = state.copyWith(
        loadedBusinessId: businessId,
        settings: results[0] as BusinessWhatsappSettings,
        configs: results[1] as List<WhatsappConfig>,
        mappings: results[2] as List<WhatsappLocationMapping>,
        outbox: results[3] as List<WhatsappOutboxItem>,
        templates: results[4] as List<WhatsappTemplate>,
        templateAssignments: results[5] as List<WhatsappTemplateAssignment>,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  WhatsappConfig? resolveConfigForLocation(int locationId) {
    final mapping = state.mappings
        .where((m) => m.locationId == locationId)
        .cast<WhatsappLocationMapping?>()
        .firstWhere((m) => m != null, orElse: () => null);
    if (mapping != null) {
      final specific = state.configs
          .where((c) => c.id == mapping.whatsappConfigId && c.isActive)
          .cast<WhatsappConfig?>()
          .firstWhere((c) => c != null, orElse: () => null);
      if (specific != null) return specific;
    }

    final businessDefault = state.configs
        .where((c) => c.isDefault && c.isActive)
        .cast<WhatsappConfig?>()
        .firstWhere((c) => c != null, orElse: () => null);
    if (businessDefault != null) return businessDefault;

    return null;
  }

  bool canSendForLocation(int locationId) =>
      (state.settings?.canSendMessages ?? false) &&
      resolveConfigForLocation(locationId) != null;

  Future<void> updateBusinessMessageSending({
    required int businessId,
    required bool enabled,
  }) async {
    final settings = await _api.updateBusinessWhatsappSettings(
      businessId: businessId,
      payload: {'business_messages_enabled': enabled},
    );
    state = state.copyWith(settings: settings);
  }

  Future<void> upsertLocationMapping({
    required int businessId,
    required int locationId,
    required int whatsappConfigId,
  }) async {
    await _api.upsertWhatsappLocationMapping(
      businessId: businessId,
      locationId: locationId,
      whatsappConfigId: whatsappConfigId,
    );
    await loadBusinessWhatsappData(businessId);
  }

  Future<void> deleteLocationMapping({
    required int businessId,
    required int mappingId,
  }) async {
    await _api.deleteWhatsappLocationMapping(
      businessId: businessId,
      mappingId: mappingId,
    );
    await loadBusinessWhatsappData(businessId);
  }

  Future<void> deleteBusinessWhatsappConfig({
    required int businessId,
    required int configId,
  }) async {
    await _api.deleteBusinessWhatsappConfig(
      businessId: businessId,
      configId: configId,
    );
    await loadBusinessWhatsappData(businessId);
  }

  Future<void> upsertTemplate({
    required int businessId,
    int? templateId,
    required String templateName,
    required String languageCode,
    required String messageType,
    required String status,
    bool isGlobal = false,
    String? bodyPreview,
  }) async {
    await _api.upsertWhatsappTemplate(
      businessId: businessId,
      templateId: templateId,
      templateName: templateName,
      languageCode: languageCode,
      messageType: messageType,
      status: status,
      isGlobal: isGlobal,
      bodyPreview: bodyPreview,
    );
    await loadBusinessWhatsappData(businessId);
  }

  Future<void> disableTemplate({
    required int businessId,
    required int templateId,
  }) async {
    await _api.disableWhatsappTemplate(
      businessId: businessId,
      templateId: templateId,
    );
    await loadBusinessWhatsappData(businessId);
  }

  Future<Map<String, dynamic>> submitDefaultTemplate({
    required int businessId,
  }) async {
    final result = await _api.submitDefaultWhatsappTemplate(businessId);
    await loadBusinessWhatsappData(businessId);
    return result;
  }

  Future<void> upsertTemplateAssignment({
    required int businessId,
    int? locationId,
    required String messageType,
    required String languageCode,
    required int whatsappTemplateId,
  }) async {
    await _api.upsertWhatsappTemplateAssignment(
      businessId: businessId,
      locationId: locationId,
      messageType: messageType,
      languageCode: languageCode,
      whatsappTemplateId: whatsappTemplateId,
    );
    await loadBusinessWhatsappData(businessId);
  }

  Future<void> deleteTemplateAssignment({
    required int businessId,
    required int assignmentId,
  }) async {
    await _api.deleteWhatsappTemplateAssignment(
      businessId: businessId,
      assignmentId: assignmentId,
    );
    await loadBusinessWhatsappData(businessId);
  }

  Future<WhatsappOutboxItem?> enqueueTemplateMessage({
    required int businessId,
    required int locationId,
    required int bookingId,
    required String recipientPhone,
    required String templateName,
    required Map<String, dynamic> variables,
    required bool optIn,
    String templateLanguage = 'it',
    DateTime? scheduledAt,
  }) async {
    if (!optIn) {
      state = state.copyWith(error: 'Opt-in WhatsApp non attivo');
      return null;
    }

    final config = resolveConfigForLocation(locationId);
    if (config == null) {
      return null;
    }

    final message = await _api.enqueueWhatsappTemplateMessage(
      businessId: businessId,
      locationId: locationId,
      bookingId: bookingId,
      recipientPhone: recipientPhone,
      templateName: templateName,
      templateLanguage: templateLanguage,
      templateVariables: variables,
      optIn: optIn,
      scheduledAt: scheduledAt,
    );

    state = state.copyWith(outbox: [message, ...state.outbox]);
    return message;
  }

  Future<void> enqueue24hReminder({
    required int businessId,
    required int locationId,
    required int bookingId,
    required String recipientPhone,
    required Map<String, dynamic> variables,
    required bool optIn,
  }) async {
    await enqueueTemplateMessage(
      businessId: businessId,
      locationId: locationId,
      bookingId: bookingId,
      recipientPhone: recipientPhone,
      templateName: 'booking_reminder_24h',
      variables: variables,
      optIn: optIn,
    );
  }

  Future<void> enqueue2hReminder({
    required int businessId,
    required int locationId,
    required int bookingId,
    required String recipientPhone,
    required Map<String, dynamic> variables,
    required bool optIn,
  }) async {
    await enqueueTemplateMessage(
      businessId: businessId,
      locationId: locationId,
      bookingId: bookingId,
      recipientPhone: recipientPhone,
      templateName: 'booking_reminder_2h',
      variables: variables,
      optIn: optIn,
    );
  }

  Future<void> runOutboxWorker(int businessId) async {
    final queued = state.outbox
        .where((m) => m.status == WhatsappOutboxStatus.queued)
        .toList(growable: false);

    for (final item in queued) {
      try {
        await _api.sendWhatsappOutboxItem(
          businessId: businessId,
          outboxId: item.id,
        );
      } on ApiException catch (e) {
        final isRetryable = e.statusCode == 429 || e.statusCode >= 500;
        if (isRetryable) {
          await _api.retryWhatsappOutboxItem(
            businessId: businessId,
            outboxId: item.id,
          );
        } else {
          await _api.updateWhatsappOutboxStatus(
            businessId: businessId,
            outboxId: item.id,
            status: whatsappOutboxStatusToString(WhatsappOutboxStatus.failed),
            errorMessage: e.message,
          );
        }
      }
    }

    await loadBusinessWhatsappData(businessId);
  }

  Future<bool> processWebhookPayload({
    required int businessId,
    required Map<String, dynamic> payload,
  }) async {
    final eventId = _extractWebhookEventId(payload);
    if (eventId != null && _processedWebhookEventIds.contains(eventId)) {
      return false;
    }

    await _api.processWhatsappWebhook(
      businessId: businessId,
      payload: payload,
      eventId: eventId,
    );

    if (eventId != null) {
      _processedWebhookEventIds.add(eventId);
      if (_processedWebhookEventIds.length > 1000) {
        _processedWebhookEventIds.remove(_processedWebhookEventIds.first);
      }
    }
    return true;
  }

  Future<WhatsappGoLiveCheck> runGoLiveCheck({
    required int businessId,
    int? locationId,
  }) async {
    return _api.getWhatsappGoLiveCheck(
      businessId: businessId,
      locationId: locationId,
    );
  }

  Future<WhatsappEmbeddedSignupResult> completeEmbeddedSignup({
    required int businessId,
    required String code,
    String? state,
    int? sessionInfoVersion,
    String? wabaId,
    String? phoneNumberId,
    String? displayPhoneNumber,
  }) async {
    final result = await _api.completeWhatsappEmbeddedSignup(
      businessId: businessId,
      code: code,
      state: state,
      sessionInfoVersion: sessionInfoVersion,
      wabaId: wabaId,
      phoneNumberId: phoneNumberId,
      displayPhoneNumber: displayPhoneNumber,
    );
    await loadBusinessWhatsappData(businessId);
    return result;
  }

  Future<String> createEmbeddedSignupState(int businessId) async {
    final response = await _api.createWhatsappEmbeddedSignupState(
      businessId: businessId,
    );
    return response['state']?.toString() ?? '';
  }

  String? _extractWebhookEventId(Map<String, dynamic> payload) {
    final id = payload['event_id'] ?? payload['id'];
    if (id != null && id.toString().trim().isNotEmpty) return id.toString();

    final entry = payload['entry'];
    if (entry is List && entry.isNotEmpty) {
      final firstEntry = entry.first;
      if (firstEntry is Map<String, dynamic>) {
        final changes = firstEntry['changes'];
        if (changes is List && changes.isNotEmpty) {
          final firstChange = changes.first;
          if (firstChange is Map<String, dynamic>) {
            final value = firstChange['value'];
            if (value is Map<String, dynamic>) {
              final statuses = value['statuses'];
              if (statuses is List &&
                  statuses.isNotEmpty &&
                  statuses.first is Map<String, dynamic>) {
                final statusId = (statuses.first as Map<String, dynamic>)['id'];
                if (statusId != null) return statusId.toString();
              }
            }
          }
        }
      }
    }
    return null;
  }
}
