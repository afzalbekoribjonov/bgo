// Beshariq mijoz ilovasi — asosiy smoke testlar.
import 'package:customer_app/core/providers.dart';
import 'package:customer_app/core/token_storage.dart';
import 'package:customer_app/features/restaurant/restaurant_api.dart';
import 'package:customer_app/features/restaurant/restaurant_list_screen.dart';
import 'package:customer_app/features/restaurant/restaurant_models.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:customer_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testda platforma kanalisiz ishlovchi soxta token saqlovchi.
class _FakeTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;

  @override
  Future<String?> readAccess() async => _access;

  @override
  Future<String?> readRefresh() async => _refresh;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

void main() {
  testWidgets('Ilova ochilganda kirish ekrani ko\'rinadi', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        ],
        child: const BeshariqApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Beshariq'), findsWidgets);
    expect(find.text('Kod yuborish'), findsOneWidget);
  });

  testWidgets('Oshxonalar ro\'yxati ko\'rinadi', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantsProvider.overrideWith(
            (ref) async => const [
              RestaurantSummary(
                id: 'r1',
                name: 'Test Oshxona',
                address: 'Beshariq',
                isOpen: true,
                rating: 4.5,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          locale: Locale('uz'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RestaurantListScreen(),
        ),
      ),
    );

    await tester.pump(); // loading
    await tester.pump(); // data

    expect(find.text('Test Oshxona'), findsOneWidget);
    expect(find.text('Oshxonalar'), findsOneWidget);
  });
}
