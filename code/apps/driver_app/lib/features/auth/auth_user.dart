/// Haydovchi (auth foydalanuvchisi). id -> kuryer endpointlarida driverId.
class AuthUser {
  final String id;
  final String phone;
  final String locale;
  final List<String> roles;

  const AuthUser({
    required this.id,
    required this.phone,
    required this.locale,
    required this.roles,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      locale: (json['locale'] as String?) ?? 'uz',
      roles: ((json['roles'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'locale': locale,
        'roles': roles,
      };
}
