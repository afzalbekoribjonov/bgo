import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_flow.dart';
import 'features/delivery/delivery_board_screen.dart';

/// Auth holatiga qarab ekran ko'rsatadi.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _pushRegistered = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).status;
    // Kirilgach FCM tokenini bir marta ro'yxatga olamiz (best-effort).
    if (status == AuthStatus.authenticated && !_pushRegistered) {
      _pushRegistered = true;
      Future.microtask(() => ref.read(pushServiceProvider).registerToken());
    } else if (status == AuthStatus.unauthenticated) {
      _pushRegistered = false;
    }
    return switch (status) {
      AuthStatus.unknown => const _Splash(),
      AuthStatus.unauthenticated => const LoginFlow(),
      AuthStatus.authenticated => const DeliveryBoardScreen(),
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
