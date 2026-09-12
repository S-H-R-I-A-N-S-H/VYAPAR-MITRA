import re
from typing import Any, Dict, List, Optional, Tuple
from pydantic import BaseModel, Field

from app.schemas.finance import FinancialSimulationResult


# ---------------------------------------------------------------------------
# Input Sanitization for LLM Security (Prompt Injection Guardrails)
# ---------------------------------------------------------------------------

INJECTION_PATTERNS = [
    r"ignore\s+(all\s+)?(previous|above)\s+instructions",
    r"system\s+prompt",
    r"disregard\s+all\s+prior",
    r"you\s+are\s+now\s+in\s+developer\s+mode",
    r"jailbreak",
    r"output\s+the\s+initial\s+prompt",
    r"act\s+as\s+an\s+unrestricted",
]

COMPILED_INJECTION_RE = re.compile(
    "|".join(INJECTION_PATTERNS), re.IGNORECASE
)


def sanitize_prompt_input(text: str) -> str:
    """
    Sanitizes user input by stripping injection patterns, controlling whitespace,
    and removing control characters to prevent prompt hijacking.
    """
    if not text:
        return ""
    # Strip null bytes and non-printable control characters
    cleaned = "".join(ch for ch in text if ch.isprintable() or ch in "\n\t ")
    # Replace injection patterns with empty string
    cleaned = COMPILED_INJECTION_RE.sub("", cleaned)
    # Strip leading/trailing whitespace
    return cleaned.strip()


# ---------------------------------------------------------------------------
# Structured Pydantic Schemas for AI Outputs
# ---------------------------------------------------------------------------

class ExtractedFactor(BaseModel):
    factor: str = Field(description="skills, experience, capital, risk_preference, location_resource, interest")
    value: str = Field(description="Extracted insight, e.g. '5 years dairy processing'")
    confidence: float = Field(ge=0.0, le=1.0, description="Confidence in extraction")


class InterviewTurnResponse(BaseModel):
    reply: str = Field(description="Conversational empathetic response in user's language")
    extracted_factors: List[ExtractedFactor] = Field(default_factory=list)
    next_question: Optional[str] = Field(None, description="Targeted follow-up question")
    is_complete: bool = Field(default=False, description="True if sufficient profile context gathered")


class OpportunityItem(BaseModel):
    id: Optional[str] = None
    title: str
    domain: str
    summary: str
    why_it_may_fit: List[str]
    estimated_capital_required: float
    feasibility_score: float = Field(ge=0.0, le=1.0)
    local_demand_indicator: str = Field(default="medium", description="high, medium, low")
    initial_evidence_ids: List[str] = Field(default_factory=list)
    unknowns: List[str] = Field(default_factory=list)
    next_validation_step: str


class OpportunityDiscoveryResponse(BaseModel):
    opportunities: List[OpportunityItem]


class FinancialExplanationResponse(BaseModel):
    executive_summary: str
    viability_analysis: str
    key_financial_risks: List[str]
    breakeven_interpretation: str
    suggested_actions: List[str]


class ResearchQuestion(BaseModel):
    id: Optional[str] = None
    question: str
    category: str = Field(description="demand, competition, pricing, supplier, distribution, risk")
    purpose: str


class ResearchQuestionsResponse(BaseModel):
    questions: List[ResearchQuestion]


class ConflictResolutionProposal(BaseModel):
    explanation: str
    confidence_impact: str = Field(description="high_risk, medium_risk, low_risk")
    suggested_action: str
    recommended_field_validation: str


# ---------------------------------------------------------------------------
# Prompt Engineering & Grounding Service
# ---------------------------------------------------------------------------

class PromptService:
    """
    Constructs grounded, multilingual prompts enforcing SIH 26091 AI principles:
    - Evidence before confidence
    - Deterministic financial integrity (never hallucinates financial numbers)
    - Multilingual adaptation (Hindi, Marathi, Gujarati, English, etc.)
    """

    def build_interview_prompt(
        self,
        conversation_history: List[Dict[str, str]],
        language: str = "en",
        known_context: Optional[Dict[str, Any]] = None,
    ) -> Tuple[str, str]:
        """Generates system instruction and user prompt for conversational profile discovery."""
        context_str = ""
        if known_context:
            context_str = f"Known entrepreneur context: {known_context}\n"

        system_instruction = (
            f"You are Vyapar Mitra, an empathetic, highly knowledgeable AI business mentor for rural "
            f"and micro-entrepreneurs in India.\n"
            f"Target conversation language: {language}.\n"
            f"RULES:\n"
            f"1. Be encouraging, conversational, and concise (avoid asking more than 1 or 2 questions at a time).\n"
            f"2. DO NOT ask questions whose answers are already known in the context.\n"
            f"3. Continuously extract structured facts into 'extracted_factors' (skills, experience, available capital, risk tolerance, assets).\n"
            f"4. If you have gathered sufficient information (skills, capital range, business domain interest), mark is_complete=true.\n"
            f"{context_str}"
        )

        # Build turn sequence
        history_lines = []
        for msg in conversation_history:
            role = msg.get("role", "user")
            content = sanitize_prompt_input(msg.get("content", ""))
            history_lines.append(f"{role.capitalize()}: {content}")

        user_prompt = "\n".join(history_lines) if history_lines else "User: Hello, I want to explore starting a business."
        return system_instruction, user_prompt

    def build_financial_explanation_prompt(
        self,
        simulation_result: FinancialSimulationResult,
        business_name: str,
        language: str = "en",
    ) -> Tuple[str, str]:
        """
        Enforces deterministic financial constraints.
        The AI MUST explain the pre-calculated numbers and NOT recalculate or invent numbers.
        """
        system_instruction = (
            f"You are the Financial Advisory module of Vyapar Mitra.\n"
            f"Response language: {language}.\n"
            f"CRITICAL PRINCIPLE: Financial calculations are STRICTLY DETERMINISTIC.\n"
            f"You MUST NOT calculate or invent your own financial numbers, EMIs, interest rates, or profit figures.\n"
            f"You must strictly ground your interpretation in the verified simulation output provided below.\n"
            f"Explain the viability, risks, and next steps in plain, accessible terms for a first-time entrepreneur."
        )

        user_prompt = (
            f"Business: {business_name}\n"
            f"Verified Simulation Output:\n"
            f"- Total Project Cost: ₹{simulation_result.total_project_cost:,.2f} ({simulation_result.total_project_cost})\n"
            f"- Own Capital: ₹{simulation_result.own_capital:,.2f} ({simulation_result.own_capital})\n"
            f"- Required Loan Amount: ₹{simulation_result.required_loan_amount:,.2f} ({simulation_result.required_loan_amount})\n"
            f"- Monthly Loan EMI: ₹{simulation_result.monthly_emi:,.2f} ({simulation_result.monthly_emi})\n"
            f"- Projected Monthly Profit: ₹{simulation_result.projected_monthly_profit:,.2f} ({simulation_result.projected_monthly_profit})\n"
            f"- Net Cash Flow After EMI: ₹{simulation_result.net_cash_flow_after_emi:,.2f} ({simulation_result.net_cash_flow_after_emi})\n"
            f"- Debt Service Coverage Ratio (DSCR): {simulation_result.debt_service_coverage_ratio:.2f}\n"
            f"- Risk Assessment Tier: {simulation_result.affordability_risk_level}\n"
            f"- Is Affordable: {simulation_result.is_affordable}\n"
            f"- Rationale: {simulation_result.affordability_rationale}\n\n"
            f"Please provide an executive summary, viability analysis, key financial risks, "
            f"breakeven interpretation, and practical suggested actions for this entrepreneur."
        )

        return system_instruction, user_prompt

    def build_opportunity_prompt(
        self,
        skills: List[str],
        capital: float,
        location: str,
        count: int = 3,
        language: str = "en",
    ) -> Tuple[str, str]:
        """Generates prompt for grounded opportunity synthesis."""
        system_instruction = (
            f"You are the Opportunity Discovery Engine of Vyapar Mitra.\n"
            f"Response language: {language}.\n"
            f"Your job is to recommend realistic, viable micro-business opportunities tailored to "
            f"the entrepreneur's exact capital and skills.\n"
            f"RULES:\n"
            f"1. Never recommend businesses requiring significantly more capital than available.\n"
            f"2. Explicitly explain WHY each opportunity fits their skill set and location.\n"
            f"3. Clearly identify what remains UNKNOWN and what primary field validation step is required next.\n"
            f"4. Do not present opportunities as guaranteed successes."
        )

        user_prompt = (
            f"Entrepreneur Profile:\n"
            f"- Skills & Experience: {', '.join(skills) if skills else 'General manual & retail'}\n"
            f"- Available Capital: ₹{capital:,.2f} ({capital})\n"
            f"- Geography / Location: {location}\n"
            f"- Number of Opportunities Requested: {count}\n\n"
            f"Generate {count} distinct, viable micro-business opportunities matching these constraints."
        )

        return system_instruction, user_prompt

    def build_research_questions_prompt(
        self,
        business_name: str,
        domain: str,
        target_market: str,
        language: str = "en",
    ) -> Tuple[str, str]:
        """Generates targeted, falsifiable validation questions across key business pillars."""
        system_instruction = (
            f"You are the Market Research Orchestrator of Vyapar Mitra.\n"
            f"Target language: {language}.\n"
            f"Generate targeted, specific, and falsifiable research questions to validate this business idea.\n"
            f"Categories must include: demand, competition, pricing, supplier, distribution, and risk.\n"
            f"Avoid vague questions like 'Is the market good?'. Ask concrete questions that can be answered "
            f"with data or field interviews."
        )

        user_prompt = (
            f"Business: {business_name}\n"
            f"Domain: {domain}\n"
            f"Target Market / Geography: {target_market}\n"
            f"Generate 6 high-priority validation questions across the required categories."
        )

        return system_instruction, user_prompt

    def build_conflict_resolution_prompt(
        self,
        conflict_topic: str,
        primary_claim: str,
        primary_source: str,
        secondary_claim: str,
        secondary_source: str,
        language: str = "en",
    ) -> Tuple[str, str]:
        """Generates prompt to explain evidence discrepancy and propose resolution."""
        system_instruction = (
            f"You are the Evidence Reconciliation Engine of Vyapar Mitra.\n"
            f"Target language: {language}.\n"
            f"Analyze the discrepancy between secondary macro research and primary local field evidence.\n"
            f"Explain why the conflict exists (e.g. macro statistical trend vs local customer preference).\n"
            f"Suggest concrete, actionable field validation steps the entrepreneur can take."
        )

        user_prompt = (
            f"Topic of Conflict: {conflict_topic}\n"
            f"Secondary Research Source: {secondary_source}\n"
            f"Secondary Claim: {secondary_claim}\n"
            f"Primary Field Survey Source: {primary_source}\n"
            f"Primary Field Claim: {primary_claim}\n\n"
            f"Synthesize the conflict, explain the root cause of the divergence, and provide a concrete action plan."
        )

        return system_instruction, user_prompt
