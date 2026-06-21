/// Saqlangan manzil — Auth servisi javobiga mos.
class Address {
  final String id;
  final String label;
  final String text;
  final double? lat;
  final double? lng;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.text,
    required this.isDefault,
    this.lat,
    this.lng,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }
}
