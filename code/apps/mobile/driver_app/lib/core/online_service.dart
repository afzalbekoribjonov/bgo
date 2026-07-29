import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Fonda online turish (foreground service). Haydovchi «Liniyaga chiqish»
/// bosganda ishga tushadi va ilova fonda/yopiq bo'lsa ham har ~12s joriy GPS'ni
/// backendga yuboradi — shunda haydovchi online qoladi va yangi buyurtma
/// (FCM to'liq ekran signali) kelaveradi. «Ishni yakunlash»da to'xtaydi.
class OnlineService {
  static bool _inited = false;

  /// main() da bir marta — foreground task sozlamalari.
  static void init() {
    if (_inited) return;
    _inited = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'beshariq_online',
        channelName: 'Liniyada',
        channelDescription: "Haydovchi liniyada — buyurtma kutilmoqda",
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(12000), // 12s
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// «Liniyaga chiqish» — servisni ishga tushiradi (idempotent).
  static Future<void> start() async {
    init();
    try {
      if (await FlutterForegroundTask.checkNotificationPermission() !=
          NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (_) {/* ruxsatsiz ham davom etadi */}
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 7700,
      notificationTitle: 'Liniyadasiz',
      notificationText: 'Buyurtma kutilmoqda',
      callback: startOnlineCallback,
    );
  }

  /// «Ishni yakunlash» — servisni to'xtatadi.
  static Future<void> stop() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }
}

/// Foreground isolate kirish nuqtasi (alohida isolate).
@pragma('vm:entry-point')
void startOnlineCallback() {
  DartPluginRegistrant.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(_OnlinePingHandler());
}

/// Fonda har ~12s joylashuvni yuboradi (driver online qoladi).
class _OnlinePingHandler extends TaskHandler {
  final TokenStorage _tokens = TokenStorage();
  Dio? _dio;

  Future<Dio?> _client() async {
    final token = await _tokens.readAccess();
    if (token == null) return null;
    _dio ??= Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio!.options.headers['Authorization'] = 'Bearer $token';
    return _dio;
  }

  Future<void> _ping() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final dio = await _client();
      if (dio == null) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await dio.post('/driver/location', data: {
        'lat': pos.latitude,
        'lng': pos.longitude,
        if (pos.heading >= 0) 'heading': pos.heading,
      });
    } catch (_) {/* tarmoq/GPS — jim o'tkazamiz */}
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) => _ping();

  @override
  void onRepeatEvent(DateTime timestamp) {
    _ping();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
