import re
from typing import Any, Dict, List, Optional, Tuple

from app.schemas.evidence import EvidenceItem
from app.schemas.feasibility import AssessmentLevel, MarketGapAnalysis

# These confidence values are provisional evidence-quality heuristics and are not calibrated statistical probabilities.
PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS: Dict[str, float] = {
    "EXPLICIT_PRIMARY_UNMET_NEED": 0.85,
    "DEMAND_AND_ACCESS_FRICTION": 0.75,
    "DEMAND_AND_LIMITED_COMPETITION": 0.70,
    "DISCREPANT_OR_MISMATCHED_SCOPE": 0.45,
    "COMPETITION_OR_POPULATION_ONLY": 0.20,
    "NO_EVIDENCE": 0.0,
}


class MarketGapDetector:
    """
    Authoritative Market Gap Detector service for Vyapar Mitra.

    Identifies unserved or underserved market niches, customer travel/leakage signals,
    and explicit unmet customer needs strictly from evidence records.

    Core Product Rules & Guardrails:
    1. Zero Mapped Competitors is NOT a Market Gap: Mapped business listings may be incomplete.
       0 mapped competitors never implies zero real competitors or an underserved market.
    2. Population Alone is NOT a Market Gap: High population census figures describe reach, not gaps.
    3. Pure Quantitative Demand Volume Alone is NOT a Market Gap: Sales volume without explicit supply deficit or unmet need does not create a gap.
    4. Competitor Discrepancies reduce confidence: If mapped POI count (e.g. 2) disagrees with local field reports (e.g. 6-10),
       both are preserved without averaging, and confidence is reduced.
    5. Geographic Scope Preservation: Mismatched geographic scope (e.g. district demand vs 5 km radius) sets
       scope_alignment = "MISMATCHED" and lowers confidence.
    6. Market Gap is an Inference: Distinguishes observed evidence from evidence-supported inference.
    7. Confidence is separate from gap_level.
    8. Deterministic & Provider-Agnostic: Uses zero external APIs or LLMs.
    """

    PROVISIONAL_CONFIDENCE_HEURISTICS = PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS

    @staticmethod
    def is_demand_evidence(e: EvidenceItem) -> bool:
        """Determines if evidence item contains customer demand signals."""
        claim = (e.claim or "").lower()
        unit = (e.unit or "").lower()
        keywords = ["demand", "purchase", "buying", "buy", "customer interest", "liters/day", "kg/day", "units/day", "willing to pay"]
        return any(k in claim or k in unit for k in keywords)

    @staticmethod
    def is_competition_evidence(e: EvidenceItem) -> bool:
        """Determines if evidence item contains competitor counts or competitor landscape observations."""
        claim = (e.claim or "").lower()
        keywords = ["competitor", "seller", "shop", "vendor", "mapped competitors", "poi search", "existing businesses"]
        return any(k in claim for k in keywords)

    @staticmethod
    def is_population_evidence(e: EvidenceItem) -> bool:
        """Determines if evidence item contains population or household metrics."""
        claim = (e.claim or "").lower()
        unit = (e.unit or "").lower()
        keywords = ["population", "resident", "household", "census", "inhabitants"]
        return any(k in claim or k in unit for k in keywords)

    @staticmethod
    def is_unmet_need_evidence(e: EvidenceItem) -> bool:
        """
        Determines if evidence item contains explicit unmet needs, customer travel/leakage,
        or supply/access friction.
        """
        claim = (e.claim or "").lower()
        unmet_keywords = [
            "travel to",
            "travels to",
            "another village",
            "another town",
            "nearby town",
            "outside",
            "difficult to find",
            "no local",
            "unavailable",
            "stock-out",
            "stock out",
            "waiting time",
            "lack of convenient",
            "unmet",
            "underserved",
            "dissatisfied",
            "no supplier",
            "no provider",
            "no nearby",
            "unable to find",
            "leakage",
        ]
        return any(k in claim for k in unmet_keywords)

    @staticmethod
    def extract_segments(items: List[EvidenceItem]) -> List[str]:
        """Extracts explicitly mentioned customer segments from evidence items without inventing demographic segments."""
        segments: List[str] = []
        known_segment_keywords = [
            ("small household", "Small households"),
            ("student", "Students"),
            ("women", "Women customers"),
            ("female", "Women customers"),
            ("elderly", "Elderly customers"),
            ("senior", "Elderly customers"),
            ("early-morning", "Early-morning buyers"),
            ("morning", "Early-morning buyers"),
            ("evening", "Evening buyers"),
            ("late night", "Evening buyers"),
            ("small retailer", "Small retailers"),
            ("commuter", "Commuters"),
        ]

        for item in items:
            claim_lower = (item.claim or "").lower()
            for kw, label in known_segment_keywords:
                if kw in claim_lower and label not in segments:
                    segments.append(label)

        return segments

    @classmethod
    def detect_radius_mismatch(
        cls, items: List[EvidenceItem], target_radius_km: float
    ) -> Tuple[bool, Optional[float]]:
        """
        Detects if evidence specifies a geographic radius different from target_radius_km.
        Returns (is_mismatch, evidence_radius_km).
        """
        for item in items:
            claim = (item.claim or "").lower()
            match = re.search(r"(\d+(?:\.\d+)?)\s*km", claim)
            if match:
                ev_radius = float(match.group(1))
                if abs(ev_radius - target_radius_km) > 0.5:
                    return True, ev_radius
            # Check geography field for macro-level scope (e.g. "district", "block") vs km target
            geog = (item.geography or "").lower()
            if any(macro in geog for macro in ["district", "block", "state"]):
                return True, None
        return False, None

    @classmethod
    def analyze(
        cls,
        evidence_items: Optional[List[EvidenceItem]] = None,
        target_radius_km: Optional[float] = 5.0,
    ) -> MarketGapAnalysis:
        """
        Executes market gap detection pipeline deterministically.

        :param evidence_items: List of EvidenceItem objects
        :param target_radius_km: Requested catchment radius in km (default 5.0)
        :return: MarketGapAnalysis Pydantic model
        """
        radius = max(0.1, target_radius_km if target_radius_km is not None else 5.0)
        items = evidence_items or []

        if not items:
            return MarketGapAnalysis(
                gap_level=AssessmentLevel.UNCERTAIN,
                gap_opportunity_level=AssessmentLevel.UNCERTAIN,
                confidence_score=PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["NO_EVIDENCE"],
                scope_alignment="UNKNOWN",
                key_evidence_ids=[],
            )

        # Categorize evidence
        demand_items = [e for e in items if cls.is_demand_evidence(e)]
        comp_items = [e for e in items if cls.is_competition_evidence(e)]
        pop_items = [e for e in items if cls.is_population_evidence(e)]
        unmet_items = [e for e in items if cls.is_unmet_need_evidence(e)]

        # Used items for citation traceability
        used_items = list({e.id: e for e in (demand_items + comp_items + pop_items + unmet_items) if e.id}.values())
        key_evidence_ids = [e.id for e in used_items]

        # Geographic scope alignment check
        is_scope_mismatch, _ = cls.detect_radius_mismatch(items, radius)
        scope_alignment = "MISMATCHED" if is_scope_mismatch else ("ALIGNED" if used_items else "UNKNOWN")

        # Extract explicitly mentioned segments
        segments = cls.extract_segments(items)

        # Extract structured evidence basis
        evidence_basis: List[Dict[str, Any]] = []
        for item in used_items:
            ev_type = "unmet_need" if cls.is_unmet_need_evidence(item) else (
                "demand" if cls.is_demand_evidence(item) else (
                    "competition" if cls.is_competition_evidence(item) else "population"
                )
            )
            evidence_basis.append({
                "id": item.id,
                "type": ev_type,
                "claim": item.claim,
                "source_type": item.source_type,
            })

        # Check competition details for discrepancy guardrail
        mapped_count: Optional[int] = None
        has_local_reported_comp = False
        for item in comp_items:
            claim_lower = (item.claim or "").lower()
            val = item.extracted_value
            if "mapped" in claim_lower or "poi" in claim_lower or item.source_type in ["GOVERNMENT", "TRUSTED_WEB"]:
                if val and val.isdigit():
                    mapped_count = int(val)
            if "survey" in claim_lower or "local" in claim_lower or item.source_type == "FIELD_PRIMARY":
                has_local_reported_comp = True

        has_discrepancy = (mapped_count is not None and mapped_count == 0 and has_local_reported_comp) or (
            mapped_count is not None and mapped_count > 0 and has_local_reported_comp
        )

        identified_gaps: List[str] = []

        # Zero mapped competitor guardrail note
        if mapped_count == 0:
            identified_gaps.append(
                "No mapped competitors were observed in available data. Because mapped listings may be incomplete, this does not establish that no competitors exist."
            )

        # -------------------------------------------------------------------
        # Deterministic Gap Classification Rules
        # -------------------------------------------------------------------

        # Rule 1: Explicit local unmet need / customer travel / access friction
        if unmet_items:
            for item in unmet_items:
                claim = item.claim or ""
                if "travel" in claim.lower():
                    identified_gaps.append(f"Potential local access gap: {claim}")
                elif "no local" in claim.lower() or "unavailable" in claim.lower():
                    identified_gaps.append(f"Explicit unmet local supply/service gap: {claim}")
                else:
                    identified_gaps.append(f"Unmet customer need: {claim}")

            # Check evidence strength (primary vs secondary)
            has_primary_unmet = any(e.source_type == "FIELD_PRIMARY" for e in unmet_items)
            if has_primary_unmet:
                gap_level = AssessmentLevel.UNDERSERVED
                confidence = PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["EXPLICIT_PRIMARY_UNMET_NEED"]
            else:
                gap_level = AssessmentLevel.POTENTIAL_GAP
                confidence = PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["DEMAND_AND_ACCESS_FRICTION"]

        # Rule 2: Strong/moderate demand + limited/discrepant competition without explicit unmet need claims
        elif demand_items and (comp_items or mapped_count is not None):
            gap_level = AssessmentLevel.POTENTIAL_GAP
            confidence = PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["DEMAND_AND_LIMITED_COMPETITION"]
            identified_gaps.append("Potential opportunity indicated by demand presence and limited observed competition.")

        # Rule 3: Pure demand evidence without supply deficit or competition context
        elif demand_items and not comp_items and not unmet_items:
            # Pure demand volume alone (e.g. 50 L/day) does NOT create a market gap
            gap_level = AssessmentLevel.UNCERTAIN
            confidence = PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["COMPETITION_OR_POPULATION_ONLY"]

        # Rule 4: Population only, or competition only (e.g. 0 mapped competitors without demand)
        elif pop_items or comp_items:
            gap_level = AssessmentLevel.UNCERTAIN
            confidence = PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["COMPETITION_OR_POPULATION_ONLY"]

        # Default fallback
        else:
            gap_level = AssessmentLevel.UNCERTAIN
            confidence = PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["NO_EVIDENCE"]

        # Apply confidence penalties for scope mismatch or evidence discrepancy
        if is_scope_mismatch or has_discrepancy:
            confidence = min(confidence, PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS["DISCREPANT_OR_MISMATCHED_SCOPE"])
            if gap_level == AssessmentLevel.UNDERSERVED and is_scope_mismatch:
                # Mismatched scope prevents UNDERSERVED classification
                gap_level = AssessmentLevel.POTENTIAL_GAP

        return MarketGapAnalysis(
            gap_level=gap_level,
            identified_gaps=identified_gaps,
            unserved_customer_segments=segments,
            gap_opportunity_level=gap_level,
            confidence_score=confidence,
            evidence_basis=evidence_basis,
            scope_alignment=scope_alignment,
            key_evidence_ids=key_evidence_ids,
        )
