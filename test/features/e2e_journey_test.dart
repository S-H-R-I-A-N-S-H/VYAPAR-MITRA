import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/app/router.dart';
import 'package:vyapar_mitra/core/theme/app_theme.dart';

void main() {
  group('Vyapar Mitra Complete E2E User Journey', () {
    testWidgets('Traverses full 10-screen flow from Welcome to Action Plan',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'Vyapar Mitra',
            theme: AppTheme.lightTheme,
            initialRoute: AppRouter.welcome,
            routes: AppRouter.routes,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // --- 1. Welcome Screen ---
      expect(find.text('VYAPAR MITRA'), findsWidgets);
      expect(find.text('Turn Your Business Idea Into Reality'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 2. Language Selection Screen ---
      expect(find.text('Choose Your Language'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 3. Business Profile Screen ---
      expect(find.text('Your Business Situation'), findsOneWidget);
      expect(find.text('Starting a New Idea'), findsOneWidget);
      expect(find.text('Continue to AI Interview'), findsOneWidget);

      await tester.tap(find.text('Continue to AI Interview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 4. Conversational Interview Screen ---
      expect(find.text('AI Discovery Session'), findsOneWidget);
      expect(find.text('View Tailored Opportunities'), findsOneWidget);

      await tester.tap(find.text('View Tailored Opportunities'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 5. Curated Opportunities Screen ---
      expect(find.text('Curated Opportunities'), findsOneWidget);
      expect(find.text('Select & Validate Business'), findsWidgets);

      await tester.tap(find.text('Select & Validate Business').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 6. Business Confirmation Checkpoint ---
      expect(find.text('Confirm Selected Opportunity'), findsOneWidget);
      expect(find.text('Proceed to Market Research'), findsOneWidget);

      await tester.tap(find.text('Proceed to Market Research'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 7. Research Step Progress Screen ---
      expect(find.text('LIVE MARKET RESEARCH'), findsOneWidget);
      expect(find.text('View Validation Report'), findsOneWidget);

      await tester.tap(find.text('View Validation Report'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 8. Validation Dashboard Screen ---
      expect(find.text('VALIDATION DASHBOARD'), findsOneWidget);
      expect(find.text('Explore Financial Scenarios'), findsOneWidget);

      await tester.tap(find.text('Explore Financial Scenarios'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 9. Financial Scenario Screen ---
      expect(find.text('FINANCIAL VIABILITY'), findsOneWidget);
      expect(find.text('View Final Recommendation'), findsOneWidget);

      await tester.tap(find.text('View Final Recommendation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 10. Action Plan Screen ---
      expect(find.text('PROCEED TO LAUNCH (GO)'), findsOneWidget);
      expect(find.text('Comprehensive Business Recommendation'), findsOneWidget);
      expect(find.text('4-Week Launch Checklist'), findsOneWidget);
      expect(find.text('Return to Dashboard / Home'), findsOneWidget);
    });
  });
}
