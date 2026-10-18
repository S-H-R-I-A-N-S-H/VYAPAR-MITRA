import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/core/theme/app_theme.dart';
import 'package:vyapar_mitra/features/research/models/supplier_logistics.dart';
import 'package:vyapar_mitra/features/research/providers/logistics_provider.dart';
import 'package:vyapar_mitra/features/research/widgets/logistics_feasibility_card.dart';

void main() {
  group('Feature 6: Travel & Distribution Cost Intelligence Tests', () {
    test('1. Freight vehicle modes and rural benchmark rates', () {
      expect(FreightVehicleMode.twoWheeler.defaultRatePerKm, 6.0);
      expect(FreightVehicleMode.autoRickshaw.defaultRatePerKm, 12.0);
      expect(FreightVehicleMode.pickupTempo.defaultRatePerKm, 18.0);
      expect(FreightVehicleMode.tractorTrolley.defaultRatePerKm, 25.0);

      expect(
        FreightVehicleMode.fromApiValue('auto_rickshaw'),
        FreightVehicleMode.autoRickshaw,
      );
      expect(
        FreightVehicleMode.fromApiValue('unknown'),
        FreightVehicleMode.pickupTempo,
      );
    });

    test('2. SupplierLandedCostItem JSON parsing and calculations', () {
      final json = {
        'supplier_id': 's-01',
        'supplier_name': 'Kisan Feed Store',
        'distance_km': 10.0,
        'duration_minutes': 20,
        'quoted_price_per_unit': 25.0,
        'unit_name': 'kg',
        'min_order_quantity': 100.0,
        'trip_distance_billed_km': 20.0,
        'trip_freight_cost': 360.0,
        'freight_cost_per_unit': 3.60,
        'effective_landed_cost': 28.60,
        'monthly_freight_total': 1440.0,
        'is_recommended': true,
        'is_real_mappls': true,
      };

      final item = SupplierLandedCostItem.fromJson(json);
      expect(item.supplierId, 's-01');
      expect(item.supplierName, 'Kisan Feed Store');
      expect(item.distanceKm, 10.0);
      expect(item.durationMinutes, 20);
      expect(item.quotedPricePerUnit, 25.0);
      expect(item.tripDistanceBilledKm, 20.0);
      expect(item.tripFreightCost, 360.0);
      expect(item.freightCostPerUnit, 3.60);
      expect(item.effectiveLandedCost, 28.60);
      expect(item.isRecommended, isTrue);
      expect(item.isRealMappls, isTrue);
    });

    test('3. SupplierFreightEvaluationResult parsing & best supplier getter', () {
      final json = {
        'vehicle_mode': 'pickup_tempo',
        'freight_rate_per_km': 18.0,
        'is_round_trip': true,
        'trips_per_month': 4,
        'results': [
          {
            'supplier_id': 's-near',
            'supplier_name': 'Local Depot',
            'distance_km': 4.0,
            'duration_minutes': 8,
            'quoted_price_per_unit': 96.0,
            'unit_name': 'kg',
            'min_order_quantity': 100.0,
            'trip_distance_billed_km': 8.0,
            'trip_freight_cost': 144.0,
            'freight_cost_per_unit': 1.44,
            'effective_landed_cost': 97.44,
            'monthly_freight_total': 576.0,
            'is_recommended': true,
            'is_real_mappls': false,
          },
          {
            'supplier_id': 's-far',
            'supplier_name': 'Distant Yard',
            'distance_km': 20.0,
            'duration_minutes': 38,
            'quoted_price_per_unit': 92.0,
            'unit_name': 'kg',
            'min_order_quantity': 100.0,
            'trip_distance_billed_km': 40.0,
            'trip_freight_cost': 720.0,
            'freight_cost_per_unit': 7.20,
            'effective_landed_cost': 99.20,
            'monthly_freight_total': 2880.0,
            'is_recommended': false,
            'is_real_mappls': false,
          },
        ],
        'recommended_supplier_id': 's-near',
        'monthly_savings_vs_worst': 704.0,
        'insight_summary_en': 'Local Depot provides lowest landed cost.',
        'insight_summary_hi': 'Local Depot की प्रभावी लागत सबसे कम है।',
        'monthly_operating_cost_delta': 576.0,
      };

      final result = SupplierFreightEvaluationResult.fromJson(json);
      expect(result.results.length, 2);
      expect(result.recommendedSupplierId, 's-near');
      expect(result.recommendedSupplier?.supplierName, 'Local Depot');
      expect(result.monthlySavingsVsWorst, 704.0);
      expect(result.monthlyOperatingCostDelta, 576.0);
    });

    testWidgets('4. LogisticsFeasibilityCard renders UI components cleanly', (tester) async {
      final mockResult = SupplierFreightEvaluationResult(
        vehicleMode: FreightVehicleMode.pickupTempo,
        freightRatePerKm: 18.0,
        isRoundTrip: true,
        tripsPerMonth: 4,
        results: const [
          SupplierLandedCostItem(
            supplierId: 's-1',
            supplierName: 'Sanwer Local Agro',
            distanceKm: 3.5,
            durationMinutes: 7,
            quotedPricePerUnit: 25.0,
            unitName: 'kg',
            minOrderQuantity: 100.0,
            tripDistanceBilledKm: 7.0,
            tripFreightCost: 126.0,
            freightCostPerUnit: 1.26,
            effectiveLandedCost: 26.26,
            monthlyFreightTotal: 504.0,
            isRecommended: true,
            isRealMappls: false,
          ),
          SupplierLandedCostItem(
            supplierId: 's-2',
            supplierName: 'Indore Mandi Wholesale',
            distanceKm: 22.0,
            durationMinutes: 40,
            quotedPricePerUnit: 22.0,
            unitName: 'kg',
            minOrderQuantity: 100.0,
            tripDistanceBilledKm: 44.0,
            tripFreightCost: 792.0,
            freightCostPerUnit: 7.92,
            effectiveLandedCost: 29.92,
            monthlyFreightTotal: 3168.0,
            isRecommended: false,
            isRealMappls: false,
          ),
        ],
        recommendedSupplierId: 's-1',
        monthlySavingsVsWorst: 1464.0,
        insightSummaryEn: 'Sanwer Local Agro offers lowest landed cost at ₹26.26/kg.',
        insightSummaryHi: 'Sanwer Local Agro से प्रभावी लागत सबसे कम ₹26.26/kg है।',
        monthlyOperatingCostDelta: 504.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supplierFreightEvaluationProvider.overrideWith((ref) => Future.value(mockResult)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LogisticsFeasibilityCard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and tags
      expect(find.text('Logistics & Landed Cost Intelligence'), findsOneWidget);
      expect(find.text('Distance Matrix'), findsOneWidget);

      // Check suppliers listed
      expect(find.text('Sanwer Local Agro'), findsOneWidget);
      expect(find.text('Indore Mandi Wholesale'), findsOneWidget);
      expect(find.text('Best Value'), findsOneWidget);

      // Check effective landed cost
      expect(find.text('₹26.26/kg'), findsOneWidget);
      expect(find.text('₹29.92/kg'), findsOneWidget);

      // Check insight callout
      expect(find.text('Sanwer Local Agro offers lowest landed cost at ₹26.26/kg.'), findsOneWidget);

      // Check CTA button
      expect(
        find.text('Add ₹504/mo Freight to Operating Costs'),
        findsOneWidget,
      );
    });

    testWidgets('5. Applying freight cost mutates business operating costs and triggers snackbar', (tester) async {
      final mockResult = SupplierFreightEvaluationResult(
        vehicleMode: FreightVehicleMode.pickupTempo,
        freightRatePerKm: 18.0,
        isRoundTrip: true,
        tripsPerMonth: 4,
        results: const [
          SupplierLandedCostItem(
            supplierId: 's-1',
            supplierName: 'Sanwer Local Agro',
            distanceKm: 3.5,
            durationMinutes: 7,
            quotedPricePerUnit: 25.0,
            unitName: 'kg',
            minOrderQuantity: 100.0,
            tripDistanceBilledKm: 7.0,
            tripFreightCost: 126.0,
            freightCostPerUnit: 1.26,
            effectiveLandedCost: 26.26,
            monthlyFreightTotal: 504.0,
            isRecommended: true,
            isRealMappls: false,
          ),
        ],
        recommendedSupplierId: 's-1',
        monthlySavingsVsWorst: 0.0,
        insightSummaryEn: 'Optimal supplier selected.',
        insightSummaryHi: 'उचित आपूर्तिकर्ता चुना गया।',
        monthlyOperatingCostDelta: 504.0,
      );

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supplierFreightEvaluationProvider.overrideWith((ref) => Future.value(mockResult)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LogisticsFeasibilityCard(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialOpex = capturedRef.read(selectedBusinessProvider).monthlyOperatingCosts;
      expect(capturedRef.read(appliedLogisticsCostProvider), 0.0);

      // Tap apply button
      await tester.tap(find.text('Add ₹504/mo Freight to Operating Costs'));
      await tester.pumpAndSettle();

      // Verify applied state and business opex update
      expect(capturedRef.read(appliedLogisticsCostProvider), 504.0);
      expect(
        capturedRef.read(selectedBusinessProvider).monthlyOperatingCosts,
        initialOpex + 504.0,
      );

      // Verify snackbar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Monthly freight cost (₹504) added to operating costs!'), findsOneWidget);
    });
  });
}
