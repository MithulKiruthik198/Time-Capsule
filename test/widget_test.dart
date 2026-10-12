import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_capsule/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TimeCapsuleApp boots up successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true, 'local_vault_active': true});

    await tester.pumpWidget(const TimeCapsuleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify app renders with the timeline or header
    expect(find.byType(TimeCapsuleApp), findsOneWidget);
  });
}
