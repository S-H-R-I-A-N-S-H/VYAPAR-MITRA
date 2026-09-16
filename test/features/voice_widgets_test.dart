import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/core/audio/voice_service.dart';
import 'package:vyapar_mitra/shared/widgets/voice_mic_button.dart';
import 'package:vyapar_mitra/shared/widgets/voice_aware_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceMicButton Widget Tests', () {
    testWidgets('renders idle mic icon and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceMicButton(
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      await tester.tap(find.byType(VoiceMicButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders stop icon when recording state is active', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceMicButton(
                voiceState: VoiceState.recording,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    });

    testWidgets('renders volume icon when playing state is active', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceMicButton(
                voiceState: VoiceState.playing,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });
  });

  group('VoiceAwareTextField Widget Tests', () {
    testWidgets('renders TextField with mic button in suffix by default', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceAwareTextField(
                controller: controller,
                hintText: 'Enter business idea',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter business idea'), findsOneWidget);
      expect(find.byType(VoiceMicButton), findsOneWidget);
    });

    testWidgets('typing in text field updates controller text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceAwareTextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Cold-press mustard oil');
      expect(controller.text, 'Cold-press mustard oil');
    });

    testWidgets('VoiceService liveWordsNotifier updates reactive state correctly', (tester) async {
      final service = VoiceService();
      expect(service.liveWords, isEmpty);

      service.liveWordsNotifier.value = 'Spoken words from entrepreneur';
      expect(service.liveWords, 'Spoken words from entrepreneur');

      service.clearLiveWords();
      expect(service.liveWords, isEmpty);
      service.dispose();
    });
  });
}
