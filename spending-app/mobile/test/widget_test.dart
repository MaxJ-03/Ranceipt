import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('Ranceipt app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const RanceiptApp());
    await tester.pumpAndSettle();

    expect(find.text('Ranceipt'), findsOneWidget);
  });
}
