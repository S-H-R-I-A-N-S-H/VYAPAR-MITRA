from datetime import datetime
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
            created_at=datetime.utcnow(),
        ),
        EvidenceItem(
            id="e2",
            research_project_id="proj1",
            claim="Local customers express low interest in packaged paneer; prefer loose local dairy",
            source_name="In-App Village Survey (30 households)",
            source_type="FIELD_PRIMARY",
            confidence_score=0.90,
            created_at=datetime.utcnow(),
        ),
    ]

    conflicts = ConflictDetector.detect_conflicts(records)
    assert len(conflicts) == 1
    assert conflicts[0].topic == "Market Demand"
    assert conflicts[0].impact_on_confidence == "high_risk"
