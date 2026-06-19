import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'auth_user.dart';

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
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(dioProvider)));
