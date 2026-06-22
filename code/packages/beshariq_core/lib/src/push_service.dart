import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Push (FCM) — qurilma tokenini olish va auth servisiga ro'yxatga olish.
/// Token auth `/profile/device-token` orqali saqlanadi (order servisi shu
/// token bo'yicha push yuboradi). BEST-EFFORT: xato ilovani to'xtatmaydi.
/// plan/10-auth-security.md
class PushService {
  final Dio _dio;
  PushService(this._dio);

  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  /// Ilova ochiqligida kelgan xabarlar (UI'da snackbar ko'rsatish uchun).
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  /// Foydalanuvchi bildirishnomani bosib ochganida (ilova fonda edi).
  Stream<RemoteMessage> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Ruxsat so'raydi, tokenni oladi va serverga ro'yxatga oladi.
  /// Token yangilansa avtomatik qayta ro'yxatga olinadi.
  Future<void> registerToken() async {
    try {
      await _fm.requestPermission();
      final token = await _fm.getToken();
      if (token != null) await _send(token);
      _fm.onTokenRefresh.listen(_send);
    } catch (_) {
      // Firebase sozlanmagan/ruxsat yo'q — push'siz davom etadi.
    }
  }

  /// Chiqishda — tokenni serverdan o'chiradi (boshqa hisobga push bormasin).
  Future<void> unregister() async {
    try {
      final token = await _fm.getToken();
      if (token != null) {
        await _dio.post('/profile/device-token/remove', data: {'token': token});
      }
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _send(String token) async {
    try {
      await _dio.post(
        '/profile/device-token',
        data: {'token': token, 'platform': 'android'},
      );
    } catch (_) {
      // best-effort — keyingi yangilanishda qayta urinadi
    }
  }
}

final pushServiceProvider =
    Provider<PushService>((ref) => PushService(ref.read(dioProvider)));
