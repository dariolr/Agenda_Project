import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class Service {
  final int id;
  final int businessId;
  final int categoryId;
  final String name;
  final int? duration; // minuti
  final double? price; // costo singolo in euro
  final Color? color;
  final String? description;

  const Service({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    this.duration,
    this.price,
    this.color,
    this.description,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as int,
        businessId: json['business_id'] as int,
        categoryId: json['category_id'] as int,
        name: json['name'] as String,
        duration: json['duration'] as int?,
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        color: json['color_hex'] != null
            ? ColorUtils.fromHex(json['color_hex'] as String)
            : null,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'category_id': categoryId,
        'name': name,
        if (duration != null) 'duration': duration,
        if (price != null) 'price': price,
        if (color != null) 'color_hex': ColorUtils.toHex(color!),
        if (description != null) 'description': description,
      };
}
