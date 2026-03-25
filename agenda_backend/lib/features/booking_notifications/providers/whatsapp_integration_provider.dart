import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/whatsapp_location_mapping.dart';
import '/core/models/whatsapp_config.dart';
import '/core/models/whatsapp_go_live_check.dart';
import '/core/models/whatsapp_outbox_item.dart';
import '/core/network/api_client.dart';
import '/core/network/network_providers.dart';

class WhatsappIntegrationState {
  final List<WhatsappConfig> configs;
  final List<WhatsappLocationMapping> mappings;
  final List<WhatsappOutboxItem> outbox;
  final bool isLoading;
  final String? error;

  const WhatsappIntegrationState({
    this.configs = const [],
    this.mappings = const [],
    this.outbox = const [],
    this.isLoading = false,
    this.error,
  });

  WhatsappIntegrationState copyWith({
    List<WhatsappConfig>? configs,
    List<WhatsappLocationMapping>? mappings,
    List<WhatsappOutboxItem>? outbox,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WhatsappIntegrationState(
      configs: configs ?? this.configs,
      mappings: mappings ?? this.mappings,
      outbox: outbox ?? this.outbox,
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait<dynamic>([
        _api.getBusinessWhatsappConfigs(businessId),
        _api.getWhatsappLocationMappings(businessId),
        _api.getWhatsappOutbox(businessId: businessId, limit: 100, offset: 0),
      ]);
      state = state.copyWith(
        configs: results[0] as List<WhatsappConfig>,
        mappings: results[1] as List<WhatsappLocationMapping>,
        outbox: results[2] as List<WhatsappOutboxItem>,
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
      resolveConfigForLocation(locationId) != null;

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
