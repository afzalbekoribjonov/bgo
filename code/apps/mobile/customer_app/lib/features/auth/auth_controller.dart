import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  AuthState build() => const AuthState(AuthStatus.unknown);

  AuthApi get _api => ref.read(authApiProvider);

  /// Ilova ochilganda: saqlangan token bo'lsa — sessiyani tiklash.
  /// Har qanday xato (storage/tarmoq) holda — tizimga kirilmagan deb hisoblanadi.
  Future<void> bootstrap() async {
    final storage = ref.read(tokenStorageProvider);
    try {
      final token = await storage.readAccess();
      if (token == null) {
        state = const AuthState(AuthStatus.unauthenticated);
        return;
      }
      final user = await _api.me();
      state = AuthState(_statusFor(user), user);
    } catch (_) {
      try {
        await storage.clear();
      } catch (_) {
        // e'tiborsiz
      }
      state = const AuthState(AuthStatus.unauthenticated);
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
    state = AuthState(_statusFor(result.user), result.user);
  }

  Future<void> submitConsent() async {
    final user = await _api.consent(privacy: true, version: '1.0');
    state = AuthState(AuthStatus.authenticated, user);
  }

  Future<void> logout() async {
    // Tokenni serverdan o'chiramiz (token hali yaroqli) — best-effort.
    await ref.read(pushServiceProvider).unregister();
    await ref.read(tokenStorageProvider).clear();
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
