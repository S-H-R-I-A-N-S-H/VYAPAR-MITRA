import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vyapar_mitra/core/network/api_client.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/core/theme/app_theme.dart';
import 'package:vyapar_mitra/features/finance/models/financial_models.dart';
import 'package:vyapar_mitra/features/finance/screens/financial_scenario_screen.dart';

void main() {
  group('Financial Calculator & Simulation Integration Tests', () {
    test('1. DeterministicFinancialCalculator matches authoritative reducing-balance math', () {
      final emi = DeterministicFinancialCalculator.calculateEmi(
        principal: 120000.0,
        annualRatePct: 9.0,
        tenureMonths: 60,
      );
      expect(emi, 2491.0);

      final sim = DeterministicFinancialCalculator.computeLocalFallback(
        totalProjectCost: 180000.0,
        ownCapital: 60000.0,
        projectedMonthlyRevenue: 62000.0,
        projectedMonthlyOperatingCost: 33500.0,
        annualRatePct: 9.0,
        tenureMonths: 60,
      );

      expect(sim.requiredLoanAmount, 120000.0);
      expect(sim.monthlyEmi, 2491.0);
      expect(sim.projectedMonthlyProfit, 28500.0);
      expect(sim.netCashFlowAfterEmi, 26009.0);
      expect(sim.debtServiceCoverageRatio, 11.44);
      expect(sim.isAffordable, true);
      expect(sim.affordabilityRiskLevel, 'safe');
    });

    testWidgets('2. Screen calls POST /finance/scenarios when business_id exists and renders backend results',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool scenarioEndpointCalled = false;

      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/finance/scenarios')) {
          scenarioEndpointCalled = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['business_id'], 'test-biz-uuid-001');

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'scen-uuid-001',
                'business_id': 'test-biz-uuid-001',
                'scenario_name': 'Base Scenario',
                'simulation_result': {
                  'total_project_cost': 180000.0,
                  'own_capital': 60000.0,
                  'required_loan_amount': 120000.0,
                  'monthly_emi': 2491.0,
                  'total_interest_payable': 29460.0,
                  'total_repayment_amount': 149460.0,
                  'projected_monthly_profit': 28500.0,
                  'net_cash_flow_after_emi': 26009.0,
                  'debt_service_coverage_ratio': 11.44,
                  'is_affordable': true,
                  'affordability_risk_level': 'safe',
                  'affordability_rationale':
                      'Healthy debt coverage (DSCR 11.44). Net surplus after EMI is 26,009 per month.',
                  'amortization_preview': [],
                },
                'explanation': {
                  'executive_summary': 'Healthy viability with 2,491 EMI.',
                },
              },
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('{"error": "not found"}', 404);
      });

      final businessNotifier = SelectedBusinessNotifier();
      businessNotifier.selectBusiness(
        const SelectedBusinessState(
          businessId: 'test-biz-uuid-001',
          title: 'Cold-Press Mustard Oil Mill',
          estimatedCapital: 180000.0,
          monthlyRevenue: 62000.0,
          monthlyOperatingCosts: 33500.0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(httpClient: mockHttp, authToken: 'mock-token'),
            ),
            selectedBusinessProvider.overrideWith((ref) => businessNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FinancialScenarioScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(scenarioEndpointCalled, true);
      expect(find.text('Financial Planning'), findsOneWidget);
      expect(find.text('₹180000'), findsOneWidget); // Setup cost
      expect(find.text('₹60000'), findsOneWidget); // Own capital
      expect(find.text('₹120000'), findsOneWidget); // Subsidized loan
      expect(find.text('₹2491 / mo'), findsOneWidget); // Real EMI
      expect(find.text('₹26009 / month'), findsOneWidget); // Real Net Cash
      expect(find.text('Surplus Safe'), findsOneWidget);
    });

    testWidgets('3. What-if chips trigger POST /finance/scenarios/{id}/what-if and update cash flow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool whatIfCalled = false;

      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/finance/scenarios')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'scen-uuid-001',
                'business_id': 'test-biz-uuid-001',
                'scenario_name': 'Base Scenario',
                'simulation_result': {
                  'total_project_cost': 180000.0,
                  'own_capital': 60000.0,
                  'required_loan_amount': 120000.0,
                  'monthly_emi': 2491.0,
                  'total_interest_payable': 29460.0,
                  'total_repayment_amount': 149460.0,
                  'projected_monthly_profit': 28500.0,
                  'net_cash_flow_after_emi': 26009.0,
                  'debt_service_coverage_ratio': 11.44,
                  'is_affordable': true,
                  'affordability_risk_level': 'safe',
                  'affordability_rationale': 'Healthy debt coverage.',
                },
              },
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path.contains('/what-if')) {
          whatIfCalled = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['revenue_drop_pct'], 20.0);

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'scenario_id': 'scen-uuid-001',
                'base_case': {
                  'monthly_profit': 28500.0,
                  'net_cash_flow': 26009.0,
                  'dscr': 11.44,
                  'affordability_risk_level': 'safe',
                },
                'stressed_case': {
                  'monthly_profit': 16100.0,
                  'net_cash_flow': 13609.0,
                  'dscr': 6.46,
                  'affordability_risk_level': 'moderate',
                },
                'stress_summary':
                    'Under a 20% revenue drop, net monthly cash flow moves to 13,609. Risk tier changes to MODERATE.',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('{"error": "not found"}', 404);
      });

      final businessNotifier = SelectedBusinessNotifier();
      businessNotifier.selectBusiness(
        const SelectedBusinessState(
          businessId: 'test-biz-uuid-001',
          estimatedCapital: 180000.0,
          monthlyRevenue: 62000.0,
          monthlyOperatingCosts: 33500.0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(httpClient: mockHttp, authToken: 'mock-token'),
            ),
            selectedBusinessProvider.overrideWith((ref) => businessNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FinancialScenarioScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "-20% Slow" scenario chip
      expect(find.text('-20% Slow'), findsOneWidget);
      await tester.ensureVisible(find.text('-20% Slow'));
      await tester.tap(find.text('-20% Slow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(whatIfCalled, true);
      expect(find.text('₹13609 / month'), findsOneWidget);
      expect(find.text('Tight Margin'), findsOneWidget);
    });

    testWidgets('4. Missing business_id safely calls POST /finance/simulate without foreign key violation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool simulateCalled = false;
      bool scenarioCalled = false;

      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/finance/simulate')) {
          simulateCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'total_project_cost': 180000.0,
                'own_capital': 60000.0,
                'required_loan_amount': 120000.0,
                'monthly_emi': 2491.0,
                'total_interest_payable': 29460.0,
                'total_repayment_amount': 149460.0,
                'projected_monthly_profit': 28500.0,
                'net_cash_flow_after_emi': 26009.0,
                'debt_service_coverage_ratio': 11.44,
                'is_affordable': true,
                'affordability_risk_level': 'safe',
                'affordability_rationale': 'Healthy debt coverage.',
                'amortization_preview': [],
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.url.path.endsWith('/finance/scenarios')) {
          scenarioCalled = true;
          return http.Response('{"error": "forbidden"}', 500);
        }

        return http.Response('{"error": "not found"}', 404);
      });

      // selectedBusinessProvider with businessId: null
      final businessNotifier = SelectedBusinessNotifier();
      businessNotifier.selectBusiness(
        const SelectedBusinessState(
          businessId: null, // No businessId!
          estimatedCapital: 180000.0,
          monthlyRevenue: 62000.0,
          monthlyOperatingCosts: 33500.0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(httpClient: mockHttp, authToken: 'mock-token'),
            ),
            selectedBusinessProvider.overrideWith((ref) => businessNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FinancialScenarioScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(simulateCalled, true);
      expect(scenarioCalled, false);
      expect(find.text('₹2491 / mo'), findsOneWidget);
      expect(find.text('₹26009 / month'), findsOneWidget);
    });

    testWidgets('5. Backend failure / offline gracefully renders deterministic local calculation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockHttp = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
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
            home: const FinancialScenarioScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // UI still displays clean deterministic reducing-balance fallback values without crashing
      expect(find.text('Financial Planning'), findsOneWidget);
      expect(find.text('₹180000'), findsOneWidget);
      expect(find.text('₹2491 / mo'), findsOneWidget);
      expect(find.text('₹26009 / month'), findsOneWidget);
      expect(find.text('Surplus Safe'), findsOneWidget);
    });
  });
}
