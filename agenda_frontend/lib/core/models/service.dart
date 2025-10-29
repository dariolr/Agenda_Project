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
