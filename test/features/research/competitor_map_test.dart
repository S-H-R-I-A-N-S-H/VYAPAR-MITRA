import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vyapar_mitra/app/router.dart';
import 'package:vyapar_mitra/features/research/models/competitor_poi.dart';
import 'package:vyapar_mitra/features/research/screens/competitor_map_screen.dart';
import 'package:vyapar_mitra/features/research/widgets/hyperlocal_competitor_map.dart';

void main() {
  group('CompetitorPoi Model & Provider Tests', () {
    test('CompetitorPoi model parses JSON correctly with radial coordinates', () {
      final json = {
        'id': 'test_comp_1',
        'name': 'Shree Ram Expeller',
        'distance_km': 2.5,
        'category': 'oil_mill',
        'address': 'Mandi Gate, Sanwer',
      };

      final poi = CompetitorPoi.fromJson(json, fallbackLat: 22.9772, fallbackLon: 75.8078);
      expect(poi.id, 'test_comp_1');
      expect(poi.name, 'Shree Ram Expeller');
      expect(poi.distanceKm, 2.5);
      expect(poi.category, 'oil_mill');
      expect(poi.latitude, isNot(0.0));
      expect(poi.longitude, isNot(0.0));
      expect(poi.differentiationTip, contains('cold-pressed'));
    });

    test('CompetitorPoi converts to JSON and retains values', () {
      const poi = CompetitorPoi(
        id: 'comp_abc',
        name: 'Kisan Cold Press',
        distanceKm: 3.1,
        category: 'Food Processing',
        address: 'Bypass Road',
        latitude: 22.98,
        longitude: 75.81,
      );

      final map = poi.toJson();
      expect(map['id'], 'comp_abc');
      expect(map['distance_km'], 3.1);
      expect(map['is_direct_competitor'], true);
    });
  });

  group('HyperlocalCompetitorMap Widget Tests', () {
    final testCompetitors = [
      const CompetitorPoi(
        id: 'comp_1',
        name: 'Shree Ram Expeller Mill',
        distanceKm: 1.8,
        category: 'Expeller Mill',
        address: 'Old Mandi Road',
        latitude: 22.9882,
        longitude: 75.8168,
        differentiationTip: 'Focus on cold-pressed purity.',
      ),
      const CompetitorPoi(
        id: 'comp_2',
        name: 'Kisan Agro Cold Press',
        distanceKm: 3.5,
        category: 'Agro Processing',
        address: 'Highway Link',
        latitude: 22.9612,
        longitude: 75.7938,
        differentiationTip: 'Offer on-demand pressing service.',
      ),
    ];

    testWidgets('HyperlocalCompetitorMap renders radar overlay and competitor pins in test environment', (tester) async {
      CompetitorPoi? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperlocalCompetitorMap(
              competitors: testCompetitors,
              radiusKm: 5.0,
              onCompetitorSelected: (comp) {
                tapped = comp;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header badge and legend
      expect(find.text('Mappls Hyperlocal • 5 km Radius'), findsOneWidget);
      expect(find.text('Your Site'), findsOneWidget);
      expect(find.text('Competitor'), findsOneWidget);

      // Verify competitor storefront icon pins are rendered
      expect(find.byIcon(Icons.storefront_rounded), findsNWidgets(2));

      // Tap on the first competitor pin
      await tester.tap(find.byIcon(Icons.storefront_rounded).first);
      await tester.pumpAndSettle();

      expect(tapped, isNotNull);
      expect(tapped?.name, 'Shree Ram Expeller Mill');
    });

    testWidgets('CompetitorMapScreen renders search radius filter and competitor directory', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CompetitorMapScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Hyperlocal Competitor Map'), findsOneWidget);

      // Verify radius chips
      expect(find.text('3 km'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);

      // Verify competitor list rendered
      expect(find.textContaining('Identified Competitors'), findsOneWidget);
      expect(find.text('Shree Ram Expeller Mustard Mill'), findsOneWidget);

      // Tap on competitor pin on map or list item
      await tester.ensureVisible(find.text('Shree Ram Expeller Mustard Mill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shree Ram Expeller Mustard Mill'));
      await tester.pumpAndSettle();

      // Verify Strategic Advantage card appears
      expect(find.text('Vyapar Mitra Strategic Advantage:'), findsOneWidget);
      expect(find.textContaining('Kachi Ghani'), findsOneWidget);
    });

    testWidgets('ValidationDashboardScreen links to CompetitorMapScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            initialRoute: AppRouter.validationDashboard,
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "View Hyperlocal Competitor Map →" button
      final mapButton = find.text('View Hyperlocal Competitor Map →');
      expect(mapButton, findsOneWidget);

      // Tap the button
      await tester.tap(mapButton);
      await tester.pumpAndSettle();

      // Verify navigation to CompetitorMapScreen
      expect(find.text('Hyperlocal Competitor Map'), findsOneWidget);
      expect(find.text('Mappls Hyperlocal • 5 km Radius'), findsOneWidget);
    });
  });
}
