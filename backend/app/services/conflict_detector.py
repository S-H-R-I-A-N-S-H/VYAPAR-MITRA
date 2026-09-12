from typing import List
from app.schemas.evidence import ConflictItem, EvidenceItem


class ConflictDetector:
    """
    Detects contradictions between secondary macro/online data and local primary survey evidence.
    Ensures discrepancies are surfaced clearly to lower confidence and trigger local validation.
    """

    @classmethod
    def detect_conflicts(cls, evidence_records: List[EvidenceItem]) -> List[ConflictItem]:
        conflicts: List[ConflictItem] = []
        secondary = [e for e in evidence_records if e.source_type in ["GOVERNMENT", "TRUSTED_WEB"]]
        primary = [e for e in evidence_records if e.source_type in ["FIELD_PRIMARY", "LOCAL_SURVEY"]]

        # Check for Demand / Pricing / Competition discrepancies
        for sec in secondary:
            for prim in primary:
                # Demand conflict
                if "high demand" in sec.claim.lower() and (
                    "low interest" in prim.claim.lower() or "no demand" in prim.claim.lower()
                ):
                    conflicts.append(
                        ConflictItem(
                            id=f"conflict-demand-{sec.id}-{prim.id}",
                            topic="Market Demand",
                            secondary_claim=sec.claim,
                            secondary_source=sec.source_name,
                            primary_claim=prim.claim,
                            primary_source=prim.source_name,
                            discrepancy_explanation=(
                                f"Online research suggests strong regional demand ('{sec.claim}'), "
                                f"whereas local field surveys indicate weak immediate intent ('{prim.claim}')."
                            ),
                            impact_on_confidence="high_risk",
                            suggested_action="Conduct 15 additional local customer interviews with free sample demonstrations before committing capital.",
                        )
                    )

                # Pricing conflict
                if "willing to pay" in sec.claim.lower() and "unaffordable" in prim.claim.lower():
                    conflicts.append(
                        ConflictItem(
                            id=f"conflict-price-{sec.id}-{prim.id}",
                            topic="Customer Price Tolerance",
                            secondary_claim=sec.claim,
                            secondary_source=sec.source_name,
                            primary_claim=prim.claim,
                            primary_source=prim.source_name,
                            discrepancy_explanation=(
                                "Regional price benchmarks are higher than what local respondents state they are able to afford."
                            ),
                            impact_on_confidence="medium_risk",
                            suggested_action="Recalculate unit economics around a lower price point or offer smaller package sizes (sachet strategy).",
                        )
                    )

        return conflicts
