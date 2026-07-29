import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_gate.dart';
import 'package:beshariq_core/beshariq_core.dart';
import 'l10n/generated/app_localizations.dart';

/// Ilova fonda/yopiq bo'lganda kelgan push (alohida isolate).
/// Yangi buyurtma (type==offer) bo'lsa — to'liq ekran signal: jiringlash +
/// vibratsiya + ekran yonadi (boshqa ilova/lock ustidan ham).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await showOfferAlert(message);
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase sozlanmagan bo'lsa ham ilova ishlayveradi (push'siz).
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await initPushNotifications();
  } catch (_) {}
  runApp(const ProviderScope(child: DriverApp()));
}

/// Beshariq haydovchi (kuryer) ilovasi. plan/06-driver-app.md
class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
    );
  }
}
