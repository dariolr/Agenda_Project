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
  final bool isDefault;

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
    this.isDefault = false,
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
      isDefault: json['is_default'] as bool? ?? false,
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
      'is_default': isDefault,
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
