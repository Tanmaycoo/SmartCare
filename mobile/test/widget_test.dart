import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare/main.dart';

void main() {
  testWidgets('SmartCare login screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SmartCareApp());
    await tester.pump();

    // Verify that the brand name SMARTCARE is displayed
    expect(find.text('SMARTCARE'), findsOneWidget);
    // Verify the sign in label is present
    expect(find.text('Sign in to continue'), findsOneWidget);
    // Verify the SIGN IN button is present
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
