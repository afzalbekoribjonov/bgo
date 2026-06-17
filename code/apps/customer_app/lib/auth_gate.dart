import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/consent_screen.dart';
import 'features/auth/login_flow.dart';
import 'features/home/home_screen.dart';

/// Auth holatiga qarab to'g'ri ekranni ko'rsatadi (deklarativ navigatsiya).
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Saqlangan sessiyani tiklash (token bor-yo'qligini tekshirish).
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).status;
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
