class Resource {
  final int id;
  final int locationId;
  final String name;
  final int quantity;
  final String? type;
  final String? note;

  const Resource({
    required this.id,
    required this.locationId,
    required this.name,
    required this.quantity,
    this.type,
    this.note,
  });

  Resource copyWith({
    int? id,
    int? locationId,
    String? name,
    int? quantity,
    String? type,
    String? note,
  }) {
    return Resource(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as int,
      locationId: json['location_id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      type: json['type'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': locationId,
      'name': name,
      'quantity': quantity,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
    };
  }
}

