import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Yuqori muhimlikdagi bildirishnoma kanali (banner + ovoz).
const AndroidNotificationChannel kPushChannel = AndroidNotificationChannel(
  'beshariq_default',
  'Bildirishnomalar',
  description: 'Buyurtma, taksi va dostavka xabarlari',
  importance: Importance.high,
);

/// Yangi buyurtma signali kanali — MAX muhimlik, ovoz + vibratsiya, to'liq
/// ekran (full screen intent). Haydovchi ilovasi uchun: telefon jiringlaydi va
/// ekran boshqa ilova ustidan ham yonadi.
const AndroidNotificationChannel kOfferChannel = AndroidNotificationChannel(
  'beshariq_offer',
  'Yangi buyurtmalar',
  description: 'Yangi buyurtma takliflari (ovoz + ekran)',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();
bool _localInited = false;

/// Local bildirishnoma plaginini va kanallarni tayyorlaydi (idempotent).
/// Background isolate (yopiq ilova push'i) ham shu orqali init qiladi.
Future<void> _ensureLocalInit() async {
  if (_localInited) return;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifications.initialize(
    const InitializationSettings(android: androidInit),
  );
  final android = _localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(kPushChannel);
  await android?.createNotificationChannel(kOfferChannel);
  _localInited = true;
}

/// Push bannerlarini ko'rsatishni sozlaydi (kanal + foreground tinglovchi).
/// main() da Firebase.initializeApp dan keyin bir marta chaqiriladi.
Future<void> initPushNotifications() async {
  await _ensureLocalInit();
  // Foreground: oddiy xabarlarni banner qilamiz. Yangi buyurtma (type==offer)
  // foreground'da ilovaning O'ZI (bosh ekran poll + banner + ovoz) bilan
  // ko'rsatiladi — bu yerda takror signal bermaymiz.
  FirebaseMessaging.onMessage.listen((m) {
    if (m.data['type'] == 'offer') return;
    showLocalFromRemote(m);
  });
}

/// FCM xabaridan local banner ko'rsatadi. Notification qismi bo'lmasa
/// (data-only push) — data ichidagi title/body dan foydalanadi, shunda
/// hech bir xabar foreground'da "jimgina yo'qolib" ketmaydi.
Future<void> showLocalFromRemote(RemoteMessage message) async {
  final n = message.notification;
  final title = n?.title ?? (message.data['title'] as String?);
  final body = n?.body ?? (message.data['body'] as String?);
  if ((title ?? '').isEmpty && (body ?? '').isEmpty) return;
  await _ensureLocalInit();
  await _localNotifications.show(
    (title ?? body).hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        kPushChannel.id,
        kPushChannel.name,
        channelDescription: kPushChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: message.data['type'] as String?,
  );
}

/// Yangi buyurtma (type==offer) data-push'i uchun TO'LIQ EKRAN signal.
/// Ilova fonda/yopiq bo'lsa ham background handler shuni chaqiradi: telefon
/// jiringlaydi, vibratsiya, ekran yonadi va boshqa ilova/lock ustidan ko'rinadi.
/// Bosilsa ilova ochiladi va bosh ekran taklifni ko'rsatadi.
Future<void> showOfferAlert(RemoteMessage message) async {
  final data = message.data;
  if (data['type'] != 'offer') {
    await showLocalFromRemote(message);
    return;
  }
  await _ensureLocalInit();
  final title = (data['title'] as String?) ?? 'Yangi buyurtma';
  final body = (data['body'] as String?) ?? '';
  await _localNotifications.show(
    7711, // barqaror id — bir vaqtda bitta taklif signali
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        kOfferChannel.id,
        kOfferChannel.name,
        channelDescription: kOfferChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        ticker: 'Yangi buyurtma',
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: 'offer:${data['orderId'] ?? ''}',
  );
}

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
