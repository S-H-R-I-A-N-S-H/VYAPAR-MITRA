import 'package:flutter/material.dart';
import '../features/evidence/presentation/evidence_dashboard_screen.dart';
import '../features/finance/presentation/financial_modeler_screen.dart';
import '../features/interview/presentation/interview_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';

class AppRouter {
  static const String onboarding = '/';
  static const String interview = '/interview';
  static const String finance = '/finance';
  static const String evidence = '/evidence';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case interview:
        return MaterialPageRoute(builder: (_) => const InterviewScreen());
      case finance:
        return MaterialPageRoute(builder: (_) => const FinancialModelerScreen());
      case evidence:
        return MaterialPageRoute(builder: (_) => const EvidenceDashboardScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}
