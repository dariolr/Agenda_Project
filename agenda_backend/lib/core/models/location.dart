class Location {
  final int id;
  final int businessId;
  final String name;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? currency;
  final bool
  isDefault; // 🔹 nuova proprietà: indica se la sede è quella predefinita

  const Location({
    required this.id,
    required this.businessId,
    required this.name,
    this.address,
    this.city,
    this.region,
    this.country,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.currency,
    this.isDefault = false, // 🔹 di default false
  });

  Location copyWith({
    int? id,
    int? businessId,
    String? name,
    String? address,
    String? city,
    String? region,
    String? country,
    String? phone,
    String? email,
    double? latitude,
    double? longitude,
    String? currency,
    bool? isDefault,
  }) {
    return Location(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      isDefault: json['is_default'] as bool? ?? false, // 🔹 compatibilità JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (region != null) 'region': region,
      if (country != null) 'country': country,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (currency != null) 'currency': currency,
      'is_default': isDefault, // 🔹 incluso sempre per chiarezza
    };
  }
}
