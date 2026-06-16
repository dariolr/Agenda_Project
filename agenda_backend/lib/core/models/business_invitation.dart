/// Rappresenta un invito pendente per un utente.
class BusinessInvitation {
  final int id;
  final int businessId;
  final String email;
  final String role;
  final int? staffId;
  final String scopeType;
  final List<int> locationIds;
  /// null = Tutti, [] = Nessuno, [1,2] = Solo selezionati.
  final List<int>? allowedServiceIds;
  /// null = Tutti, [] = Nessuno, [1,2] = Solo selezionati.
  final List<int>? allowedClassTypeIds;
  /// null = Tutti, [] = Nessuno, [1,2] = Solo selezionati.
  final List<int>? allowedStaffIds;
  /// Permessi granulari salvati sull'invito (null = default del ruolo all'accettazione).
  final bool? canManageBookings;
  final bool? canManageClients;
  final bool? canManageServices;
  final bool? canManageStaff;
  final bool? canViewReports;
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
    this.staffId,
    this.scopeType = 'business',
    this.locationIds = const [],
    this.allowedServiceIds,
    this.allowedClassTypeIds,
    this.allowedStaffIds,
    this.canManageBookings,
    this.canManageClients,
    this.canManageServices,
    this.canManageStaff,
    this.canViewReports,
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
    'custom' => 'Operatore personalizzato',
    _ => role,
  };

  BusinessInvitation copyWith({
    int? id,
    int? businessId,
    String? email,
    String? role,
    int? staffId,
    String? scopeType,
    List<int>? locationIds,
    List<int>? allowedServiceIds,
    List<int>? allowedClassTypeIds,
    List<int>? allowedStaffIds,
    bool? canManageBookings,
    bool? canManageClients,
    bool? canManageServices,
    bool? canManageStaff,
    bool? canViewReports,
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
    staffId: staffId ?? this.staffId,
    scopeType: scopeType ?? this.scopeType,
    locationIds: locationIds ?? this.locationIds,
    allowedServiceIds: allowedServiceIds ?? this.allowedServiceIds,
    allowedClassTypeIds: allowedClassTypeIds ?? this.allowedClassTypeIds,
    allowedStaffIds: allowedStaffIds ?? this.allowedStaffIds,
    canManageBookings: canManageBookings ?? this.canManageBookings,
    canManageClients: canManageClients ?? this.canManageClients,
    canManageServices: canManageServices ?? this.canManageServices,
    canManageStaff: canManageStaff ?? this.canManageStaff,
    canViewReports: canViewReports ?? this.canViewReports,
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
      staffId: json['staff_id'] != null ? _asInt(json['staff_id']) : null,
      scopeType: json['scope_type'] as String? ?? 'business',
      locationIds:
          (json['location_ids'] as List<dynamic>?)
              ?.map(_asInt)
              .where((e) => e > 0)
              .toList() ??
          [],
      allowedServiceIds:
          (json['allowed_service_ids'] as List<dynamic>?)
              ?.map(_asInt)
              .where((e) => e > 0)
              .toList(),
      allowedClassTypeIds:
          (json['allowed_class_type_ids'] as List<dynamic>?)
              ?.map(_asInt)
              .where((e) => e > 0)
              .toList(),
      allowedStaffIds:
          (json['allowed_staff_ids'] as List<dynamic>?)
              ?.map(_asInt)
              .where((e) => e > 0)
              .toList(),
      canManageBookings: _asNullableBool(json['can_manage_bookings']),
      canManageClients: _asNullableBool(json['can_manage_clients']),
      canManageServices: _asNullableBool(json['can_manage_services']),
      canManageStaff: _asNullableBool(json['can_manage_staff']),
      canViewReports: _asNullableBool(json['can_view_reports']),
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
    'staff_id': staffId,
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

/// null = non specificato sull'invito (si userà il default del ruolo).
bool? _asNullableBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }
  return null;
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
