// Beshariq mijoz ilovasi — asosiy smoke test.
import 'package:customer_app/core/providers.dart';
import 'package:customer_app/core/token_storage.dart';
import 'package:customer_app/main.dart';
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

    // bootstrap (token yo'q) -> unauthenticated -> LoginFlow
    await tester.pump(); // Splash
    await tester.pump(); // holat yangilandi
    await tester.pump();

    // Standart til (uz) da kirish ekrani elementlari
    expect(find.text('Beshariq'), findsWidgets);
    expect(find.text('Kod yuborish'), findsOneWidget);
  });
}
