class Client {
  final int id;
  final int businessId;
  final String? firstName;
  final String? lastName;
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
    this.firstName,
    this.lastName,
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

  /// Nome completo (firstName + lastName)
  String get name {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.join(' ');
  }

  /// Prefissi comuni nei cognomi italiani (e alcune varianti internazionali)
  static const _lastNamePrefixes = {
    // Italiani
    'de', 'di', 'da', 'del', 'della', 'delle', 'dei', 'degli',
    'dall', "dall'", 'dalla', 'dallo', 'dalle', 'dagli',
    'la', 'lo', 'li', 'le',
    // Internazionali comuni
    'van', 'von', 'den', 'der', 'ter', 'ten',
    'mc', 'mac', "o'", 'al', 'el', 'ben', 'bin',
  };

  /// Crea un Client a partire da un nome completo, separando automaticamente
  /// nome e cognome. Riconosce cognomi composti con prefissi (es. "La Rosa", "De Luca").
  static ({String? firstName, String? lastName}) splitFullName(
    String fullName,
  ) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return (firstName: null, lastName: null);
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      // Solo una parola: la consideriamo come firstName
      return (firstName: parts.first, lastName: null);
    }

    if (parts.length == 2) {
      // Due parole: firstName + lastName
      return (firstName: parts[0], lastName: parts[1]);
    }

    // 3+ parole: cerchiamo un prefisso di cognome
    // Partiamo dalla penultima parola e vediamo se è un prefisso
    int lastNameStartIndex = parts.length - 1;

    for (int i = parts.length - 2; i >= 1; i--) {
      final word = parts[i].toLowerCase().replaceAll("'", "'");
      if (_lastNamePrefixes.contains(word)) {
        lastNameStartIndex = i;
      } else {
        // Se troviamo una parola che non è un prefisso, ci fermiamo
        break;
      }
    }

    final firstName = parts.sublist(0, lastNameStartIndex).join(' ');
    final lastName = parts.sublist(lastNameStartIndex).join(' ');

    return (firstName: firstName, lastName: lastName);
  }

  Client copyWith({
    int? id,
    int? businessId,
    String? firstName,
    String? lastName,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
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
