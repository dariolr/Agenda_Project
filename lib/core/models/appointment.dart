class Appointment {
  final int id;
  final int staffId;
  final String clientName;
  final String serviceName;
  final DateTime startTime;
  final DateTime endTime;
  final double? price; // costo singolo in euro

  const Appointment({
    required this.id,
    required this.staffId,
    required this.clientName,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    this.price,
  });

  /// 🔸 Costruttore da JSON
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    staffId: json['staff_id'],
    clientName: json['client_name'],
    serviceName: json['service_name'],
    startTime: DateTime.parse(json['start_time']),
    endTime: DateTime.parse(json['end_time']),
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
  );

  Appointment copyWith({
    int? id,
    int? staffId,
    String? clientName,
    String? serviceName,
    DateTime? startTime,
    DateTime? endTime,
    double? price,
  }) {
    return Appointment(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      clientName: clientName ?? this.clientName,
      serviceName: serviceName ?? this.serviceName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      price: price ?? this.price,
    );
  }

  /// 🔸 Serializzazione in JSON
  Map<String, dynamic> toJson({bool includeServices = true}) {
    return {
      'id': id,
      'staff_id': staffId,
      'client_name': clientName,
      'service_name': serviceName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (price != null) 'price': price,
    };
  }

  /// 🔹 Durata totale in minuti
  int get totalDuration => endTime.difference(startTime).inMinutes;

  /// 🔹 Stringa formattata per prezzo totale
  String get formattedPrice {
    if (price == null || price == 0) return '';
    return '${price!.toStringAsFixed(2)}€';
  }
}
