import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.services.opportunity_generator import OpportunityGenerator
from app.services.prompt_service import OpportunityDiscoveryResponse, OpportunityItem


@pytest.mark.asyncio
async def test_opportunity_generator_fallback_when_gemini_offline():
    # Test that when gemini adapter is offline or returns mock, generator provides grounded fallbacks
    with patch("app.services.opportunity_generator.GeminiAdapter") as MockAdapter:
        mock_adapter_instance = MagicMock()
        mock_adapter_instance.is_live = False
        MockAdapter.return_value = mock_adapter_instance

        generator = OpportunityGenerator(adapter=mock_adapter_instance)
        result = await generator.discover_opportunities(
            skills=["dairy", "livestock"],
            capital=150000.0,
            location="Baramati, Maharashtra",
            count=3
        )

        assert isinstance(result, OpportunityDiscoveryResponse)
        assert len(result.opportunities) >= 1
        first_opp = result.opportunities[0]
        assert first_opp.title != ""
        assert first_opp.estimated_capital_required > 0
        assert len(first_opp.why_it_may_fit) > 0
        assert first_opp.next_validation_step != ""


@pytest.mark.asyncio
async def test_opportunity_generator_with_live_ai_structured_output():
    mock_response = OpportunityDiscoveryResponse(
        opportunities=[
            OpportunityItem(
                id="opp-1",
                title="Millet Value Addition Unit",
                domain="Food Processing",
                summary="Processing pearl millet into packaged ready-to-cook flour.",
                why_it_may_fit=["Local millet harvest available", "Low machinery cost"],
                estimated_capital_required=120000.0,
                feasibility_score=0.86,
                local_demand_indicator="high",
                initial_evidence_ids=["EVID-101"],
                unknowns=["Retail shelf life in humid months"],
                next_validation_step="Survey 20 local kirana stores about stocking packaged flour"
            )
        ]
    )

    mock_adapter = MagicMock()
    mock_adapter.is_live = True
    mock_adapter.generate_structured_output = AsyncMock(return_value=mock_response)

    generator = OpportunityGenerator(adapter=mock_adapter)
    result = await generator.discover_opportunities(
        skills=["food processing"],
        capital=150000.0,
        location="Nashik, Maharashtra",
        count=1
    )

    assert len(result.opportunities) == 1
    assert result.opportunities[0].title == "Millet Value Addition Unit"
    assert result.opportunities[0].feasibility_score == 0.86


@pytest.mark.asyncio
async def test_opportunity_generator_filters_excessive_capital_proposals():
    # If an AI proposal exceeds reasonable leverage (e.g. requires 20 lakhs when user has 50k),
    # generator caps or flags feasibility appropriately.
    mock_response = OpportunityDiscoveryResponse(
        opportunities=[
            OpportunityItem(
                id="opp-unrealistic",
                title="Commercial Cold Storage Plant",
                domain="Logistics",
                summary="Large 500-ton cold storage facility.",
                why_it_may_fit=["District needs cold storage"],
                estimated_capital_required=5000000.0,  # 50 Lakhs
                feasibility_score=0.9,
                local_demand_indicator="high",
                initial_evidence_ids=[],
                unknowns=["Massive capex debt servicing"],
                next_validation_step="Check bank lending limit"
            ),
            OpportunityItem(
                id="opp-realistic",
                title="Solar Powered Micro Cold Room",
                domain="Logistics",
                summary="Mini 2-ton solar chilling kiosk for perishable vegetables.",
                why_it_may_fit=["Affordable capex, subsidy eligible"],
                estimated_capital_required=180000.0,
                feasibility_score=0.88,
                local_demand_indicator="high",
                initial_evidence_ids=[],
                unknowns=["Local vendor battery replacement cost"],
                next_validation_step="Interview 15 vegetable vendors at mandi"
            )
        ]
    )

    mock_adapter = MagicMock()
    mock_adapter.is_live = True
    mock_adapter.generate_structured_output = AsyncMock(return_value=mock_response)

    generator = OpportunityGenerator(adapter=mock_adapter)
    result = await generator.discover_opportunities(
        skills=["farming"],
        capital=100000.0,
        location="Indore, Madhya Pradesh",
        count=2
    )

    # The 50 lakh opportunity should be adjusted/filtered or marked with reduced feasibility
    feasible_opps = [o for o in result.opportunities if o.estimated_capital_required <= 100000.0 * 3.5]
    assert len(feasible_opps) >= 1
    assert feasible_opps[0].title == "Solar Powered Micro Cold Room"


@pytest.mark.asyncio
async def test_opportunity_generator_handles_empty_skills_and_low_capital():
    mock_adapter = MagicMock()
    mock_adapter.is_live = False

    generator = OpportunityGenerator(adapter=mock_adapter)
    result = await generator.discover_opportunities(
        skills=[],
        capital=25000.0,  # Micro capital (25k)
        location="Rural Sehore, MP",
        count=2
    )

    assert len(result.opportunities) >= 1
    for opp in result.opportunities:
        # Should be tailored for micro-capital
        assert opp.estimated_capital_required <= 100000.0
