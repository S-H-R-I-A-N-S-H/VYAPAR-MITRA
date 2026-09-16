import logging
import logging.config
import sys
import uuid
from contextvars import ContextVar
from pathlib import Path
from typing import Callable

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

# ---------------------------------------------------------------------------
# Structured Logging Configuration (Vyapar Mitra Backend)
# ---------------------------------------------------------------------------

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "json": {
            "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
            "fmt": "%(asctime)s %(name)s %(levelname)s %(message)s %(request_id)s %(user_id)s %(method)s %(path)s %(status_code)s %(duration_ms)s",
            "datefmt": "%Y-%m-%dT%H:%M:%S",
        },
        "simple": {
            "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "stream": "ext://sys.stdout",
            "formatter": "json" if settings.ENVIRONMENT == "production" else "simple",
        },
    },
    "root": {
        "level": settings.LOG_LEVEL.upper(),
        "handlers": ["console"],
    },
}

try:
    logging.config.dictConfig(LOGGING_CONFIG)
except Exception:
    # Fallback if python-json-logger is not installed (dev without the package)
    logging.basicConfig(
        level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Production Guard — fail fast if dangerous dev flags are set in production
# ---------------------------------------------------------------------------

if settings.ENVIRONMENT == "production" and getattr(settings, "DEV_ALLOW_ANONYMOUS", False):
    raise RuntimeError(
        "FATAL: DEV_ALLOW_ANONYMOUS=True is set but ENVIRONMENT=production. "
        "This would disable all authentication. Refusing to start."
    )

# ---------------------------------------------------------------------------
# Request Context Vars (for structured per-request logging)
# ---------------------------------------------------------------------------

_request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")
_user_id_ctx: ContextVar[str] = ContextVar("user_id", default="-")


class RequestContextFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = _request_id_ctx.get("-")
        record.user_id = _user_id_ctx.get("-")
        if not hasattr(record, "method"):
            record.method = "-"
        if not hasattr(record, "path"):
            record.path = "-"
        if not hasattr(record, "status_code"):
            record.status_code = "-"
        if not hasattr(record, "duration_ms"):
            record.duration_ms = "-"
        return True


_context_filter = RequestContextFilter()
logging.getLogger().addFilter(_context_filter)
for handler in logging.getLogger().handlers:
    handler.addFilter(_context_filter)

from contextlib import asynccontextmanager

# ---------------------------------------------------------------------------
# Application Lifespan (Startup & Graceful Shutdown - FIX INFRA4)
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(
        f"Starting Vyapar Mitra Backend API v1.0.0 [env={settings.ENVIRONMENT}]"
    )
    try:
        from app.adapters.supabase_adapter import supabase_adapter
        if supabase_adapter.is_connected:
            logger.info("Supabase database adapter initialized successfully.")
        else:
            logger.warning("Supabase database connection not ready or in sandbox/offline mode.")
    except Exception as exc:
        logger.warning(f"Database pre-flight check warning on startup: {exc}")
    yield
    logger.info("Shutting down Vyapar Mitra Backend API cleanly.")


# ---------------------------------------------------------------------------
# FastAPI Application
# ---------------------------------------------------------------------------

app = FastAPI(
    title="VYAPAR MITRA Backend API",
    description="Full-Lifecycle Evidence-Based Advisory & Smart Financing for Rural Micro-Entrepreneurs",
    version="1.0.0",
    lifespan=lifespan,
)


# ---------------------------------------------------------------------------
# CORS Middleware
# FIX(CRIT-1): allow_credentials=False for wildcard origin.
# JWT-header-based auth does not require credentials mode.
# For web clients with specific origins, enumerate them in CORS_ORIGINS env var.
# ---------------------------------------------------------------------------

_cors_origins = [o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()] if settings.CORS_ORIGINS else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=False,   # FIX: cannot be True with wildcard origin (CORS spec violation)
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "X-Request-ID"],
)

# ---------------------------------------------------------------------------
# Request ID + Timing Middleware
# ---------------------------------------------------------------------------

@app.middleware("http")
async def request_id_and_logging_middleware(request: Request, call_next: Callable):
    request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
    _request_id_ctx.set(request_id)

    import time
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = round((time.perf_counter() - start) * 1000, 2)

    response.headers["X-Request-ID"] = request_id
    logger.info(
        f"{request.method} {request.url.path} -> {response.status_code} ({duration_ms}ms)",
        extra={
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
        },
    )
    return response

# ---------------------------------------------------------------------------
# Exception Handlers
# ---------------------------------------------------------------------------

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
    logger.error(
        "Unhandled exception",
        extra={"error": str(exc), "error_type": type(exc).__name__},
        exc_info=True,
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=APIResponse(
            success=False,
            message="An unexpected internal server error occurred. Please try again later.",
            error_code="INTERNAL_SERVER_ERROR",
        ).model_dump(),
    )


# ---------------------------------------------------------------------------
# Attach API v1 Router
# ---------------------------------------------------------------------------

app.include_router(api_v1_router, prefix="/api")


@app.get("/")
async def root():
    return {
        "app": "VYAPAR MITRA API",
        "docs": "/docs",
        "version": "1.0.0",
    }
