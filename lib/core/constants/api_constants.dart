/// Authoritative API endpoint definitions for Vyapar Mitra backend communication.
class ApiConstants {
  static const String baseUrl = 'http://10.124.227.226:8000/api/v1'; // Android Emulator loopback; 'http://localhost:8000/api/v1' for Web

  // Health
  static const String health = '/health';

  // Finance
  static const String simulateFinance = '/finance/simulate';

  // Schemes
  static const String matchSchemes = '/schemes/match';

  // Evidence & Conflicts
  static const String detectConflicts = '/evidence/detect-conflicts';
}
