import 'package:flutter/foundation.dart';

/// Modello per un servizio popolare (top 5 più prenotati).
/// Ritornato dall'endpoint /v1/staff/{staff_id}/services/popular
@immutable
class PopularService {
  final int rank;
  final int bookingCount;
  final int serviceId;
  final String serviceName;
  final int? categoryId;
  final String? categoryName;
  final double price;
  final int durationMinutes;
  final String? color;

  const PopularService({
    required this.rank,
    required this.bookingCount,
    required this.serviceId,
    required this.serviceName,
    this.categoryId,
    this.categoryName,
    required this.price,
    required this.durationMinutes,
    this.color,
  });

  factory PopularService.fromJson(Map<String, dynamic> json) {
    return PopularService(
      rank: json['rank'] as int,
      bookingCount: json['booking_count'] as int,
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'booking_count': bookingCount,
    'service_id': serviceId,
    'service_name': serviceName,
    'category_id': categoryId,
    'category_name': categoryName,
    'price': price,
    'duration_minutes': durationMinutes,
    'color': color,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PopularService &&
          runtimeType == other.runtimeType &&
          serviceId == other.serviceId;

  @override
  int get hashCode => serviceId.hashCode;
}

/// Risultato dell'endpoint popular services
@immutable
class PopularServicesResult {
  final List<PopularService> popularServices;
  final int enabledServicesCount;
  final bool showPopularSection;

  const PopularServicesResult({
    required this.popularServices,
    required this.enabledServicesCount,
    required this.showPopularSection,
  });

  factory PopularServicesResult.fromJson(Map<String, dynamic> json) {
    final servicesList =
        (json['popular_services'] as List<dynamic>?)
            ?.map((e) => PopularService.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PopularServicesResult(
      popularServices: servicesList,
      enabledServicesCount: json['enabled_services_count'] as int? ?? 0,
      showPopularSection: json['show_popular_section'] as bool? ?? false,
    );
  }

  /// Risultato vuoto (nessun servizio popolare)
  static const empty = PopularServicesResult(
    popularServices: [],
    enabledServicesCount: 0,
    showPopularSection: false,
  );
}
