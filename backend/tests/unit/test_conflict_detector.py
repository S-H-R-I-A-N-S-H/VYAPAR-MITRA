from datetime import datetime, timezone
from app.schemas.evidence import EvidenceItem
from app.services.conflict_detector import ConflictDetector


def test_conflict_detector_identifies_demand_contradiction():
    records = [
        EvidenceItem(
            id="e1",
            research_project_id="proj1",
            claim="High demand for packaged paneer reported in district census and retail portals",
            source_name="District Industry Center Report",
            source_type="GOVERNMENT",
            confidence_score=0.85,
            created_at=datetime.now(timezone.utc),
        ),
        EvidenceItem(
            id="e2",
            research_project_id="proj1",
            claim="Local customers express low interest in packaged paneer; prefer loose local dairy",
            source_name="In-App Village Survey (30 households)",
            source_type="FIELD_PRIMARY",
            confidence_score=0.90,
            created_at=datetime.now(timezone.utc),
        ),
    ]

    conflicts = ConflictDetector.detect_conflicts(records)
    assert len(conflicts) == 1
    assert conflicts[0].topic == "Market Demand"
    assert conflicts[0].impact_on_confidence == "high_risk"


def test_conflict_detector_identifies_pricing_contradiction():
    records = [
        EvidenceItem(
            id="e1",
            research_project_id="proj1",
            claim="Consumers in district willing to pay ₹120 per kg for organic flour",
            source_name="State Agricultural Marketing Board",
            source_type="GOVERNMENT",
            confidence_score=0.80,
            created_at=datetime.now(timezone.utc),
        ),
        EvidenceItem(
            id="e2",
            research_project_id="proj1",
            claim="Packaged flour above ₹80 considered unaffordable by local village wage earners",
            source_name="Weekly Haat Survey",
            source_type="LOCAL_SURVEY",
            confidence_score=0.88,
            created_at=datetime.now(timezone.utc),
        ),
    ]

    conflicts = ConflictDetector.detect_conflicts(records)
    assert len(conflicts) == 1
    assert conflicts[0].topic == "Customer Price Tolerance"
    assert conflicts[0].impact_on_confidence == "medium_risk"


def test_conflict_detector_empty_or_no_contradiction():
    """When claims agree or evidence is empty, zero conflicts should be generated."""
    # 1. Empty records
    assert ConflictDetector.detect_conflicts([]) == []

    # 2. Both claims agree on positive demand
    agreeing_records = [
        EvidenceItem(
            id="e1",
            research_project_id="proj1",
            claim="Steady growing demand for cold-pressed mustard oil in regional markets",
            source_name="KVK Market Study",
            source_type="GOVERNMENT",
            confidence_score=0.85,
            created_at=datetime.now(timezone.utc),
        ),
        EvidenceItem(
            id="e2",
            research_project_id="proj1",
            claim="80% of local grocery retailers express interest in stocking locally pressed mustard oil",
            source_name="Retailer Field Survey",
            source_type="FIELD_PRIMARY",
            confidence_score=0.92,
            created_at=datetime.now(timezone.utc),
        ),
    ]
    assert ConflictDetector.detect_conflicts(agreeing_records) == []


def test_conflict_detector_only_single_source_type():
    """If only secondary data exists (no field primary evidence to contrast), no conflicts are raised."""
    secondary_only = [
        EvidenceItem(
            id="e1",
            research_project_id="proj1",
            claim="High demand for poultry feed in district",
            source_name="NABARD Potential Linked Credit Plan",
            source_type="GOVERNMENT",
            confidence_score=0.82,
            created_at=datetime.now(timezone.utc),
        )
    ]
    assert ConflictDetector.detect_conflicts(secondary_only) == []
