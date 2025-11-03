import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class Service {
  final int id;
  final String name;
  final int? duration; // minuti
  final double? price; // costo singolo in euro
  final Color? color;

  const Service({
    required this.id,
    required this.name,
    this.duration,
    this.price,
    this.color,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'],
    name: json['name'],
    duration: json['duration'],
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    color: json['color_hex'] != null
        ? ColorUtils.fromHex(json['color_hex'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (duration != null) 'duration': duration,
    if (price != null) 'price': price,
    if (color != null) 'color_hex': ColorUtils.toHex(color!),
  };
}
