import 'package:flutter_test/flutter_test.dart';
import 'package:ethara_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EtharaApp());
    expect(find.byType(EtharaApp), findsOneWidget);
  });
}
