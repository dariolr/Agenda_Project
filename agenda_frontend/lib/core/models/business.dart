import 'package:flutter/material.dart';

/// Modello Business
@immutable
class Business {
  final int id;
  final String name;
  final String slug;
  final String? email;
  final String? phone;
  final String timezone;
  final String currency;
  final int? cancellationHours;
  final int? defaultLocationId;
  final Color? primaryColor;

  const Business({
    required this.id,
    required this.name,
    required this.slug,
    this.email,
    this.phone,
    this.timezone = 'Europe/Rome',
    this.currency = 'EUR',
    this.cancellationHours,
    this.defaultLocationId,
    this.primaryColor,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      timezone: json['timezone'] as String? ?? 'Europe/Rome',
      currency: json['currency'] as String? ?? 'EUR',
      cancellationHours: json['cancellation_hours'] as int?,
      defaultLocationId: json['default_location_id'] as int?,
      primaryColor: _parseColor(json['primary_color'] as String?),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'email': email,
      'phone': phone,
      'timezone': timezone,
      'currency': currency,
      if (cancellationHours != null) 'cancellation_hours': cancellationHours,
      'default_location_id': defaultLocationId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Business && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Business(id: $id, name: $name, slug: $slug)';
}
