import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class Staff {
  final int id;
  final int businessId;
  final String name;
  final String surname;
  final Color color;
  final List<int> locationIds;
  final int sortOrder; // 🔹 ordine in agenda
  final bool isDefault; // 🔹 staff predefinito

  const Staff({
    required this.id,
    required this.businessId,
    required this.name,
    required this.surname,
    required this.color,
    required this.locationIds,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  Staff copyWith({
    int? id,
    int? businessId,
    String? name,
    String? surname,
    Color? color,
    List<int>? locationIds,
    int? sortOrder,
    bool? isDefault,
  }) => Staff(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    surname: surname ?? this.surname,
    color: color ?? this.color,
    locationIds: locationIds ?? this.locationIds,
    sortOrder: sortOrder ?? this.sortOrder,
    isDefault: isDefault ?? this.isDefault,
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
    sortOrder: json['sort_order'] as int? ?? 0,
    isDefault: json['is_default'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'name': name,
    'surname': surname,
    'color_hex': ColorUtils.toHex(color),
    'location_ids': locationIds,
    'sort_order': sortOrder,
    'is_default': isDefault,
  };

  bool worksAtLocation(int locationId) =>
      locationIds.isEmpty || locationIds.contains(locationId);

  String get displayName {
    if (surname.isEmpty) return name;
    return '$name $surname';
  }

  String get initials {
    final nameInitial = name.isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).first[0].toUpperCase()
        : '';

    final surnameParts = surname.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);

    if (nameInitial.isEmpty && surnameParts.isEmpty) {
      return '';
    }

    var initials = nameInitial;

    if (surnameParts.isNotEmpty) {
      for (final part in surnameParts) {
        initials += part[0].toUpperCase();
        if (initials.length >= 3) break;
      }
    }

    if (initials.length < 3 && surnameParts.isEmpty) {
      final nameParts = name.trim().split(RegExp(r'\s+'))
        ..removeWhere((p) => p.isEmpty);
      if (nameParts.length > 1) {
        for (int i = 1; i < nameParts.length; i++) {
          initials += nameParts[i][0].toUpperCase();
          if (initials.length >= 3) break;
        }
      } else if (name.length > 1) {
        initials += name[1].toUpperCase();
      }
    }

    final endIndex = initials.length.clamp(1, 3).toInt();
    return initials.substring(0, endIndex);
  }
}
