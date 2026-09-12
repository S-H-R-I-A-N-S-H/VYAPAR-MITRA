from typing import Generic, Optional, TypeVar
from pydantic import BaseModel, Field

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    """Standard unified response wrapper for all API endpoints."""

    success: bool = Field(default=True, description="Whether the request succeeded")
    data: Optional[T] = Field(default=None, description="Payload data")
    message: Optional[str] = Field(default=None, description="User-facing summary message")
    error_code: Optional[str] = Field(default=None, description="Machine-readable error code if failed")


class PaginationParams(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)


class HealthStatus(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    environment: str = "development"
