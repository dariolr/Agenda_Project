import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class Staff {
  final int id;
  final int businessId;
  final String name;
  final String surname;
  final Color color;
  final List<int> locationIds;

  const Staff({
    required this.id,
    required this.businessId,
    required this.name,
    required this.surname,
    required this.color,
    required this.locationIds,
  });

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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'surname': surname,
        'color_hex': ColorUtils.toHex(color),
        'location_ids': locationIds,
      };

  bool worksAtLocation(int locationId) =>
      locationIds.isEmpty || locationIds.contains(locationId);
}
