from fastapi import APIRouter
from app.api.v1.endpoints import (
    businesses,
    evidence,
    feasibility,
    finance,
    geospatial,
    health,
    interview,
    opportunities,
    profile,
    recommendations,
    research,
    schemes,
    speech,
    surveys,
)

api_v1_router = APIRouter(prefix="/v1")

api_v1_router.include_router(health.router, tags=["Health"])
api_v1_router.include_router(speech.router, tags=["Speech & Bhashini"])
api_v1_router.include_router(profile.router, tags=["Profile & Location"])
api_v1_router.include_router(interview.router, tags=["Conversational Interview"])
api_v1_router.include_router(opportunities.router, tags=["Opportunity Discovery"])
api_v1_router.include_router(businesses.router, tags=["Businesses"])
api_v1_router.include_router(feasibility.router, tags=["Business Feasibility"])
api_v1_router.include_router(recommendations.router, tags=["Recommendations"])
api_v1_router.include_router(research.router, tags=["Research"])
api_v1_router.include_router(surveys.router, tags=["Surveys"])
api_v1_router.include_router(finance.router, prefix="/finance", tags=["Finance"])
api_v1_router.include_router(schemes.router, prefix="/schemes", tags=["Schemes"])
api_v1_router.include_router(evidence.router, prefix="/evidence", tags=["Evidence"])
api_v1_router.include_router(geospatial.router, prefix="/geospatial", tags=["Geospatial Intelligence"])

