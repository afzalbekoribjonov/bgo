import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hamkor panel (oshxona/do'kon) JWT'sini xavfsiz saqlaydi — mijozning o'z
/// sessiya tokenidan ALOHIDA, chunki backend RolesGuard'i 'restaurant'/'seller'
/// rolini talab qiladi (mijozning oddiy tokenida bu rol yo'q — bu maxsus
/// token egalik tekshirilgach ALOHIDA mint qilinadi, `/restaurants/my-kitchen`
/// yoki `/marketplace/my-shop` orqali).
///
/// Har panel turi ('kitchen' | 'seller') uchun alohida kalit ostida saqlaydi.
class PanelTokenCache {
  final FlutterSecureStorage _storage;
  final String panelType;

  PanelTokenCache(this.panelType, [FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  String get _tokenKey => 'panel_${panelType}_token';
  String get _expiryKey => 'panel_${panelType}_expiry';

  /// Keshlangan token — muddati tugashiga 90s dan kam qolgan bo'lsa (yoki
  /// umuman yo'q bo'lsa) `null` qaytaradi, chaqiruvchi yangisini so'rashi kerak.
  Future<String?> readToken() async {
    final token = await _storage.read(key: _tokenKey);
    final expiryStr = await _storage.read(key: _expiryKey);
    if (token == null || expiryStr == null) return null;
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return null;
    if (DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 90)))) {
      return null;
    }
    return token;
  }

  Future<void> save(String token) async {
    final expiry = _decodeExpiry(token) ?? DateTime.now().add(const Duration(minutes: 25));
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _expiryKey, value: expiry.toIso8601String());
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiryKey);
  }

  /// JWT `exp` claim'ini (soniyalarda, UTC) mahalliy dekod qiladi — imzo
  /// TEKSHIRILMAYDI (faqat kesh muddatini bilish uchun, xavfsizlik backendda).
  DateTime? _decodeExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true).toLocal();
    } catch (_) {
      return null;
    }
  }
}
