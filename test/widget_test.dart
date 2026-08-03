import 'package:flutter_test/flutter_test.dart';
import 'package:nltime/common/app_service.dart';
import 'package:nltime/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('NLTime app launch smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppService.init();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('NLTime'), findsWidgets);
  });
}
