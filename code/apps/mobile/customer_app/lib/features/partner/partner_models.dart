// Hamkorlik (partner) arizasi modeli — Auth servisi javobiga mos.

enum PartnerType { restaurant, driver }

extension PartnerTypeApi on PartnerType {
  String get api => this == PartnerType.restaurant ? 'RESTAURANT' : 'DRIVER';
}

class PartnerApplication {
  final String id;
  final String fullName;
  final String type; // RESTAURANT | DRIVER
  final String? note;
  final String status; // PENDING | APPROVED | REJECTED
  final String createdAt;

  const PartnerApplication({
    required this.id,
    required this.fullName,
    required this.type,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory PartnerApplication.fromJson(Map<String, dynamic> json) {
    return PartnerApplication(
      id: json['id'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      note: json['note'] as String?,
      status: (json['status'] as String?) ?? 'PENDING',
      createdAt: (json['createdAt'] as String?) ?? '',
    );
  }
}
