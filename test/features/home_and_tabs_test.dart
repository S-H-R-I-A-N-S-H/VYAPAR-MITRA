import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/app/main_navigation_shell.dart';
import 'package:vyapar_mitra/app/router.dart';
import 'package:vyapar_mitra/core/models/business_lifecycle.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/core/theme/app_theme.dart';
import 'package:vyapar_mitra/features/analyzer/screens/analyzer_screen.dart';
import 'package:vyapar_mitra/features/finance/screens/finance_home_screen.dart';
import 'package:vyapar_mitra/features/home/screens/home_screen.dart';
import 'package:vyapar_mitra/features/learn/screens/learn_screen.dart';

void main() {
  group('Vyapar Mitra 4-Page Navigation & Stage-Aware Home Tests', () {
    testWidgets('MainNavigationShell renders persistent 4 tabs and switches between them',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainNavigationShell(),
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ── Tab 0: Home ────────────────────────────────────────────────────────
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('NEXT BEST ACTION'), findsOneWidget);
      expect(find.text('Research & Ground Signals'), findsOneWidget);
      expect(find.text('Capital & Subsidy Status'), findsOneWidget);

      // Verify bottom navigation bar has 4 tabs
      final navBar = find.byType(NavigationBar);
      expect(find.descendant(of: navBar, matching: find.text('Home')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Analyzer')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Finance')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Learn')), findsOneWidget);

      // ── Switch to Tab 1: Analyzer ──────────────────────────────────────────
      await tester.tap(find.descendant(of: navBar, matching: find.text('Analyzer')));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyzerScreen), findsOneWidget);
      expect(find.text('Business Analyzer Hub'), findsOneWidget);
      expect(find.text('1. Business Opportunity Discovery'), findsOneWidget);
      expect(find.text('5. Feasibility (6 Pillars)'), findsOneWidget);

      // ── Switch to Tab 2: Finance ───────────────────────────────────────────
      await tester.tap(find.descendant(of: navBar, matching: find.text('Finance')));
      await tester.pumpAndSettle();

      expect(find.byType(FinanceHomeScreen), findsOneWidget);
      expect(find.text('Finance & Capital Hub'), findsOneWidget);
      expect(find.text('Funding & Capital Overview'), findsOneWidget);
      expect(find.text('Financial Safety Principle'), findsOneWidget);
      expect(find.text('PMEGP (पीएमईजीपी योजना)'), findsOneWidget);

      // ── Switch to Tab 3: Learn ─────────────────────────────────────────────
      await tester.tap(find.descendant(of: navBar, matching: find.text('Learn')));
      await tester.pumpAndSettle();

      expect(find.byType(LearnScreen), findsOneWidget);
      expect(find.text('Business Knowledge Hub'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Business Tips'), findsOneWidget);
      expect(find.text('Schemes'), findsOneWidget);
    });

    testWidgets('HomeScreen dynamically updates Next Best Action for different lifecycle stages',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default stage is DISCOVER
      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.text('AI Interview & Opportunity Discovery'), findsOneWidget);
      expect(find.text('Continue Discovery →'), findsOneWidget);

      // Change stage to VALIDATE
      container.read(businessLifecycleProvider.notifier).setStage(BusinessLifecycleStage.validate);
      await tester.pumpAndSettle();

      expect(find.text('VALIDATE'), findsOneWidget);
      expect(find.text('Field Research & Evidence Pipeline'), findsOneWidget);
      expect(find.text('Complete Next Research Task →'), findsOneWidget);

      // Change stage to DECIDE
      container.read(businessLifecycleProvider.notifier).setStage(BusinessLifecycleStage.decide);
      await tester.pumpAndSettle();

      expect(find.text('DECIDE'), findsOneWidget);
      expect(find.text('Final Recommendation & Confidence'), findsOneWidget);
      expect(find.text('Review Recommendation →'), findsOneWidget);

      // Change stage to FINANCE PLANNING
      container.read(businessLifecycleProvider.notifier).setStage(BusinessLifecycleStage.financePlanning);
      await tester.pumpAndSettle();

      expect(find.text('FINANCE'), findsOneWidget);
      expect(find.text('Project Cost, Schemes & Affordability'), findsOneWidget);
      expect(find.text('Check Affordability →'), findsOneWidget);

      // Change stage to STARTED
      container.read(businessLifecycleProvider.notifier).setStage(BusinessLifecycleStage.started);
      await tester.pumpAndSettle();

      expect(find.text('OPERATING'), findsOneWidget);
      expect(find.text('AI Business Insights & Daily Logbook'), findsOneWidget);
      expect(find.text('View Latest Insight →'), findsOneWidget);

      // Change stage to GROWTH
      container.read(businessLifecycleProvider.notifier).setStage(BusinessLifecycleStage.growth);
      await tester.pumpAndSettle();

      expect(find.text('GROWTH'), findsOneWidget);
      expect(find.text('Expansion Targets & Growth Capacity'), findsOneWidget);
      expect(find.text('Analyze Growth →'), findsOneWidget);
    });

    testWidgets('MainNavigationShell renders correctly in Hindi',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      container.read(localeProvider.notifier).setLocale('hi');
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainNavigationShell(),
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Hindi labels in navigation bar
      expect(find.text('होम'), findsOneWidget);
      expect(find.text('विश्लेषक'), findsOneWidget);
      expect(find.text('वित्त'), findsOneWidget);
      expect(find.text('ज्ञान'), findsOneWidget);

      // Check Hindi Home contents
      expect(find.text('अगला सबसे महत्वपूर्ण कदम'), findsOneWidget);
      expect(find.text('पहचान चरण'), findsOneWidget);
      expect(find.text('शोध एवं जमीनी साक्ष्य'), findsOneWidget);
      expect(find.text('पूंजी व सरकारी सब्सिडी'), findsOneWidget);

      // Switch to Hindi Analyzer
      await tester.tap(find.text('विश्लेषक'));
      await tester.pumpAndSettle();

      expect(find.text('व्यापार विश्लेषक हब'), findsOneWidget);
      expect(find.text('1. व्यवसाय अवसर खोज'), findsOneWidget);

      // Switch to Hindi Finance
      await tester.tap(find.text('वित्त'));
      await tester.pumpAndSettle();

      expect(find.text('वित्त एवं ऋण योजना'), findsOneWidget);
      expect(find.text('सुरक्षा नियम • Financial Safety Principle'), findsOneWidget);

      // Switch to Hindi Learn
      await tester.tap(find.text('ज्ञान'));
      await tester.pumpAndSettle();

      expect(find.text('व्यापार ज्ञान एवं शिक्षा'), findsOneWidget);
      expect(find.text('सभी'), findsOneWidget);
    });
  });
}
