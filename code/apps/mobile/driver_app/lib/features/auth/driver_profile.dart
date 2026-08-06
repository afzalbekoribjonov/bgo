/// Haydovchi profili (GET /auth/driver/me) — ilova ichida ko'rsatish uchun.
class DriverProfile {
  final String id;
  final String phone;
  final String fullName;
  final int? age;
  final String? carName;
  final int? carYear;
  final String? plateNumber;
  final String? licenseInfo;
  final bool isActive;
  final bool isOnline;
  final int balance;
  /// "Uyga" rejimi — uy manzili (belgilanmagan bo'lsa null).
  final double? homeLat;
  final double? homeLng;
  final String? homeAddress;
  final bool isHomeModeActive;
  /// Umumiy reyting (mijoz baholari + admin tuzatishi bilan), 0-5 oralig'ida.
  final double rating;

  const DriverProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.isActive,
    required this.isOnline,
    this.age,
    this.carName,
    this.carYear,
    this.plateNumber,
    this.licenseInfo,
    this.balance = 0,
    this.homeLat,
    this.homeLng,
    this.homeAddress,
    this.isHomeModeActive = false,
    this.rating = 0,
  });

  bool get hasHomeAddress => homeLat != null && homeLng != null;

  /// Avatar uchun ism bosh harfi.
  String get initial {
    final n = fullName.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String,
      phone: (json['phone'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      age: (json['age'] as num?)?.toInt(),
      carName: json['carName'] as String?,
      carYear: (json['carYear'] as num?)?.toInt(),
      plateNumber: json['plateNumber'] as String?,
      licenseInfo: json['licenseInfo'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      isOnline: (json['isOnline'] as bool?) ?? false,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      homeLat: (json['homeLat'] as num?)?.toDouble(),
      homeLng: (json['homeLng'] as num?)?.toDouble(),
      homeAddress: json['homeAddress'] as String?,
      isHomeModeActive: (json['isHomeModeActive'] as bool?) ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}
