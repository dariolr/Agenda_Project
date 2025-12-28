/// Rappresenta un utente associato a un business (operatore).
class BusinessUser {
  final int id;
  final int userId;
  final int businessId;
  final String role;
  final String email;
  final String firstName;
  final String lastName;
  final String status;
  final DateTime? invitedAt;
  final DateTime? joinedAt;
  final bool isCurrentUser;

  const BusinessUser({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.role,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.invitedAt,
    this.joinedAt,
    this.isCurrentUser = false,
  });

  /// Nome completo dell'utente.
  String get fullName => '$firstName $lastName'.trim();

  /// Indica se l'utente ha un ruolo admin o superiore.
  bool get isAdmin => role == 'owner' || role == 'admin';

  /// Indica se l'utente può gestire altri utenti (owner o admin).
  bool get canManageUsers => role == 'owner' || role == 'admin';

  /// Etichetta tradotta per il ruolo.
  String get roleLabel => switch (role) {
    'owner' => 'Proprietario',
    'admin' => 'Amministratore',
    'manager' => 'Manager',
    'staff' => 'Staff',
    _ => role,
  };

  BusinessUser copyWith({
    int? id,
    int? userId,
    int? businessId,
    String? role,
    String? email,
    String? firstName,
    String? lastName,
    String? status,
    DateTime? invitedAt,
    DateTime? joinedAt,
    bool? isCurrentUser,
  }) => BusinessUser(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    businessId: businessId ?? this.businessId,
    role: role ?? this.role,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    status: status ?? this.status,
    invitedAt: invitedAt ?? this.invitedAt,
    joinedAt: joinedAt ?? this.joinedAt,
    isCurrentUser: isCurrentUser ?? this.isCurrentUser,
  );

  factory BusinessUser.fromJson(Map<String, dynamic> json) => BusinessUser(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    businessId: json['business_id'] as int,
    role: json['role'] as String,
    email: json['email'] as String,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    status: json['status'] as String? ?? 'active',
    invitedAt: json['invited_at'] != null
        ? DateTime.parse(json['invited_at'] as String)
        : null,
    joinedAt: json['joined_at'] != null
        ? DateTime.parse(json['joined_at'] as String)
        : null,
    isCurrentUser: json['is_current_user'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'business_id': businessId,
    'role': role,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'status': status,
    if (invitedAt != null) 'invited_at': invitedAt!.toIso8601String(),
    if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    'is_current_user': isCurrentUser,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BusinessUser(id: $id, email: $email, role: $role)';
}
