import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class Staff {
  final int id;
  final String name;
  final String surname;
  final Color color;

  const Staff({
    required this.id,
    required this.name,
    required this.surname,
    required this.color,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
    id: json['id'],
    name: json['name'],
    surname: json['surname'] ?? '',
    color: json['color_hex'] != null
        ? ColorUtils.fromHex(json['color_hex'])
        : ColorUtils.fromHex('#FFD700'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'surname': surname,
    'color_hex': ColorUtils.toHex(color),
  };
}
