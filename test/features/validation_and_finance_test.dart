import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/features/finance/screens/financial_scenario_screen.dart';
import 'package:vyapar_mitra/features/recommendations/screens/action_plan_screen.dart';
import 'package:vyapar_mitra/features/research/screens/research_progress_screen.dart';
import 'package:vyapar_mitra/features/validation/screens/validation_dashboard_screen.dart';

void main() {
  group('Validation & Finance Screens Tests', () {
    testWidgets('ResearchProgressScreen renders scanner and pipeline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResearchProgressScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Live Market Research'), findsOneWidget);
      expect(find.text('LIVE MARKET FINDING'), findsOneWidget);
      expect(find.text('Research Pipeline'), findsOneWidget);
      expect(find.text('View Validation Dashboard →'), findsOneWidget);
    });

    testWidgets('ValidationDashboardScreen renders 6 pillars and assessment',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ValidationDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Validation Dashboard'), findsOneWidget);
      expect(find.text('Overall: Promising with Conditions'), findsOneWidget);
      expect(find.text('Customer Demand'), findsOneWidget);
      expect(find.text('Competition'), findsOneWidget);
      expect(find.text('Pricing & Margin'), findsOneWidget);
      expect(find.text('Raw Material Supply'), findsOneWidget);
      expect(find.text('Regulatory & Licenses'), findsOneWidget);
      expect(find.text('Government Schemes'), findsOneWidget);
      expect(find.text('Simulate Financials & What-If →'), findsOneWidget);
    });

    testWidgets('FinancialScenarioScreen renders cash flow and what-if modeler',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FinancialScenarioScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Planning'), findsOneWidget);
      expect(find.text('Setup Capital & Loan'), findsOneWidget);
      expect(find.text('Total Setup Cost'), findsOneWidget);
      expect(find.text('Monthly Cash Flow (Expected)'), findsOneWidget);
      expect(find.text('What if sales are lower?'), findsOneWidget);
      expect(find.text('View Final Action Plan & Milestones →'), findsOneWidget);
    });

    testWidgets('ActionPlanScreen renders green light verdict and 4-week checklist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActionPlanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Executive Summary'), findsOneWidget);
      expect(find.text('Validated Strategy • Green Light'), findsOneWidget);
      expect(find.text('Start with a 100 kg/day Mini-Pilot'), findsOneWidget);
      expect(find.text('3 Core Guardrails for Safe Operation'), findsOneWidget);
      expect(find.text('4-Week Milestone Checklist'), findsOneWidget);
      expect(find.text('Submit PMEGP Subsidy Application'), findsOneWidget);
      expect(find.text('Share Action Plan (WhatsApp / PDF)'), findsOneWidget);
    });
  });
}
