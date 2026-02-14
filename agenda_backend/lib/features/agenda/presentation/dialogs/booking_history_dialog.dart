import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Mostra il dialog/bottom sheet con lo storico di una prenotazione
Future<void> showBookingHistoryDialog(
  BuildContext context,
  WidgetRef ref, {
  required int bookingId,
}) async {
  final formFactor = ref.read(formFactorProvider);

  final content = _BookingHistoryContent(bookingId: bookingId);

  if (formFactor == AppFormFactor.desktop) {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: content,
        ),
      ),
    );
  } else {
    await AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      builder: (_) => content,
      heightFactor: 0.7,
    );
  }
}

class _BookingHistoryContent extends ConsumerStatefulWidget {
  const _BookingHistoryContent({required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<_BookingHistoryContent> createState() =>
      _BookingHistoryContentState();
}

class _BookingHistoryContentState
    extends ConsumerState<_BookingHistoryContent> {
  List<Map<String, dynamic>>? _events;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getBookingHistory(
        bookingId: widget.bookingId,
      );

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response['events'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.bookingHistoryTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Content
        Flexible(child: _buildContent(l10n, theme)),
      ],
    );
  }

  Widget _buildContent(dynamic l10n, ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.bookingHistoryLoading),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.bookingHistoryError,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      );
    }

    if (_events == null || _events!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: theme.hintColor),
              const SizedBox(height: 16),
              Text(
                l10n.bookingHistoryEmpty,
                style: TextStyle(color: theme.hintColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _events!.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final event = _events![index];
        return _EventTile(event: event);
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    final eventType = event['event_type'] as String? ?? 'unknown';
    final actorType = event['actor_type'] as String? ?? 'system';
    final actorName = event['actor_name'] as String?;
    final createdAt = event['created_at'] as String?;
    final payload = event['payload'] as Map<String, dynamic>? ?? {};

    final (icon, color, title) = _getEventDisplay(eventType, payload, l10n);
    final actorLabel = actorName ?? _getActorLabel(actorType, l10n);

    // Format date with locale-adaptive format
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final dateStr = DateFormat.yMMMd(locale).format(date);
        final timeStr = DateFormat.Hm(locale).format(date);
        formattedDate = '$dateStr, $timeStr';
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    // Build user-friendly description based on event type and payload
    final description = _buildDescription(eventType, payload, locale);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(description, style: theme.textTheme.bodySmall),
            ),
          Text(
            '$formattedDate • $actorLabel',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
      isThreeLine: description != null,
    );
  }

  String? _buildDescription(
    String eventType,
    Map<String, dynamic> payload,
    String locale,
  ) {
    switch (eventType) {
      case 'appointment_updated':
        return _describeAppointmentUpdate(payload, locale);
      case 'booking_created':
        return _describeBookingCreated(payload, locale);
      case 'booking_cancelled':
        return _describeBookingCancelled(payload, locale);
      case 'booking_item_added':
        return _describeItemAdded(payload);
      case 'booking_item_deleted':
        return _describeItemDeleted(payload);
      case 'booking_updated':
        return _describeBookingUpdate(payload);
      default:
        return null;
    }
  }

  String? _describeAppointmentUpdate(
    Map<String, dynamic> payload,
    String locale,
  ) {
    final before = payload['before'] as Map<String, dynamic>? ?? {};
    final after = payload['after'] as Map<String, dynamic>? ?? {};
    final changedFields =
        (payload['changed_fields'] as List<dynamic>?)?.cast<String>() ?? [];

    if (changedFields.isEmpty) return null;

    final descriptions = <String>[];

    // Check for time/duration changes
    final beforeStart = _parseTime(before['start_time']);
    final beforeEnd = _parseTime(before['end_time']);
    final afterStart = _parseTime(after['start_time']);
    final afterEnd = _parseTime(after['end_time']);

    if (beforeStart != null &&
        beforeEnd != null &&
        afterStart != null &&
        afterEnd != null) {
      final beforeDuration = beforeEnd.difference(beforeStart).inMinutes;
      final afterDuration = afterEnd.difference(afterStart).inMinutes;

      final startChanged = changedFields.contains('start_time');
      final endChanged = changedFields.contains('end_time');

      if (startChanged && endChanged) {
        // Both changed - check if it's a move or resize
        if (beforeDuration == afterDuration) {
          // Same duration = moved
          descriptions.add(
            'Orario spostato da ${_formatTimeWithOptionalDate(beforeStart, locale, reference: afterStart)} a ${_formatTimeWithOptionalDate(afterStart, locale, reference: beforeStart)}',
          );
        } else {
          // Different duration = resized and possibly moved
          if (beforeStart != afterStart) {
            descriptions.add(
              'Orario spostato da ${_formatTimeWithOptionalDate(beforeStart, locale, reference: afterStart)} a ${_formatTimeWithOptionalDate(afterStart, locale, reference: beforeStart)}',
            );
          }
          descriptions.add(
            'Durata modificata da ${_formatDuration(beforeDuration)} a ${_formatDuration(afterDuration)}, termina alle ${_formatTimeWithOptionalDate(afterEnd, locale, reference: afterStart)}',
          );
        }
      } else if (endChanged && !startChanged) {
        // Only end changed = resize
        descriptions.add(
          'Durata modificata da ${_formatDuration(beforeDuration)} a ${_formatDuration(afterDuration)}, termina alle ${_formatTimeWithOptionalDate(afterEnd, locale, reference: afterStart)}',
        );
      } else if (startChanged && !endChanged) {
        // Only start changed (rare)
        descriptions.add(
          'Orario inizio modificato da ${_formatTimeWithOptionalDate(beforeStart, locale, reference: afterStart)} a ${_formatTimeWithOptionalDate(afterStart, locale, reference: beforeStart)}',
        );
      }
    }

    // Check for staff change
    if (changedFields.contains('staff_id')) {
      final beforeStaff = before['staff_id'];
      final afterStaff = after['staff_id'];
      if (beforeStaff != afterStaff) {
        final beforeStaffName = before['staff_name'] as String?;
        final afterStaffName = after['staff_name'] as String?;
        if (beforeStaffName != null && afterStaffName != null) {
          descriptions.add(
            'Operatore cambiato da $beforeStaffName a $afterStaffName',
          );
        } else {
          descriptions.add('Operatore cambiato');
        }
      }
    }

    // Check for price change
    if (changedFields.contains('price')) {
      final beforePrice = (before['price'] as num?)?.toDouble();
      final afterPrice = (after['price'] as num?)?.toDouble();
      if (beforePrice != null && afterPrice != null) {
        descriptions.add(
          'Prezzo modificato da €${beforePrice.toStringAsFixed(2)} a €${afterPrice.toStringAsFixed(2)}',
        );
      }
    }

    return descriptions.isNotEmpty ? descriptions.join('\n') : null;
  }

  String? _describeBookingCreated(Map<String, dynamic> payload, String locale) {
    final items = payload['items'] as List<dynamic>?;
    final totalPrice = (payload['total_price'] as num?)?.toDouble();
    final firstStartTime = payload['first_start_time'] as String?;

    final parts = <String>[];

    // Data e ora
    if (firstStartTime != null) {
      try {
        final dateTime = DateTime.parse(firstStartTime);
        final dateStr = DateFormat.yMMMd(locale).format(dateTime);
        final timeStr = DateFormat.Hm(locale).format(dateTime);
        parts.add('$dateStr alle $timeStr');
      } catch (_) {}
    }

    // Staff (dal primo item)
    if (items != null && items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>?;
      final staffName = firstItem?['staff_name'] as String?;
      if (staffName != null && staffName.isNotEmpty) {
        parts.add('con $staffName');
      }
    }

    // Servizi e prezzo
    if (items != null && items.isNotEmpty) {
      parts.add(
        '${items.length} ${items.length == 1 ? 'servizio' : 'servizi'}',
      );
    }

    if (totalPrice != null && totalPrice > 0) {
      parts.add('€${totalPrice.toStringAsFixed(2)}');
    }

    return parts.isNotEmpty ? parts.join(' • ') : null;
  }

  String? _describeBookingCancelled(
    Map<String, dynamic> payload,
    String locale,
  ) {
    final items = payload['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      return '${items.length} ${items.length == 1 ? 'appuntamento cancellato' : 'appuntamenti cancellati'}';
    }
    return null;
  }

  String? _describeItemAdded(Map<String, dynamic> payload) {
    // Il nome servizio può essere in item_data.service_name_snapshot o direttamente in payload
    final itemData = payload['item_data'] as Map<String, dynamic>? ?? {};
    final serviceName =
        itemData['service_name_snapshot'] as String? ??
        payload['service_name'] as String?;
    final price =
        (itemData['price'] as num?)?.toDouble() ??
        (payload['price'] as num?)?.toDouble();

    if (serviceName != null && serviceName.isNotEmpty) {
      if (price != null && price > 0) {
        return 'Aggiunto: $serviceName • €${price.toStringAsFixed(2)}';
      }
      return 'Aggiunto: $serviceName';
    }
    return null;
  }

  String? _describeItemDeleted(Map<String, dynamic> payload) {
    // Il nome servizio può essere in deleted_item o direttamente in payload
    final deletedItem = payload['deleted_item'] as Map<String, dynamic>? ?? {};
    final serviceName =
        deletedItem['service_name_snapshot'] as String? ??
        deletedItem['service_name'] as String? ??
        payload['service_name'] as String?;

    if (serviceName != null && serviceName.isNotEmpty) {
      return 'Rimosso: $serviceName';
    }
    return null;
  }

  String? _describeBookingUpdate(Map<String, dynamic> payload) {
    final changedFields =
        (payload['changed_fields'] as List<dynamic>?)?.cast<String>() ?? [];
    final before = payload['before'] as Map<String, dynamic>? ?? {};
    final after = payload['after'] as Map<String, dynamic>? ?? {};

    final descriptions = <String>[];

    if (changedFields.contains('client_id') ||
        changedFields.contains('customer_name')) {
      final beforeName = before['customer_name'] as String?;
      final afterName = after['customer_name'] as String?;
      if (beforeName != null && afterName != null && beforeName != afterName) {
        descriptions.add('Cliente cambiato da "$beforeName" a "$afterName"');
      } else if (afterName != null) {
        descriptions.add('Cliente assegnato: $afterName');
      }
    }

    if (changedFields.contains('notes')) {
      descriptions.add('Note modificate');
    }

    if (changedFields.contains('status')) {
      final afterStatus = after['status'] as String?;
      if (afterStatus != null) {
        descriptions.add('Stato: $afterStatus');
      }
    }

    return descriptions.isNotEmpty ? descriptions.join('\n') : null;
  }

  DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatTime(DateTime time, String locale) {
    return DateFormat.Hm(locale).format(time);
  }

  String _formatTimeWithOptionalDate(
    DateTime value,
    String locale, {
    DateTime? reference,
  }) {
    final includeDate =
        reference == null || !DateUtils.isSameDay(value, reference);
    if (!includeDate) {
      return _formatTime(value, locale);
    }
    final date = DateFormat.yMMMd(locale).format(value);
    final time = _formatTime(value, locale);
    return '$date $time';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}min';
  }

  (IconData, Color, String) _getEventDisplay(
    String eventType,
    Map<String, dynamic> payload,
    dynamic l10n,
  ) {
    switch (eventType) {
      case 'booking_created':
        return (
          Icons.add_circle_outline,
          Colors.green,
          l10n.bookingHistoryEventCreated,
        );
      case 'booking_updated':
        return (
          Icons.edit_outlined,
          Colors.blue,
          l10n.bookingHistoryEventUpdated,
        );
      case 'booking_cancelled':
        return (
          Icons.cancel_outlined,
          Colors.red,
          l10n.bookingHistoryEventCancelled,
        );
      case 'booking_item_added':
        return (
          Icons.add_box_outlined,
          Colors.teal,
          l10n.bookingHistoryEventItemAdded,
        );
      case 'booking_item_deleted':
        return (
          Icons.indeterminate_check_box_outlined,
          Colors.orange,
          l10n.bookingHistoryEventItemDeleted,
        );
      case 'appointment_updated':
        // Genera titolo dinamico in base ai campi modificati
        final title = _getAppointmentUpdateTitle(payload, l10n);
        return (Icons.update, Colors.purple, title);
      case 'booking_replaced':
      case 'booking_created_by_replace':
        return (
          Icons.swap_horiz,
          Colors.indigo,
          l10n.bookingHistoryEventReplaced,
        );
      default:
        return (Icons.info_outline, Colors.grey, eventType);
    }
  }

  /// Genera un titolo specifico per appointment_updated in base ai campi modificati
  String _getAppointmentUpdateTitle(
    Map<String, dynamic> payload,
    dynamic l10n,
  ) {
    final changedFields =
        (payload['changed_fields'] as List<dynamic>?)?.cast<String>() ?? [];

    if (changedFields.isEmpty) {
      return l10n.bookingHistoryEventAppointmentUpdated;
    }

    // Se cambiano più di un tipo di campo, usa titolo generico
    final hasTimeChange =
        changedFields.contains('start_time') ||
        changedFields.contains('end_time');
    final hasStaffChange = changedFields.contains('staff_id');
    final hasPriceChange = changedFields.contains('price');

    final changeCount = [
      hasTimeChange,
      hasStaffChange,
      hasPriceChange,
    ].where((b) => b).length;

    if (changeCount > 1) {
      // Modifiche multiple, usa titolo generico
      return l10n.bookingHistoryEventUpdated;
    }

    // Singola modifica, usa titolo specifico
    if (hasStaffChange) {
      return l10n.bookingHistoryEventStaffChanged;
    }
    if (hasPriceChange) {
      return l10n.bookingHistoryEventPriceChanged;
    }
    if (hasTimeChange) {
      // Determina se è cambio orario o solo durata
      final before = payload['before'] as Map<String, dynamic>? ?? {};
      final after = payload['after'] as Map<String, dynamic>? ?? {};
      final beforeStart = _parseTime(before['start_time']);
      final afterStart = _parseTime(after['start_time']);

      if (beforeStart != null &&
          afterStart != null &&
          beforeStart != afterStart) {
        return l10n.bookingHistoryEventTimeChanged;
      }
      // Solo end_time cambiato = cambio durata
      return l10n.bookingHistoryEventDurationChanged;
    }

    return l10n.bookingHistoryEventAppointmentUpdated;
  }

  String _getActorLabel(String actorType, dynamic l10n) {
    switch (actorType) {
      case 'staff':
        return l10n.bookingHistoryActorStaff;
      case 'customer':
        return l10n.bookingHistoryActorCustomer;
      case 'system':
        return l10n.bookingHistoryActorSystem;
      default:
        return actorType;
    }
  }
}
