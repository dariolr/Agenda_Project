import 'package:flutter/foundation.dart';

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

  const Business({
    required this.id,
    required this.name,
    required this.slug,
    this.email,
    this.phone,
    this.timezone = 'Europe/Rome',
    this.currency = 'EUR',
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
    );
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
