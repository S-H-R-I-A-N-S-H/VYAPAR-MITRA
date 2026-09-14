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
    page: int = Field(default=1, ge=1, description="Page number (1-indexed)")
    page_size: int = Field(default=20, ge=1, le=100, description="Items per page (1 to 100)")

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.page_size

    @property
    def limit(self) -> int:
        return self.page_size

    def range_offset(self) -> tuple[int, int]:
        """Returns 0-indexed inclusive (start, end) range tuple for PostgREST .range(start, end)."""
        start = self.offset
        end = start + self.page_size - 1
        return (start, end)



class DatabaseHealth(BaseModel):
    status: str = Field(..., description="Status: connected, disconnected, or unconfigured")
    latency_ms: Optional[float] = Field(default=None, description="Roundtrip latency in milliseconds")
    error: Optional[str] = Field(default=None, description="Sanitized error message if disconnected")


class HealthStatus(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    environment: str = "development"
    database: DatabaseHealth = Field(default_factory=lambda: DatabaseHealth(status="unconfigured"))
