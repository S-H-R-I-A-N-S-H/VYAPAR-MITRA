import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers/app_providers.dart';
import '../models/financial_models.dart';

/// State of the financial scenario & calculator screen.
class FinancialState {
  final FinancialSimulationResult simulation;
  final double baseRevenue;
  final double baseOperatingCosts;
  final String? scenarioId;
  final WhatIfResponse? whatIfResult;
  final double capacityPercentage; // 60.0 to 100.0
  final bool isLoading;
  final bool isStressTesting;
  final String? errorMessage;
  final bool isBackendSynced;

  const FinancialState({
    required this.simulation,
    this.baseRevenue = 62000.0,
    this.baseOperatingCosts = 33500.0,
    this.scenarioId,
    this.whatIfResult,
    this.capacityPercentage = 100.0,
    this.isLoading = false,
    this.isStressTesting = false,
    this.errorMessage,
    this.isBackendSynced = false,
  });

  /// Current monthly sales revenue scaled by what-if capacity.
  double get currentRevenue => baseRevenue * (capacityPercentage / 100.0);

  /// Current operating costs scaled with 30% fixed and 70% variable components.
  double get currentOperatingCosts =>
      baseOperatingCosts * (0.3 + 0.7 * (capacityPercentage / 100.0));

  /// Monthly EMI (authoritative reducing-balance).
  double get monthlyEmi => simulation.monthlyEmi;

  /// Current net cash in hand after operating costs and EMI.
  double get netCashInHand {
    if (whatIfResult != null && capacityPercentage < 99.9) {
      return whatIfResult!.stressedCase.netCashFlow;
    }
    return currentRevenue - currentOperatingCosts - monthlyEmi;
  }

  /// Current active risk tier ('safe', 'moderate', 'critical').
  String get activeRiskLevel {
    if (whatIfResult != null && capacityPercentage < 99.9) {
      return whatIfResult!.stressedCase.affordabilityRiskLevel.toLowerCase();
    }
    return simulation.affordabilityRiskLevel.toLowerCase();
  }

  /// Whether current net cash and debt coverage are in safe status.
  bool get isHealthy =>
      activeRiskLevel == 'safe' || (activeRiskLevel != 'critical' && netCashInHand >= 15000.0);

  /// Narrative rationale or stress summary.
  String get displayRationale {
    if (whatIfResult != null && capacityPercentage < 99.9 && whatIfResult!.stressSummary.isNotEmpty) {
      return whatIfResult!.stressSummary;
    }
    return simulation.affordabilityRationale;
  }

  FinancialState copyWith({
    FinancialSimulationResult? simulation,
    double? baseRevenue,
    double? baseOperatingCosts,
    String? scenarioId,
    WhatIfResponse? whatIfResult,
    double? capacityPercentage,
    bool? isLoading,
    bool? isStressTesting,
    String? errorMessage,
    bool? isBackendSynced,
  }) {
    return FinancialState(
      simulation: simulation ?? this.simulation,
      baseRevenue: baseRevenue ?? this.baseRevenue,
      baseOperatingCosts: baseOperatingCosts ?? this.baseOperatingCosts,
      scenarioId: scenarioId ?? this.scenarioId,
      whatIfResult: whatIfResult ?? this.whatIfResult,
      capacityPercentage: capacityPercentage ?? this.capacityPercentage,
      isLoading: isLoading ?? this.isLoading,
      isStressTesting: isStressTesting ?? this.isStressTesting,
      errorMessage: errorMessage ?? this.errorMessage,
      isBackendSynced: isBackendSynced ?? this.isBackendSynced,
    );
  }
}

class FinancialNotifier extends StateNotifier<FinancialState> {
  FinancialNotifier()
      : super(
          FinancialState(
            simulation: DeterministicFinancialCalculator.computeLocalFallback(
              totalProjectCost: 180000.0,
              ownCapital: 60000.0,
              projectedMonthlyRevenue: 62000.0,
              projectedMonthlyOperatingCost: 33500.0,
              annualRatePct: 9.0,
              tenureMonths: 60,
            ),
            baseRevenue: 62000.0,
            baseOperatingCosts: 33500.0,
          ),
        );

  /// Executes base calculation, synchronizing with backend API.
  /// Calls POST /api/v1/finance/scenarios if a valid businessId exists.
  /// Otherwise calls POST /api/v1/finance/simulate to protect against missing foreign key.
  Future<void> calculateBaseScenario({
    required ApiClient apiClient,
    required SelectedBusinessState business,
    required BusinessProfileState profile,
  }) async {
    // 1. Synchronously update state with authoritative local deterministic calculation
    final localFallback = DeterministicFinancialCalculator.computeLocalFallback(
      totalProjectCost: business.estimatedCapital,
      ownCapital: profile.personalCapital,
      projectedMonthlyRevenue: business.monthlyRevenue,
      projectedMonthlyOperatingCost: business.monthlyOperatingCosts,
      annualRatePct: 9.0,
      tenureMonths: 60,
    );
    state = state.copyWith(
      simulation: localFallback,
      baseRevenue: business.monthlyRevenue,
      baseOperatingCosts: business.monthlyOperatingCosts,
      isLoading: true,
      errorMessage: null,
    );

    final hasValidBusinessId =
        business.businessId != null && business.businessId!.trim().isNotEmpty;

    try {
      if (hasValidBusinessId) {
        // Business ID exists: Persist scenario via POST /api/v1/finance/scenarios
        final payload = {
          'business_id': business.businessId!.trim(),
          'scenario_name': 'Base Scenario',
          'total_project_cost': business.estimatedCapital,
          'own_capital': profile.personalCapital,
          'annual_interest_rate_pct': 9.0,
          'tenure_months': 60,
          'projected_monthly_revenue': business.monthlyRevenue,
          'projected_monthly_operating_cost': business.monthlyOperatingCosts,
        };

        final res = await apiClient.post(
          ApiEndpoints.financeScenarios,
          body: payload,
        );

        if (res is Map && res['data'] != null && res['data'] is Map) {
          final scenData = res['data'] as Map<String, dynamic>;
          final scenarioId = scenData['id']?.toString();
          final simMap = scenData['simulation_result'] as Map<String, dynamic>?;

          if (simMap != null) {
            final parsedSim = FinancialSimulationResult.fromJson(simMap);
            state = state.copyWith(
              simulation: parsedSim,
              scenarioId: scenarioId,
              isLoading: false,
              isBackendSynced: true,
            );
            return;
          }
        }
      } else {
        // No Business ID: Stateless simulation via POST /api/v1/finance/simulate
        final payload = {
          'total_project_cost': business.estimatedCapital,
          'own_capital': profile.personalCapital,
          'loan_amount_requested': business.estimatedCapital - profile.personalCapital,
          'annual_interest_rate_pct': 9.0,
          'tenure_months': 60,
          'projected_monthly_revenue': business.monthlyRevenue,
          'projected_monthly_operating_cost': business.monthlyOperatingCosts,
        };

        final res = await apiClient.post(
          ApiEndpoints.financeSimulate,
          body: payload,
        );

        if (res is Map && res['data'] != null && res['data'] is Map) {
          final simMap = res['data'] as Map<String, dynamic>;
          final parsedSim = FinancialSimulationResult.fromJson(simMap);
          state = state.copyWith(
            simulation: parsedSim,
            scenarioId: null,
            isLoading: false,
            isBackendSynced: true,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Financial calculation backend request completed with fallback: $e');
      state = state.copyWith(
        isLoading: false,
        isBackendSynced: false,
        errorMessage: e.toString(),
      );
      return;
    }

    state = state.copyWith(isLoading: false);
  }

  /// Updates capacity percentage and executes what-if sensitivity stress analysis.
  /// Calls POST /api/v1/finance/scenarios/{id}/what-if if scenarioId exists.
  Future<void> updateCapacity({
    required ApiClient apiClient,
    required double capacityPercentage,
  }) async {
    state = state.copyWith(
      capacityPercentage: capacityPercentage,
      isStressTesting: true,
    );

    final scenarioId = state.scenarioId;
    final revenueDropPct = (100.0 - capacityPercentage).clamp(0.0, 100.0);

    if (scenarioId != null && scenarioId.isNotEmpty) {
      try {
        final payload = {
          'revenue_drop_pct': revenueDropPct,
          'cost_increase_pct': 0.0,
          'interest_rate_delta_pct': 0.0,
        };

        final res = await apiClient.post(
          ApiEndpoints.financeWhatIf(scenarioId),
          body: payload,
        );

        if (res is Map && res['data'] != null && res['data'] is Map) {
          final whatIf = WhatIfResponse.fromJson(res['data'] as Map<String, dynamic>);
          state = state.copyWith(
            whatIfResult: whatIf,
            isStressTesting: false,
          );
          return;
        }
      } catch (e) {
        debugPrint('What-if analysis request completed with fallback: $e');
      }
    }

    // Fallback: If no scenarioId or network call fails, calculate stress locally
    state = state.copyWith(
      isStressTesting: false,
      whatIfResult: null,
    );
  }
}

/// Provider for financial calculation state and actions.
final financialProvider =
    StateNotifierProvider<FinancialNotifier, FinancialState>((ref) {
  return FinancialNotifier();
});
