import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'auth_user.dart';
import 'driver_balance.dart';
import 'driver_profile.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<String?> requestOtp(String phone) async {
    final res = await _dio.post('/auth/otp/request', data: {'phone': phone});
    final data = res.data['data'] as Map<String, dynamic>?;
    return data?['devCode'] as String?;
  }

  Future<({AuthUser user, String access, String refresh})> verifyOtp(
    String phone,
    String code,
  ) async {
    final res = await _dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return (
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
  }

  Future<AuthUser> me() async {
    final res = await _dio.get('/auth/me');
    return AuthUser.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Raqam admin tomonidan qo'shilgan haydovchimi? (kod inputidan oldin)
  Future<bool> driverCheck(String phone) async {
    final res = await _dio.post('/auth/driver/check', data: {'phone': phone});
    final data = res.data['data'] as Map<String, dynamic>?;
    return (data?['exists'] as bool?) ?? false;
  }

  /// Onlayn/oflayn holatni o'rnatish (Liniyaga chiqish / Ishni yakunlash).
  Future<void> setOnline(bool isOnline) async {
    await _dio.post('/auth/driver/status', data: {'isOnline': isOnline});
  }

  /// Joriy haydovchi profilidagi onlayn holat (ilova ochilganda tiklash uchun).
  Future<bool> fetchOnline() async {
    final res = await _dio.get('/auth/driver/me');
    return (res.data['data']?['isOnline'] as bool?) ?? false;
  }

  /// To'liq haydovchi profili (profil/sozlamalar sahifasi uchun).
  Future<DriverProfile> driverProfile() async {
    final res = await _dio.get('/auth/driver/me');
    return DriverProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Hisob balansi + to'ldirish tarixi (Hisobim).
  Future<DriverBalance> balance() async {
    final res = await _dio.get('/auth/driver/balance');
    return DriverBalance.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Telefon + 8 xonali kod bilan kirish (uzoq muddatli token).
  Future<({AuthUser user, String access, String refresh})> driverLogin(
    String phone,
    String code,
  ) async {
    final res = await _dio.post('/auth/driver/login', data: {
      'phone': phone,
      'code': code,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return (
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(dioProvider)));

/// Joriy haydovchi profili (profil/sozlamalar uchun).
final driverProfileProvider = FutureProvider<DriverProfile>(
  (ref) => ref.read(authApiProvider).driverProfile(),
);

/// Hisob balansi + tarix (Hisobim).
final driverBalanceProvider = FutureProvider<DriverBalance>(
  (ref) => ref.read(authApiProvider).balance(),
);
