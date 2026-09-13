# Architecture Decision Records (ADR) Log

**Document:** `docs/decisions.md`
**Purpose:** Living decision log recording key technical and architectural decisions for Vyapar Mitra.

---

## ADR-005: Implementation of MarketGapDetector Service (Phase 4)

* **Date**: 2026-09-13
* **Status**: ACCEPTED (Phase 4 Implemented in `apeksha` branch)

### Context
Market gap detection identifies unserved or underserved customer needs, customer access/travel leakage, and explicit market niches strictly from evidence records, without treating digital POI competitor counts as a complete census or creating fabricated market gap conclusions.

### Decision
1. **Service Location**: Created `backend/app/services/market_gap_detector.py` implementing `MarketGapDetector`.
2. **Schema Integration**: Created `backend/app/schemas/feasibility.py` providing the `AssessmentLevel` enum and `MarketGapAnalysis` model tailored for the `apeksha` branch architecture.
3. **Core Architectural Rules**:
   - **Market Gap is an Evidence-Supported Inference**: Inferred market gaps are explicitly presented with supporting evidence citations (`evidence_basis`) and are never asserted as confirmed facts.
   - **Zero Mapped Competitors is NOT a Market Gap**: Zero mapped competitors (`mapped_competitors = 0`) indicates incomplete map data, not an unserved market. Without explicit demand or unmet-need evidence, status remains `UNCERTAIN` or `NO_CLEAR_GAP`.
   - **Population Alone is NOT a Market Gap**: Population census figures describe catchment reach, not unmet demand or market gaps.
   - **Pure Quantitative Demand Volume Alone is NOT a Market Gap**: Sales volume metrics (e.g. 50 L/day) without explicit supply deficit or unmet-need evidence evaluate to `UNCERTAIN`.
   - **Primary Unmet Need Receives Strong Weight**: Explicit primary/local evidence of unmet customer need or service unavailability (e.g. "no local supplier offers home delivery") triggers `UNDERSERVED` classification with high confidence.
   - **No Discrepancy Resolution by Averaging**: When mapped POI counts disagree with local field reports, both are preserved without averaging, and confidence is reduced.
   - **Geographic Scope Preservation**: Mismatched geographic scope (e.g. district demand vs 5km radius target) sets `scope_alignment = "MISMATCHED"` and reduces confidence score.
   - **Provisional Confidence Heuristics**: Centralized in `PROVISIONAL_MARKET_GAP_CONFIDENCE_HEURISTICS` and explicitly annotated: *"These confidence values are provisional evidence-quality heuristics and are not calibrated statistical probabilities."* Confidence is separate from gap classification (`gap_level`).
4. **Output**: Returns a validated `MarketGapAnalysis` schema instance.

### Consequences
- Prevents false market gap claims based on incomplete POI map data.
- Ensures evidence-traceable market gap detection for rural micro-entrepreneurs.
- Independent, provider-agnostic service ready for integration into top-level advisory workflows.
- Zero modification to existing sub-analyzers, database schemas, external API calls, or Flutter UI.

---

## ADR-006: Implementation of Risk / Threat Analyzer (Phase 5)

* **Date**: 2026-09-13
* **Status**: ACCEPTED (Phase 5 Implemented in `apeksha` branch)

### Context
Risk/threat analysis evaluates business-specific risks (supply, seasonal, competition, demand, distribution, customer concentration, accessibility, pricing, operational) strictly from available evidence records, without fabricating generic category risks or duplicating financial debt service calculations.

### Decision
1. **Service Location**: Created `backend/app/services/risk_analyzer.py` implementing `RiskAnalyzer`.
2. **Schema Integration**: Extended `backend/app/schemas/feasibility.py` with `RiskItem` and `RiskAnalysis` Pydantic models.
3. **Core Architectural Rules**:
   - **Evidence-Driven Risk Extraction**: Risks are extracted ONLY when supported by explicit input evidence. Generic risks (e.g., "Dairy has spoilage risk") are NEVER fabricated without evidence.
   - **No Evidence = UNCERTAIN**: If no relevant risk evidence is provided, returns `risk_items = []` and `overall_risk_level = UNCERTAIN` (`confidence_score = 0.0`).
   - **Population Alone is NOT a Risk**: Population census figures do not generate risk items.
   - **Competition Count Alone is NOT a Risk**: Mapped competitor counts (e.g., "7 mapped competitors") do not create competition risk without evidence of competitive pressure or threats.
   - **Demand Volume Alone is NOT a Risk**: Sales volume metrics (e.g., "50 liters/day demand") do not create demand risk without evidence of weakness, volatility, or uncertainty.
   - **Separation from FinancialEngine**: Financial debt, EMI, DSCR, and loan repayment affordability belong strictly to `FinancialEngine` and are NEVER extracted here.
   - **Absence of Evidence != Evidence of Absence**: Missing supplier evidence does not imply high supply risk.
   - **Keyword Relevance & Context**: Broad words like "delay" do not create supply risk unless tied to supply chain or operational inputs.
   - **Conflict & Scope Handling**: Contradictory claims or mismatched geographic scope lower the confidence score while preserving all evidence IDs.
   - **Severity vs Confidence Distinction**: Risk severity tier (`HIGH`, `MODERATE`, `LOW`, `UNCERTAIN`) is kept separate from confidence score (`0.0` to `1.0`).
   - **Provisional Confidence Heuristics**: Centralized in `PROVISIONAL_RISK_CONFIDENCE_HEURISTICS` and explicitly annotated: *"These confidence values are provisional evidence-quality heuristics and are not calibrated statistical probabilities."*
4. **Output**: Returns a validated `RiskAnalysis` schema instance containing structured `RiskItem` records with authentic evidence citations.

### Consequences
- Eliminates fabricated category risks and preserves evidence provenance.
- Clear separation between deterministic financial engine calculations and qualitative risk extraction.
- Independent, provider-agnostic component ready for integration into top-level Business Feasibility Report workflows.
- Zero modification to existing sub-analyzers, database schemas, external API calls, or Flutter UI.
