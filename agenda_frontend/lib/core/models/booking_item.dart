/// Modello per le prenotazioni utente recuperate da /v1/me/bookings
class BookingItem {
  final int id;
  final int businessId;
  final String businessName;
  final int locationId;
  final String locationName;
  final String? locationAddress;
  final String? locationCity;
  final List<String> serviceNames;
  final List<int> serviceIds;
  final String? staffName;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String? notes;
  final bool canModify;
  final DateTime? canModifyUntil;
  final String status;

  const BookingItem({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.locationId,
    required this.locationName,
    this.locationAddress,
    this.locationCity,
    required this.serviceNames,
    this.serviceIds = const [],
    this.staffName,
    required this.startTime,
    required this.endTime,
    this.totalPrice = 0.0,
    this.notes,
    required this.canModify,
    this.canModifyUntil,
    this.status = 'confirmed',
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    // Supporta sia formato nested (location.id) che flat (location_id)
    final location = json['location'] as Map<String, dynamic>?;
    final business = json['business'] as Map<String, dynamic>?;

    return BookingItem(
      id: json['id'] as int? ?? json['booking_id'] as int,
      businessId: business?['id'] as int? ?? json['business_id'] as int,
      businessName:
          business?['name'] as String? ?? json['business_name'] as String,
      locationId: location?['id'] as int? ?? json['location_id'] as int,
      locationName:
          location?['name'] as String? ?? json['location_name'] as String,
      locationAddress:
          location?['address'] as String? ??
          json['location_address'] as String?,
      locationCity:
          location?['city'] as String? ?? json['location_city'] as String?,
      serviceNames: _parseServiceNames(json),
      serviceIds: _parseServiceIds(json),
      staffName: json['staff_name'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      totalPrice:
          (json['total_price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      notes: json['notes'] as String?,
      canModify: json['can_modify'] as bool? ?? false,
      canModifyUntil: json['can_modify_until'] != null
          ? DateTime.parse(json['can_modify_until'] as String)
          : null,
      status: json['status'] as String? ?? 'confirmed',
    );
  }

  /// Parsa service_names supportando sia array che singolo valore
  static List<String> _parseServiceNames(Map<String, dynamic> json) {
    // Formato array: service_names: ["Taglio", "Piega"]
    if (json.containsKey('service_names') && json['service_names'] != null) {
      final names = json['service_names'];
      if (names is List) {
        return names.map((e) => e.toString()).toList();
      }
    }
    // Formato singolo: service_name: "Taglio + Piega"
    if (json.containsKey('service_name') && json['service_name'] != null) {
      return [json['service_name'] as String];
    }
    return [];
  }

  /// Parsa service_ids supportando sia array che singolo valore
  static List<int> _parseServiceIds(Map<String, dynamic> json) {
    if (json.containsKey('service_ids') && json['service_ids'] != null) {
      final ids = json['service_ids'];
      if (ids is List) {
        return ids.map((e) => e as int).toList();
      }
    }
    return [];
  }

  /// Stringa formattata dei servizi
  String get servicesDisplay => serviceNames.join(' + ');

  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isUpcoming => !isPast;
  bool get isCancelled => status == 'cancelled';

  /// Crea copia con nuovi valori (per update locale dopo reschedule)
  BookingItem copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    bool? canModify,
    DateTime? canModifyUntil,
    String? status,
  }) {
    return BookingItem(
      id: id,
      businessId: businessId,
      businessName: businessName,
      locationId: locationId,
      locationName: locationName,
      locationAddress: locationAddress,
      locationCity: locationCity,
      serviceNames: serviceNames,
      serviceIds: serviceIds,
      staffName: staffName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice,
      notes: notes ?? this.notes,
      canModify: canModify ?? this.canModify,
      canModifyUntil: canModifyUntil ?? this.canModifyUntil,
      status: status ?? this.status,
    );
  }
}
