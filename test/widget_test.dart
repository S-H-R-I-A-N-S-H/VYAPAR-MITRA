import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/app/app.dart';

void main() {
  testWidgets('App initializes and shows Vyapar Mitra', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VyaparMitraApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify app name is rendered on the screen
    expect(find.text('VYAPAR MITRA'), findsWidgets);
  });
}
