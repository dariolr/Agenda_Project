import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class Service {
  final int id;
  final int businessId;
  final int categoryId;
  final String name;
  final int? duration;
  final int? processingTime; // minuti opzionali post-lavorazione
  final int? blockedTime; // minuti opzionali bloccati
  final double? price;
  final Color? color;
  final String? description;
  final bool isBookableOnline; // 🔹 prenotabile online
  final bool isFree; // 🔹 gratuito
  final bool isPriceStartingFrom; // 🔹 prezzo “a partire da”
  final int sortOrder; // 🔹 posizione nella categoria
  final String? currency; // 🔹 valuta effettiva (es. EUR, USD, GBP...)

  const Service({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    this.duration,
    this.processingTime,
    this.blockedTime,
    this.price,
    this.color,
    this.description,
    this.isBookableOnline = true,
    this.isFree = false,
    this.isPriceStartingFrom = false,
    this.sortOrder = 0,
    this.currency, // 🔹 opzionale (può arrivare da effectiveCurrencyProvider)
  });

  Service copyWith({
    int? id,
    int? businessId,
    int? categoryId,
    String? name,
    int? duration,
    int? processingTime,
    int? blockedTime,
    double? price,
    Color? color,
    String? description,
    bool? isBookableOnline,
    bool? isFree,
    bool? isPriceStartingFrom,
    int? sortOrder,
    String? currency,
  }) => Service(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    duration: duration ?? this.duration,
    processingTime: processingTime ?? this.processingTime,
    blockedTime: blockedTime ?? this.blockedTime,
    price: price ?? this.price,
    color: color ?? this.color,
    description: description ?? this.description,
    isBookableOnline: isBookableOnline ?? this.isBookableOnline,
    isFree: isFree ?? this.isFree,
    isPriceStartingFrom: isPriceStartingFrom ?? this.isPriceStartingFrom,
    sortOrder: sortOrder ?? this.sortOrder,
    currency: currency ?? this.currency,
  );

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    categoryId: json['category_id'] as int,
    name: json['name'] as String,
    duration: json['duration'] as int?,
    processingTime: json['processing_time'] as int?,
    blockedTime: json['blocked_time'] as int?,
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    color: json['color_hex'] != null
        ? ColorUtils.fromHex(json['color_hex'] as String)
        : null,
    description: json['description'] as String?,
    isBookableOnline: json['is_bookable_online'] as bool? ?? true,
    isFree: json['is_free'] as bool? ?? false,
    isPriceStartingFrom: json['is_price_starting_from'] as bool? ?? false,
    sortOrder: json['sort_order'] as int? ?? 0,
    currency: json['currency'] as String?, // 🔹 nuovo campo opzionale
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'category_id': categoryId,
    'name': name,
    if (duration != null) 'duration': duration,
    if (processingTime != null) 'processing_time': processingTime,
    if (blockedTime != null) 'blocked_time': blockedTime,
    if (price != null) 'price': price,
    if (color != null) 'color_hex': ColorUtils.toHex(color!),
    if (description != null) 'description': description,
    'is_bookable_online': isBookableOnline,
    'is_free': isFree,
    'is_price_starting_from': isPriceStartingFrom,
    'sort_order': sortOrder,
    if (currency != null)
      'currency': currency, // 🔹 serializzato solo se presente
  };
}
