from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class AssessmentLevel(str, Enum):
    HIGH = "HIGH"
    MODERATE = "MODERATE"
    LOW = "LOW"
    INTENSE = "INTENSE"
    CRITICAL = "CRITICAL"
    UNCERTAIN = "UNCERTAIN"
    NO_CLEAR_GAP = "NO_CLEAR_GAP"
    POTENTIAL_GAP = "POTENTIAL_GAP"
    UNDERSERVED = "UNDERSERVED"


class MarketGapAnalysis(BaseModel):
    """
    Identifies underserved customer needs and gaps in current competitor offerings.
    """

    gap_level: AssessmentLevel = Field(
        default=AssessmentLevel.UNCERTAIN,
        description="Market gap classification (NO_CLEAR_GAP, POTENTIAL_GAP, UNDERSERVED, UNCERTAIN)",
    )
    identified_gaps: List[str] = Field(
        default_factory=list,
        description="Specific unmet customer needs or service/quality gaps",
    )
    unserved_customer_segments: List[str] = Field(
        default_factory=list,
        description="Customer segments currently underserved in the target area",
    )
    gap_opportunity_level: AssessmentLevel = Field(
        default=AssessmentLevel.UNCERTAIN,
        description="Opportunity potential rating arising from market gaps",
    )
    confidence_score: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
        description="Provisional confidence score (0.0 to 1.0) separate from gap_level",
    )
    evidence_basis: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Structured evidence citations supporting identified gaps",
    )
    scope_alignment: str = Field(
        default="UNKNOWN",
        description="Geographic scope alignment status (ALIGNED, MISMATCHED, UNKNOWN)",
    )
    key_evidence_ids: List[str] = Field(default_factory=list, description="Traceable evidence citation IDs")

    @property
    def underserved_segments(self) -> List[str]:
        """Convenience alias for unserved_customer_segments."""
        return self.unserved_customer_segments

    @property
    def evidence_ids(self) -> List[str]:
        """Convenience alias for key_evidence_ids."""
        return self.key_evidence_ids


class RiskItem(BaseModel):
    category: str = Field(description="SUPPLY, SEASONAL, COMPETITION, DEMAND, DISTRIBUTION, CUSTOMER_CONCENTRATION, ACCESSIBILITY, PRICING, OPERATIONAL, OTHER")
    title: str = Field(description="Short risk summary title")
    severity: AssessmentLevel = Field(default=AssessmentLevel.MODERATE, description="Risk severity tier (LOW, MODERATE, HIGH, UNCERTAIN)")
    explanation: str = Field(description="Detailed evidence-grounded explanation of the identified risk")
    evidence_ids: List[str] = Field(default_factory=list, description="Traceable EvidenceItem IDs supporting this risk")
    confidence: float = Field(default=0.0, ge=0.0, le=1.0, description="Provisional confidence score (0.0 to 1.0) separate from severity")

    @property
    def risk_title(self) -> str:
        """Convenience alias for title."""
        return self.title

    @property
    def risk_category(self) -> str:
        """Convenience alias for category."""
        return self.category

    @property
    def key_evidence_ids(self) -> List[str]:
        """Convenience alias for evidence_ids."""
        return self.evidence_ids


class RiskAnalysis(BaseModel):
    """
    Evaluates business-specific risks and overall risk level strictly from evidence records.
    """

    identified_risks: List[RiskItem] = Field(default_factory=list, description="Structured risk items")
    overall_risk_level: AssessmentLevel = Field(
        default=AssessmentLevel.UNCERTAIN,
        description="Overall business risk tier (HIGH, MODERATE, LOW, UNCERTAIN)",
    )
    confidence_score: float = Field(
        default=0.0, ge=0.0, le=1.0, description="Provisional confidence score (0.0 to 1.0) separate from risk level"
    )
    key_evidence_ids: List[str] = Field(default_factory=list, description="Traceable evidence citation IDs")

    @property
    def risk_items(self) -> List[RiskItem]:
        """Convenience alias for identified_risks."""
        return self.identified_risks


class FeasibilityScoreResult(BaseModel):
    """
    Deterministic score result container for Opportunity Score Analyzer.
    Supports NULL overall_score when evidence is missing or insufficient.
    """

    overall_score: Optional[float] = Field(
        default=None,
        ge=0.0,
        le=100.0,
        description="Total feasibility score out of 100. NULL if data is insufficient.",
    )
    grade: str = Field(
        default="INSUFFICIENT_DATA",
        description="Feasibility grade (HIGHLY_FEASIBLE, CONDITIONALLY_FEASIBLE, MODERATE_RISK, HIGH_RISK, INSUFFICIENT_DATA)",
    )
    status: str = Field(
        default="INSUFFICIENT_EVIDENCE",
        description="Score status (SUFFICIENT, PARTIAL, INSUFFICIENT_EVIDENCE)",
    )
    confidence_score: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
        description="Confidence score (0.0 to 1.0) separate from overall_score",
    )
    demand_score_component: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    competition_score_component: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    market_reach_score_component: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    market_gap_score_component: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    risk_score_component: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    financial_score_component: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    scoring_notes: List[str] = Field(default_factory=list, description="Explanatory notes on scoring factors")
    key_evidence_ids: List[str] = Field(default_factory=list, description="Traceable evidence citation IDs")

    @property
    def score(self) -> Optional[float]:
        """Convenience alias for overall_score."""
        return self.overall_score

    @property
    def confidence(self) -> float:
        """Convenience alias for confidence_score."""
        return self.confidence_score

    @property
    def key_reasons(self) -> List[str]:
        """Convenience alias for scoring_notes."""
        return self.scoring_notes
