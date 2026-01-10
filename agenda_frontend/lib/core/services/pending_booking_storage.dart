import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_request.dart';
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
  final Map<int, Staff?> staffByService;
  final Staff? selectedStaff;
  final bool anyOperatorSelected;
  final TimeSlot? selectedSlot;
  final String? notes;
  final DateTime savedAt;

  const PendingBookingData({
    required this.businessId,
    required this.locationId,
    this.selectedLocation,
    required this.services,
    required this.staffByService,
    this.selectedStaff,
    required this.anyOperatorSelected,
    this.selectedSlot,
    this.notes,
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
    'staffByService': staffByService.map(
      (k, v) => MapEntry(k.toString(), v?.toJson()),
    ),
    'selectedStaff': selectedStaff?.toJson(),
    'anyOperatorSelected': anyOperatorSelected,
    'selectedSlot': selectedSlot?.toJson(),
    'notes': notes,
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
      staffByService: request.selectedStaffByService,
      selectedStaff: request.selectedStaff,
      anyOperatorSelected: request.anyOperatorSelected,
      selectedSlot: request.selectedSlot,
      notes: request.notes,
      savedAt: DateTime.now(),
    );
  }

  /// Converte in BookingRequest
  BookingRequest toBookingRequest() {
    return BookingRequest(
      services: services,
      selectedStaffByService: staffByService,
      selectedStaff: selectedStaff,
      anyOperatorSelected: anyOperatorSelected,
      selectedSlot: selectedSlot,
      notes: notes,
    );
  }
}

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
