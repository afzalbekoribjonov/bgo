import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'auth_api.dart';
import 'auth_user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  const AuthState(this.status, [this.user]);
}

/// Haydovchi autentifikatsiyasi (rozilik bosqichisiz — haydovchi alohida tekshiriladi).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(AuthStatus.unknown);

  AuthApi get _api => ref.read(authApiProvider);

  Future<void> bootstrap() async {
    final storage = ref.read(tokenStorageProvider);
    try {
      final token = await storage.readAccess();
      if (token == null) {
        state = const AuthState(AuthStatus.unauthenticated);
        return;
      }
      final user = await _api.me();
      state = AuthState(AuthStatus.authenticated, user);
    } catch (_) {
      try {
        await storage.clear();
      } catch (_) {
        // e'tiborsiz
      }
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

  Future<String?> requestOtp(String phone) => _api.requestOtp(phone);

  Future<void> verifyOtp(String phone, String code) async {
    final result = await _api.verifyOtp(phone, code);
    await ref
        .read(tokenStorageProvider)
        .saveTokens(access: result.access, refresh: result.refresh);
    state = AuthState(AuthStatus.authenticated, result.user);
  }

  Future<void> logout() async {
    // Tokenni serverdan o'chiramiz (token hali yaroqli) — best-effort.
    await ref.read(pushServiceProvider).unregister();
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
