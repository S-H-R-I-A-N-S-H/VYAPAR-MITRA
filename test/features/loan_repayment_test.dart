import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vyapar_mitra/app/router.dart';
import 'package:vyapar_mitra/core/network/api_client.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/core/theme/app_theme.dart';
import 'package:vyapar_mitra/features/finance/models/financial_models.dart';
import 'package:vyapar_mitra/features/finance/providers/financial_provider.dart';
import 'package:vyapar_mitra/features/finance/screens/loan_repayment_screen.dart';

void main() {
  group('Phase 5: Loan & Repayment Planner Unit & Integration Tests', () {
    test('1. Full amortization schedule generation (correct months & balance progression)', () {
      final schedule = DeterministicFinancialCalculator.generateAmortizationSchedule(
        principal: 120000.0,
        annualRatePct: 9.0,
        tenureMonths: 60,
      );

      expect(schedule.length, 60);
      expect(schedule.first.month, 1);
      expect(schedule.first.openingBalance, 120000.0);

      // Verify opening/closing progression
      for (int i = 1; i < schedule.length; i++) {
        expect(
          schedule[i].openingBalance,
          equals(schedule[i - 1].closingBalance),
          reason: 'Month ${schedule[i].month} opening balance must match previous closing balance',
        );
      }
    });

    test('2. Zero-interest amortization schedule', () {
      final schedule = DeterministicFinancialCalculator.generateAmortizationSchedule(
        principal: 60000.0,
        annualRatePct: 0.0,
        tenureMonths: 12,
      );

      expect(schedule.length, 12);
      expect(schedule.first.interest, 0.0);
      expect(schedule.first.principal, 5000.0);
      expect(schedule.first.emi, 5000.0);
      expect(schedule.last.closingBalance, 0.0);
    });

    test('3. Normal-interest schedule and final balance is zero', () {
      final schedule = DeterministicFinancialCalculator.generateAmortizationSchedule(
        principal: 500000.0,
        annualRatePct: 9.5,
        tenureMonths: 36,
      );

      expect(schedule.length, 36);
      expect(schedule.first.openingBalance, 500000.0);
      expect(schedule.last.closingBalance, 0.0);
    });

    test('4. Principal + interest equals EMI for each month within rounding tolerance', () {
      final schedule = DeterministicFinancialCalculator.generateAmortizationSchedule(
        principal: 120000.0,
        annualRatePct: 9.0,
        tenureMonths: 60,
      );

      for (final item in schedule) {
        final sum = item.principal + item.interest;
        expect((sum - item.emi).abs() <= 0.05, isTrue,
            reason: 'Month ${item.month}: principal (${item.principal}) + interest (${item.interest}) must equal EMI (${item.emi})');
      }
    });

    testWidgets('5. Loan summary renders dynamically from FinancialProvider (not hardcoded)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Custom business scenario: Loan = 150,000, Own = 50,000, Total = 200,000
      final customSim = DeterministicFinancialCalculator.computeLocalFallback(
        totalProjectCost: 200000.0,
        ownCapital: 50000.0,
        annualRatePct: 9.0,
        tenureMonths: 60,
        projectedMonthlyRevenue: 75000.0,
        projectedMonthlyOperatingCost: 40000.0,
      );

      final customState = FinancialState(
        simulation: customSim,
        baseRevenue: 75000.0,
        baseOperatingCosts: 40000.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            financialProvider.overrideWith(
              (ref) => _StaticFinancialNotifier(customState),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoanRepaymentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Confirms custom dynamic values render, NOT hardcoded 120000 / 2491
      expect(find.text('₹150000'), findsWidgets);
      expect(find.text('₹3114 / mo'), findsWidgets);
      expect(find.text('Loan & Repayment Planner'), findsOneWidget);
      expect(find.text('Loan Summary & Terms'), findsOneWidget);
      expect(find.text('Payment Composition'), findsOneWidget);
      expect(find.text('First Payment Breakdown (Month 1)'), findsOneWidget);
      expect(find.text('Repayment Schedule'), findsOneWidget);
      expect(find.text('M1'), findsOneWidget);
    });

    testWidgets('6. Navigation from FinancialScenarioScreen to Loan Planner via EMI card CTA',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockHttp = MockClient((request) async {
        return http.Response('{"error": "offline"}', 500);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(httpClient: mockHttp, authToken: 'mock-token'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            initialRoute: AppRouter.financeModeler,
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Financial Planning'), findsOneWidget);
      expect(find.text('View Repayment Schedule →'), findsOneWidget);

      await tester.ensureVisible(find.text('View Repayment Schedule →'));
      await tester.tap(find.text('View Repayment Schedule →'));
      await tester.pumpAndSettle();

      // Verified: Navigated to Loan & Repayment Planner
      expect(find.text('Loan & Repayment Planner'), findsOneWidget);
      expect(find.text('Loan Summary & Terms'), findsOneWidget);
      expect(find.text('Payment Composition'), findsOneWidget);
    });

    testWidgets('7. Tenure comparison calculates 36 vs 60 mo without mutating base FinancialState',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final baseSim = DeterministicFinancialCalculator.computeLocalFallback(
        totalProjectCost: 180000.0,
        ownCapital: 60000.0,
        annualRatePct: 9.0,
        tenureMonths: 60,
        projectedMonthlyRevenue: 62000.0,
        projectedMonthlyOperatingCost: 33500.0,
      );

      final notifier = _StaticFinancialNotifier(
        FinancialState(simulation: baseSim),
      );

      final container = ProviderContainer(
        overrides: [
          financialProvider.overrideWith((ref) => notifier),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoanRepaymentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state has EMI of ₹2,491 for 60 months
      expect(container.read(financialProvider).simulation.monthlyEmi, 2491.0);

      // Verify tenure comparison tiles are rendered
      expect(find.text('3 Years (36 mo)'), findsOneWidget);
      expect(find.text('5 Years (60 mo)'), findsOneWidget);

      // Tap 5-year comparison tile
      await tester.ensureVisible(find.text('5 Years (60 mo)'));
      await tester.tap(find.text('5 Years (60 mo)'));
      await tester.pumpAndSettle();

      // Tap 3-year comparison tile
      await tester.ensureVisible(find.text('3 Years (36 mo)'));
      await tester.tap(find.text('3 Years (36 mo)'));
      await tester.pumpAndSettle();

      // Verify base FinancialState was NOT mutated
      expect(container.read(financialProvider).simulation.monthlyEmi, 2491.0);
      expect(container.read(financialProvider).simulation.requiredLoanAmount, 120000.0);
    });
  });
}

class _StaticFinancialNotifier extends FinancialNotifier {
  _StaticFinancialNotifier(FinancialState initialState) {
    state = initialState;
  }
}
