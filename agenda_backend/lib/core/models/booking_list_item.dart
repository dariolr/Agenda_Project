import 'package:flutter/material.dart';

import '/core/l10n/l10_extension.dart';
import 'appointment.dart';

/// Model per la visualizzazione nella lista prenotazioni.
/// Include dati aggregati (servizi, staff, date) per evitare join lato client.
class BookingListItem {
  final int id;
  final int businessId;
  final int locationId;
  final String? locationName;
  final int? clientId;
  final String? clientName;
  final String? clientEmail;
  final String? clientPhone;
  final String? notes;
  final String status;
  final String source;

  // Date aggregate
  final DateTime? firstStartTime;
  final DateTime? lastEndTime;
  final double totalPrice;

  // Liste aggregate (nomi separati da virgola)
  final String? serviceNames;
  final String? staffNames;

  // Info creazione
  final DateTime? createdAt;
  final String? creatorName;

  // Ricorrenza
  final int? recurrenceRuleId;
  final int? recurrenceIndex;

  // Items dettagliati (opzionale, per espansione)
  final List<Appointment>? items;

  const BookingListItem({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.locationName,
    this.clientId,
    this.clientName,
    this.clientEmail,
    this.clientPhone,
    this.notes,
    this.status = 'confirmed',
    this.source = 'online',
    this.firstStartTime,
    this.lastEndTime,
    this.totalPrice = 0,
    this.serviceNames,
    this.staffNames,
    this.createdAt,
    this.creatorName,
    this.recurrenceRuleId,
    this.recurrenceIndex,
    this.items,
  });

  /// Se è ricorrente
  bool get isRecurring => recurrenceRuleId != null;

  /// Status label localizzato
  String statusLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (status) {
      case 'confirmed':
        return l10n.bookingsListStatusConfirmed;
      case 'cancelled':
        return l10n.bookingsListStatusCancelled;
      case 'completed':
        return l10n.bookingsListStatusCompleted;
      case 'no_show':
        return l10n.bookingsListStatusNoShow;
      case 'pending':
        return l10n.bookingsListStatusPending;
      default:
        return status;
    }
  }

  /// Source label localizzato
  String sourceLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (source) {
      case 'online':
      case 'onlinestaff':
        return l10n.bookingsListSourceOnline;
      case 'phone':
        return l10n.bookingsListSourcePhone;
      case 'walk_in':
        return l10n.bookingsListSourceWalkIn;
      case 'internal':
        return l10n.bookingsListSourceInternal;
      default:
        return source;
    }
  }

  /// Colore status
  Color get statusColor {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'no_show':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Icona source
  IconData get sourceIcon {
    switch (source) {
      case 'online':
      case 'onlinestaff':
        return Icons.cloud_outlined;
      case 'phone':
        return Icons.phone;
      case 'walk_in':
        return Icons.person;
      case 'internal':
        return Icons.desktop_windows;
      default:
        return Icons.help_outline;
    }
  }

  factory BookingListItem.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;

    return BookingListItem(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      locationId: json['location_id'] as int,
      locationName: json['location_name'] as String?,
      clientId: json['client_id'] as int?,
      clientName: json['client_name'] as String?,
      clientEmail: json['client_email'] as String?,
      clientPhone: json['client_phone'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'confirmed',
      source: json['source'] as String? ?? 'online',
      firstStartTime: json['first_start_time'] != null
          ? DateTime.parse(json['first_start_time'] as String)
          : null,
      lastEndTime: json['last_end_time'] != null
          ? DateTime.parse(json['last_end_time'] as String)
          : null,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      serviceNames: json['service_names'] as String?,
      staffNames: json['staff_names'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      creatorName: json['creator_name'] as String?,
      recurrenceRuleId: json['recurrence_rule_id'] as int?,
      recurrenceIndex: json['recurrence_index'] as int?,
      items: itemsJson
          ?.map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'location_id': locationId,
    if (locationName != null) 'location_name': locationName,
    if (clientId != null) 'client_id': clientId,
    if (clientName != null) 'client_name': clientName,
    if (clientEmail != null) 'client_email': clientEmail,
    if (clientPhone != null) 'client_phone': clientPhone,
    if (notes != null) 'notes': notes,
    'status': status,
    'source': source,
    if (firstStartTime != null)
      'first_start_time': firstStartTime!.toIso8601String(),
    if (lastEndTime != null) 'last_end_time': lastEndTime!.toIso8601String(),
    'total_price': totalPrice,
    if (serviceNames != null) 'service_names': serviceNames,
    if (staffNames != null) 'staff_names': staffNames,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (creatorName != null) 'creator_name': creatorName,
    if (recurrenceRuleId != null) 'recurrence_rule_id': recurrenceRuleId,
    if (recurrenceIndex != null) 'recurrence_index': recurrenceIndex,
    if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
  };
}

/// Risultato paginato della lista prenotazioni
class BookingListResult {
  final List<BookingListItem> bookings;
  final int total;
  final int limit;
  final int offset;

  const BookingListResult({
    required this.bookings,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// Indica se ci sono altre pagine
  bool get hasMore => offset + bookings.length < total;

  /// Numero pagina corrente (0-based)
  int get currentPage => limit > 0 ? offset ~/ limit : 0;

  /// Numero totale di pagine
  int get totalPages => limit > 0 ? (total + limit - 1) ~/ limit : 1;

  factory BookingListResult.fromJson(Map<String, dynamic> json) {
    final bookingsJson = json['bookings'] as List<dynamic>;
    return BookingListResult(
      bookings: bookingsJson
          .map((e) => BookingListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }
}
