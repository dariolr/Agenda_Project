/// Modello utente per l'autenticazione
class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool marketingOptIn;
  final bool profilingOptIn;
  final String preferredChannel;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.marketingOptIn = false,
    this.profilingOptIn = false,
    this.preferredChannel = 'none',
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    bool? marketingOptIn,
    bool? profilingOptIn,
    String? preferredChannel,
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone: phone ?? this.phone,
    marketingOptIn: marketingOptIn ?? this.marketingOptIn,
    profilingOptIn: profilingOptIn ?? this.profilingOptIn,
    preferredChannel: preferredChannel ?? this.preferredChannel,
    createdAt: createdAt ?? this.createdAt,
  );

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    email: json['email'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    phone: json['phone'] as String?,
    marketingOptIn: json['marketing_opt_in'] == true || json['marketing_opt_in'] == 1,
    profilingOptIn: json['profiling_opt_in'] == true || json['profiling_opt_in'] == 1,
    preferredChannel: (json['preferred_channel'] as String?) ?? 'none',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    if (phone != null) 'phone': phone,
    'marketing_opt_in': marketingOptIn,
    'profiling_opt_in': profilingOptIn,
    'preferred_channel': preferredChannel,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}
