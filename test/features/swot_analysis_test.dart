import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vyapar_mitra/app/router.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/features/validation/screens/swot_analysis_screen.dart';

void main() {
  group('SwotAnalysisScreen Widget & Interaction Tests', () {
    testWidgets('renders SWOT banner, 4 quadrants, and mitigation cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SwotAnalysisScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SWOT Analysis'), findsOneWidget);
      expect(find.text('Risk-Reward: Favorable'), findsOneWidget);
      expect(find.text('Feasibility 84%'), findsOneWidget);
      expect(find.text('Enterprise Strengths'), findsOneWidget);
      expect(find.text('Operational Constraints'), findsOneWidget);
      expect(find.text('Market Opportunities'), findsOneWidget);
      expect(find.text('External Market Threats'), findsOneWidget);
      expect(find.text('Recommended Risk Mitigations'), findsOneWidget);
      expect(find.text('Simulate Financials & What-If →'), findsOneWidget);
    });

    testWidgets('filters quadrants when tapping category pills', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SwotAnalysisScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on Weaknesses filter
      await tester.tap(find.text('Weaknesses (कमजोरी)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Only Weaknesses quadrant should be displayed
      expect(find.text('Operational Constraints'), findsOneWidget);
      expect(find.text('Enterprise Strengths'), findsNothing);
      expect(find.text('Market Opportunities'), findsNothing);
      expect(find.text('External Market Threats'), findsNothing);

      // Tap on Opportunities filter
      await tester.tap(find.text('Opportunities (अवसर)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Market Opportunities'), findsOneWidget);
      expect(find.text('Operational Constraints'), findsNothing);
    });

    testWidgets('dynamically generates tailored SWOT items for non-default business', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedBusinessProvider.overrideWith((ref) => SelectedBusinessNotifier(
                  const SelectedBusinessState(
                    title: 'Bamboo Handicrafts Unit',
                    domain: 'Handicrafts & Forest Produce',
                  ),
                )),
            businessProfileProvider.overrideWith((ref) => BusinessProfileNotifier(
                  const BusinessProfileState(
                    district: 'Kamrup',
                    block: 'Hajo',
                    stateName: 'Assam',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: SwotAnalysisScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should contain bamboo-specific SWOT items
      expect(find.text('Abundant Raw Culm Stands'), findsOneWidget);
      expect(find.text('42% Value-Add Margin Spread'), findsOneWidget);
      expect(find.text('Seasoning & Weathering Moisture'), findsOneWidget);
      expect(find.text('PM Vishwakarma Toolkit & PMEGP'), findsOneWidget);
    });

    testWidgets('navigates from ValidationDashboardScreen to SwotAnalysisScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            initialRoute: AppRouter.validationDashboard,
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final swotButton = find.text('View Strategic SWOT Matrix →');
      expect(swotButton, findsOneWidget);

      await tester.ensureVisible(swotButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(swotButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SWOT Analysis'), findsOneWidget);
      expect(find.text('Risk-Reward: Favorable'), findsOneWidget);
    });
  });
}
