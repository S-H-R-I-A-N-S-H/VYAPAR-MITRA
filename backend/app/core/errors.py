from typing import Any, Optional
from fastapi import HTTPException, status


class VyaparMitraException(HTTPException):
    """Base exception for application domain errors."""

    def __init__(
        self,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        detail: str = "An application error occurred.",
        error_code: str = "APPLICATION_ERROR",
        extra: Optional[Any] = None,
    ):
        super().__init__(status_code=status_code, detail=detail)
        self.error_code = error_code
        self.extra = extra


class ResourceNotFoundException(VyaparMitraException):
    def __init__(self, resource: str, resource_id: str):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{resource} with ID '{resource_id}' was not found.",
            error_code="RESOURCE_NOT_FOUND",
        )


class UnauthorizedAccessException(VyaparMitraException):
    def __init__(self, detail: str = "Invalid or expired authorization token."):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            error_code="UNAUTHORIZED",
        )


class ForbiddenOperationException(VyaparMitraException):
    def __init__(self, detail: str = "Access to this resource is forbidden."):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
            error_code="FORBIDDEN",
        )


class AIProviderException(VyaparMitraException):
    def __init__(
        self,
        detail: str = "AI reasoning service error.",
        error_code: str = "AI_PROVIDER_ERROR",
        extra: Optional[Any] = None,
    ):
        super().__init__(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=detail,
            error_code=error_code,
            extra=extra,
        )


class ServiceUnavailableException(VyaparMitraException):
    """Raised when a required backend service (DB, external API) is temporarily unavailable."""
    def __init__(self, detail: str = "A required service is temporarily unavailable. Please try again shortly."):
        super().__init__(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=detail,
            error_code="SERVICE_UNAVAILABLE",
        )


class ValidationException(VyaparMitraException):
    """Raised for business-logic validation failures (distinct from Pydantic schema errors)."""
    def __init__(self, detail: str = "Request validation failed.", extra: Optional[Any] = None):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail,
            error_code="VALIDATION_ERROR",
            extra=extra,
        )
