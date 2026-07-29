import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Kunlik grafik nuqtasi.
class StatPoint {
  final String date; // YYYY-MM-DD
  final int count;
  final int earning;
  const StatPoint(this.date, this.count, this.earning);

  factory StatPoint.fromJson(Map<String, dynamic> j) => StatPoint(
        (j['date'] as String?) ?? '',
        (j['count'] as num?)?.toInt() ?? 0,
        (j['earning'] as num?)?.toInt() ?? 0,
      );
}

/// Bajarilgan buyurtma (ro'yxat uchun).
class StatOrder {
  final String type; // food | taxi | parcel
  final int amount;
  final int earning;
  final String createdAt;
  const StatOrder(this.type, this.amount, this.earning, this.createdAt);

  factory StatOrder.fromJson(Map<String, dynamic> j) => StatOrder(
        (j['type'] as String?) ?? 'food',
        (j['amount'] as num?)?.toInt() ?? 0,
        (j['earning'] as num?)?.toInt() ?? 0,
        (j['createdAt'] as String?) ?? '',
      );
}

/// Haydovchi statistikasi (Bugun ekrani).
class DriverStats {
  final int totalCount;
  final int totalEarning;
  final List<StatPoint> daily;
  final List<StatOrder> orders;
  const DriverStats(this.totalCount, this.totalEarning, this.daily, this.orders);

  factory DriverStats.fromJson(Map<String, dynamic> j) => DriverStats(
        (j['totalCount'] as num?)?.toInt() ?? 0,
        (j['totalEarning'] as num?)?.toInt() ?? 0,
        ((j['daily'] as List?) ?? const [])
            .map((e) => StatPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        ((j['orders'] as List?) ?? const [])
            .map((e) => StatOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StatsApi {
  final Dio _dio;
  StatsApi(this._dio);

  Future<DriverStats> stats(String period) async {
    final res = await _dio.get('/courier/stats',
        queryParameters: {'period': period});
    return DriverStats.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final statsApiProvider = Provider<StatsApi>((ref) => StatsApi(ref.read(dioProvider)));

/// period: today | week | month
final driverStatsProvider =
    FutureProvider.family<DriverStats, String>((ref, period) {
  ref.watch(localeProvider);
  return ref.read(statsApiProvider).stats(period);
});
