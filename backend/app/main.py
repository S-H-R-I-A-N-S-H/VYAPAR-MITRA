import sys
from pathlib import Path

# Ensure backend package directory is in python search path
_backend_dir = str(Path(__file__).resolve().parent.parent)
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api.v1.router import api_v1_router
from app.core.config import settings
from app.core.errors import VyaparMitraException
from app.schemas.common import APIResponse

app = FastAPI(
    title="VYAPAR MITRA Backend API",
    description="Full-Lifecycle Evidence-Based Advisory & Smart Financing for Rural Micro-Entrepreneurs",
    version="1.0.0",
)

# CORS Middleware (allows Flutter cross-platform access)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(VyaparMitraException)
async def vyapar_mitra_exception_handler(request: Request, exc: VyaparMitraException):
    return JSONResponse(
        status_code=exc.status_code,
        content=APIResponse(
            success=False,
            data=exc.extra,
            message=exc.detail,
            error_code=exc.error_code,
        ).model_dump(),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=APIResponse(
            success=False,
            message="An unexpected internal server error occurred. Please try again later.",
            error_code="INTERNAL_SERVER_ERROR",
        ).model_dump(),
    )


# Attach API v1 Router
app.include_router(api_v1_router, prefix="/api")


@app.get("/")
async def root():
    return {
        "app": "VYAPAR MITRA API",
        "docs": "/docs",
        "version": "1.0.0",
    }
