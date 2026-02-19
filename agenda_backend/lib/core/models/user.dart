import '../utils/initials_utils.dart';

/// Modello utente per l'autenticazione.
/// Rappresenta l'utente loggato nel gestionale.
class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool isSuperadmin;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.isSuperadmin = false,
    required this.createdAt,
  });

  /// Nome completo dell'utente.
  String get fullName => '$firstName $lastName';

  /// Iniziali dell'utente (per avatar).
  String get initials {
    final fullName = '$firstName $lastName'.trim();
    return InitialsUtils.fromName(fullName, maxChars: 2);
  }

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    bool? isSuperadmin,
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone: phone ?? this.phone,
    isSuperadmin: isSuperadmin ?? this.isSuperadmin,
    createdAt: createdAt ?? this.createdAt,
  );

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    email: json['email'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    phone: json['phone'] as String?,
    isSuperadmin: json['is_superadmin'] == true || json['is_superadmin'] == 1,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    if (phone != null) 'phone': phone,
    'is_superadmin': isSuperadmin,
    'created_at': createdAt.toIso8601String(),
  };
}
