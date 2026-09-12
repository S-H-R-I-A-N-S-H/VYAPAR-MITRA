from fastapi import APIRouter
from app.api.v1.endpoints import evidence, finance, health, schemes

api_v1_router = APIRouter(prefix="/v1")

api_v1_router.include_router(health.router, tags=["Health"])
api_v1_router.include_router(finance.router, prefix="/finance", tags=["Finance"])
api_v1_router.include_router(schemes.router, prefix="/schemes", tags=["Schemes"])
api_v1_router.include_router(evidence.router, prefix="/evidence", tags=["Evidence"])
