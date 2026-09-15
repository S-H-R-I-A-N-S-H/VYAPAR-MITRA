import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized API endpoint URLs for the Vyapar Mitra FastAPI backend.
class ApiEndpoints {
  /// Base URL dynamically adapting to environment override, Android USB reverse / emulator, or desktop/web.
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    if (kIsWeb) {
      return 'http://10.201.133.160:8000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // Works seamlessly with `adb reverse tcp:8000 tcp:8000` for physical devices
        // and defaults to 10.0.2.2 for Android Studio emulators
        return 'http://10.201.133.160:8000/api/v1';
      }
    } catch (_) {
      // Fallback for non-mobile platforms
    }
    return 'http://10.201.133.160:8000/api/v1';
  }

  // Health
  static String get health => '$baseUrl/health';

  // Profile & Location
  static String get locations => '$baseUrl/locations';
  static String get profile => '$baseUrl/profile';

  // Conversational Interview & Bhashini Voice
  static String get interviews => '$baseUrl/interviews';
  static String interviewMessages(String id) => '$baseUrl/interviews/$id/messages';
  static String interviewVoice(String id) => '$baseUrl/interviews/$id/voice';
  static String interviewComplete(String id) => '$baseUrl/interviews/$id/complete';

  // Bhashini Speech Services
  static String get speechTranscribe => '$baseUrl/speech/transcribe';
  static String get speechSynthesize => '$baseUrl/speech/synthesize';
  static String get speechTranslate => '$baseUrl/speech/translate';

  // Locality & Mappls Geospatial Intelligence
  static String get localityCompetitors => '$baseUrl/locality/competitors';
  static String discoverProjectCompetitors(String id) => '$baseUrl/research/projects/$id/discover-competitors';

  // Opportunities & Business
  static String get discoverOpportunities => '$baseUrl/opportunities/discover';
  static String selectOpportunity(String id) => '$baseUrl/opportunities/$id/select';
  static String get businesses => '$baseUrl/businesses';
  static String businessDetail(String id) => '$baseUrl/businesses/$id';

  // Research & Validation
  static String get researchProjects => '$baseUrl/research/projects';
  static String researchProjectDetail(String id) => '$baseUrl/research/projects/$id';
  static String researchEvidence(String id) => '$baseUrl/research/projects/$id/evidence';
  static String researchConflicts(String id) => '$baseUrl/research/projects/$id/conflicts';
  static String researchUncertainty(String id) => '$baseUrl/research/projects/$id/uncertainty';

  // Field Surveys
  static String get surveys => '$baseUrl/surveys';
  static String surveyDetail(String id) => '$baseUrl/surveys/$id';
  static String surveyResponses(String id) => '$baseUrl/surveys/$id/responses';

  // Financial Scenarios & Simulation
  static String get financeSimulate => '$baseUrl/finance/simulate';
  static String get financeScenarios => '$baseUrl/finance/scenarios';
  static String financeScenarioDetail(String id) => '$baseUrl/finance/scenarios/$id';
  static String financeWhatIf(String id) => '$baseUrl/finance/scenarios/$id/what-if';

  // Government Schemes
  static String get schemes => '$baseUrl/schemes';
  static String get schemesMatch => '$baseUrl/schemes/match';

  // Recommendations & Final Synthesis
  static String businessRecommendation(String id) => '$baseUrl/businesses/$id/recommendation';
}
