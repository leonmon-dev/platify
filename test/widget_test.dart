
import 'package:flutter_test/flutter_test.dart';
import 'package:platify/isar_service.dart';
import 'package:platify/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final isarService = IsarService();
    await tester.pumpWidget(MyApp(isarService: isarService));

    // You can add more specific tests here in the future.
    expect(find.text('Accounts'), findsOneWidget);
  });
}
