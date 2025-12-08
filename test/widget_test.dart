import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MyApp(),
    );

    // You can add more specific tests here in the future.
    expect(find.text('Accounts'), findsOneWidget);
  });
}
