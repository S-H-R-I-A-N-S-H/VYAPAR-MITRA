from datetime import datetime, timezone
import pytest

from app.schemas.evidence import EvidenceItem
from app.schemas.feasibility import AssessmentLevel, RiskAnalysis
from app.services.risk_analyzer import (
    PROVISIONAL_RISK_CONFIDENCE_HEURISTICS,
    RiskAnalyzer,
)


@pytest.fixture
def sample_now():
    return datetime.now(timezone.utc)


def test_risk_no_evidence():
    """Test 1 — No evidence returns empty risk items and UNCERTAIN overall risk."""
    analysis = RiskAnalyzer.analyze(evidence_items=[], target_radius_km=5.0)

    assert isinstance(analysis, RiskAnalysis)
    assert analysis.identified_risks == []
    assert analysis.risk_items == []
    assert analysis.overall_risk_level == AssessmentLevel.UNCERTAIN
    assert analysis.confidence_score == 0.0
    assert analysis.key_evidence_ids == []


def test_risk_supply_disruption(sample_now):
    """Test 2 — Supply disruption evidence generates a SUPPLY risk."""
    evidence = [
        EvidenceItem(
            id="ev-supply-1",
            research_project_id="proj-1",
            claim="Milk supply is irregular during summer months with frequent raw material delays",
            source_name="Village Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    risk = analysis.identified_risks[0]
    assert risk.category == "SUPPLY"
    assert risk.risk_category == "SUPPLY"
    assert risk.severity == AssessmentLevel.HIGH
    assert risk.evidence_ids == ["ev-supply-1"]
    assert risk.key_evidence_ids == ["ev-supply-1"]


def test_risk_seasonal_disruption(sample_now):
    """Test 3 — Seasonal evidence generates a SEASONAL risk."""
    evidence = [
        EvidenceItem(
            id="ev-seasonal-1",
            research_project_id="proj-1",
            claim="Demand falls significantly during monsoon season due to transport cuts",
            source_name="Local Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.identified_risks[0].category == "SEASONAL"
    assert analysis.identified_risks[0].severity == AssessmentLevel.HIGH


def test_risk_competition_pressure(sample_now):
    """Test 4 — Competition pressure evidence generates a COMPETITION risk."""
    evidence = [
        EvidenceItem(
            id="ev-comp-1",
            research_project_id="proj-1",
            claim="Several established sellers operate nearby and intense price competition exists",
            source_name="Market Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.identified_risks[0].category == "COMPETITION"


def test_risk_competition_count_alone(sample_now):
    """Test 5 — Mapped competition count alone must NOT automatically become a competition risk."""
    evidence = [
        EvidenceItem(
            id="ev-comp-count",
            research_project_id="proj-1",
            claim="Mapped POI search shows 7 mapped competitors",
            extracted_value="7",
            unit="competitors",
            source_name="Mappls API",
            source_type="TRUSTED_WEB",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    # Must NOT create a COMPETITION risk without evidence of threat/pressure
    assert analysis.identified_risks == []
    assert analysis.overall_risk_level == AssessmentLevel.UNCERTAIN


def test_risk_demand_volume_alone(sample_now):
    """Test 6 — Pure demand volume alone must NOT automatically become a demand risk."""
    evidence = [
        EvidenceItem(
            id="ev-demand-vol",
            research_project_id="proj-1",
            claim="Daily demand volume of 50 liters/day for unpasteurized milk",
            extracted_value="50",
            unit="liters/day",
            source_name="Consumer Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.identified_risks == []
    assert analysis.overall_risk_level == AssessmentLevel.UNCERTAIN


def test_risk_demand_uncertainty(sample_now):
    """Test 7 — Demand uncertainty/weakness evidence generates a DEMAND risk."""
    evidence = [
        EvidenceItem(
            id="ev-demand-weak",
            research_project_id="proj-1",
            claim="Customers report low demand during weekdays and weak purchasing intent",
            source_name="Field Interview",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.identified_risks[0].category == "DEMAND"


def test_risk_distribution_problem(sample_now):
    """Test 8 — Distribution problem evidence generates a DISTRIBUTION risk."""
    evidence = [
        EvidenceItem(
            id="ev-dist-1",
            research_project_id="proj-1",
            claim="Products are transported from nearby town and delivery becomes difficult during monsoon",
            source_name="Field Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert any(r.category == "DISTRIBUTION" for r in analysis.identified_risks)


def test_risk_customer_concentration(sample_now):
    """Test 9 — Single buyer dependency generates a CUSTOMER_CONCENTRATION risk."""
    evidence = [
        EvidenceItem(
            id="ev-conc-1",
            research_project_id="proj-1",
            claim="80% of purchases come from one institutional buyer in the block",
            source_name="Trader Interview",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.identified_risks[0].category == "CUSTOMER_CONCENTRATION"
    assert analysis.identified_risks[0].severity == AssessmentLevel.HIGH


def test_risk_accessibility_problem(sample_now):
    """Test 10 — Accessibility problem generates an ACCESSIBILITY risk."""
    evidence = [
        EvidenceItem(
            id="ev-access-1",
            research_project_id="proj-1",
            claim="Road becomes difficult to access during monsoon and customers travel 12 km",
            source_name="PWD Report",
            source_type="GOVERNMENT",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert any(r.category == "ACCESSIBILITY" for r in analysis.identified_risks)


def test_risk_pricing_volatility(sample_now):
    """Test 11 — Pricing volatility evidence generates a PRICING risk."""
    evidence = [
        EvidenceItem(
            id="ev-price-1",
            research_project_id="proj-1",
            claim="Local selling prices fluctuate significantly and raw material prices frequently change",
            source_name="Market Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.identified_risks[0].category == "PRICING"


def test_risk_operational_dependency(sample_now):
    """Test 12 — Power outage / cold storage evidence generates an OPERATIONAL risk."""
    evidence = [
        EvidenceItem(
            id="ev-op-1",
            research_project_id="proj-1",
            claim="Business depends on uninterrupted electricity and power outages cause milk spoilage",
            source_name="Field Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.identified_risks[0].category == "OPERATIONAL"
    assert analysis.identified_risks[0].severity == AssessmentLevel.HIGH


def test_risk_population_only_evidence(sample_now):
    """Test 13 — Population evidence alone must NOT generate fabricated risk items."""
    evidence = [
        EvidenceItem(
            id="ev-pop-only",
            research_project_id="proj-1",
            claim="Census reports population of 18,000 residents in block",
            extracted_value="18000",
            source_name="Census",
            source_type="GOVERNMENT",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.identified_risks == []
    assert analysis.overall_risk_level == AssessmentLevel.UNCERTAIN


def test_risk_financial_repayment_claim_excluded(sample_now):
    """Test 14 — Financial debt/EMI/DSCR claims must NOT create financial repayment risk in RiskAnalyzer."""
    evidence = [
        EvidenceItem(
            id="ev-fin-1",
            research_project_id="proj-1",
            claim="Monthly loan EMI of Rs. 15,000 and DSCR of 1.15 indicates tight repayment",
            source_name="Financial Plan",
            source_type="TRUSTED_WEB",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.identified_risks == []


def test_risk_conflicting_evidence_lowers_confidence(sample_now):
    """Test 15 — Conflicting evidence preserves evidence IDs and reduces overall confidence."""
    evidence = [
        EvidenceItem(
            id="ev-sec-supply",
            research_project_id="proj-1",
            claim="Government report states raw material supply is reliable",
            source_name="Govt Portal",
            source_type="GOVERNMENT",
            created_at=sample_now,
        ),
        EvidenceItem(
            id="ev-prim-supply",
            research_project_id="proj-1",
            claim="Local survey reports frequent raw material supply delays during summer",
            source_name="Village Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        ),
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.confidence_score <= PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["DISCREPANT_OR_MISMATCHED_SCOPE"]
    assert set(analysis.key_evidence_ids) == {"ev-prim-supply"}


def test_risk_geographic_scope_mismatch(sample_now):
    """Test 16 — Geographic scope mismatch lowers overall confidence score."""
    evidence = [
        EvidenceItem(
            id="ev-macro-risk",
            research_project_id="proj-1",
            claim="State level report notes power cuts affect dairy processing",
            geography="Maharashtra State",
            source_name="State Report",
            source_type="GOVERNMENT",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert len(analysis.identified_risks) == 1
    assert analysis.confidence_score <= PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["DISCREPANT_OR_MISMATCHED_SCOPE"]


def test_risk_evidence_traceability(sample_now):
    """Test 17 — Every evidence ID referenced in generated risk items must exist in input."""
    evidence = [
        EvidenceItem(
            id="ev-trace-risk-1",
            research_project_id="proj-1",
            claim="Milk supply is irregular due to single supplier dependency",
            source_name="Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    for risk in analysis.identified_risks:
        for ev_id in risk.evidence_ids:
            assert ev_id in ["ev-trace-risk-1"]


def test_risk_determinism(sample_now):
    """Test 18 — Identical inputs produce identical outputs across repeated executions."""
    evidence = [
        EvidenceItem(
            id="ev-det-risk",
            research_project_id="proj-1",
            claim="Cold storage is unavailable causing milk spoilage during power cut",
            source_name="Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    res1 = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)
    res2 = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert res1.model_dump() == res2.model_dump()


def test_risk_irrelevant_keyword_guardrail(sample_now):
    """Test 19 — Irrelevant occurrence of word 'delay' without supply context must NOT create a supply risk."""
    evidence = [
        EvidenceItem(
            id="ev-irrelevant-delay",
            research_project_id="proj-1",
            claim="Survey respondent delayed submitting feedback form",
            source_name="Field Note",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.identified_risks == []


def test_risk_multiple_categories(sample_now):
    """Test 20 — Evidence containing multiple risks independently identifies each category."""
    evidence = [
        EvidenceItem(
            id="ev-multi-1",
            research_project_id="proj-1",
            claim="Milk supply is irregular during summer months",
            source_name="Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        ),
        EvidenceItem(
            id="ev-multi-2",
            research_project_id="proj-1",
            claim="Power outages cause cold storage failures",
            source_name="PWD Report",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        ),
    ]
    analysis = RiskAnalyzer.analyze(evidence_items=evidence, target_radius_km=5.0)

    categories = [r.category for r in analysis.identified_risks]
    assert "SUPPLY" in categories
    assert "OPERATIONAL" in categories
    assert analysis.overall_risk_level == AssessmentLevel.HIGH
