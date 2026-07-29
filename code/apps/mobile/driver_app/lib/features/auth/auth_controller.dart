import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'auth_api.dart';
import 'auth_user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  const AuthState(this.status, [this.user]);
}

/// Haydovchi autentifikatsiyasi — admin qo'shgan, 8 xonali kod bilan kiradi.
/// Sessiya ilova o'chirilmaguncha saqlanadi (logout yo'q, kesh + uzoq token).
class AuthController extends Notifier<AuthState> {
  static const _userKey = 'driver_user';
  final _secure = const FlutterSecureStorage();

  @override
  AuthState build() => const AuthState(AuthStatus.unknown);

  AuthApi get _api => ref.read(authApiProvider);

  Future<void> bootstrap() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.readAccess();
    if (token == null) {
      state = const AuthState(AuthStatus.unauthenticated);
      return;
    }
    // Keshlangan foydalanuvchi bo'lsa — darhol kiritamiz (oflayn ham ishlaydi).
    final cached = await _readCachedUser();
    if (cached != null) state = AuthState(AuthStatus.authenticated, cached);

    try {
      final user = await _api.me();
      await _cacheUser(user);
      state = AuthState(AuthStatus.authenticated, user);
    } catch (e) {
      // Faqat token yaroqsiz bo'lsa chiqaramiz; tarmoq xatosida sessiya qoladi.
      final code = httpStatus(e);
      if (code == 401 || code == 403) {
        await _fullClear();
        state = const AuthState(AuthStatus.unauthenticated);
      } else if (cached == null) {
        // Token bor, lekin profil ham, tarmoq ham yo'q — keyingi ochilishda qayta.
        state = const AuthState(AuthStatus.unauthenticated);
      }
      // aks holda: keshdagi 'authenticated' holatda qolamiz
    }
  }

  /// Raqam admin qo'shgan haydovchimi? (kod inputini ochishdan oldin)
  Future<bool> checkDriver(String phone) => _api.driverCheck(phone);

  /// Telefon + 8 xonali kod bilan kirish.
  Future<void> driverLogin(String phone, String code) async {
    final result = await _api.driverLogin(phone, code);
    await ref
        .read(tokenStorageProvider)
        .saveTokens(access: result.access, refresh: result.refresh);
    await _cacheUser(result.user);
    state = AuthState(AuthStatus.authenticated, result.user);
  }

  /// Hisobdan chiqish: liniyadan tushirish (best-effort), FCM tokenni
  /// serverdan o'chirish, token+keshni tozalash → login ekraniga qaytadi.
  /// Qayta kirish uchun admin bergan 8 xonali kod kerak bo'ladi.
  Future<void> logout() async {
    try {
      await _api.setOnline(false);
    } catch (_) {/* oflayn bo'lsa ham chiqishga to'sqinlik qilmaydi */}
    try {
      await ref.read(pushServiceProvider).unregister();
    } catch (_) {/* best-effort */}
    await _fullClear();
    state = const AuthState(AuthStatus.unauthenticated);
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

  Future<void> _fullClear() async {
    try {
      await ref.read(tokenStorageProvider).clear();
    } catch (_) {}
    try {
      await _secure.delete(key: _userKey);
    } catch (_) {}
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
