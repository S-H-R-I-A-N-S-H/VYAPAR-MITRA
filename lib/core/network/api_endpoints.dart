
/// Centralized API endpoint URLs for the Vyapar Mitra FastAPI backend.
class ApiEndpoints {
  static String? _overrideBaseUrl;

  /// Allows dynamically overriding the base URL (e.g. for testing or network discovery).
  static void setBaseUrl(String url) {
    _overrideBaseUrl = url;
  }

  /// Base URL dynamically adapting to environment override, Android USB reverse / loopback, or desktop/web.
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    // With `adb reverse tcp:8000 tcp:8000`, 127.0.0.1:8000 connects directly to host on both physical devices and emulators.
    return 'http://127.0.0.1:8000/api/v1';
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
  static String researchSynthesizeSecondary(String id) => '$baseUrl/research/projects/$id/synthesize-secondary-research';


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
