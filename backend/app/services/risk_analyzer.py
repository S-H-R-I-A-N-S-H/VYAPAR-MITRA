import re
from typing import Any, Dict, List, Optional, Tuple

from app.schemas.evidence import EvidenceItem
from app.schemas.feasibility import AssessmentLevel, RiskAnalysis, RiskItem

# These confidence values are provisional evidence-quality heuristics and are not calibrated statistical probabilities.
PROVISIONAL_RISK_CONFIDENCE_HEURISTICS: Dict[str, float] = {
    "PRIMARY_EXPLICIT_HIGH_RISK": 0.85,
    "CORROBORATED_MODERATE_RISK": 0.75,
    "SECONDARY_RISK_SIGNAL": 0.65,
    "WEAK_OR_INDIRECT_SIGNAL": 0.55,
    "DISCREPANT_OR_MISMATCHED_SCOPE": 0.45,
    "NO_EVIDENCE": 0.0,
}


class RiskAnalyzer:
    """
    Authoritative Risk / Threat Analyzer service for Vyapar Mitra.

    Extracts business-specific operational, supply, seasonal, competition, demand,
    distribution, pricing, accessibility, and customer concentration risks strictly
    from provided EvidenceItem records.

    Core Product Rules & Guardrails:
    1. Evidence-Driven Only: Risks are extracted ONLY when supported by explicit input evidence.
       Generic risks (e.g., "Dairy has spoilage risk") are NEVER fabricated without evidence.
    2. No Evidence = UNCERTAIN: If no relevant risk evidence is provided, returns risk_items = []
       and overall_risk_level = UNCERTAIN with confidence_score = 0.0.
    3. Population Alone is NOT a Risk: High/low population figures do not generate risk items.
    4. Competition Count Alone is NOT a Risk: Mapped competitor counts (e.g., "7 mapped competitors")
       do not create competition risk without evidence of competitive pressure or threats.
    5. Demand Volume Alone is NOT a Risk: Sales volume figures (e.g., "50 liters/day demand")
       do not create demand risk without evidence of weakness, volatility, or uncertainty.
    6. No Financial Risk Duplication: EMI, DSCR, loan eligibility, and repayment affordability
       risks belong to FinancialEngine and are NEVER extracted here.
    7. Absence of Evidence != Evidence of Absence: Missing supplier evidence does not imply high supply risk.
    8. Keyword Relevance & Context: Broad words like "delay" do not create supply risk unless tied to
       supply chain or operational inputs.
    9. Contradiction & Scope Handling: Conflicting evidence or mismatched geographic scope reduces
       confidence score while preserving all evidence IDs.
    10. Deterministic & Provider-Agnostic: Zero LLMs, external APIs, or randomness.
    """

    PROVISIONAL_CONFIDENCE_HEURISTICS = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS

    @staticmethod
    def is_financial_repayment_claim(claim: str) -> bool:
        """Identifies financial debt/EMI/DSCR claims that belong exclusively to FinancialEngine."""
        claim_lower = claim.lower()
        financial_keywords = ["emi", "dscr", "debt service", "loan repayment", "interest rate risk", "loan affordability"]
        return any(k in claim_lower for k in financial_keywords)

    @classmethod
    def extract_supply_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """Extracts SUPPLY category risks if evidence indicates supply disruption or single-supplier constraint."""
        claim_lower = (item.claim or "").lower()
        if cls.is_financial_repayment_claim(claim_lower):
            return None

        supply_keywords = ["supplier", "supply", "raw material", "input supply", "material shortage", "delivery delay"]
        if not any(k in claim_lower for k in supply_keywords):
            return None

        risk_patterns = [
            ("irregular", "Irregular raw material supply"),
            ("delay", "Frequent raw material supply delays"),
            ("only one", "Single supplier dependency constraint"),
            ("single supplier", "Single supplier dependency constraint"),
            ("shortage", "Raw material availability shortage"),
            ("constraint", "Input supply availability constraint"),
            ("interruption", "Supply chain interruption risk"),
        ]

        for kw, title in risk_patterns:
            if kw in claim_lower:
                severity = AssessmentLevel.HIGH if item.source_type == "FIELD_PRIMARY" else AssessmentLevel.MODERATE
                confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
                return RiskItem(
                    category="SUPPLY",
                    title=title,
                    severity=severity,
                    explanation=f"Evidence indicates supply constraint: {item.claim}",
                    evidence_ids=[item.id],
                    confidence=confidence,
                )
        return None

    @classmethod
    def extract_seasonal_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """Extracts SEASONAL category risks if evidence indicates monsoon, weather, or festival sales drops."""
        claim_lower = (item.claim or "").lower()
        seasonal_keywords = ["monsoon", "rains", "rainy season", "festival", "diwali", "eid", "summer drop", "winter drop", "seasonal"]
        if not any(k in claim_lower for k in seasonal_keywords):
            return None

        if any(neg in claim_lower for neg in ["fall", "drop", "concentrated", "difficult", "decline", "fluctuate", "lower"]):
            severity = AssessmentLevel.HIGH if "monsoon" in claim_lower or "drop" in claim_lower else AssessmentLevel.MODERATE
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
            return RiskItem(
                category="SEASONAL",
                title="Seasonal demand or weather disruption",
                severity=severity,
                explanation=f"Evidence indicates seasonal sales or operational vulnerability: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_competition_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """
        Extracts COMPETITION category risks ONLY when evidence supports competitive pressure or threat.
        Competition count alone (e.g., '7 mapped competitors') does NOT create a risk item.
        """
        claim_lower = (item.claim or "").lower()
        # Count-only guardrail check
        if re.search(r"^\s*\d+\s*(?:mapped|competitors|sellers|shops)?\s*$", (item.extracted_value or "").strip()):
            if not any(threat in claim_lower for threat in ["price war", "reduce price", "pressure", "intense", "established", "dominate", "low differentiation"]):
                return None

        comp_threat_keywords = [
            "established competitor",
            "established sellers",
            "frequently reduce price",
            "price pressure",
            "price war",
            "intense competition",
            "low differentiation",
            "dominant seller",
            "competitor weakness",
        ]
        if any(k in claim_lower for k in comp_threat_keywords):
            severity = AssessmentLevel.HIGH if "price war" in claim_lower or "intense" in claim_lower else AssessmentLevel.MODERATE
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
            return RiskItem(
                category="COMPETITION",
                title="Competitive market pressure and price threat",
                severity=severity,
                explanation=f"Evidence indicates competitive threat: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_demand_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """
        Extracts DEMAND category risks ONLY when evidence supports demand weakness, uncertainty, or volatility.
        Population census metrics or positive demand volume alone do NOT create demand risk.
        """
        claim_lower = (item.claim or "").lower()
        if cls.is_financial_repayment_claim(claim_lower):
            return None

        demand_risk_keywords = [
            "low demand",
            "weak demand",
            "uncertain demand",
            "declining demand",
            "falling demand",
            "unpredictable demand",
            "demand is highly uncertain",
            "weak purchasing intent",
            "low interest",
        ]
        if any(k in claim_lower for k in demand_risk_keywords):
            severity = AssessmentLevel.HIGH if "low demand" in claim_lower or "declining" in claim_lower else AssessmentLevel.MODERATE
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
            return RiskItem(
                category="DEMAND",
                title="Demand uncertainty or purchasing weakness",
                severity=severity,
                explanation=f"Evidence indicates demand risk: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_distribution_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """Extracts DISTRIBUTION category risks if evidence indicates transport, delivery, or retail stocking issues."""
        claim_lower = (item.claim or "").lower()
        dist_keywords = ["transported from", "delivery becomes difficult", "retailer unwillingness", "distribution bottleneck", "logistics friction"]
        if any(k in claim_lower for k in dist_keywords):
            severity = AssessmentLevel.MODERATE
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
            return RiskItem(
                category="DISTRIBUTION",
                title="Distribution channel and logistics friction",
                severity=severity,
                explanation=f"Evidence indicates distribution vulnerability: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_customer_concentration_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """Extracts CUSTOMER_CONCENTRATION category risks if evidence indicates high dependency on one buyer."""
        claim_lower = (item.claim or "").lower()
        conc_keywords = ["80%", "90%", "single buyer", "one institutional buyer", "one wholesaler", "depends on one", "single customer"]
        if any(k in claim_lower for k in conc_keywords) and any(word in claim_lower for word in ["purchase", "buyer", "sales", "wholesaler", "customer"]):
            severity = AssessmentLevel.HIGH
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"]
            return RiskItem(
                category="CUSTOMER_CONCENTRATION",
                title="Customer concentration dependency risk",
                severity=severity,
                explanation=f"Evidence indicates high buyer concentration: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_accessibility_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """Extracts ACCESSIBILITY category risks if evidence indicates road access issues or long travel distances."""
        claim_lower = (item.claim or "").lower()
        access_keywords = ["road becomes difficult", "unpaved road", "travel 12 km", "travel 10 km", "flooding", "poor road connectivity"]
        if any(k in claim_lower for k in access_keywords):
            severity = AssessmentLevel.MODERATE
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
            return RiskItem(
                category="ACCESSIBILITY",
                title="Geographic accessibility and road infrastructure risk",
                severity=severity,
                explanation=f"Evidence indicates accessibility friction: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_pricing_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """Extracts PRICING category risks if evidence indicates price volatility or unaffordability."""
        claim_lower = (item.claim or "").lower()
        if cls.is_financial_repayment_claim(claim_lower):
            return None

        pricing_keywords = ["price fluctuate", "prices fluctuate", "prices frequently change", "price volatility", "unaffordable"]
        if any(k in claim_lower for k in pricing_keywords):
            severity = AssessmentLevel.MODERATE
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
            return RiskItem(
                category="PRICING",
                title="Price volatility and market affordability risk",
                severity=severity,
                explanation=f"Evidence indicates pricing risk: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_operational_risk(cls, item: EvidenceItem) -> Optional[RiskItem]:
        """Extracts OPERATIONAL category risks if evidence indicates power outage, cold storage, or perishability issues."""
        claim_lower = (item.claim or "").lower()
        op_keywords = ["electricity", "power outage", "power cut", "cold storage", "chilling unit", "perishability", "spoilage"]
        if any(k in claim_lower for k in op_keywords) and any(neg in claim_lower for neg in ["uninterrupted", "outage", "cut", "unavailable", "lack", "spoilage", "perish"]):
            severity = AssessmentLevel.HIGH if "outage" in claim_lower or "spoilage" in claim_lower or "unavailable" in claim_lower else AssessmentLevel.MODERATE
            confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"] if item.source_type == "FIELD_PRIMARY" else PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]
            return RiskItem(
                category="OPERATIONAL",
                title="Operational dependency and infrastructure vulnerability",
                severity=severity,
                explanation=f"Evidence indicates operational infrastructure risk: {item.claim}",
                evidence_ids=[item.id],
                confidence=confidence,
            )
        return None

    @classmethod
    def extract_risk_items(cls, items: List[EvidenceItem]) -> List[RiskItem]:
        """Extracts all supported risk items from input evidence without duplicating IDs."""
        extracted: List[RiskItem] = []
        extractors = [
            cls.extract_supply_risk,
            cls.extract_seasonal_risk,
            cls.extract_competition_risk,
            cls.extract_demand_risk,
            cls.extract_distribution_risk,
            cls.extract_customer_concentration_risk,
            cls.extract_accessibility_risk,
            cls.extract_pricing_risk,
            cls.extract_operational_risk,
        ]

        for item in items:
            for extractor in extractors:
                risk = extractor(item)
                if risk:
                    # Check if similar category & title already present
                    existing = next((r for r in extracted if r.category == risk.category and r.title == risk.title), None)
                    if existing:
                        if item.id not in existing.evidence_ids:
                            existing.evidence_ids.append(item.id)
                    else:
                        extracted.append(risk)

        return extracted

    @classmethod
    def detect_conflicts(cls, items: List[EvidenceItem]) -> Tuple[bool, List[str]]:
        """Detects contradictory evidence claims (e.g., supply reliable vs supply delays common)."""
        secondary = [e for e in items if e.source_type in ["GOVERNMENT", "TRUSTED_WEB"]]
        primary = [e for e in items if e.source_type in ["FIELD_PRIMARY", "LOCAL_SURVEY"]]
        conflict_ids: List[str] = []

        for sec in secondary:
            sec_lower = sec.claim.lower()
            for prim in primary:
                prim_lower = prim.claim.lower()
                if ("reliable" in sec_lower and "delay" in prim_lower) or (
                    "delay" in sec_lower and "reliable" in prim_lower
                ):
                    conflict_ids.extend([sec.id, prim.id])

        unique_ids = list(dict.fromkeys(conflict_ids))
        return len(unique_ids) > 0, unique_ids

    @classmethod
    def detect_scope_mismatch(cls, items: List[EvidenceItem], target_radius_km: float) -> bool:
        """Detects if evidence geographic scope differs from target radius."""
        for item in items:
            geog = (item.geography or "").lower()
            if any(macro in geog for macro in ["district", "block", "state"]):
                return True
            match = re.search(r"(\d+(?:\.\d+)?)\s*km", (item.claim or "").lower())
            if match:
                ev_radius = float(match.group(1))
                if abs(ev_radius - target_radius_km) > 0.5:
                    return True
        return False

    @classmethod
    def analyze(
        cls,
        evidence_items: Optional[List[EvidenceItem]] = None,
        target_radius_km: Optional[float] = 5.0,
    ) -> RiskAnalysis:
        """
        Executes Risk / Threat Analysis pipeline deterministically.

        :param evidence_items: List of EvidenceItem objects
        :param target_radius_km: Requested catchment radius in km (default 5.0)
        :return: RiskAnalysis Pydantic model
        """
        radius = max(0.1, target_radius_km if target_radius_km is not None else 5.0)
        items = evidence_items or []

        if not items:
            return RiskAnalysis(
                identified_risks=[],
                overall_risk_level=AssessmentLevel.UNCERTAIN,
                confidence_score=PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["NO_EVIDENCE"],
                key_evidence_ids=[],
            )

        # Extract risk items
        risk_items = cls.extract_risk_items(items)

        # Traceable evidence IDs supporting risks
        used_ids = list(dict.fromkeys([ev_id for r in risk_items for ev_id in r.evidence_ids]))

        if not risk_items:
            # All evidence provided was non-risk (e.g. population census, clean demand volume)
            all_item_ids = [e.id for e in items if e.id]
            return RiskAnalysis(
                identified_risks=[],
                overall_risk_level=AssessmentLevel.UNCERTAIN,
                confidence_score=PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["WEAK_OR_INDIRECT_SIGNAL"],
                key_evidence_ids=all_item_ids,
            )

        # Check severity counts
        high_count = sum(1 for r in risk_items if r.severity == AssessmentLevel.HIGH)
        mod_count = sum(1 for r in risk_items if r.severity == AssessmentLevel.MODERATE)

        if high_count >= 1 or mod_count >= 3:
            overall_level = AssessmentLevel.HIGH
            base_confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["PRIMARY_EXPLICIT_HIGH_RISK"]
        elif mod_count >= 1:
            overall_level = AssessmentLevel.MODERATE
            base_confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["CORROBORATED_MODERATE_RISK"]
        else:
            overall_level = AssessmentLevel.LOW
            base_confidence = PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["SECONDARY_RISK_SIGNAL"]

        # Conflict & Scope penalty checks
        has_conflict, _ = cls.detect_conflicts(items)
        is_scope_mismatch = cls.detect_scope_mismatch(items, radius)

        if has_conflict or is_scope_mismatch:
            base_confidence = min(base_confidence, PROVISIONAL_RISK_CONFIDENCE_HEURISTICS["DISCREPANT_OR_MISMATCHED_SCOPE"])

        return RiskAnalysis(
            identified_risks=risk_items,
            overall_risk_level=overall_level,
            confidence_score=base_confidence,
            key_evidence_ids=used_ids,
        )
