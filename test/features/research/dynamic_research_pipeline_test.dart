import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vyapar_mitra/core/network/api_client.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/features/research/models/research_synthesis_model.dart';
import 'package:vyapar_mitra/features/research/providers/research_pipeline_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Dynamic Research Pipeline & Synthesis Tests', () {
    test('ResearchSynthesisResult parses full backend synthesis with grounding sources', () {
      final backendJson = {
        'project_id': 'proj-test-123',
        'business_name': 'Bamboo Utility Products',
        'location': {
          'district': 'Kamrup',
          'state': 'Assam',
        },
        'evidence_count': 6,
        'data_points_collected': 16,
        'synthesis': {
          'overall_status': 'Highly Feasible',
          'status_color': 'success',
          'summary': 'Abundant local bamboo stands and high eco-lifestyle product demand in Kamrup.',
          'pillars': [
            {
              'pillar': 'Customer Demand',
              'badge_text': 'Strong (85%)',
              'badge_type': 'success',
              'description': 'High demand for bamboo homeware and utility baskets.',
              'confidence': 0.88,
              'source': 'State Craft Mission & Local Weekly Bazaars',
            },
            {
              'pillar': 'Competition',
              'badge_text': 'Low Mechanized',
              'badge_type': 'warning',
              'description': 'Informal cottage craft workers with limited mechanized finishing.',
              'confidence': 0.80,
              'source': 'District Industries Centre (DIC)',
            },
            {
              'pillar': 'Pricing & Margin',
              'badge_text': 'High Value-Add (42%)',
              'badge_type': 'success',
              'description': 'Raw bamboo culm ₹60 yields retail product ₹400+.',
              'confidence': 0.90,
              'source': 'Assam Bamboo Development Agency',
            },
          ],
          'discrepancies': [
            {
              'parameter': 'Culm Transport Cost',
              'secondary_source': 'District Freight Index: ₹8/km',
              'field_source': 'Local Tempo Union: ₹12/km',
              'discrepancy_pct': 50.0,
              'impact': 'Medium',
            },
          ],
          'grounding_sources': [
            {
              'title': 'National Bamboo Mission Market Bulletin',
              'url': 'https://nbm.nic.in',
            },
            {
              'title': 'Kamrup DIC MSME Directory',
              'url': 'https://industries.assam.gov.in',
            },
          ],
        },
        'created_at': '2026-09-14T20:00:00Z',
      };

      final result = ResearchSynthesisResult.fromJson(backendJson);

      expect(result.projectId, 'proj-test-123');
      expect(result.businessName, 'Bamboo Utility Products');
      expect(result.district, 'Kamrup');
      expect(result.overallStatus, 'Highly Feasible');
      expect(result.evidenceCount, 6);
      expect(result.dataPointsCollected, 16);
      expect(result.pillars.length, 3);
      expect(result.discrepancies.length, 1);
      expect(result.groundingSources.length, 2);
      expect(result.groundingSources.first.title, 'National Bamboo Mission Market Bulletin');

      // Verify PillarItem conversion
      final demandPillar = result.pillars.first.toPillarItem();
      expect(demandPillar.title, 'Customer Demand');
      expect(demandPillar.badgeText, 'Strong (85%)');
    });

    test('Non-default business (e.g. Dairy Parlour) dynamically generates tailored localized evidence', () {
      final container = ProviderContainer(
        overrides: [
          selectedBusinessProvider.overrideWith((ref) => SelectedBusinessNotifier(
                const SelectedBusinessState(
                  businessId: 'b-dairy-01',
                  title: 'Chilled Milk & Paneer Dairy',
                  domain: 'Dairy & Animal Husbandry',
                ),
              )),
          businessProfileProvider.overrideWith((ref) => BusinessProfileNotifier(
                const BusinessProfileState(
                  district: 'Meerut',
                  block: 'Sardhana',
                  stateName: 'Uttar Pradesh',
                  personalCapital: 90000.0,
                  businessIdea: 'Chilled Milk & Paneer Dairy',
                ),
              )),
        ],
      );

      final state = container.read(researchPipelineProvider);

      // Verify steps reflect the dynamic business title and block
      expect(state.steps.first.subtitleEn, contains('Chilled Milk & Paneer Dairy'));
      expect(state.steps[2].subtitleEn, contains('Sardhana'));

      container.dispose();
    });

    test('ResearchPipelineNotifier completes research flow and produces synthesized result without mustard oil bias', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/research/projects') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': '00000000-0000-0000-0000-000000000099',
                'business_id': '00000000-0000-0000-0000-000000000001',
                'location_id': '00000000-0000-0000-0000-000000000002',
                'status': 'ANALYSIS',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              'message': 'Project created',
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'business_name': 'Bamboo Handicrafts',
              'district': 'Hajo',
              'state': 'Assam',
              'block': 'Hajo Rural',
              'business_type': 'Handicrafts & Utility',
              'summary': 'High local demand for bamboo baskets and crafts in Hajo market.',
              'pillars': {},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => ApiClient(
                httpClient: mockHttp,
                authToken: 'mock-user-dev-001',
              )),
          selectedBusinessProvider.overrideWith((ref) => SelectedBusinessNotifier(
                const SelectedBusinessState(
                  businessId: '00000000-0000-0000-0000-000000000001',
                  title: 'Bamboo Handicrafts',
                  domain: 'Handicrafts & Utility',
                ),
              )),
          businessProfileProvider.overrideWith((ref) => BusinessProfileNotifier(
                const BusinessProfileState(
                  district: 'Hajo',
                  block: 'Hajo Rural',
                  stateName: 'Assam',
                ),
              )),
        ],
      );

      final notifier = container.read(researchPipelineProvider.notifier);

      // Trigger research
      final future = notifier.startResearch(forceRefresh: true);
      expect(container.read(researchPipelineProvider).isScanning, true);

      await future;

      final completedState = container.read(researchPipelineProvider);
      expect(completedState.isScanning, false);
      expect(completedState.progress, 1.0);
      expect(completedState.completedSteps, 6);
      expect(completedState.synthesisResult, isNotNull);

      // Ensure findings are tailored to bamboo, not mustard oil
      final synth = completedState.synthesisResult!;
      expect(synth.businessName, 'Bamboo Handicrafts');
      expect(synth.district, 'Hajo');
      expect(completedState.liveFindingEn.toLowerCase(), contains('bamboo'));

      container.dispose();
    });
  });
}
