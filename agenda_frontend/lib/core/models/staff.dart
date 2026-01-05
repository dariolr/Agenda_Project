/// Modello Staff/Operatore
class Staff {
  final int id;
  final int businessId;
  final String name;
  final String surname;
  final String? avatarUrl;
  final int sortOrder;
  final bool isBookableOnline;
  final List<int> serviceIds;

  const Staff({
    required this.id,
    required this.businessId,
    required this.name,
    required this.surname,
    this.avatarUrl,
    this.sortOrder = 0,
    this.isBookableOnline = true,
    this.serviceIds = const [],
  });

  String get displayName {
    if (surname.isEmpty) return name;
    return '$name $surname';
  }

  String get fullName => '${name.trim()} ${surname.trim()}'.trim();

  String get initials {
    final nameInitial = name.isNotEmpty ? name[0].toUpperCase() : '';
    final surnameInitial = surname.isNotEmpty ? surname[0].toUpperCase() : '';
    return '$nameInitial$surnameInitial';
  }

  Staff copyWith({
    int? id,
    int? businessId,
    String? name,
    String? surname,
    String? avatarUrl,
    int? sortOrder,
    bool? isBookableOnline,
    List<int>? serviceIds,
  }) =>
      Staff(
        id: id ?? this.id,
        businessId: businessId ?? this.businessId,
        name: name ?? this.name,
        surname: surname ?? this.surname,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        isBookableOnline: isBookableOnline ?? this.isBookableOnline,
        serviceIds: serviceIds ?? this.serviceIds,
      );

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        id: json['id'] as int,
        businessId: json['business_id'] as int,
        name: json['name'] as String,
        surname: json['surname'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        isBookableOnline: json['is_bookable_online'] as bool? ?? true,
        serviceIds: (json['service_ids'] as List<dynamic>? ?? [])
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .where((id) => id > 0)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'surname': surname,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'sort_order': sortOrder,
        'is_bookable_online': isBookableOnline,
        'service_ids': serviceIds,
      };
}
