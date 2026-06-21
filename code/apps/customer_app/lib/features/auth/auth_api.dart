import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'auth_user.dart';

/// Auth servisi (gateway orqali) bilan aloqa. plan/14-api-design.md
class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  /// OTP so'rash. Dev rejimda devCode; SMS kanal bo'lsa telegramBotUrl qaytadi.
  Future<({String? devCode, String? telegramBotUrl})> requestOtp(
    String phone,
  ) async {
    final res = await _dio.post('/auth/otp/request', data: {'phone': phone});
    final data = res.data['data'] as Map<String, dynamic>?;
    return (
      devCode: data?['devCode'] as String?,
      telegramBotUrl: data?['telegramBotUrl'] as String?,
    );
  }

  /// OTP tasdiqlash → foydalanuvchi + tokenlar.
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

  Future<AuthUser> consent({required bool privacy, required String version}) async {
    final res = await _dio.post('/auth/consent', data: {
      'privacy': privacy,
      'version': version,
    });
    return AuthUser.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(dioProvider)));
