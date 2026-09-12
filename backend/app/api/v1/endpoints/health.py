from fastapi import APIRouter
from app.adapters.supabase_adapter import supabase_adapter
from app.core.config import settings
from app.schemas.common import APIResponse, DatabaseHealth, HealthStatus

router = APIRouter()


@router.get("/health", response_model=APIResponse[HealthStatus])
async def health_check():
    """Health check endpoint to verify backend status and live Supabase connectivity."""
    db_health = supabase_adapter.check_connection()

    db_status = DatabaseHealth(
        status=db_health["status"],
        latency_ms=db_health.get("latency_ms"),
        error=db_health.get("error"),
    )

    overall_status = "ok" if db_status.status == "connected" else "degraded"

    return APIResponse(
        success=True,
        data=HealthStatus(
            status=overall_status,
            version="1.0.0",
            environment=settings.ENVIRONMENT,
            database=db_status,
        ),
        message=f"VYAPAR MITRA API status: {overall_status}.",
    )
