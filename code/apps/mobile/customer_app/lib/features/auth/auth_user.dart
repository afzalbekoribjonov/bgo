/// Auth servisidan keladigan foydalanuvchi (sanitized). plan/04-backend-services.md
class AuthUser {
  final String id;
  final String phone;
  final String? fullName;
  final String locale;
  final List<String> roles;
  final bool hasConsent;

  const AuthUser({
    required this.id,
    required this.phone,
    required this.locale,
    required this.roles,
    required this.hasConsent,
    this.fullName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String?,
      locale: (json['locale'] as String?) ?? 'uz',
      roles: ((json['roles'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      hasConsent: (json['hasConsent'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'fullName': fullName,
        'locale': locale,
        'roles': roles,
        'hasConsent': hasConsent,
      };
}
