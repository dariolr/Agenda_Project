import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_request.dart';
import '../models/class_event.dart';
import '../models/location.dart';
import '../models/service.dart';
import '../models/staff.dart';
import '../models/time_slot.dart';

/// Dati della prenotazione in sospeso
class PendingBookingData {
  final int businessId;
  final int locationId;
  final Location? selectedLocation;
  final List<Service> services;
  final Set<int> selectedServiceIds;
  final Set<int> selectedPackageIds;
  final Map<int, List<int>> selectedPackageServiceIdsByPackage;
  final Map<int, Staff?> staffByService;
  final Staff? selectedStaff;
  final bool anyOperatorSelected;
  final TimeSlot? selectedSlot;
  final String? notes;
  final ClassEvent? selectedClassEvent;
  final DateTime savedAt;

  const PendingBookingData({
    required this.businessId,
    required this.locationId,
    this.selectedLocation,
    required this.services,
    this.selectedServiceIds = const {},
    this.selectedPackageIds = const {},
    this.selectedPackageServiceIdsByPackage = const {},
    required this.staffByService,
    this.selectedStaff,
    required this.anyOperatorSelected,
    this.selectedSlot,
    this.notes,
    this.selectedClassEvent,
    required this.savedAt,
  });

  /// Verifica se i dati sono ancora validi (non troppo vecchi)
  bool get isValid {
    // Valido per 1 ora
    final expiry = savedAt.add(const Duration(hours: 1));
    return DateTime.now().isBefore(expiry);
  }

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'locationId': locationId,
    'selectedLocation': selectedLocation?.toJson(),
    'services': services.map((s) => s.toJson()).toList(),
    'selectedServiceIds': selectedServiceIds.toList(),
    'selectedPackageIds': selectedPackageIds.toList(),
    'selectedPackageServiceIdsByPackage': selectedPackageServiceIdsByPackage
        .map((k, v) => MapEntry(k.toString(), v)),
    'staffByService': staffByService.map(
      (k, v) => MapEntry(k.toString(), v?.toJson()),
    ),
    'selectedStaff': selectedStaff?.toJson(),
    'anyOperatorSelected': anyOperatorSelected,
    'selectedSlot': selectedSlot?.toJson(),
    'notes': notes,
    'selectedClassEvent': selectedClassEvent != null
        ? _classEventToJson(selectedClassEvent!)
        : null,
    'savedAt': savedAt.toIso8601String(),
  };

  factory PendingBookingData.fromJson(Map<String, dynamic> json) {
    return PendingBookingData(
      businessId: json['businessId'] as int,
      locationId: json['locationId'] as int,
      selectedLocation: json['selectedLocation'] != null
          ? Location.fromJson(json['selectedLocation'] as Map<String, dynamic>)
          : null,
      services: (json['services'] as List)
          .map((s) => Service.fromJson(s as Map<String, dynamic>))
          .toList(),
      selectedServiceIds: ((json['selectedServiceIds'] as List?) ?? const [])
          .map((id) => (id as num).toInt())
          .toSet(),
      selectedPackageIds: ((json['selectedPackageIds'] as List?) ?? const [])
          .map((id) => (id as num).toInt())
          .toSet(),
      selectedPackageServiceIdsByPackage:
          ((json['selectedPackageServiceIdsByPackage']
                      as Map<String, dynamic>?) ??
                  const {})
              .map(
                (k, v) => MapEntry(
                  int.parse(k),
                  (v as List).map((id) => (id as num).toInt()).toList(),
                ),
              ),
      staffByService: (json['staffByService'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          int.parse(k),
          v != null ? Staff.fromJson(v as Map<String, dynamic>) : null,
        ),
      ),
      selectedStaff: json['selectedStaff'] != null
          ? Staff.fromJson(json['selectedStaff'] as Map<String, dynamic>)
          : null,
      anyOperatorSelected: json['anyOperatorSelected'] as bool? ?? false,
      selectedSlot: json['selectedSlot'] != null
          ? TimeSlot.fromJson(json['selectedSlot'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
      selectedClassEvent: json['selectedClassEvent'] != null
          ? ClassEvent.fromJson(
              json['selectedClassEvent'] as Map<String, dynamic>,
            )
          : null,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  /// Crea da BookingRequest
  factory PendingBookingData.fromBookingRequest({
    required int businessId,
    required int locationId,
    required Location? selectedLocation,
    required BookingRequest request,
  }) {
    return PendingBookingData(
      businessId: businessId,
      locationId: locationId,
      selectedLocation: selectedLocation,
      services: request.services,
      selectedServiceIds: request.selectedServiceIds,
      selectedPackageIds: request.selectedPackageIds,
      selectedPackageServiceIdsByPackage:
          request.selectedPackageServiceIdsByPackage,
      staffByService: request.selectedStaffByService,
      selectedStaff: request.selectedStaff,
      anyOperatorSelected: request.anyOperatorSelected,
      selectedSlot: request.selectedSlot,
      notes: request.notes,
      selectedClassEvent: request.selectedClassEvent,
      savedAt: DateTime.now(),
    );
  }

  /// Converte in BookingRequest
  BookingRequest toBookingRequest() {
    return BookingRequest(
      services: services,
      selectedServiceIds: selectedServiceIds,
      selectedPackageIds: selectedPackageIds,
      selectedPackageServiceIdsByPackage: selectedPackageServiceIdsByPackage,
      selectedStaffByService: staffByService,
      selectedStaff: selectedStaff,
      anyOperatorSelected: anyOperatorSelected,
      selectedSlot: selectedSlot,
      notes: notes,
      selectedClassEvent: selectedClassEvent,
    );
  }
}

Map<String, dynamic> _classEventToJson(ClassEvent event) => {
  'id': event.id,
  'business_id': event.businessId,
  'class_type_id': event.classTypeId,
  'class_type_name': event.classTypeName,
  'class_type_color_hex': event.classTypeColorHex,
  'class_type_service_category_id': event.classTypeServiceCategoryId,
  'class_type_service_category_name': event.classTypeServiceCategoryName,
  'starts_at': event.startsAt,
  'starts_at_local': event.startsAtLocal,
  'ends_at': event.endsAt,
  'ends_at_local': event.endsAtLocal,
  'location_id': event.locationId,
  'staff_id': event.staffId,
  'capacity_total': event.capacityTotal,
  'capacity_reserved': event.capacityReserved,
  'confirmed_count': event.confirmedCount,
  'waitlist_count': event.waitlistCount,
  'waitlist_enabled': event.waitlistEnabled,
  'booking_open_at': event.bookingOpenAt,
  'booking_close_at': event.bookingCloseAt,
  'cancel_cutoff_minutes': event.cancelCutoffMinutes,
  'status': event.status,
  'visibility': event.visibility,
  'online_visibility': event.onlineVisibility,
  'price_cents': event.priceCents,
  'currency': event.currency,
  'spots_left': event.spotsLeft,
  'is_full': event.isFull,
};

/// Servizio per salvare/ripristinare lo stato della prenotazione.
/// Usato quando il token scade durante la conferma.
/// Usa SharedPreferences per compatibilità cross-platform.
class PendingBookingStorage {
  static const _storageKey = 'pending_booking_state';

  /// Salva lo stato della prenotazione
  static Future<void> save(PendingBookingData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = data.toJson();
      final encoded = jsonEncode(json);
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('PendingBookingStorage.save error: $e');
    }
  }

  /// Recupera lo stato salvato (se esiste e valido)
  static Future<PendingBookingData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded == null || encoded.isEmpty) return null;

      final json = jsonDecode(encoded) as Map<String, dynamic>;
      final data = PendingBookingData.fromJson(json);

      // Verifica se ancora valido
      if (!data.isValid) {
        await clear();
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('PendingBookingStorage.load error: $e');
      await clear();
      return null;
    }
  }

  /// Elimina lo stato salvato
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // Ignora errori
    }
  }

  /// Verifica se c'è uno stato salvato
  static Future<bool> hasPendingBooking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded == null || encoded.isEmpty) return false;

      // Verifica anche validità
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      final savedAt = DateTime.parse(json['savedAt'] as String);
      final expiry = savedAt.add(const Duration(hours: 1));
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }
}
