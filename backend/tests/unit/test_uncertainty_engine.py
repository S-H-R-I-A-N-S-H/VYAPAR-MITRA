from datetime import datetime
import pytest
from unittest.mock import AsyncMock, MagicMock
from app.schemas.evidence import EvidenceItem, ConflictItem
from app.services.conflict_detector import ConflictDetector, UncertaintyReport
from app.services.prompt_service import ConflictResolutionProposal


@pytest.fixture
def sample_evidence():
    return [
        EvidenceItem(
            id="sec-1",
            research_project_id="proj-1",
            claim="State average retail price for packaged flour is 120 per kg.",
            extracted_value="120",
            unit="INR/kg",
            source_name="Ministry of Consumer Affairs",
            source_type="GOVERNMENT",
            confidence_score=0.92,
            created_at=datetime.utcnow()
        ),
        EvidenceItem(
            id="prim-1",
            research_project_id="proj-1",
            claim="Local consumers state maximum affordable price is 80 per kg.",
            extracted_value="80",
            unit="INR/kg",
            source_name="Primary Village Survey (N=22)",
            source_type="FIELD_PRIMARY",
            confidence_score=0.85,
            created_at=datetime.utcnow()
        )
    ]


@pytest.mark.asyncio
async def test_conflict_detector_detects_numerical_pricing_divergence(sample_evidence):
    detector = ConflictDetector()
    conflicts = await detector.analyze_and_resolve(sample_evidence)

    assert len(conflicts) >= 1
    pricing_conflict = next(c for c in conflicts if "price" in c.topic.lower() or "pricing" in c.topic.lower())
    assert pricing_conflict.secondary_source == "Ministry of Consumer Affairs"
    assert pricing_conflict.primary_source == "Primary Village Survey (N=22)"
    assert pricing_conflict.impact_on_confidence in ["high_risk", "medium_risk"]
    assert len(pricing_conflict.suggested_action) > 10


@pytest.mark.asyncio
async def test_conflict_detector_uncertainty_report(sample_evidence):
    detector = ConflictDetector()
    report = await detector.generate_uncertainty_report(sample_evidence)

    assert isinstance(report, UncertaintyReport)
    assert report.total_evidence_count == 2
    assert report.has_primary_research is True
    assert report.has_secondary_research is True
    assert report.conflict_count >= 1
    # Because of the pricing conflict, confidence should be penalized
    assert report.overall_confidence < 0.90
    assert len(report.recommended_next_steps) >= 1


@pytest.mark.asyncio
async def test_conflict_detector_uncertainty_report_with_no_primary_evidence():
    detector = ConflictDetector()
    secondary_only = [
        EvidenceItem(
            id="sec-only",
            research_project_id="proj-1",
            claim="High regional demand for packaged honey.",
            source_name="Khadi Commission",
            source_type="GOVERNMENT",
            confidence_score=0.90,
            created_at=datetime.utcnow()
        )
    ]
    report = await detector.generate_uncertainty_report(secondary_only)

    assert report.has_primary_research is False
    assert "primary field validation" in " ".join(report.recommended_next_steps).lower()


@pytest.mark.asyncio
async def test_conflict_detector_with_ai_resolution_proposal(sample_evidence):
    mock_adapter = MagicMock()
    mock_adapter.is_live = True
    mock_adapter.generate_structured_output = AsyncMock(
        return_value=ConflictResolutionProposal(
            explanation="Macro regional prices include retail distribution markups, whereas village buyers expect unbranded direct pricing.",
            confidence_impact="medium_risk",
            suggested_action="Introduce ₹20 sachets (200g) rather than 1kg packs to match local liquidity.",
            recommended_field_validation="Run test sales of 50 sachets at weekly village haat."
        )
    )

    detector = ConflictDetector(adapter=mock_adapter)
    conflicts = await detector.analyze_and_resolve(sample_evidence)

    assert len(conflicts) >= 1
    assert "sachets" in conflicts[0].suggested_action
