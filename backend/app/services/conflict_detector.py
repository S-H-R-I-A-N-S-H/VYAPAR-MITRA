import logging
from typing import List, Optional
from pydantic import BaseModel, Field

from app.adapters.gemini_adapter import GeminiAdapter
from app.schemas.evidence import ConflictItem, EvidenceItem
from app.services.prompt_service import ConflictResolutionProposal, PromptService

logger = logging.getLogger(__name__)


class UncertaintyReport(BaseModel):
    total_evidence_count: int
    has_primary_research: bool
    has_secondary_research: bool
    conflict_count: int
    overall_confidence: float = Field(ge=0.0, le=1.0)
    recommended_next_steps: List[str]


class ConflictDetector:
    """
    Detects contradictions between secondary macro/online data and local primary survey evidence.
    Ensures discrepancies are surfaced clearly to lower confidence and trigger local validation.
    Equipped with automated AI resolution proposal synthesis and uncertainty scoring.
    """

    def __init__(
        self,
        adapter: Optional[GeminiAdapter] = None,
        prompt_service: Optional[PromptService] = None,
    ):
        self.adapter = adapter or GeminiAdapter()
        self.prompt_service = prompt_service or PromptService()

    @classmethod
    def detect_conflicts(cls, evidence_records: List[EvidenceItem]) -> List[ConflictItem]:
        """
        Deterministic contradiction analysis across claims and numerical values.
        Preserves synchronous class method interface for legacy callers.
        """
        conflicts: List[ConflictItem] = []
        secondary = [e for e in evidence_records if e.source_type in ["GOVERNMENT", "TRUSTED_WEB"]]
        primary = [e for e in evidence_records if e.source_type in ["FIELD_PRIMARY", "LOCAL_SURVEY"]]

        # Check for Demand / Pricing / Competition discrepancies
        for sec in secondary:
            for prim in primary:
                # 1. Qualitative Demand conflict
                sec_lower = sec.claim.lower()
                prim_lower = prim.claim.lower()

                if "high demand" in sec_lower and (
                    "low interest" in prim_lower or "no demand" in prim_lower
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
                            suggested_action=(
                                "Conduct 15 additional local customer interviews with free sample "
                                "demonstrations before committing capital."
                            ),
                        )
                    )

                # 2. Qualitative Pricing conflict
                elif "willing to pay" in sec_lower and "unaffordable" in prim_lower:
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
                            suggested_action=(
                                "Recalculate unit economics around a lower price point or offer "
                                "smaller package sizes (sachet strategy)."
                            ),
                        )
                    )

                # 3. Numerical Pricing Discrepancy (variance > 20%)
                elif sec.extracted_value and prim.extracted_value:
                    try:
                        val_sec = float(sec.extracted_value.strip())
                        val_prim = float(prim.extracted_value.strip())
                        if val_sec > 0 and val_prim > 0:
                            diff_pct = abs(val_sec - val_prim) / val_sec
                            if diff_pct >= 0.20:
                                conflicts.append(
                                    ConflictItem(
                                        id=f"conflict-num-price-{sec.id}-{prim.id}",
                                        topic="Pricing Divergence",
                                        secondary_claim=sec.claim,
                                        secondary_source=sec.source_name,
                                        primary_claim=prim.claim,
                                        primary_source=prim.source_name,
                                        discrepancy_explanation=(
                                            f"Secondary benchmark price ({sec.extracted_value} {sec.unit or ''}) "
                                            f"diverges by {diff_pct * 100:.0f}% from local surveyed expectation "
                                            f"({prim.extracted_value} {prim.unit or ''})."
                                        ),
                                        impact_on_confidence="high_risk" if diff_pct > 0.35 else "medium_risk",
                                        suggested_action=(
                                            "Validate raw material supplier quotes and test smaller pouch sizes "
                                            "to match village purchasing power."
                                        ),
                                    )
                                )
                    except ValueError:
                        pass

        return conflicts

    async def analyze_and_resolve(self, evidence_records: List[EvidenceItem]) -> List[ConflictItem]:
        """
        Detects conflicts and leverages Gemini AI to generate customized resolution proposals.
        Falls back cleanly to deterministic grounded actions if AI is unavailable.
        """
        conflicts = self.detect_conflicts(evidence_records)
        if not conflicts or not self.adapter.is_live:
            return conflicts

        resolved_conflicts = []
        for conflict in conflicts:
            try:
                system_prompt, user_prompt = self.prompt_service.build_conflict_resolution_prompt(
                    conflict_topic=conflict.topic,
                    primary_claim=conflict.primary_claim,
                    primary_source=conflict.primary_source,
                    secondary_claim=conflict.secondary_claim,
                    secondary_source=conflict.secondary_source,
                )
                ai_proposal: ConflictResolutionProposal = await self.adapter.generate_structured_output(
                    system_instruction=system_prompt,
                    user_prompt=user_prompt,
                    response_schema=ConflictResolutionProposal,
                )
                conflict.discrepancy_explanation = ai_proposal.explanation
                conflict.impact_on_confidence = ai_proposal.confidence_impact
                conflict.suggested_action = (
                    f"{ai_proposal.suggested_action} Next Step: {ai_proposal.recommended_field_validation}"
                )
            except Exception as e:
                logger.warning(f"AI conflict resolution failed for {conflict.id}: {e}")
            resolved_conflicts.append(conflict)

        return resolved_conflicts

    async def generate_uncertainty_report(
        self, evidence_records: List[EvidenceItem]
    ) -> UncertaintyReport:
        """
        Evaluates knowledge completeness, presence of primary vs secondary evidence,
        and conflict penalties to compute grounded overall confidence.
        """
        total_count = len(evidence_records)
        has_primary = any(e.source_type in ["FIELD_PRIMARY", "LOCAL_SURVEY"] for e in evidence_records)
        has_secondary = any(e.source_type in ["GOVERNMENT", "TRUSTED_WEB"] for e in evidence_records)

        conflicts = self.detect_conflicts(evidence_records)
        conflict_count = len(conflicts)

        # Baseline confidence scoring
        if total_count == 0:
            confidence = 0.0
            next_steps = ["Begin secondary research and prepare primary survey questions."]
        else:
            avg_score = sum(e.confidence_score for e in evidence_records) / total_count
            confidence = avg_score

            # Penalize if primary research is completely missing
            if not has_primary:
                confidence *= 0.70

            # Penalize for each unresolved conflict
            if conflict_count > 0:
                penalty = min(conflict_count * 0.15, 0.40)
                confidence -= penalty

            confidence = max(0.0, min(confidence, 1.0))

            next_steps = []
            if not has_primary:
                next_steps.append("Conduct primary field validation with at least 15-20 target customers.")
            if conflict_count > 0:
                next_steps.append(
                    f"Resolve {conflict_count} active conflict(s) between regional statistics and local responses."
                )
            if not next_steps:
                next_steps.append("Sufficient initial evidence gathered; proceed to financial scenario modeling.")

        return UncertaintyReport(
            total_evidence_count=total_count,
            has_primary_research=has_primary,
            has_secondary_research=has_secondary,
            conflict_count=conflict_count,
            overall_confidence=round(confidence, 2),
            recommended_next_steps=next_steps,
        )
