import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/app/app.dart';

void main() {
  testWidgets('App initializes and shows Vyapar Mitra', (WidgetTester tester) async {
    await tester.pumpWidget(const VyaparMitraApp());
    await tester.pumpAndSettle();

    // Verify app name is rendered on the screen
    expect(find.text('VYAPAR MITRA'), findsOneWidget);
  });
}
