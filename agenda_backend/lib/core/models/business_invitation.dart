/// Rappresenta un invito pendente per un utente.
class BusinessInvitation {
  final int id;
  final int businessId;
  final String email;
  final String role;
  final String scopeType; // 'business' o 'locations'
  final List<int>
  locationIds; // IDs delle location accessibili (se scopeType='locations')
  final String? token;
  final String status;
  final DateTime? acceptedAt;
  final DateTime expiresAt;
  final DateTime createdAt;
  final InviterInfo invitedBy;

  const BusinessInvitation({
    required this.id,
    required this.businessId,
    required this.email,
    required this.role,
    this.scopeType = 'business',
    this.locationIds = const [],
    this.token,
    this.status = 'pending',
    this.acceptedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.invitedBy,
  });

  /// Verifica se l'invito è scaduto.
  bool get isExpired => effectiveStatus == 'expired';

  /// Stato calcolato lato client (supporta pending già scaduti).
  String get effectiveStatus {
    if (status == 'pending' && DateTime.now().isAfter(expiresAt)) {
      return 'expired';
    }
    return status;
  }

  bool get isPending => effectiveStatus == 'pending';

  /// Indica se l'invito è per tutte le location.
  bool get hasBusinessScope => scopeType == 'business';

  /// Indica se l'invito è per location specifiche.
  bool get hasLocationScope => scopeType == 'locations';

  /// Etichetta tradotta per il ruolo.
  String get roleLabel => switch (role) {
    'admin' => 'Amministratore',
    'manager' => 'Manager',
    'staff' => 'Staff',
    'viewer' => 'Visualizzatore',
    _ => role,
  };

  BusinessInvitation copyWith({
    int? id,
    int? businessId,
    String? email,
    String? role,
    String? scopeType,
    List<int>? locationIds,
    String? token,
    String? status,
    DateTime? acceptedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    InviterInfo? invitedBy,
  }) => BusinessInvitation(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    email: email ?? this.email,
    role: role ?? this.role,
    scopeType: scopeType ?? this.scopeType,
    locationIds: locationIds ?? this.locationIds,
    token: token ?? this.token,
    status: status ?? this.status,
    acceptedAt: acceptedAt ?? this.acceptedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
    invitedBy: invitedBy ?? this.invitedBy,
  );

  factory BusinessInvitation.fromJson(Map<String, dynamic> json) {
    final invitedByData = json['invited_by'] as Map<String, dynamic>?;
    final now = DateTime.now();
    return BusinessInvitation(
      id: _asInt(json['id']),
      businessId: _asInt(json['business_id']),
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'staff',
      scopeType: json['scope_type'] as String? ?? 'business',
      locationIds:
          (json['location_ids'] as List<dynamic>?)
              ?.map(_asInt)
              .where((e) => e > 0)
              .toList() ??
          [],
      token: json['token'] as String?,
      status:
          json['effective_status'] as String? ??
          json['status'] as String? ??
          'pending',
      acceptedAt: _parseDateTime(json['accepted_at']),
      expiresAt:
          _parseDateTime(json['expires_at']) ??
          now.add(const Duration(days: 7)),
      createdAt: _parseDateTime(json['created_at']) ?? now,
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
    'scope_type': scopeType,
    'location_ids': locationIds,
    if (token != null) 'token': token,
    'status': status,
    if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
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
      'BusinessInvitation(id: $id, email: $email, role: $role, scopeType: $scopeType)';
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
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
