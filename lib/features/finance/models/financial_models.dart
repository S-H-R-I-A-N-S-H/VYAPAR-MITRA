import 'dart:math' as math;

/// Single item in the 6-month amortization schedule preview.
class AmortizationScheduleItem {
  final int month;
  final double openingBalance;
  final double emi;
  final double principal;
  final double interest;
  final double closingBalance;

  const AmortizationScheduleItem({
    required this.month,
    required this.openingBalance,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.closingBalance,
  });

  factory AmortizationScheduleItem.fromJson(Map<String, dynamic> json) {
    return AmortizationScheduleItem(
      month: (json['month'] as num?)?.toInt() ?? 1,
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      emi: (json['emi'] as num?)?.toDouble() ?? 0.0,
      principal: (json['principal'] as num?)?.toDouble() ?? 0.0,
      interest: (json['interest'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (json['closing_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Authoritative financial simulation result matching backend FinancialSimulationResult schema.
class FinancialSimulationResult {
  final double totalProjectCost;
  final double ownCapital;
  final double requiredLoanAmount;
  final double monthlyEmi;
  final double totalInterestPayable;
  final double totalRepaymentAmount;
  final double projectedMonthlyProfit;
  final double netCashFlowAfterEmi;
  final double debtServiceCoverageRatio;
  final bool isAffordable;
  final String affordabilityRiskLevel; // safe, moderate, critical
  final String affordabilityRationale;
  final List<AmortizationScheduleItem> amortizationPreview;

  const FinancialSimulationResult({
    required this.totalProjectCost,
    required this.ownCapital,
    required this.requiredLoanAmount,
    required this.monthlyEmi,
    required this.totalInterestPayable,
    required this.totalRepaymentAmount,
    required this.projectedMonthlyProfit,
    required this.netCashFlowAfterEmi,
    required this.debtServiceCoverageRatio,
    required this.isAffordable,
    required this.affordabilityRiskLevel,
    required this.affordabilityRationale,
    this.amortizationPreview = const [],
  });

  factory FinancialSimulationResult.fromJson(Map<String, dynamic> json) {
    return FinancialSimulationResult(
      totalProjectCost: (json['total_project_cost'] as num?)?.toDouble() ?? 0.0,
      ownCapital: (json['own_capital'] as num?)?.toDouble() ?? 0.0,
      requiredLoanAmount: (json['required_loan_amount'] as num?)?.toDouble() ?? 0.0,
      monthlyEmi: (json['monthly_emi'] as num?)?.toDouble() ?? 0.0,
      totalInterestPayable: (json['total_interest_payable'] as num?)?.toDouble() ?? 0.0,
      totalRepaymentAmount: (json['total_repayment_amount'] as num?)?.toDouble() ?? 0.0,
      projectedMonthlyProfit: (json['projected_monthly_profit'] as num?)?.toDouble() ?? 0.0,
      netCashFlowAfterEmi: (json['net_cash_flow_after_emi'] as num?)?.toDouble() ?? 0.0,
      debtServiceCoverageRatio: (json['debt_service_coverage_ratio'] as num?)?.toDouble() ?? 0.0,
      isAffordable: json['is_affordable'] as bool? ?? true,
      affordabilityRiskLevel: json['affordability_risk_level']?.toString() ?? 'safe',
      affordabilityRationale: json['affordability_rationale']?.toString() ?? '',
      amortizationPreview: (json['amortization_preview'] as List<dynamic>?)
              ?.map((item) => AmortizationScheduleItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Scenario response matching backend FinancialScenarioResponse schema.
class FinancialScenarioResponse {
  final String id;
  final String businessId;
  final String scenarioName;
  final FinancialSimulationResult simulationResult;
  final String? executiveSummary;

  const FinancialScenarioResponse({
    required this.id,
    required this.businessId,
    required this.scenarioName,
    required this.simulationResult,
    this.executiveSummary,
  });

  factory FinancialScenarioResponse.fromJson(Map<String, dynamic> json) {
    final simJson = json['simulation_result'] as Map<String, dynamic>? ?? {};
    final explJson = json['explanation'] as Map<String, dynamic>?;

    return FinancialScenarioResponse(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      scenarioName: json['scenario_name']?.toString() ?? 'Base Scenario',
      simulationResult: FinancialSimulationResult.fromJson(simJson),
      executiveSummary: explJson?['executive_summary']?.toString(),
    );
  }
}

/// Single what-if outcome case (base case or stressed case).
class WhatIfCase {
  final double monthlyProfit;
  final double netCashFlow;
  final double dscr;
  final String affordabilityRiskLevel;

  const WhatIfCase({
    required this.monthlyProfit,
    required this.netCashFlow,
    required this.dscr,
    required this.affordabilityRiskLevel,
  });

  factory WhatIfCase.fromJson(Map<String, dynamic> json) {
    return WhatIfCase(
      monthlyProfit: (json['monthly_profit'] as num?)?.toDouble() ?? 0.0,
      netCashFlow: (json['net_cash_flow'] as num?)?.toDouble() ?? 0.0,
      dscr: (json['dscr'] as num?)?.toDouble() ?? 0.0,
      affordabilityRiskLevel: json['affordability_risk_level']?.toString() ?? 'safe',
    );
  }
}

/// What-if stress analysis response matching backend WhatIfResponse schema.
class WhatIfResponse {
  final String scenarioId;
  final WhatIfCase baseCase;
  final WhatIfCase stressedCase;
  final String stressSummary;

  const WhatIfResponse({
    required this.scenarioId,
    required this.baseCase,
    required this.stressedCase,
    required this.stressSummary,
  });

  factory WhatIfResponse.fromJson(Map<String, dynamic> json) {
    return WhatIfResponse(
      scenarioId: json['scenario_id']?.toString() ?? '',
      baseCase: WhatIfCase.fromJson(json['base_case'] as Map<String, dynamic>? ?? {}),
      stressedCase: WhatIfCase.fromJson(json['stressed_case'] as Map<String, dynamic>? ?? {}),
      stressSummary: json['stress_summary']?.toString() ?? '',
    );
  }
}

/// Authoritative deterministic reducing-balance financial calculator.
/// Uses the exact same mathematical formulas as backend FinancialEngine.
class DeterministicFinancialCalculator {
  /// Standard reducing balance EMI formula: P * r * (1 + r)^n / ((1 + r)^n - 1)
  static double calculateEmi({
    required double principal,
    required double annualRatePct,
    required int tenureMonths,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return 0.0;
    if (annualRatePct <= 0) {
      return double.parse((principal / tenureMonths).toStringAsFixed(2));
    }

    final monthlyRate = (annualRatePct / 100.0) / 12.0;
    final factor = math.pow(1.0 + monthlyRate, tenureMonths).toDouble();
    final emi = principal * monthlyRate * factor / (factor - 1.0);
    return double.parse(emi.toStringAsFixed(2));
  }

  /// Calculates authoritative deterministic fallback simulation without network.
  static FinancialSimulationResult computeLocalFallback({
    required double totalProjectCost,
    required double ownCapital,
    double annualRatePct = 9.0,
    int tenureMonths = 60,
    required double projectedMonthlyRevenue,
    required double projectedMonthlyOperatingCost,
  }) {
    final requiredLoan = math.max(0.0, totalProjectCost - ownCapital);
    final monthlyEmi = calculateEmi(
      principal: requiredLoan,
      annualRatePct: annualRatePct,
      tenureMonths: tenureMonths,
    );
    final totalRepayment = double.parse((monthlyEmi * tenureMonths).toStringAsFixed(2));
    final totalInterest = double.parse(math.max(0.0, totalRepayment - requiredLoan).toStringAsFixed(2));
    final monthlyProfit = double.parse((projectedMonthlyRevenue - projectedMonthlyOperatingCost).toStringAsFixed(2));
    final netCashFlow = double.parse((monthlyProfit - monthlyEmi).toStringAsFixed(2));
    final dscr = monthlyEmi > 0
        ? double.parse((monthlyProfit / monthlyEmi).toStringAsFixed(2))
        : (monthlyProfit >= 0 ? 99.0 : 0.0);

    final bool isAffordable;
    final String riskLevel;
    final String rationale;

    if (monthlyProfit <= 0) {
      isAffordable = false;
      riskLevel = 'critical';
      rationale = 'Projected operating revenue is insufficient to cover operating costs even before debt repayment.';
    } else if (netCashFlow < 0) {
      isAffordable = false;
      riskLevel = 'critical';
      rationale = 'Negative monthly net cash flow (₹${netCashFlow.toStringAsFixed(0)}). Monthly EMI exceeds operating profit.';
    } else if (dscr < 1.25) {
      isAffordable = true;
      riskLevel = 'moderate';
      rationale = 'Tight debt servicing margin (DSCR ${dscr.toStringAsFixed(2)}). Cash flow can cover EMI, but unexpected cost surges could cause repayment pressure.';
    } else {
      isAffordable = true;
      riskLevel = 'safe';
      rationale = 'Healthy debt coverage (DSCR ${dscr.toStringAsFixed(2)}). Net surplus after EMI is ₹${netCashFlow.toStringAsFixed(0)} per month.';
    }

    return FinancialSimulationResult(
      totalProjectCost: totalProjectCost,
      ownCapital: ownCapital,
      requiredLoanAmount: requiredLoan,
      monthlyEmi: monthlyEmi,
      totalInterestPayable: totalInterest,
      totalRepaymentAmount: totalRepayment,
      projectedMonthlyProfit: monthlyProfit,
      netCashFlowAfterEmi: netCashFlow,
      debtServiceCoverageRatio: dscr,
      isAffordable: isAffordable,
      affordabilityRiskLevel: riskLevel,
      affordabilityRationale: rationale,
    );
  }
}
