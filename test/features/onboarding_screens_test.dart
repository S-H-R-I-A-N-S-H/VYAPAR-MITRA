import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/features/onboarding/screens/language_selection_screen.dart';
import 'package:vyapar_mitra/features/onboarding/screens/welcome_screen.dart';

void main() {
  group('Onboarding Screens Tests', () {
    testWidgets('WelcomeScreen renders key value propositions and CTAs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check title and key features
      expect(find.text('VYAPAR MITRA'), findsOneWidget);
      expect(find.text('Turn Your Business Idea Into Reality'), findsOneWidget);
      expect(find.text('Local Market Signals'), findsOneWidget);
      expect(find.text('Government Schemes & Subsidies'), findsOneWidget);
      expect(find.text('Clear Action Checklist'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('LanguageSelectionScreen renders Indic language options and selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LanguageSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check language options
      expect(find.text('Choose Your Language'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('मराठी'), findsOneWidget);
      expect(find.text('ગુજરાતી'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Hindi option
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      // Check checkmark indicator
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
