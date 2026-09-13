import 'package:flutter/material.dart';
import '../features/business/screens/business_confirmation_screen.dart';
import '../features/finance/screens/financial_scenario_screen.dart';
import '../features/interview/screens/conversational_interview_screen.dart';
import '../features/onboarding/screens/language_selection_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/opportunities/screens/curated_opportunities_screen.dart';
import '../features/profile/screens/business_profile_screen.dart';
import '../features/recommendations/screens/action_plan_screen.dart';
import '../features/recommendations/screens/scheme_detail_screen.dart';
import '../features/recommendations/screens/scheme_recommendations_screen.dart';
import '../features/research/screens/research_progress_screen.dart';
import '../features/validation/screens/validation_dashboard_screen.dart';

class AppRouter {
  static const String welcome = '/';
  static const String language = '/language';
  static const String logbook = '/logbook';
  static const String profile = '/profile';
  static const String interview = '/interview';
  static const String opportunities = '/opportunities';
  static const String businessConfirmation = '/business-confirmation';
  static const String researchProgress = '/research-progress';
  static const String validationDashboard = '/validation-dashboard';
  static const String financeModeler = '/finance-modeler';
  static const String schemeRecommendations = '/scheme-recommendations';
  static const String schemeDetail = '/scheme-detail';
  static const String actionPlan = '/action-plan';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case language:
        return MaterialPageRoute(builder: (_) => const LanguageSelectionScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const BusinessProfileScreen());
      case interview:
        return MaterialPageRoute(builder: (_) => const ConversationalInterviewScreen());
      case opportunities:
        return MaterialPageRoute(builder: (_) => const CuratedOpportunitiesScreen());
      case businessConfirmation:
        return MaterialPageRoute(builder: (_) => const BusinessConfirmationScreen());
      case researchProgress:
        return MaterialPageRoute(builder: (_) => const ResearchProgressScreen());
      case validationDashboard:
        return MaterialPageRoute(builder: (_) => const ValidationDashboardScreen());
      case financeModeler:
        return MaterialPageRoute(builder: (_) => const FinancialScenarioScreen());
      case schemeRecommendations:
        return MaterialPageRoute(builder: (_) => const SchemeRecommendationsScreen());
      case schemeDetail:
        return MaterialPageRoute(builder: (_) => const SchemeDetailScreen());
      case actionPlan:
        return MaterialPageRoute(builder: (_) => const ActionPlanScreen());
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
