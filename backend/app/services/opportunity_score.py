from typing import Any, Dict, List, Optional, Tuple

from app.schemas.feasibility import AssessmentLevel, FeasibilityScoreResult, MarketGapAnalysis, RiskAnalysis
from app.schemas.finance import FinancialSimulationResult

# MVP Heuristic Component Weights (Must sum to 1.0 / 100%)
DEFAULT_MVP_WEIGHTS: Dict[str, float] = {
    "demand": 0.25,
    "competition": 0.20,
    "market_reach": 0.15,
    "market_gap": 0.20,
    "risk": 0.10,
    "financial": 0.10,
}


class OpportunityScoreAnalyzer:
    """
    Authoritative Opportunity Score Analyzer service for Vyapar Mitra.

    Summarizes evidence outputs from sub-analyzers (Competition, Demand, Market Reach,
    Market Gap, Risk, Financial Engine) into an evidence-based Opportunity Score (0–100).

    Core Product Rules & Guardrails:
    1. No Fake Success Probability: The score represents "how favorable currently available evidence appears",
       NOT a statistical probability of business success or guaranteed profitability.
    2. Confidence is Separate: overall_score (e.g. 78/100) and confidence_score (e.g. 0.54) are independent dimensions.
       Confidence NEVER mathematically multiplies or reduces the opportunity score.
    3. Missing Evidence != Zero: Missing evidence components (e.g. unavailable demand) are excluded from the weighted average
       and active weights are renormalized to 100%. Missing data lowers confidence separately without punishing the score.
    4. Explicit Configurable Weights: Weights sum to 100% and are explicitly declared in DEFAULT_MVP_WEIGHTS.
    5. Financial Engine Boundary: Consumes FinancialSimulationResult affordability signals if provided, but NEVER recalculates EMI or DSCR.
    6. Competition Boundary: Relies on Competition Analyzer signals without reinterpreting raw competitor counts.
    7. Market Gap Boundary: Consumes MarketGapAnalysis without treating 0 mapped competitors as a maximum opportunity score.
    8. Risk Boundary: Consumes RiskAnalysis severity as a negative opportunity signal without inventing category risks.
    9. Traceability: Collects authentic input evidence citation IDs. Zero fake/generated IDs.
    10. Deterministic & Provider-Agnostic: Zero LLMs, external APIs, or randomness.
    """

    DEFAULT_WEIGHTS = DEFAULT_MVP_WEIGHTS

    @classmethod
    def normalize_demand(cls, demand: Optional[Any]) -> Tuple[Optional[float], Optional[float], List[str]]:
        """Normalizes demand signal to 0-100 scale, returning (score, confidence, notes)."""
        if demand is None:
            return None, None, []

        level = getattr(demand, "qualitative_demand_level", None) or getattr(demand, "demand_level", None)
        if isinstance(level, str):
            level = level.upper()

        if level == AssessmentLevel.HIGH or level == "HIGH":
            return 90.0, 0.85, ["Demand evidence indicates strong local demand."]
        elif level == AssessmentLevel.MODERATE or level == "MODERATE":
            return 70.0, 0.75, ["Demand evidence indicates moderate local demand."]
        elif level == AssessmentLevel.LOW or level == "LOW":
            return 40.0, 0.60, ["Demand evidence indicates weak local demand."]
        elif level == AssessmentLevel.UNCERTAIN or level == "UNCERTAIN":
            return None, 0.20, []
        return None, None, []

    @classmethod
    def normalize_competition(cls, competition: Optional[Any]) -> Tuple[Optional[float], Optional[float], List[str]]:
        """Normalizes competition signal to 0-100 scale (lower competition = higher opportunity score)."""
        if competition is None:
            return None, None, []

        level = getattr(competition, "competition_assessment", None) or getattr(competition, "competition_level", None)
        conf = getattr(competition, "confidence_score", None) or getattr(competition, "confidence", 0.70)
        if isinstance(level, str):
            level = level.upper()

        if level == AssessmentLevel.LOW or level == "LOW":
            return 90.0, conf, ["Competition evidence indicates low competitor density."]
        elif level == AssessmentLevel.MODERATE or level == "MODERATE":
            return 70.0, conf, ["Competition evidence indicates moderate competitor presence."]
        elif level == AssessmentLevel.HIGH or level == "HIGH":
            return 40.0, conf, ["Competition evidence indicates high local competition."]
        elif level == AssessmentLevel.INTENSE or level == "INTENSE":
            return 20.0, conf, ["Competition evidence indicates intense local competitor saturation."]
        elif level == AssessmentLevel.UNCERTAIN or level == "UNCERTAIN":
            return None, 0.20, []
        return None, None, []

    @classmethod
    def normalize_market_reach(cls, market_reach: Optional[Any]) -> Tuple[Optional[float], Optional[float], List[str]]:
        """Normalizes market reach signal to 0-100 scale."""
        if market_reach is None:
            return None, None, []

        level = getattr(market_reach, "reachability_assessment", None) or getattr(market_reach, "reachability", None)
        if isinstance(level, str):
            level = level.upper()

        if level == AssessmentLevel.HIGH or level == "HIGH":
            return 90.0, 0.85, ["Market reach evidence indicates strong local catchment accessibility."]
        elif level == AssessmentLevel.MODERATE or level == "MODERATE":
            return 70.0, 0.75, ["Market reach evidence indicates reasonable catchment accessibility."]
        elif level == AssessmentLevel.LOW or level == "LOW":
            return 40.0, 0.60, ["Market reach evidence indicates constrained catchment accessibility."]
        elif level == AssessmentLevel.UNCERTAIN or level == "UNCERTAIN":
            return None, 0.20, []
        return None, None, []

    @classmethod
    def normalize_market_gap(cls, market_gap: Optional[MarketGapAnalysis]) -> Tuple[Optional[float], Optional[float], List[str]]:
        """Normalizes market gap signal to 0-100 scale (underserved gap = high opportunity score)."""
        if market_gap is None:
            return None, None, []

        level = market_gap.gap_level
        conf = market_gap.confidence_score

        if level == AssessmentLevel.UNDERSERVED:
            return 95.0, conf, ["Market gap evidence indicates explicit underserved customer needs."]
        elif level == AssessmentLevel.POTENTIAL_GAP:
            return 75.0, conf, ["Market gap evidence indicates a potential market opportunity."]
        elif level == AssessmentLevel.NO_CLEAR_GAP:
            return 50.0, conf, ["Market gap evidence indicates existing supply appears reasonably present."]
        elif level == AssessmentLevel.UNCERTAIN:
            return None, conf, []
        return None, None, []

    @classmethod
    def normalize_risk(cls, risks: Optional[RiskAnalysis]) -> Tuple[Optional[float], Optional[float], List[str]]:
        """Normalizes risk signal to 0-100 scale (lower risk = higher opportunity score)."""
        if risks is None:
            return None, None, []

        level = risks.overall_risk_level
        conf = risks.confidence_score

        if level == AssessmentLevel.LOW:
            return 90.0, conf, ["Risk analysis indicates low business-specific threat levels."]
        elif level == AssessmentLevel.MODERATE:
            return 60.0, conf, ["Risk analysis indicates moderate business threats."]
        elif level == AssessmentLevel.HIGH:
            return 25.0, conf, ["Risk analysis indicates high business operational or supply threats."]
        elif level == AssessmentLevel.CRITICAL:
            return 10.0, conf, ["Risk analysis indicates critical threat levels."]
        elif level == AssessmentLevel.UNCERTAIN:
            return None, conf, []
        return None, None, []

    @classmethod
    def normalize_financial(cls, financial: Optional[FinancialSimulationResult]) -> Tuple[Optional[float], Optional[float], List[str]]:
        """Normalizes financial simulation result to 0-100 scale."""
        if financial is None:
            return None, None, []

        risk_level = (financial.affordability_risk_level or "").lower()
        if risk_level == "safe":
            return 90.0, 0.90, ["Financial simulation indicates strong debt service affordability."]
        elif risk_level == "moderate":
            return 60.0, 0.80, ["Financial simulation indicates tight but feasible debt affordability."]
        elif risk_level == "critical" or not financial.is_affordable:
            return 15.0, 0.85, ["Financial simulation indicates critical repayment or cash flow risk."]
        return None, None, []

    @classmethod
    def analyze(
        cls,
        competition: Optional[Any] = None,
        demand: Optional[Any] = None,
        market_reach: Optional[Any] = None,
        market_gap: Optional[MarketGapAnalysis] = None,
        risks: Optional[RiskAnalysis] = None,
        financial: Optional[FinancialSimulationResult] = None,
        custom_weights: Optional[Dict[str, float]] = None,
    ) -> FeasibilityScoreResult:
        """
        Executes Opportunity Score analysis pipeline deterministically.

        :param competition: CompetitionAnalysis or similar object
        :param demand: DemandAnalysis or similar object
        :param market_reach: MarketReachAnalysis or similar object
        :param market_gap: MarketGapAnalysis object
        :param risks: RiskAnalysis object
        :param financial: FinancialSimulationResult object
        :param custom_weights: Optional overriding weight dictionary
        :return: FeasibilityScoreResult Pydantic model
        """
        weights = custom_weights or cls.DEFAULT_WEIGHTS

        # Validate weight sum (must be ~1.0)
        weight_total = sum(weights.values())
        if abs(weight_total - 1.0) > 0.01:
            raise ValueError(f"Weights must sum to 1.0 (got {weight_total:.4f})")

        # Extract normalized scores, confidences, and explanatory notes
        components: Dict[str, Tuple[Optional[float], Optional[float], List[str]]] = {
            "demand": cls.normalize_demand(demand),
            "competition": cls.normalize_competition(competition),
            "market_reach": cls.normalize_market_reach(market_reach),
            "market_gap": cls.normalize_market_gap(market_gap),
            "risk": cls.normalize_risk(risks),
            "financial": cls.normalize_financial(financial),
        }

        active_scores: Dict[str, float] = {}
        active_weights: Dict[str, float] = {}
        confidences: List[float] = []
        scoring_notes: List[str] = []
        key_evidence_ids: List[str] = []

        # Collect evidence IDs from all provided input models
        input_models = [competition, demand, market_reach, market_gap, risks]
        for m in input_models:
            if m is not None:
                ids = getattr(m, "key_evidence_ids", None) or getattr(m, "evidence_ids", None) or []
                for ev_id in ids:
                    if ev_id and ev_id not in key_evidence_ids:
                        key_evidence_ids.append(ev_id)

        # Process each component
        for name, (score, conf, notes) in components.items():
            if score is not None:
                active_scores[name] = score
                active_weights[name] = weights.get(name, 0.0)
                scoring_notes.extend(notes)
                if conf is not None and conf > 0.0:
                    confidences.append(conf)

        num_available = len(active_scores)
        total_components = len(weights)

        # Handle case where NO component evidence is available
        if num_available == 0:
            return FeasibilityScoreResult(
                overall_score=None,
                grade="INSUFFICIENT_DATA",
                status="INSUFFICIENT_EVIDENCE",
                confidence_score=0.0,
                demand_score_component=None,
                competition_score_component=None,
                market_reach_score_component=None,
                market_gap_score_component=None,
                risk_score_component=None,
                financial_score_component=None,
                scoring_notes=["Insufficient evidence across all business feasibility dimensions."],
                key_evidence_ids=key_evidence_ids,
            )

        # Renormalize active weights to 100% (1.0)
        active_weight_sum = sum(active_weights.values())
        if active_weight_sum > 0:
            weighted_score_sum = sum(score * (active_weights[name] / active_weight_sum) for name, score in active_scores.items())
            overall_score = round(max(0.0, min(100.0, weighted_score_sum)), 1)
        else:
            overall_score = None

        # Confidence calculation (Separate dimension)
        # Average confidence across available components, scaled by data completeness ratio
        base_conf = (sum(confidences) / len(confidences)) if confidences else 0.50
        completeness_ratio = num_available / float(total_components)
        confidence_score = round(max(0.0, min(1.0, base_conf * (0.5 + 0.5 * completeness_ratio))), 2)

        # Determine Status
        if num_available >= 3:
            status = "SUFFICIENT"
        elif num_available >= 1:
            status = "PARTIAL"
        else:
            status = "INSUFFICIENT_EVIDENCE"

        # Determine Grade Thresholds (Provisional MVP Heuristic Thresholds)
        if overall_score is None:
            grade = "INSUFFICIENT_DATA"
        elif overall_score >= 80.0:
            grade = "HIGHLY_FEASIBLE"
        elif overall_score >= 65.0:
            grade = "CONDITIONALLY_FEASIBLE"
        elif overall_score >= 50.0:
            grade = "MODERATE_RISK"
        else:
            grade = "HIGH_RISK"

        return FeasibilityScoreResult(
            overall_score=overall_score,
            grade=grade,
            status=status,
            confidence_score=confidence_score,
            demand_score_component=active_scores.get("demand"),
            competition_score_component=active_scores.get("competition"),
            market_reach_score_component=active_scores.get("market_reach"),
            market_gap_score_component=active_scores.get("market_gap"),
            risk_score_component=active_scores.get("risk"),
            financial_score_component=active_scores.get("financial"),
            scoring_notes=scoring_notes,
            key_evidence_ids=key_evidence_ids,
        )
