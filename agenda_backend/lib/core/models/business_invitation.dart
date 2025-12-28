/// Rappresenta un invito pendente per un utente.
class BusinessInvitation {
  final int id;
  final int businessId;
  final String email;
  final String role;
  final String? token;
  final DateTime expiresAt;
  final DateTime createdAt;
  final InviterInfo invitedBy;

  const BusinessInvitation({
    required this.id,
    required this.businessId,
    required this.email,
    required this.role,
    this.token,
    required this.expiresAt,
    required this.createdAt,
    required this.invitedBy,
  });

  /// Verifica se l'invito è scaduto.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Etichetta tradotta per il ruolo.
  String get roleLabel => switch (role) {
    'admin' => 'Amministratore',
    'manager' => 'Manager',
    'staff' => 'Staff',
    _ => role,
  };

  BusinessInvitation copyWith({
    int? id,
    int? businessId,
    String? email,
    String? role,
    String? token,
    DateTime? expiresAt,
    DateTime? createdAt,
    InviterInfo? invitedBy,
  }) => BusinessInvitation(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    email: email ?? this.email,
    role: role ?? this.role,
    token: token ?? this.token,
    expiresAt: expiresAt ?? this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
    invitedBy: invitedBy ?? this.invitedBy,
  );

  factory BusinessInvitation.fromJson(Map<String, dynamic> json) {
    final invitedByData = json['invited_by'] as Map<String, dynamic>?;
    return BusinessInvitation(
      id: json['id'] as int,
      businessId: json['business_id'] as int? ?? 0,
      email: json['email'] as String,
      role: json['role'] as String,
      token: json['token'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      invitedBy: invitedByData != null
          ? InviterInfo.fromJson(invitedByData)
          : const InviterInfo(firstName: '', lastName: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'email': email,
    'role': role,
    if (token != null) 'token': token,
    'expires_at': expiresAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'invited_by': invitedBy.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessInvitation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BusinessInvitation(id: $id, email: $email, role: $role)';
}

/// Informazioni sull'utente che ha inviato l'invito.
class InviterInfo {
  final String firstName;
  final String lastName;

  const InviterInfo({required this.firstName, required this.lastName});

  String get fullName => '$firstName $lastName'.trim();

  factory InviterInfo.fromJson(Map<String, dynamic> json) => InviterInfo(
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
  };
}
