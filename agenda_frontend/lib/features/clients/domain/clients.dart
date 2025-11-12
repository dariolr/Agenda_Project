class Client {
  final int id;
  final int businessId;
  final String name;
  final String? email;
  final String? phone;
  final String? gender;
  final DateTime? birthDate;
  final String? city;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastVisit;
  final int? loyaltyPoints;
  final List<String>? tags;
  final bool isArchived;

  const Client({
    required this.id,
    required this.businessId,
    required this.name,
    this.email,
    this.phone,
    this.gender,
    this.birthDate,
    this.city,
    this.notes,
    required this.createdAt,
    this.lastVisit,
    this.loyaltyPoints,
    this.tags,
    this.isArchived = false,
  });

  Client copyWith({
    int? id,
    int? businessId,
    String? name,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
    String? city,
    String? notes,
    DateTime? createdAt,
    DateTime? lastVisit,
    int? loyaltyPoints,
    List<String>? tags,
    bool? isArchived,
  }) {
    return Client(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
