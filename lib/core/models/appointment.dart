class Appointment {
  final int id;
  final int staffId;
  final String clientName;
  final DateTime startTime;
  final DateTime endTime;

  /// 🔹 Lista di ID dei servizi associati (versione "leggera")
  final List<int>? serviceIds;

  /// 🔹 Lista completa di servizi (versione "espansa")
  final List<Service>? services;

  const Appointment({
    required this.id,
    required this.staffId,
    required this.clientName,
    required this.startTime,
    required this.endTime,
    this.serviceIds,
    this.services,
  });

  /// 🔸 Costruttore da JSON
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    staffId: json['staff_id'],
    clientName: json['client_name'],
    startTime: DateTime.parse(json['start_time']),
    endTime: DateTime.parse(json['end_time']),
    serviceIds: json['service_ids'] != null
        ? List<int>.from(json['service_ids'])
        : null,
    services: json['services'] != null
        ? (json['services'] as List).map((s) => Service.fromJson(s)).toList()
        : null,
  );

  Appointment copyWith({
    int? id,
    int? staffId,
    String? clientName,
    DateTime? startTime,
    DateTime? endTime,
    List<int>? serviceIds,
    List<Service>? services,
  }) {
    return Appointment(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      clientName: clientName ?? this.clientName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      serviceIds: serviceIds ?? this.serviceIds,
      services: services ?? this.services,
    );
  }

  /// 🔸 Serializzazione in JSON
  Map<String, dynamic> toJson({bool includeServices = true}) {
    return {
      'id': id,
      'staff_id': staffId,
      'client_name': clientName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (serviceIds != null) 'service_ids': serviceIds,
      if (includeServices && services != null)
        'services': services!.map((s) => s.toJson()).toList(),
    };
  }

  /// 🔹 Durata totale in minuti
  int get totalDuration => endTime.difference(startTime).inMinutes;

  /// 🔹 Prezzo totale dell'appuntamento
  double get totalPrice {
    if (services == null || services!.isEmpty) return 0.0;
    return services!.map((s) => s.price ?? 0.0).fold(0.0, (a, b) => a + b);
  }

  /// 🔹 Restituisce lista nomi servizi (se presenti)
  List<String> get serviceNames {
    if (services != null && services!.isNotEmpty) {
      return services!.map((s) => s.name).toList();
    }
    return [];
  }

  /// 🔹 Stringa compatta per UI (es. "Taglio, Shampoo – 45 min")
  String get formattedServices {
    if (serviceNames.isEmpty) return '';
    final names = serviceNames.length > 3
        ? '${serviceNames.length} servizi'
        : serviceNames.join(', ');
    return '$names – $totalDuration min';
  }

  /// 🔹 Stringa formattata per prezzo totale
  String get formattedPrice {
    if (totalPrice == 0) return '';
    return '${totalPrice.toStringAsFixed(2)}€';
  }
}

class Service {
  final int id;
  final String name;
  final int? duration; // minuti
  final double? price; // costo singolo in euro

  const Service({
    required this.id,
    required this.name,
    this.duration,
    this.price,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'],
    name: json['name'],
    duration: json['duration'],
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (duration != null) 'duration': duration,
    if (price != null) 'price': price,
  };
}
