from fastapi import APIRouter
from app.schemas.common import APIResponse, HealthStatus

router = APIRouter()


@router.get("/health", response_model=APIResponse[HealthStatus])
async def health_check():
    """Health check endpoint to verify backend status."""
    return APIResponse(
        success=True,
        data=HealthStatus(status="ok", version="1.0.0", environment="development"),
        message="VYAPAR MITRA API is healthy and operational.",
    )
