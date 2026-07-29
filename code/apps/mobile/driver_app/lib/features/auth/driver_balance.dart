/// Hisob to'ldirish yozuvi (Hisobim sahifasi).
class DriverTopup {
  final int amount;
  final String? note;
  final String createdAt;
  const DriverTopup(this.amount, this.note, this.createdAt);

  factory DriverTopup.fromJson(Map<String, dynamic> j) => DriverTopup(
        (j['amount'] as num?)?.toInt() ?? 0,
        j['note'] as String?,
        (j['createdAt'] as String?) ?? '',
      );
}

/// Haydovchi hisob balansi + to'ldirish tarixi.
class DriverBalance {
  final int balance;
  final List<DriverTopup> topups;
  const DriverBalance(this.balance, this.topups);

  factory DriverBalance.fromJson(Map<String, dynamic> j) => DriverBalance(
        (j['balance'] as num?)?.toInt() ?? 0,
        ((j['topups'] as List?) ?? const [])
            .map((e) => DriverTopup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
