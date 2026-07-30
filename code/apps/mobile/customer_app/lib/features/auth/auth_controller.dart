import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/app_webview_screen.dart';
import 'auth_api.dart';
import 'auth_user.dart';

enum AuthStatus { unknown, unauthenticated, needsConsent, authenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  const AuthState(this.status, [this.user]);
}

/// Autentifikatsiya holatini boshqaradi. plan/05-customer-app.md, plan/10-auth-security.md
class AuthController extends Notifier<AuthState> {
  static const _userKey = 'customer_user';
  final _secure = const FlutterSecureStorage();

  @override
  AuthState build() => const AuthState(AuthStatus.unknown);

  AuthApi get _api => ref.read(authApiProvider);

  /// Ilova ochilganda: saqlangan token bo'lsa — sessiyani tiklash.
  /// Keshlangan foydalanuvchi bo'lsa darhol ko'rsatiladi (oflayn ham ishlaydi);
  /// faqat haqiqiy 401/403'da chiqariladi, oddiy tarmoq xatosida sessiya qoladi.
  Future<void> bootstrap() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.readAccess();
    if (token == null) {
      state = const AuthState(AuthStatus.unauthenticated);
      return;
    }
    final cached = await _readCachedUser();
    if (cached != null) state = AuthState(_statusFor(cached), cached);

    try {
      final user = await _api.me();
      await _cacheUser(user);
      state = AuthState(_statusFor(user), user);
    } catch (e) {
      final code = httpStatus(e);
      if (code == 401 || code == 403) {
        try {
          await storage.clear();
        } catch (_) {
          // e'tiborsiz
        }
        try {
          await _secure.delete(key: _userKey);
        } catch (_) {
          // e'tiborsiz
        }
        state = const AuthState(AuthStatus.unauthenticated);
      } else if (cached == null) {
        state = const AuthState(AuthStatus.unauthenticated);
      }
      // aks holda: keshdagi holatda qolamiz
    }
  }

  Future<void> _cacheUser(AuthUser user) =>
      _secure.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<AuthUser?> _readCachedUser() async {
    try {
      final raw = await _secure.read(key: _userKey);
      if (raw == null) return null;
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<({String? devCode, String? telegramBotUrl})> requestOtp(
          String phone) =>
      _api.requestOtp(phone);

  Future<void> verifyOtp(String phone, String code) async {
    final result = await _api.verifyOtp(phone, code);
    await ref
        .read(tokenStorageProvider)
        .saveTokens(access: result.access, refresh: result.refresh);
    await _cacheUser(result.user);
    state = AuthState(_statusFor(result.user), result.user);
  }

  Future<void> submitConsent() async {
    final user = await _api.consent(privacy: true, version: '1.0');
    await _cacheUser(user);
    state = AuthState(AuthStatus.authenticated, user);
  }

  Future<void> logout() async {
    // Tokenni serverdan o'chiramiz (token hali yaroqli) — best-effort.
    await ref.read(pushServiceProvider).unregister();
    await ref.read(tokenStorageProvider).clear();
    try {
      await _secure.delete(key: _userKey);
    } catch (_) {
      // e'tiborsiz
    }
    // Keshlangan Market/Do'konlar WebView sessiyalari shu hisobga tegishli —
    // boshqa hisob kirganda ular bilan aralashib qolmasin.
    AppWebViewScreen.clearCache();
    state = const AuthState(AuthStatus.unauthenticated);
  }

  AuthStatus _statusFor(AuthUser user) =>
      user.hasConsent ? AuthStatus.authenticated : AuthStatus.needsConsent;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
