import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/features/interview/screens/conversational_interview_screen.dart';
import 'package:vyapar_mitra/shared/widgets/floating_voice_bar.dart';

void main() {
  group('Conversational Interview Screen Voice Integration Tests', () {
    testWidgets('renders Bhashini Live badge, Mappls POI banner, and FloatingVoiceBar',
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

      // Verify Bhashini Live status badge
      expect(find.text('Bhashini 2-Way Voice'), findsOneWidget);

      // Verify Mappls POI Grounding banner
      expect(find.textContaining('Mappls POI'), findsOneWidget);

      // Verify FloatingVoiceBar and tap-to-speak dock
      expect(find.byType(FloatingVoiceBar), findsOneWidget);
      expect(find.text('बोलकर पूछें / Tap to Speak'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('text input submits turn and renders Listen voice button on advisor response',
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

      // Type a message in the input field
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'I have 5 years experience in dairy production');
      await tester.tap(find.byIcon(Icons.send_rounded));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Verify user message appears
      expect(find.text('I have 5 years experience in dairy production'), findsOneWidget);

      // Verify advisor response bubble renders with "Listen" button
      expect(find.textContaining('Listen'), findsWidgets);
    });
  });
}
