// Beshariq haydovchi ilovasi — asosiy smoke test.
import 'package:beshariq_core/beshariq_core.dart';
import 'package:driver_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  testWidgets('Ilova ochilganda haydovchi kirish ekrani ko\'rinadi',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        ],
        child: const DriverApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Kod yuborish'), findsOneWidget);
  });
}
