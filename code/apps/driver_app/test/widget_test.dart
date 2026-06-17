// Beshariq haydovchi ilovasi — asosiy smoke test.
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_app/main.dart';

void main() {
  testWidgets('Haydovchi ilovasi ishga tushadi', (tester) async {
    await tester.pumpWidget(const DriverApp());
    await tester.pumpAndSettle();

    expect(find.text('Beshariq Haydovchi'), findsWidgets);
  });
}
