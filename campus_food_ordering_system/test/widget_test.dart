import 'package:flutter_test/flutter_test.dart';
import 'package:campus_food_ordering_system/app.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Verify the app renders the prototype splash branding.
    expect(find.text('Fresco\'s'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
  });
}
