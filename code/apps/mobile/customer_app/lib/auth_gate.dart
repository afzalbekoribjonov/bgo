import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'core/location_service.dart';
import 'core/navigation.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/consent_screen.dart';
import 'features/auth/login_flow.dart';
import 'features/home/home_screen.dart';
import 'features/kitchen/kitchen_home_screen.dart';
import 'features/profile/profile_api.dart';

/// Auth holatiga qarab to'g'ri ekranni ko'rsatadi (deklarativ navigatsiya).
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _pushRegistered = false;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  @override
  void initState() {
    super.initState();
    // Saqlangan sessiyani tiklash (token bor-yo'qligini tekshirish).
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );
  }

  @override
  void dispose() {
    _openedSub?.cancel();
    _foregroundSub?.cancel();
    super.dispose();
  }

  /// Push-bildirishnoma payload'iga qarab to'g'ridan-to'g'ri tegishli
  /// ekranga o'tadi — masalan yangi buyurtma push'ida oshxona egasi darhol
  /// native "Mening oshxonam" panelining Buyurtmalar tabiga tushadi.
  void _handleDeepLink(RemoteMessage message) {
    final type = message.data['type'];
    final restaurantId = message.data['restaurantId'] as String?;
    if (type == 'kitchen_order' && restaurantId != null && restaurantId.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => KitchenHomeScreen(restaurantId: restaurantId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).status;
    // Kirilgach FCM tokenini bir marta ro'yxatga olamiz (best-effort).
    if (status == AuthStatus.authenticated && !_pushRegistered) {
      _pushRegistered = true;
      Future.microtask(() {
        ref.read(pushServiceProvider).registerToken();
        // Kirishda joylashuv (GPS) ruxsatini so'raymiz — taksi/dostavka uchun.
        ref.read(locationServiceProvider).ensurePermission();
        // Hamkor (oshxona/do'kon) egaligi — bir marta tekshirib keshlaymiz,
        // "Mening oshxonam"/"Mening do'konim" kartalari ilova ochilganda
        // darhol (qayta tekshirmasdan) ko'rinishi uchun.
        ref.read(kitchenLinkProvider.notifier).bootstrap();
        ref.read(sellerShopLinkProvider.notifier).bootstrap();
        // Push chuqur-havola: ilova bildirishnoma orqali sovuq/issiq
        // ishga tushgan bo'lsa — darhol tegishli ekranga o'tadi.
        FirebaseMessaging.instance.getInitialMessage().then((m) {
          if (m != null) _handleDeepLink(m);
        }).catchError((_) {});
        _openedSub ??= ref.read(pushServiceProvider).onMessageOpened.listen(_handleDeepLink);
        // Ilova OCHIQ paytda kelgan yangi-buyurtma push'i — bosiladigan banner
        // (fondagi/yopiq holat allaqachon _handleDeepLink orqali qamrab olingan).
        _foregroundSub ??= ref.read(pushServiceProvider).onForegroundMessage.listen((m) {
          if (m.data['type'] != 'kitchen_order') return;
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;
          // navigatorKey.currentContext — widgetning o'z BuildContext'i emas,
          // har chaqiruvda YANGI olinadi (async gap orqasidan saqlanmaydi).
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('Yangi buyurtma keldi'),
              action: SnackBarAction(label: "Ko'rish", onPressed: () => _handleDeepLink(m)),
              duration: const Duration(seconds: 6),
            ),
          );
        });
      });
    } else if (status == AuthStatus.unauthenticated) {
      _pushRegistered = false;
    }
    return switch (status) {
      AuthStatus.unknown => const _Splash(),
      AuthStatus.unauthenticated => const LoginFlow(),
      AuthStatus.needsConsent => const ConsentScreen(),
      AuthStatus.authenticated => const HomeScreen(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
