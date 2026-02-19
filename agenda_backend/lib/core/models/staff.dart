import 'package:flutter/material.dart';

import '../utils/initials_utils.dart';
import '../utils/color_utils.dart';

class Staff {
  final int id;
  final int businessId;
  final String name;
  final String surname;
  final Color color;
  final List<int> locationIds;
  final List<int> serviceIds;
  final int sortOrder; // 🔹 ordine in agenda
  final bool isDefault; // 🔹 staff predefinito
  final bool isBookableOnline; // 🔹 abilitato alle prenotazioni online

  const Staff({
    required this.id,
    required this.businessId,
    required this.name,
    required this.surname,
    required this.color,
    required this.locationIds,
    this.serviceIds = const [],
    this.sortOrder = 0,
    this.isDefault = false,
    this.isBookableOnline = true,
  });

  Staff copyWith({
    int? id,
    int? businessId,
    String? name,
    String? surname,
    Color? color,
    List<int>? locationIds,
    List<int>? serviceIds,
    int? sortOrder,
    bool? isDefault,
    bool? isBookableOnline,
  }) => Staff(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    surname: surname ?? this.surname,
    color: color ?? this.color,
    locationIds: locationIds ?? this.locationIds,
    serviceIds: serviceIds ?? this.serviceIds,
    sortOrder: sortOrder ?? this.sortOrder,
    isDefault: isDefault ?? this.isDefault,
    isBookableOnline: isBookableOnline ?? this.isBookableOnline,
  );

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    name: json['name'] as String,
    surname: json['surname'] as String? ?? '',
    color: json['color_hex'] != null
        ? ColorUtils.fromHex(json['color_hex'] as String)
        : ColorUtils.fromHex('#FFD700'),
    locationIds: (json['location_ids'] as List<dynamic>? ?? [])
        .map((id) => id as int)
        .toList(),
    serviceIds: (json['service_ids'] as List<dynamic>? ?? [])
        .map((id) => id as int)
        .toList(),
    sortOrder: json['sort_order'] as int? ?? 0,
    isDefault: json['is_default'] as bool? ?? false,
    isBookableOnline: json['is_bookable_online'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'name': name,
    'surname': surname,
    'color_hex': ColorUtils.toHex(color),
    'location_ids': locationIds,
    'service_ids': serviceIds,
    'sort_order': sortOrder,
    'is_default': isDefault,
    'is_bookable_online': isBookableOnline,
  };

  bool worksAtLocation(int locationId) =>
      locationIds.isEmpty || locationIds.contains(locationId);

  String get displayName {
    if (surname.isEmpty) return name;
    return '$name $surname';
  }

  String get initials {
    final fullName = '$name $surname'.trim();
    return InitialsUtils.fromName(fullName, maxChars: 3);
  }
}
