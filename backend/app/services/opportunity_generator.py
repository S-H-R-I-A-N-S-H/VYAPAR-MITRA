import logging
import uuid
from typing import List, Optional

from app.adapters.gemini_adapter import GeminiAdapter
from app.services.prompt_service import (
    OpportunityDiscoveryResponse,
    OpportunityItem,
    PromptService,
)

logger = logging.getLogger(__name__)


# Deterministic curated catalog of grounded micro-enterprise templates for fallback/sandbox
GROUNDED_OPPORTUNITY_CATALOG = [
    # Micro Tier (<= ₹50,000)
    {
        "title": "Home-Based Spice Grinding & Packaging Unit",
        "domain": "Food Processing",
        "summary": "Procuring whole spices from local wholesale mandis, grinding, and sealing in 100g/250g retail pouches.",
        "why_it_may_fit": ["Low capex requirements", "High daily consumption in rural households", "Can operate from home"],
        "min_capital": 20000.0,
        "max_capital": 60000.0,
        "base_capital": 35000.0,
        "matching_keywords": ["food", "spices", "packaging", "retail", "manual"],
        "feasibility_score": 0.85,
        "local_demand_indicator": "high",
        "unknowns": ["Local retail margin expectations", "FSSAI registration turnaround time in district"],
        "next_validation_step": "Interview 15 neighborhood kirana stores about stocking 250g unbranded turmeric/chilli packets.",
    },
    {
        "title": "Organic Vermicompost Production Unit",
        "domain": "Agri-Business",
        "summary": "Converting farm cow dung and biomass into organic vermicompost for local farmers and horticulture growers.",
        "why_it_may_fit": ["Utilizes abundant local organic waste", "Zero synthetic chemical input costs", "Low initial capital"],
        "min_capital": 15000.0,
        "max_capital": 50000.0,
        "base_capital": 30000.0,
        "matching_keywords": ["agriculture", "farming", "dairy", "livestock", "organic"],
        "feasibility_score": 0.82,
        "local_demand_indicator": "high",
        "unknowns": ["Local farmer willingness to switch from subsidized chemical urea"],
        "next_validation_step": "Survey 10 local vegetable farmers on their monthly expenditure on soil conditioners.",
    },
    # Small Tier (₹50,000 - ₹2,50,000)
    {
        "title": "Mini Dairy Chilling & Bulk Milk Collection Point",
        "domain": "Dairy",
        "summary": "Establishing a centralized collection hub with fat-testing analyzer and mini bulk milk cooler for 20-30 dairy farmers.",
        "why_it_may_fit": ["Experience in cattle rearing", "Daily recurring cash flow", "Direct off-take by dairy cooperatives"],
        "min_capital": 80000.0,
        "max_capital": 220000.0,
        "base_capital": 140000.0,
        "matching_keywords": ["dairy", "livestock", "cows", "milk", "buffalo"],
        "feasibility_score": 0.89,
        "local_demand_indicator": "high",
        "unknowns": ["Consistency of 3-phase electricity supply for chilling tank"],
        "next_validation_step": "Visit the nearest cooperative dairy procurement center to verify daily collection routes.",
    },
    {
        "title": "Solar Powered Micro Cold Room",
        "domain": "Logistics & Storage",
        "summary": "Mini 2-ton solar chilling kiosk providing affordable pay-per-crate overnight storage for vegetable growers.",
        "why_it_may_fit": ["Reduces distress selling of perishable produce", "High government subsidy eligibility", "Shared infrastructure model"],
        "min_capital": 120000.0,
        "max_capital": 300000.0,
        "base_capital": 180000.0,
        "matching_keywords": ["solar", "storage", "vegetables", "farming", "perishables"],
        "feasibility_score": 0.84,
        "local_demand_indicator": "medium",
        "unknowns": ["Vendor willingness to pay ₹15-20 per crate per night"],
        "next_validation_step": "Interview 15 vegetable vendors at the local weekly haat regarding daily spoilage loss.",
    },
    # Medium Tier (> ₹2,50,000)
    {
        "title": "Millet Value-Addition & Flour Packaging Unit",
        "domain": "Food Processing",
        "summary": "Processing locally grown millets (Ragi/Jowar/Bajra) into ready-to-use flour and roasted healthy snacks.",
        "why_it_may_fit": ["Surging health-conscious demand", "High value retention compared to raw grains", "Eligible for PM-FME subsidy"],
        "min_capital": 200000.0,
        "max_capital": 500000.0,
        "base_capital": 320000.0,
        "matching_keywords": ["millet", "grains", "food", "processing", "flour"],
        "feasibility_score": 0.87,
        "local_demand_indicator": "high",
        "unknowns": ["Consumer acceptance of blended vs pure millet flour"],
        "next_validation_step": "Conduct taste and willingness-to-pay test with 25 urban-adjacent households.",
    },
    {
        "title": "Farm Machinery & Custom Hiring Center",
        "domain": "Agri-Services",
        "summary": "Providing tractor-mounted rotavators, seed drills, and power sprayers on hourly rental to smallholder farmers.",
        "why_it_may_fit": ["High demand during sowing and harvesting peaks", "Strong asset-backed security", "Subsidized under SMAM"],
        "min_capital": 250000.0,
        "max_capital": 750000.0,
        "base_capital": 450000.0,
        "matching_keywords": ["tractor", "machinery", "equipment", "farming", "rental"],
        "feasibility_score": 0.81,
        "local_demand_indicator": "high",
        "unknowns": ["Peak seasonal equipment utilization rate"],
        "next_validation_step": "Map competing tractor owners within 10km radius and document their hourly rates.",
    },
]


class OpportunityGenerator:
    """
    Synthesizes entrepreneur constraints (skills, capital, location) with local demand signals.
    Employs Gemini AI for adaptive contextual synthesis and falls back on grounded, verified templates.
    """

    def __init__(
        self,
        adapter: Optional[GeminiAdapter] = None,
        prompt_service: Optional[PromptService] = None,
    ):
        self.adapter = adapter or GeminiAdapter()
        self.prompt_service = prompt_service or PromptService()

    async def discover_opportunities(
        self,
        skills: List[str],
        capital: float,
        location: str,
        count: int = 3,
        language: str = "en",
    ) -> OpportunityDiscoveryResponse:
        """
        Discovers tailored, feasible business opportunities adhering strictly to capital limits.
        """
        clamped_count = max(1, min(count, 5))
        max_feasible_capital = max(capital * 3.5, 50000.0)

        if self.adapter.is_live:
            try:
                system_prompt, user_prompt = self.prompt_service.build_opportunity_prompt(
                    skills=skills,
                    capital=capital,
                    location=location,
                    count=clamped_count,
                    language=language,
                )
                ai_response = await self.adapter.generate_structured_output(
                    system_instruction=system_prompt,
                    user_prompt=user_prompt,
                    response_schema=OpportunityDiscoveryResponse,
                )
                # Filter out unrealistic proposals where capital exceeds reasonable borrowing capacity
                filtered_opps = [
                    opp
                    for opp in ai_response.opportunities
                    if opp.estimated_capital_required <= max_feasible_capital
                ]
                if filtered_opps:
                    # Assign IDs if missing
                    for opp in filtered_opps:
                        if not opp.id:
                            opp.id = f"opp-{uuid.uuid4().hex[:8]}"
                    return OpportunityDiscoveryResponse(opportunities=filtered_opps[:clamped_count])
            except Exception as e:
                logger.warning(f"AI opportunity discovery failed ({e}). Falling back to grounded catalog.")

        # Fallback to deterministic catalog
        return self._generate_fallback_opportunities(skills, capital, location, clamped_count)

    def _generate_fallback_opportunities(
        self,
        skills: List[str],
        capital: float,
        location: str,
        count: int,
    ) -> OpportunityDiscoveryResponse:
        """Synthesizes deterministic, curated opportunities strictly respecting capital constraints."""
        max_allowed_capex = max(capital * 3.0, 50000.0)
        skills_lower = [s.lower() for s in skills]

        # Score catalog items based on capital compatibility and skill keywords
        scored_candidates = []
        for item in GROUNDED_OPPORTUNITY_CATALOG:
            # Capital constraint: must be reasonably achievable
            if item["min_capital"] > max_allowed_capex:
                continue

            score = item["feasibility_score"]
            # Boost score if skills match
            keyword_matches = sum(
                1 for kw in item["matching_keywords"] if any(kw in s for s in skills_lower)
            )
            if keyword_matches > 0:
                score += min(keyword_matches * 0.05, 0.15)

            # Proximity to user's exact capital
            if item["base_capital"] <= capital:
                score += 0.05

            scored_candidates.append((score, item))

        # Sort by score descending
        scored_candidates.sort(key=lambda x: x[0], reverse=True)

        selected_items = []
        for score, template in scored_candidates[:count]:
            # Scale estimated capital to match user's capital within template bounds
            est_capital = min(max(capital * 1.2, template["min_capital"]), template["max_capital"])
            item = OpportunityItem(
                id=f"opp-{uuid.uuid4().hex[:8]}",
                title=template["title"],
                domain=template["domain"],
                summary=f"{template['summary']} Tailored for operations in {location}.",
                why_it_may_fit=template["why_it_may_fit"],
                estimated_capital_required=round(est_capital, 2),
                feasibility_score=round(min(score, 0.95), 2),
                local_demand_indicator=template["local_demand_indicator"],
                initial_evidence_ids=["EVID-GOV-MICRO-01"],
                unknowns=template["unknowns"],
                next_validation_step=template["next_validation_step"],
            )
            selected_items.append(item)

        # Fallback if catalog filter was too tight
        if not selected_items:
            first_template = GROUNDED_OPPORTUNITY_CATALOG[0]
            selected_items.append(
                OpportunityItem(
                    id=f"opp-{uuid.uuid4().hex[:8]}",
                    title=first_template["title"],
                    domain=first_template["domain"],
                    summary=f"{first_template['summary']} Tailored for {location}.",
                    why_it_may_fit=first_template["why_it_may_fit"],
                    estimated_capital_required=round(min(capital, 30000.0), 2),
                    feasibility_score=0.80,
                    local_demand_indicator="medium",
                    initial_evidence_ids=["EVID-GOV-MICRO-01"],
                    unknowns=first_template["unknowns"],
                    next_validation_step=first_template["next_validation_step"],
                )
            )

        return OpportunityDiscoveryResponse(opportunities=selected_items)
