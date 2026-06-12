import 'package:flutter_test/flutter_test.dart';
import 'package:macro_deck/main.dart';
import 'package:macro_deck/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Mock initial values for SharedPreferences
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MacroDeckApp());

    // Verify that our title is present.
    expect(find.text('MACRO-DECK'), findsOneWidget);
  });
}

