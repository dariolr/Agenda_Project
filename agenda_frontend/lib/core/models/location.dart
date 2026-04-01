import 'package:flutter/foundation.dart';

/// Modello Location (sede)
@immutable
class Location {
  final int id;
  final int businessId;
  final String name;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? currency;
  final String timezone;
  final bool allowCustomerChooseStaff;
  final String staffIconKey;
  final int? cancellationHours;
  final bool isDefault;
  final int maxBookingAdvanceDays;
  final int onlineBookingSlotIntervalMinutes;
  final Map<String, Map<String, String>>? bookingTextOverrides;

  const Location({
    required this.id,
    required this.businessId,
    required this.name,
    this.address,
    this.city,
    this.region,
    this.country,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.currency,
    this.timezone = 'Europe/Rome',
    this.allowCustomerChooseStaff = false,
    this.staffIconKey = 'person',
    this.cancellationHours,
    this.isDefault = false,
    this.maxBookingAdvanceDays = 90,
    this.onlineBookingSlotIntervalMinutes = 15,
    this.bookingTextOverrides,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
      timezone: json['timezone'] as String? ?? 'Europe/Rome',
      allowCustomerChooseStaff:
          json['allow_customer_choose_staff'] as bool? ?? false,
      staffIconKey: (json['staff_icon_key'] as String?) ?? 'person',
      cancellationHours: json['cancellation_hours'] as int?,
      isDefault: json['is_default'] as bool? ?? false,
      maxBookingAdvanceDays: json['max_booking_advance_days'] as int? ?? 90,
      onlineBookingSlotIntervalMinutes:
          json['online_booking_slot_interval_minutes'] as int? ?? 15,
      bookingTextOverrides: _parseBookingTextOverrides(
        json['booking_text_overrides'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'address': address,
      'city': city,
      'region': region,
      'country': country,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'currency': currency,
      'timezone': timezone,
      'allow_customer_choose_staff': allowCustomerChooseStaff,
      'staff_icon_key': staffIconKey,
      if (cancellationHours != null) 'cancellation_hours': cancellationHours,
      'is_default': isDefault,
      'max_booking_advance_days': maxBookingAdvanceDays,
      'online_booking_slot_interval_minutes': onlineBookingSlotIntervalMinutes,
      if (bookingTextOverrides != null)
        'booking_text_overrides': bookingTextOverrides,
    };
  }

  /// Indirizzo formattato per visualizzazione
  String get formattedAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Location(id: $id, name: $name, city: $city)';
}

Map<String, Map<String, String>>? _parseBookingTextOverrides(dynamic raw) {
  if (raw is! Map) return null;

  final result = <String, Map<String, String>>{};
  for (final entry in raw.entries) {
    final locale = entry.key.toString().trim();
    if (locale.isEmpty || entry.value is! Map) {
      continue;
    }

    final phrasesRaw = entry.value as Map;
    final phrases = <String, String>{};
    for (final phraseEntry in phrasesRaw.entries) {
      final key = phraseEntry.key.toString().trim();
      final value = phraseEntry.value?.toString().trim() ?? '';
      if (key.isEmpty || value.isEmpty) {
        continue;
      }
      phrases[key] = value;
    }
    if (phrases.isNotEmpty) {
      result[locale.toLowerCase()] = phrases;
    }
  }

  return result.isEmpty ? null : result;
}
