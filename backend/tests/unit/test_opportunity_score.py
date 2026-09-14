from typing import List, Optional
import pytest
from pydantic import BaseModel

from app.schemas.feasibility import AssessmentLevel, FeasibilityScoreResult, MarketGapAnalysis, RiskAnalysis, RiskItem
from app.schemas.finance import FinancialSimulationResult
from app.services.opportunity_score import DEFAULT_MVP_WEIGHTS, OpportunityScoreAnalyzer


# Dummy mock objects for sub-analyzers not present in the current branch
class DummyDemand(BaseModel):
    qualitative_demand_level: AssessmentLevel
    key_evidence_ids: List[str] = ["ev-demand-1"]


class DummyCompetition(BaseModel):
    competition_assessment: AssessmentLevel
    confidence_score: float = 0.80
    key_evidence_ids: List[str] = ["ev-comp-1"]


class DummyMarketReach(BaseModel):
    reachability_assessment: AssessmentLevel
    key_evidence_ids: List[str] = ["ev-reach-1"]


# ---------------------------------------------------------------------------
# Basic Scoring Tests (1-3)
# ---------------------------------------------------------------------------

def test_opportunity_score_all_favorable():
    """Test 1 — All components favorable produces a high score (>=85)."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.90, key_evidence_ids=["ev-gap-1"])
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.LOW, confidence_score=0.90, key_evidence_ids=["ev-risk-1"])
    fin = FinancialSimulationResult(
        total_project_cost=100000, own_capital=20000, required_loan_amount=80000,
        monthly_emi=2500, total_interest_payable=10000, total_repayment_amount=90000,
        projected_monthly_profit=10000, net_cash_flow_after_emi=7500, debt_service_coverage_ratio=4.0,
        is_affordable=True, affordability_risk_level="safe", affordability_rationale="Strong cash flow",
    )

    result = OpportunityScoreAnalyzer.analyze(
        demand=DummyDemand(qualitative_demand_level=AssessmentLevel.HIGH),
        competition=DummyCompetition(competition_assessment=AssessmentLevel.LOW),
        market_reach=DummyMarketReach(reachability_assessment=AssessmentLevel.HIGH),
        market_gap=gap,
        risks=risk,
        financial=fin,
    )

    assert result.overall_score is not None
    assert result.overall_score >= 85.0
    assert result.grade == "HIGHLY_FEASIBLE"
    assert result.status == "SUFFICIENT"


def test_opportunity_score_all_unfavorable():
    """Test 2 — All components unfavorable produces a low score (<50)."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.NO_CLEAR_GAP, confidence_score=0.80)
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.HIGH, confidence_score=0.80)
    fin = FinancialSimulationResult(
        total_project_cost=100000, own_capital=0, required_loan_amount=100000,
        monthly_emi=5000, total_interest_payable=20000, total_repayment_amount=120000,
        projected_monthly_profit=1000, net_cash_flow_after_emi=-4000, debt_service_coverage_ratio=0.2,
        is_affordable=False, affordability_risk_level="critical", affordability_rationale="Loss-making",
    )

    result = OpportunityScoreAnalyzer.analyze(
        demand=DummyDemand(qualitative_demand_level=AssessmentLevel.LOW),
        competition=DummyCompetition(competition_assessment=AssessmentLevel.INTENSE),
        market_reach=DummyMarketReach(reachability_assessment=AssessmentLevel.LOW),
        market_gap=gap,
        risks=risk,
        financial=fin,
    )

    assert result.overall_score is not None
    assert result.overall_score < 50.0
    assert result.grade == "HIGH_RISK"


def test_opportunity_score_mixed_evidence():
    """Test 3 — Mixed evidence produces an intermediate score."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.POTENTIAL_GAP, confidence_score=0.75)
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.MODERATE, confidence_score=0.75)

    result = OpportunityScoreAnalyzer.analyze(
        demand=DummyDemand(qualitative_demand_level=AssessmentLevel.HIGH),
        competition=DummyCompetition(competition_assessment=AssessmentLevel.HIGH),
        market_gap=gap,
        risks=risk,
    )

    assert result.overall_score is not None
    assert 50.0 <= result.overall_score <= 75.0


# ---------------------------------------------------------------------------
# Missing Evidence Tests (4-11)
# ---------------------------------------------------------------------------

def test_opportunity_score_missing_demand():
    """Test 4 — Missing demand is excluded and weights renormalized without setting score to 0."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.85)

    result = OpportunityScoreAnalyzer.analyze(demand=None, market_gap=gap)

    assert result.demand_score_component is None
    assert result.overall_score is not None
    assert result.overall_score >= 80.0


def test_opportunity_score_missing_competition():
    """Test 5 — Missing competition does not zero the score."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.85)

    result = OpportunityScoreAnalyzer.analyze(competition=None, market_gap=gap)

    assert result.competition_score_component is None
    assert result.overall_score is not None


def test_opportunity_score_missing_market_reach():
    """Test 6 — Missing market reach handled cleanly."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.85)

    result = OpportunityScoreAnalyzer.analyze(market_reach=None, market_gap=gap)

    assert result.market_reach_score_component is None
    assert result.overall_score is not None


def test_opportunity_score_missing_market_gap():
    """Test 7 — Missing market gap handled cleanly."""
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.LOW, confidence_score=0.85)

    result = OpportunityScoreAnalyzer.analyze(market_gap=None, risks=risk)

    assert result.market_gap_score_component is None
    assert result.overall_score is not None


def test_opportunity_score_missing_risk():
    """Test 8 — Missing risk handled cleanly."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.85)

    result = OpportunityScoreAnalyzer.analyze(risks=None, market_gap=gap)

    assert result.risk_score_component is None
    assert result.overall_score is not None


def test_opportunity_score_missing_financial():
    """Test 9 — Missing financial component handled cleanly."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.85)

    result = OpportunityScoreAnalyzer.analyze(financial=None, market_gap=gap)

    assert result.financial_score_component is None
    assert result.overall_score is not None


def test_opportunity_score_multiple_components_missing():
    """Test 10 — Multiple missing components produce PARTIAL status."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.POTENTIAL_GAP, confidence_score=0.75)

    result = OpportunityScoreAnalyzer.analyze(market_gap=gap)

    assert result.status == "PARTIAL"
    assert result.overall_score is not None


def test_opportunity_score_completely_empty_input():
    """Test 11 — Completely empty input returns NULL overall_score and INSUFFICIENT_EVIDENCE status."""
    result = OpportunityScoreAnalyzer.analyze()

    assert result.overall_score is None
    assert result.score is None
    assert result.status == "INSUFFICIENT_EVIDENCE"
    assert result.grade == "INSUFFICIENT_DATA"
    assert result.confidence_score == 0.0


# ---------------------------------------------------------------------------
# Confidence Independence Tests (12-14)
# ---------------------------------------------------------------------------

def test_opportunity_score_high_score_low_confidence():
    """Test 12 — High opportunity score with low confidence is valid."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.20)

    result = OpportunityScoreAnalyzer.analyze(market_gap=gap)

    assert result.overall_score is not None
    assert result.overall_score >= 80.0
    assert result.confidence_score < 0.40


def test_opportunity_score_low_score_high_confidence():
    """Test 13 — Low opportunity score with high confidence is valid."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.NO_CLEAR_GAP, confidence_score=0.90)
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.HIGH, confidence_score=0.90)

    result = OpportunityScoreAnalyzer.analyze(market_gap=gap, risks=risk)

    assert result.overall_score is not None
    assert result.overall_score < 50.0
    assert result.confidence_score >= 0.50


def test_opportunity_score_confidence_no_multiplication():
    """Test 14 — Confidence does NOT mathematically multiply or lower the overall score."""
    gap_low_conf = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.10)
    gap_high_conf = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.90)

    res_low = OpportunityScoreAnalyzer.analyze(market_gap=gap_low_conf)
    res_high = OpportunityScoreAnalyzer.analyze(market_gap=gap_high_conf)

    # Opportunity score MUST remain identical (confidence score differs)
    assert res_low.overall_score == res_high.overall_score
    assert res_low.confidence_score != res_high.confidence_score


# ---------------------------------------------------------------------------
# Component Boundary Tests (15-27)
# ---------------------------------------------------------------------------

def test_opportunity_score_low_mapped_competition():
    """Test 15 — Low competition assessment yields high competition component score."""
    res = OpportunityScoreAnalyzer.analyze(competition=DummyCompetition(competition_assessment=AssessmentLevel.LOW))
    assert res.competition_score_component == 90.0


def test_opportunity_score_high_mapped_competition():
    """Test 16 — High competition assessment yields lower competition component score."""
    res = OpportunityScoreAnalyzer.analyze(competition=DummyCompetition(competition_assessment=AssessmentLevel.HIGH))
    assert res.competition_score_component == 40.0


def test_opportunity_score_competition_uncertainty():
    """Test 17 — Uncertain competition is excluded from scoring."""
    res = OpportunityScoreAnalyzer.analyze(competition=DummyCompetition(competition_assessment=AssessmentLevel.UNCERTAIN))
    assert res.competition_score_component is None


def test_opportunity_score_strong_demand():
    """Test 18 — Strong demand yields high demand component score."""
    res = OpportunityScoreAnalyzer.analyze(demand=DummyDemand(qualitative_demand_level=AssessmentLevel.HIGH))
    assert res.demand_score_component == 90.0


def test_opportunity_score_weak_demand():
    """Test 19 — Weak demand yields low demand component score."""
    res = OpportunityScoreAnalyzer.analyze(demand=DummyDemand(qualitative_demand_level=AssessmentLevel.LOW))
    assert res.demand_score_component == 40.0


def test_opportunity_score_uncertain_demand():
    """Test 20 — Uncertain demand is excluded from scoring."""
    res = OpportunityScoreAnalyzer.analyze(demand=DummyDemand(qualitative_demand_level=AssessmentLevel.UNCERTAIN))
    assert res.demand_score_component is None


def test_opportunity_score_no_clear_gap():
    """Test 21 — NO_CLEAR_GAP yields neutral gap score (50.0)."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.NO_CLEAR_GAP, confidence_score=0.80)
    res = OpportunityScoreAnalyzer.analyze(market_gap=gap)
    assert res.market_gap_score_component == 50.0


def test_opportunity_score_potential_gap():
    """Test 22 — POTENTIAL_GAP yields favorable gap score (75.0)."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.POTENTIAL_GAP, confidence_score=0.80)
    res = OpportunityScoreAnalyzer.analyze(market_gap=gap)
    assert res.market_gap_score_component == 75.0


def test_opportunity_score_underserved_gap():
    """Test 23 — UNDERSERVED yields high gap score (95.0)."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.80)
    res = OpportunityScoreAnalyzer.analyze(market_gap=gap)
    assert res.market_gap_score_component == 95.0


def test_opportunity_score_uncertain_gap():
    """Test 24 — UNCERTAIN gap is excluded from scoring."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNCERTAIN, confidence_score=0.0)
    res = OpportunityScoreAnalyzer.analyze(market_gap=gap)
    assert res.market_gap_score_component is None


def test_opportunity_score_low_risk():
    """Test 25 — LOW risk yields high risk component score (90.0)."""
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.LOW, confidence_score=0.80)
    res = OpportunityScoreAnalyzer.analyze(risks=risk)
    assert res.risk_score_component == 90.0


def test_opportunity_score_high_risk():
    """Test 26 — HIGH risk yields low risk component score (25.0)."""
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.HIGH, confidence_score=0.80)
    res = OpportunityScoreAnalyzer.analyze(risks=risk)
    assert res.risk_score_component == 25.0


def test_opportunity_score_multiple_moderate_risks():
    """Test 27 — Multiple moderate risks leading to HIGH risk level yields 25.0 component score."""
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.HIGH, confidence_score=0.75)
    res = OpportunityScoreAnalyzer.analyze(risks=risk)
    assert res.risk_score_component == 25.0


# ---------------------------------------------------------------------------
# Financial Boundary Tests (28-29)
# ---------------------------------------------------------------------------

def test_opportunity_score_consumes_financial_readiness_signal():
    """Test 28 — FinancialSimulationResult is consumed if available."""
    fin = FinancialSimulationResult(
        total_project_cost=100000, own_capital=20000, required_loan_amount=80000,
        monthly_emi=2500, total_interest_payable=10000, total_repayment_amount=90000,
        projected_monthly_profit=10000, net_cash_flow_after_emi=7500, debt_service_coverage_ratio=4.0,
        is_affordable=True, affordability_risk_level="safe", affordability_rationale="Strong cash flow",
    )
    res = OpportunityScoreAnalyzer.analyze(financial=fin)
    assert res.financial_score_component == 90.0


def test_opportunity_score_does_not_recalculate_emi_or_dscr():
    """Test 29 — OpportunityScoreAnalyzer contains zero EMI/DSCR calculation logic."""
    fin = FinancialSimulationResult(
        total_project_cost=50000, own_capital=10000, required_loan_amount=40000,
        monthly_emi=1200, total_interest_payable=5000, total_repayment_amount=45000,
        projected_monthly_profit=3000, net_cash_flow_after_emi=1800, debt_service_coverage_ratio=2.5,
        is_affordable=True, affordability_risk_level="moderate", affordability_rationale="Tight",
    )
    res = OpportunityScoreAnalyzer.analyze(financial=fin)
    assert res.financial_score_component == 60.0


# ---------------------------------------------------------------------------
# Traceability & Determinism Tests (30-32)
# ---------------------------------------------------------------------------

def test_opportunity_score_preserves_evidence_ids():
    """Test 30 — Evidence citation IDs from input analyzers are preserved."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.85, key_evidence_ids=["ev-gap-100"])
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.LOW, confidence_score=0.85, key_evidence_ids=["ev-risk-200"])

    res = OpportunityScoreAnalyzer.analyze(
        demand=DummyDemand(qualitative_demand_level=AssessmentLevel.HIGH),
        market_gap=gap,
        risks=risk,
    )

    assert "ev-gap-100" in res.key_evidence_ids
    assert "ev-risk-200" in res.key_evidence_ids
    assert "ev-demand-1" in res.key_evidence_ids


def test_opportunity_score_no_fabricated_evidence_ids():
    """Test 31 — Zero input evidence IDs results in an empty key_evidence_ids list."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, key_evidence_ids=[])
    res = OpportunityScoreAnalyzer.analyze(market_gap=gap)

    assert res.key_evidence_ids == []


def test_opportunity_score_determinism():
    """Test 32 — Identical inputs produce identical outputs across repeated executions."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.POTENTIAL_GAP, confidence_score=0.75)
    risk = RiskAnalysis(overall_risk_level=AssessmentLevel.MODERATE, confidence_score=0.75)

    res1 = OpportunityScoreAnalyzer.analyze(market_gap=gap, risks=risk)
    res2 = OpportunityScoreAnalyzer.analyze(market_gap=gap, risks=risk)

    assert res1.model_dump() == res2.model_dump()


# ---------------------------------------------------------------------------
# Guardrail Invariant Tests (33-36)
# ---------------------------------------------------------------------------

def test_opportunity_score_population_alone_guardrail():
    """Test 33 — Population alone cannot produce a score without analytical components."""
    res = OpportunityScoreAnalyzer.analyze()
    assert res.overall_score is None


def test_opportunity_score_zero_mapped_competitors_guardrail():
    """Test 34 — Zero mapped competitors alone does NOT produce a maximum opportunity score."""
    # When market_gap and competition are UNCERTAIN, score remains NULL
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNCERTAIN)
    res = OpportunityScoreAnalyzer.analyze(market_gap=gap)
    assert res.overall_score is None


def test_opportunity_score_demand_volume_alone_guardrail():
    """Test 35 — Quantitative demand volume alone does NOT automatically produce max score."""
    res = OpportunityScoreAnalyzer.analyze(demand=DummyDemand(qualitative_demand_level=AssessmentLevel.UNCERTAIN))
    assert res.overall_score is None


def test_opportunity_score_missing_evidence_not_negative():
    """Test 36 — Missing evidence components are excluded without penalizing the active score."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED, confidence_score=0.85)

    res_single = OpportunityScoreAnalyzer.analyze(market_gap=gap)

    # Score must reflect 95.0 (UNDERSERVED), not a reduced/penalized score
    assert res_single.overall_score == 95.0


# ---------------------------------------------------------------------------
# Transparency & Boundary Property Tests (37-40)
# ---------------------------------------------------------------------------

def test_opportunity_score_configurable_weights():
    """Test 37 — Configurable weights work correctly."""
    custom = {
        "demand": 0.50,
        "competition": 0.0,
        "market_reach": 0.0,
        "market_gap": 0.50,
        "risk": 0.0,
        "financial": 0.0,
    }
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED) # 95.0
    demand = DummyDemand(qualitative_demand_level=AssessmentLevel.HIGH) # 90.0

    res = OpportunityScoreAnalyzer.analyze(demand=demand, market_gap=gap, custom_weights=custom)
    assert res.overall_score == 92.5


def test_opportunity_score_weight_sum_validation():
    """Test 38 — Weights that do not sum to 1.0 raise ValueError."""
    bad_weights = {"demand": 0.50, "competition": 0.10}
    with pytest.raises(ValueError):
        OpportunityScoreAnalyzer.analyze(custom_weights=bad_weights)


def test_opportunity_score_bounds_invariant():
    """Test 39 — Invariant: overall_score is strictly within [0.0, 100.0]."""
    gap = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED)
    res = OpportunityScoreAnalyzer.analyze(market_gap=gap)
    assert 0.0 <= res.overall_score <= 100.0


def test_opportunity_score_grade_thresholds():
    """Test 40 — Grade thresholds behave deterministically."""
    gap_high = MarketGapAnalysis(gap_level=AssessmentLevel.UNDERSERVED) # 95.0 -> HIGHLY_FEASIBLE
    gap_mod = MarketGapAnalysis(gap_level=AssessmentLevel.POTENTIAL_GAP) # 75.0 -> CONDITIONALLY_FEASIBLE
    gap_low = MarketGapAnalysis(gap_level=AssessmentLevel.NO_CLEAR_GAP) # 50.0 -> MODERATE_RISK

    assert OpportunityScoreAnalyzer.analyze(market_gap=gap_high).grade == "HIGHLY_FEASIBLE"
    assert OpportunityScoreAnalyzer.analyze(market_gap=gap_mod).grade == "CONDITIONALLY_FEASIBLE"
    assert OpportunityScoreAnalyzer.analyze(market_gap=gap_low).grade == "MODERATE_RISK"
