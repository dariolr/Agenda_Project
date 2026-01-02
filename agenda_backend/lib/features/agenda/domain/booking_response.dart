/// Risposta API per un booking con i suoi items
class BookingResponse {
  final int id;
  final int businessId;
  final int locationId;
  final int? clientId;
  final int? userId;
  final String? customerName;
  final String? notes;
  final String status;
  final String source;
  final double totalPrice;
  final int totalDurationMinutes;
  final String createdAt;
  final String updatedAt;
  final List<BookingItemResponse> items;

  const BookingResponse({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.clientId,
    this.userId,
    this.customerName,
    this.notes,
    required this.status,
    required this.source,
    required this.totalPrice,
    required this.totalDurationMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return BookingResponse(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      locationId: json['location_id'] as int,
      clientId: json['client_id'] as int?,
      userId: json['user_id'] as int?,
      customerName: json['customer_name'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      source: json['source'] as String? ?? 'online',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      totalDurationMinutes: json['total_duration_minutes'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      items: itemsList
          .map((i) => BookingItemResponse.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Singolo item di un booking (un servizio prenotato)
class BookingItemResponse {
  final int id;
  final int? bookingId;
  final int serviceId;
  final int? serviceVariantId;
  final int staffId;
  final String startTime;
  final String endTime;
  final double price;
  final int durationMinutes;
  final String? serviceName;
  final String? staffDisplayName;

  const BookingItemResponse({
    required this.id,
    this.bookingId,
    required this.serviceId,
    this.serviceVariantId,
    required this.staffId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.durationMinutes,
    this.serviceName,
    this.staffDisplayName,
  });

  factory BookingItemResponse.fromJson(Map<String, dynamic> json) {
    return BookingItemResponse(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int?,
      serviceId: json['service_id'] as int,
      serviceVariantId: json['service_variant_id'] as int?,
      staffId: json['staff_id'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      serviceName: json['service_name'] as String?,
      staffDisplayName:
          (json['staff_display_name'] ?? json['staff_name']) as String?,
    );
  }

  /// Converte start_time in DateTime
  DateTime get startDateTime => DateTime.parse(startTime);

  /// Converte end_time in DateTime
  DateTime get endDateTime => DateTime.parse(endTime);
}
