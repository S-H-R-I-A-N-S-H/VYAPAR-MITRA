import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/features/business/screens/business_confirmation_screen.dart';
import 'package:vyapar_mitra/features/interview/screens/conversational_interview_screen.dart';
import 'package:vyapar_mitra/features/opportunities/screens/curated_opportunities_screen.dart';
import 'package:vyapar_mitra/features/profile/screens/business_profile_screen.dart';

void main() {
  group('Discovery & Opportunities Screens Tests', () {
    testWidgets('BusinessProfileScreen renders 3 starting positions and capital chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BusinessProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Do you have a business idea?'), findsOneWidget);
      expect(find.text('I have a specific idea'), findsOneWidget);
      expect(find.text('I have a general domain'), findsOneWidget);
      expect(find.text('I don\'t have an idea yet'), findsOneWidget);
      expect(find.text('Available Personal Capital'), findsOneWidget);
      expect(find.text('Continue to AI Interview'), findsOneWidget);
    });

    testWidgets('ConversationalInterviewScreen renders advisor dialogue and quick chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConversationalInterviewScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Business Advisor AI'), findsOneWidget);
      expect(find.text('Direct farm access'), findsOneWidget);
      expect(find.text('Have storage shed'), findsOneWidget);
      expect(find.text('Starting from scratch'), findsOneWidget);
    });

    testWidgets('CuratedOpportunitiesScreen renders grounded options and selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CuratedOpportunitiesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Curated Business Opportunities'), findsOneWidget);
      expect(find.text('Cold-Press Mustard Oil Mill'), findsOneWidget);
      expect(find.text('Organic Compost & Fertilizer Unit'), findsOneWidget);
      expect(find.text('Cattle Feed & Grain Depot'), findsOneWidget);
      expect(find.text('Confirm Selected Business →'), findsOneWidget);
    });

    testWidgets('BusinessConfirmationScreen renders summary checkpoint and parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BusinessConfirmationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Your Business Idea'), findsOneWidget);
      expect(find.text('Cold-Press Mustard Oil Mill'), findsOneWidget);
      expect(find.text('Target Customers'), findsOneWidget);
      expect(find.text('Target Area'), findsOneWidget);
      expect(find.text('Confirm & Begin Market Research →'), findsOneWidget);
    });
  });
}
