from fastapi import APIRouter
from app.schemas.common import APIResponse
from app.schemas.finance import FinancialSimulationInput, FinancialSimulationResult
from app.services.financial_engine import FinancialEngine

router = APIRouter()


@router.post("/simulate", response_model=APIResponse[FinancialSimulationResult])
async def simulate_financials(payload: FinancialSimulationInput):
    """
    Executes authoritative deterministic financial modeling.
    Calculates EMI, cash flow, DSCR, and affordability risk.
    """
    result = FinancialEngine.simulate(payload)
    return APIResponse(
        success=True,
        data=result,
        message="Financial simulation completed successfully.",
    )
