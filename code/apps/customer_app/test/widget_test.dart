// Beshariq mijoz ilovasi — asosiy smoke test.
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/main.dart';

void main() {
  testWidgets('Ilova ishga tushadi va bosh ekran ko\'rinadi', (tester) async {
    await tester.pumpWidget(const BeshariqApp());
    await tester.pumpAndSettle();

    // Standart til (uz) da ilova nomi va xizmatlar ko'rinishi kerak
    expect(find.text('Beshariq'), findsWidgets);
    expect(find.text('Ovqat'), findsOneWidget);
    expect(find.text('Taksi'), findsOneWidget);
    expect(find.text('Dostavka'), findsOneWidget);
  });
}
