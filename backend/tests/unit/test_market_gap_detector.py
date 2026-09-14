from datetime import datetime, timezone
import pytest

from app.schemas.evidence import EvidenceItem
from app.schemas.feasibility import AssessmentLevel, MarketGapAnalysis
from app.services.market_gap_detector import (
    PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS,
    MarketGapDetector,
)


@pytest.fixture
def sample_now():
    return datetime.now(timezone.utc)


def test_market_gap_no_evidence():
    """Test 1 — No evidence returns UNCERTAIN, confidence 0.0, empty evidence IDs."""
    analysis = MarketGapDetector.analyze(evidence_items=[], target_radius_km=5.0)

    assert isinstance(analysis, MarketGapAnalysis)
    assert analysis.gap_level == AssessmentLevel.UNCERTAIN
    assert analysis.confidence_score == 0.0
    assert analysis.key_evidence_ids == []
    assert analysis.evidence_ids == []
    assert analysis.unserved_customer_segments == []


def test_market_gap_population_only(sample_now):
    """Test 2 — Population evidence alone (15,000 residents) must NOT create a market gap."""
    evidence = [
        EvidenceItem(
            id="ev-pop-1",
            research_project_id="proj-1",
            claim="Census reports population of 15,000 residents within 5 km radius",
            extracted_value="15000",
            unit="residents",
            source_name="Census",
            source_type="GOVERNMENT",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.gap_level == AssessmentLevel.UNCERTAIN
    assert analysis.confidence_score == PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["COMPETITION_OR_POPULATION_ONLY"]
    assert analysis.key_evidence_ids == ["ev-pop-1"]


def test_market_gap_competition_only_zero_mapped(sample_now):
    """Test 3 — Zero mapped competitors alone must NOT automatically generate a market gap."""
    evidence = [
        EvidenceItem(
            id="ev-comp-0",
            research_project_id="proj-1",
            claim="Mapped POI search found 0 mapped competitors",
            extracted_value="0",
            source_name="Mappls API",
            source_type="TRUSTED_WEB",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    # Must NOT be UNDERSERVED or POTENTIAL_GAP without demand/unmet need evidence
    assert analysis.gap_level == AssessmentLevel.UNCERTAIN
    assert any("mapped listings may be incomplete" in gap for gap in analysis.identified_gaps)


def test_market_gap_strong_demand_without_supply_deficit(sample_now):
    """Test 4 — Strong demand alone without supply deficit evidence does not automatically become UNDERSERVED."""
    evidence = [
        EvidenceItem(
            id="ev-demand-1",
            research_project_id="proj-1",
            claim="High consumer demand for organic dairy products",
            source_name="Regional Survey",
            source_type="TRUSTED_WEB",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.gap_level == AssessmentLevel.UNCERTAIN
    assert analysis.key_evidence_ids == ["ev-demand-1"]


def test_market_gap_explicit_local_access_problem(sample_now):
    """Test 5 — Explicit customer travel outside target area indicates an access gap."""
    evidence = [
        EvidenceItem(
            id="ev-access-1",
            research_project_id="proj-1",
            claim="Customers travel to nearby town 8 km away to purchase packaged milk",
            source_name="Field Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.gap_level in [AssessmentLevel.POTENTIAL_GAP, AssessmentLevel.UNDERSERVED]
    assert len(analysis.identified_gaps) > 0
    assert analysis.key_evidence_ids == ["ev-access-1"]


def test_market_gap_explicit_unmet_need(sample_now):
    """Test 6 — Explicit primary evidence of no local provider produces UNDERSERVED with traceable ID."""
    evidence = [
        EvidenceItem(
            id="ev-unmet-1",
            research_project_id="proj-1",
            claim="No local supplier currently offers home delivery in the village",
            source_name="Village Interview",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.gap_level == AssessmentLevel.UNDERSERVED
    assert analysis.confidence_score == PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["EXPLICIT_PRIMARY_UNMET_NEED"]
    assert analysis.key_evidence_ids == ["ev-unmet-1"]


def test_market_gap_demand_and_limited_competition(sample_now):
    """Test 7 — Demand + limited mapped competition produces POTENTIAL_GAP without treating mapped competition as census."""
    evidence = [
        EvidenceItem(
            id="ev-demand-2",
            research_project_id="proj-1",
            claim="High demand for fresh unpasteurized milk",
            source_name="Consumer Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        ),
        EvidenceItem(
            id="ev-comp-2",
            research_project_id="proj-1",
            claim="Mapped POI search shows 2 competitors",
            extracted_value="2",
            source_name="Mappls API",
            source_type="TRUSTED_WEB",
            created_at=sample_now,
        ),
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.gap_level == AssessmentLevel.POTENTIAL_GAP
    assert set(analysis.key_evidence_ids) == {"ev-demand-2", "ev-comp-2"}


def test_market_gap_zero_mapped_competitors_guard(sample_now):
    """Test 8 — mapped_competitors = 0 does NOT automatically produce UNDERSERVED."""
    evidence = [
        EvidenceItem(
            id="ev-zero-comp",
            research_project_id="proj-1",
            claim="Mapped POI search found 0 mapped competitors",
            extracted_value="0",
            source_name="Mappls API",
            source_type="TRUSTED_WEB",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.gap_level != AssessmentLevel.UNDERSERVED


def test_market_gap_local_reported_competition_discrepancy(sample_now):
    """Test 9 — Discrepancy between mapped (2) and local-reported (6-10) reduces confidence without averaging."""
    evidence = [
        EvidenceItem(
            id="ev-map-comp",
            research_project_id="proj-1",
            claim="Mapped POI search shows 2 competitors",
            extracted_value="2",
            source_name="Mappls API",
            source_type="TRUSTED_WEB",
            created_at=sample_now,
        ),
        EvidenceItem(
            id="ev-local-comp",
            research_project_id="proj-1",
            claim="Local survey reports 6 to 10 local vendors",
            source_name="Village Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        ),
        EvidenceItem(
            id="ev-demand-mix",
            research_project_id="proj-1",
            claim="Strong demand for fresh dairy",
            source_name="Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        ),
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    # Confidence must be reduced due to discrepancy
    assert analysis.confidence_score <= PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["DISCREPANT_OR_MISMATCHED_SCOPE"]
    assert set(analysis.key_evidence_ids) == {"ev-map-comp", "ev-local-comp", "ev-demand-mix"}


def test_market_gap_scope_mismatch(sample_now):
    """Test 10 — District-level demand with 5 km target sets scope_alignment = MISMATCHED and lowers confidence."""
    evidence = [
        EvidenceItem(
            id="ev-macro-demand",
            research_project_id="proj-1",
            claim="District level demand report shows high demand",
            geography="Pune District",
            source_name="District Report",
            source_type="GOVERNMENT",
            created_at=sample_now,
        ),
        EvidenceItem(
            id="ev-unmet-scope",
            research_project_id="proj-1",
            claim="No local supplier available in the area",
            source_name="Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        ),
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.scope_alignment == "MISMATCHED"
    assert analysis.confidence_score <= PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["DISCREPANT_OR_MISMATCHED_SCOPE"]


def test_market_gap_segment_preservation(sample_now):
    """Test 11 — Explicitly mentioned segment (small households, evening buyers) is preserved without inventing others."""
    evidence = [
        EvidenceItem(
            id="ev-seg-1",
            research_project_id="proj-1",
            claim="Small households and evening buyers report difficulty obtaining fresh milk after 7 PM",
            source_name="Field Interview",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert "Small households" in analysis.unserved_customer_segments
    assert "Evening buyers" in analysis.underserved_segments
    assert analysis.key_evidence_ids == ["ev-seg-1"]


def test_market_gap_demand_contamination(sample_now):
    """Test 12 — Pure quantitative demand (50 liters/day) without unmet need evidence must NOT create a gap."""
    evidence = [
        EvidenceItem(
            id="ev-vol-1",
            research_project_id="proj-1",
            claim="Daily sales volume of 50 liters for unpasteurized milk",
            extracted_value="50",
            unit="liters/day",
            source_name="Field Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert analysis.gap_level == AssessmentLevel.UNCERTAIN


def test_market_gap_distribution_access_gap(sample_now):
    """Test 13 — Evidence of customer travel to another village is recognized as an access gap."""
    evidence = [
        EvidenceItem(
            id="ev-travel-1",
            research_project_id="proj-1",
            claim="People travel to another village 6 km away for dairy items",
            source_name="Village Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    analysis = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert any("access gap" in gap.lower() or "travel" in gap.lower() for gap in analysis.identified_gaps)


def test_market_gap_determinism(sample_now):
    """Test 14 — Identical inputs produce identical outputs across repeated executions."""
    evidence = [
        EvidenceItem(
            id="ev-det-1",
            research_project_id="proj-1",
            claim="No local supplier currently offers evening home delivery",
            source_name="Survey",
            source_type="FIELD_PRIMARY",
            created_at=sample_now,
        )
    ]
    res1 = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)
    res2 = MarketGapDetector.analyze(evidence_items=evidence, target_radius_km=5.0)

    assert res1.model_dump() == res2.model_dump()
