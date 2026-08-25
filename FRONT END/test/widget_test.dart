import 'package:flutter_test/flutter_test.dart';
import 'package:smart_poultry_farm/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NovaraApp());
    expect(find.byType(NovaraApp), findsOneWidget);
  });
}
